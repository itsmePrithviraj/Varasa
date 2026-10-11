import {randomUUID} from 'node:crypto';
import {db, auth, bucket, FieldPath, HttpsError, profile, account, story, id, hash} from './base.js';
import {mutateFollow, mutateLike, friendship} from './social.js';

export async function requestExport(uid) {
  const ref = db.collection('maintenanceJobs').doc();
  await db.runTransaction(async tx=>{const a=await tx.get(account(uid));if(!a.exists||a.get('deleting'))throw new HttpsError('failed-precondition','Account unavailable.');tx.create(ref,{uid,type:'export',status:'pending',section:0,cursor:null,part:0,leaseUntil:0,attempts:0,createdAtMs:Date.now()});});
  return {id: ref.id};
}
export async function requestDeletion(uid) {
  const ref = db.doc(`maintenanceJobs/delete_${uid}`);
  await db.runTransaction(async tx => {
    const previous = await tx.get(ref);
    if (previous.exists) return;
    tx.set(account(uid), {deleting: true}, {merge: true});
    tx.create(ref, {uid, type: 'delete', status: 'pending', section: 0, leaseUntil: 0, attempts: 0, createdAtMs: Date.now()});
  });
  return {id: ref.id};
}
export async function exportParts(uid, data) {
  const ref = db.doc(`maintenanceJobs/${id(data.jobId)}`), job = await ref.get();
  if (!job.exists || job.get('uid') !== uid || job.get('type') !== 'export') throw new HttpsError('permission-denied', 'Export unavailable.');
  let q = ref.collection('parts').orderBy(FieldPath.documentId());
  if (data.cursor) q = q.startAfter(id(data.cursor));
  const docs = await q.limit(21).get(), slice = docs.docs.slice(0,20);
  return {items: slice.map(d => ({id:d.id,...d.data()})), cursor: docs.size > 20 ? slice.at(-1).id : null};
}
export async function retryJob(uid, data) {
  const ref = db.doc(`maintenanceJobs/${id(data.jobId)}`);
  await db.runTransaction(async tx => {
    const d = await tx.get(ref);
    if (d.get('uid') !== uid || d.get('type') !== 'export' || d.get('status') !== 'failed') throw new HttpsError('failed-precondition', 'This job cannot be retried.');
    tx.update(ref, {status:'pending', attempts:0, leaseUntil:0, errorCode:''});
  });
  return {ok:true};
}
async function claim(ref) {
  const nonce = randomUUID();
  return db.runTransaction(async tx => {
    const d = await tx.get(ref), now = Date.now();
    if (!d.exists || !['pending','running'].includes(d.get('status')) || (d.get('leaseUntil') || 0) > now) return null;
    tx.update(ref, {status:'running', nonce, leaseUntil:now + 240000});
    return {...d.data(), nonce};
  });
}
async function progress(ref, nonce, changes) {
  await db.runTransaction(async tx => {
    const d = await tx.get(ref);
    if (d.get('nonce') !== nonce) throw Error('lease-lost');
    tx.update(ref, {...changes, status:changes.status || 'pending', leaseUntil:0, updatedAtMs:Date.now()});
  });
}
export async function runFanout(ref) {
  const job = await claim(ref);
  if (!job) return;
  try {
    const post = await story(job.storyId).get();
    if (!post.exists || post.get('deleted')) { await progress(ref,job.nonce,{status:'complete'}); return; }
    let q = profile(job.authorId).collection('followers').orderBy(FieldPath.documentId());
    if (job.cursor) q = q.startAfter(job.cursor);
    const followers = await q.limit(200).get(), batch = db.batch();
    for (const follower of followers.docs) batch.set(account(follower.id).collection('feed').doc(post.id),
      {userId:job.authorId,createdAtMs:post.get('createdAtMs')});
    await batch.commit();
    await progress(ref,job.nonce,{cursor:followers.docs.at(-1)?.id || job.cursor, status:followers.size < 200 ? 'complete' : 'pending'});
  } catch (error) { await failure(ref,job,error); }
}
const exportSections = ['profile','following','followers','friends','incoming','outgoing','blocks','stories','comments','likes','reports'];
function exportQuery(uid, section) {
  if (['following','followers','friends','incoming','outgoing'].includes(section)) return profile(uid).collection(section);
  if (section === 'blocks') return account(uid).collection('blocks');
  if (section === 'stories') return db.collection('stories').where('userId','==',uid);
  if (section === 'comments' || section === 'likes') return db.collectionGroup(section).where('userId','==',uid);
  return db.collection('reports').where('reporterId','==',uid);
}
async function exportStep(ref, job) {
  if ((await account(job.uid).get()).get('deleting')) {
    await progress(ref,job.nonce,{status:'cancelled'}); return;
  }
  if (job.section >= exportSections.length) {
    await progress(ref,job.nonce,{status:'complete',expiresAtMs:Date.now()+7*86400000}); return;
  }
  const name = exportSections[job.section];
  let records, next = null;
  if (name === 'profile') {
    const p = await profile(job.uid).get(), u = await auth.getUser(job.uid);
    records = [{path:p.ref.path, data:p.data() || {}, account:{uid:job.uid,email:u.email || '',displayName:u.displayName || '',createdAt:u.metadata.creationTime}}];
  } else {
    let query = exportQuery(job.uid,name).orderBy(FieldPath.documentId());
    if (job.cursor) query = query.startAfter(job.cursor);
    const result = await query.limit(100).get();
    records = result.docs.map(d => ({path:d.ref.path,data:d.data()}));
    // Group cursors require the full document path, ordinary collection cursors use the id.
    if (result.size === 100) next = ['comments','likes'].includes(name) ? result.docs.at(-1).ref.path : result.docs.at(-1).id;
  }
  const partId = `${String(job.section).padStart(2,'0')}_${String(job.part).padStart(6,'0')}`;
  const path = `exports/${job.uid}/${ref.id}/${partId}.json`;
  await bucket.file(path).save(JSON.stringify({schemaVersion:2,section:name,exportedAt:new Date().toISOString(),records},null,2),
    {resumable:false,metadata:{contentType:'application/json',cacheControl:'private, no-store'}});
  await ref.collection('parts').doc(partId).set({path,section:name,records:records.length,createdAtMs:Date.now()});
  await progress(ref,job.nonce,{section:next ? job.section : job.section+1,cursor:next,part:job.part+1});
}
const deletionSections = ['disable','following','followers','friends','incoming','outgoing','comments','likes','stories','reports','targetReports','blocksToUser','storage','identity'];
async function deleteStep(ref,job) {
  const uid = job.uid, section = deletionSections[job.section];
  if (section === 'disable') {
    try { await auth.updateUser(uid,{disabled:true}); await auth.revokeRefreshTokens(uid); }
    catch (e) { if (e.code !== 'auth/user-not-found') throw e; }
  } else if (['following','followers','friends','incoming','outgoing'].includes(section)) {
    const docs = await profile(uid).collection(section).limit(50).get();
    for (const d of docs.docs) {
      if (section === 'following') await mutateFollow(uid,d.id,false);
      else if (section === 'followers') await mutateFollow(d.id,uid,false);
      else await friendship(uid,{userId:d.id,action:section === 'friends' ? 'remove' : section === 'incoming' ? 'decline' : 'cancel'});
      await d.ref.delete();
    }
    if (docs.size) { await progress(ref,job.nonce,{}); return; }
  } else if (section === 'comments' || section === 'likes') {
    const docs = await db.collectionGroup(section).where('userId','==',uid).limit(50).get();
    for (const d of docs.docs) {
      if (section === 'likes') await mutateLike(uid,d.ref.parent.parent.id,false);
      else await db.runTransaction(async tx => {
        const parent = await tx.get(d.ref.parent.parent), comment = await tx.get(d.ref);
        if (parent.exists && comment.exists && !comment.get('deleted')) tx.update(parent.ref,{commentCount:Math.max(0,(parent.get('commentCount') || 0)-1)});
        tx.delete(d.ref);
      });
    }
    if (docs.size) { await progress(ref,job.nonce,{}); return; }
  } else if (section === 'stories') {
    const docs = await db.collection('stories').where('userId','==',uid).limit(20).get();
    for (const d of docs.docs) { await db.recursiveDelete(d.ref); await db.doc(`fanoutJobs/${d.id}`).delete(); }
    if (docs.size) { await progress(ref,job.nonce,{}); return; }
  } else if (section === 'reports') {
    const docs = await db.collection('reports').where('reporterId','==',uid).limit(100).get(), batch = db.batch();
    // Preserve moderation decisions without retaining the reporter's identity or free text.
    for (const d of docs.docs) batch.update(d.ref,{reporterId:'deleted',details:''});
    await batch.commit();
    if (docs.size) { await progress(ref,job.nonce,{}); return; }
  } else if (section === 'targetReports') {
    const docs = await db.collection('reports').where('targetUserId','==',uid).limit(100).get(), batch=db.batch();
    for(const d of docs.docs) batch.update(d.ref,{targetUserId:'deleted',targetPath:'',details:'',note:'',status:d.get('status')==='open'?'removed':d.get('status')});
    await batch.commit();
    if(docs.size){await progress(ref,job.nonce,{});return;}
  } else if (section === 'blocksToUser') {
    const docs = await db.collectionGroup('blocks').where('userId','==',uid).limit(100).get(), batch = db.batch();
    for (const d of docs.docs) batch.delete(d.ref);
    await batch.commit();
    if (docs.size) { await progress(ref,job.nonce,{}); return; }
  } else if (section === 'storage') {
    for (const prefix of [`posts/${uid}/`,`avatars/${uid}/`,`exports/${uid}/`]) await bucket.deleteFiles({prefix});
  } else if (section === 'identity') {
    const handles = await db.collection('handles').where('uid','==',uid).get();
    for (const h of handles.docs) await h.ref.delete();
    const otherJobs = await db.collection('maintenanceJobs').where('uid','==',uid).get();
    for (const j of otherJobs.docs) if (j.id !== ref.id) await db.recursiveDelete(j.ref);
    // Keep a private deletion marker to reject already-in-flight profile creation.
    await db.doc(`deletedAccounts/${uid}`).set({deletedAtMs:Date.now()});
    await db.recursiveDelete(profile(uid));
    await db.recursiveDelete(account(uid));
    try { await auth.deleteUser(uid); } catch (e) { if (e.code !== 'auth/user-not-found') throw e; }
    await progress(ref,job.nonce,{status:'complete',uid:null,subjectHash:hash(uid),section:job.section+1}); return;
  }
  await progress(ref,job.nonce,{section:job.section+1});
}
async function failure(ref,job,error) {
  const attempts = (job.attempts || 0)+1;
  await progress(ref,job.nonce,{status:attempts >= 10 ? 'failed' : 'pending',attempts,errorCode:String(error.code || 'worker-error').slice(0,100)});
}
export async function runMaintenance(ref) {
  const job = await claim(ref);
  if (!job) return;
  try {
    if (job.type === 'export') await exportStep(ref,job);
    else if (job.type === 'delete') await deleteStep(ref,job);
    else throw Error('unknown-job');
  } catch (error) { await failure(ref,job,error); }
}
export async function drainJobs() {
  for (const [collection,worker] of [['fanoutJobs',runFanout],['maintenanceJobs',runMaintenance]]) {
    const jobs = await db.collection(collection).where('status','in',['pending','running']).orderBy('createdAtMs').limit(20).get();
    // Work is bounded; unfinished jobs persist for the next scheduled invocation.
    for (const job of jobs.docs) for (let step=0;step<5;step++) await worker(job.ref);
  }
}
export async function cleanupStorage() {
  const state = db.doc('backendState/storageSweep'), saved = await state.get();
  const [files,next] = await bucket.getFiles({autoPaginate:false,maxResults:200,pageToken:saved.get('cursor') || undefined});
  for (const file of files) {
    const path=file.name, age=Date.now()-Date.parse(file.metadata.timeCreated || new Date().toISOString());
    if (age < 86400000) continue;
    const parts=path.split('/');
    let remove=false;
    if (parts[0] === 'posts' && parts.length === 4) {
      const p=await story(parts[2]).get(); remove=!p.exists || p.get('deleted') === true;
    } else if (parts[0] === 'avatars' && parts.length === 3) {
      const [users,posts]=await Promise.all([db.collection('profiles').where('avatarPath','==',path).limit(1).get(),db.collection('stories').where('authorAvatarPath','==',path).where('deleted','==',false).limit(1).get()]);
      remove=users.empty && posts.empty;
    } else if (parts[0] === 'exports') remove=age > 7*86400000;
    if (remove) await file.delete({ignoreNotFound:true});
  }
  await state.set({cursor:next?.pageToken || null,updatedAtMs:Date.now()});
  const tombstones=await db.collection('stories').where('deleted','==',true).where('deletedAtMs','<',Date.now()-7*86400000).limit(20).get();
  for (const p of tombstones.docs) await db.recursiveDelete(p.ref);
  const expired=await db.collection('rateLimits').where('expiresAtMs','<',Date.now()).limit(300).get(), batch=db.batch();
  for (const d of expired.docs) batch.delete(d.ref);
  await batch.commit();
}
