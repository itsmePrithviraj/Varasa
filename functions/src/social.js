import {db, auth, bucket, FieldValue, FieldPath, HttpsError, profile, account, story, id, text, bool, hash, page, visible, checkPair, publicProfile, publishedPost, emulator, transactionActive} from './base.js';

export async function ensureProfile(uid, data, req) {
  const ref = profile(uid), handle = `member_${hash(uid).slice(0, 23)}`, handleRef = db.doc(`handles/${handle}`);
  const rawName = typeof req.auth.token.name === 'string' ? req.auth.token.name.trim() : '';
  const displayName = (rawName || 'Varasa member').slice(0, 80);
  await db.runTransaction(async tx => {
    const [p, reservation] = await Promise.all([tx.get(ref), tx.get(handleRef)]);
    if (p.exists) { if(p.get('suspended')) throw new HttpsError('permission-denied','Your profile is suspended. You can still access your account data.'); return; }
    const state=await tx.get(account(uid));
    if((await tx.get(db.doc(`deletedAccounts/${uid}`))).exists)throw new HttpsError('failed-precondition','This account was deleted.');
    if(state.get('deleting')) throw new HttpsError('failed-precondition','Account deletion is in progress.');
    if (reservation.exists && reservation.get('uid') !== uid) throw new HttpsError('already-exists', 'Please contact support to finish this profile.');
    tx.set(ref, {displayName, username: handle, username_lower: handle, bio: '', photoUrl: '', avatarPath: '',
      followersCount: 0, followingCount: 0, friendsCount: 0, suspended: false, createdAtMs: Date.now()});
    tx.set(handleRef, {uid});
    tx.set(account(uid), {deleting: false, createdAtMs: Date.now()}, {merge: true});
  });
  return {ok: true};
}
async function uploaded(uid, path, url, avatar = false) {
  if (typeof path !== 'string' || !(avatar ? new RegExp(`^avatars/${uid}/[A-Za-z0-9_-]+$`) : new RegExp(`^posts/${uid}/[A-Za-z0-9_-]+/attachment$`)).test(path)) {
    throw new HttpsError('invalid-argument', 'The upload does not belong to this account.');
  }
  const [metadata] = await bucket.file(path).getMetadata();
  const size = Number(metadata.size), type = metadata.contentType;
  if (!size || size > (avatar ? 3 : 10) * 1024 * 1024 || ![...['image/jpeg','image/png','image/webp'], ...(avatar ? [] : ['application/pdf'])].includes(type)) {
    throw new HttpsError('invalid-argument', 'Invalid file size or type.');
  }
  let uri;
  try { uri = new URL(url); } catch { throw new HttpsError('invalid-argument', 'Invalid upload URL.'); }
  const tokens = String(metadata.metadata?.firebaseStorageDownloadTokens || '').split(',');
  if ((!emulator && (uri.protocol !== 'https:' || uri.hostname !== 'firebasestorage.googleapis.com')) ||
      decodeURIComponent(uri.pathname) !== `/v0/b/${bucket.name}/o/${path}` || !tokens.includes(uri.searchParams.get('token'))) {
    throw new HttpsError('invalid-argument', 'Upload URL does not match the stored file.');
  }
  return {url: uri.toString(), type};
}
export async function updateProfile(uid, data) {
  const name = text(data.name, 80), bio = text(data.bio, 300, false), handle = text(data.username, 30).toLowerCase();
  if (!/^[a-z0-9_]{3,30}$/.test(handle)) throw new HttpsError('invalid-argument', 'Use 3–30 lowercase letters, numbers or underscores.');
  const avatar = data.avatarPath ? await uploaded(uid, data.avatarPath, data.avatarUrl, true) : null;
  if (avatar && data.removeAvatar) throw new HttpsError('invalid-argument', 'Choose or remove the photo, not both.');
  await db.runTransaction(async tx => {
    await transactionActive(tx,uid);
    const ref = profile(uid), nextHandle = db.doc(`handles/${handle}`);
    const [p, h] = await Promise.all([tx.get(ref), tx.get(nextHandle)]);
    if (!p.exists) throw new HttpsError('not-found', 'Profile not found.');
    if (h.exists && h.get('uid') !== uid) throw new HttpsError('already-exists', 'That username is already taken.');
    const oldHandle = db.doc(`handles/${p.get('username')}`), old = await tx.get(oldHandle);
    tx.update(ref, {displayName: name, bio, username: handle, username_lower: handle,
      ...avatar ? {photoUrl: avatar.url, avatarPath: data.avatarPath} : data.removeAvatar ? {photoUrl: '', avatarPath: ''} : {}});
    tx.set(nextHandle, {uid});
    if (oldHandle.path !== nextHandle.path && old.get('uid') === uid) tx.delete(oldHandle);
  });
  return {ok: true};
}
export async function mutateFollow(from, to, follow) {
  const a = profile(from), b = profile(to), edge = a.collection('following').doc(to), reverse = b.collection('followers').doc(from);
  let changed = false;
  await db.runTransaction(async tx => {
    const [e, pa, pb] = await Promise.all([tx.get(edge), tx.get(a), tx.get(b)]);
    if (follow) await transactionActive(tx,from,to);
    if (e.exists === follow) return;
    changed = true;
    if (follow) {
      tx.set(edge, {userId: to, createdAtMs: Date.now()}); tx.set(reverse, {userId: from, createdAtMs: Date.now()});
    } else { tx.delete(edge); tx.delete(reverse); }
    const delta = follow ? 1 : -1;
    if (pa.exists) tx.update(a, {followingCount: Math.max(0, (pa.get('followingCount') || 0) + delta)});
    if (pb.exists) tx.update(b, {followersCount: Math.max(0, (pb.get('followersCount') || 0) + delta)});
  });
  return changed;
}
export async function setFollowing(uid, data) {
  const target = id(data.userId), follow = bool(data.follow);
  if (follow) await checkPair(uid, target);
  if (uid === target) throw new HttpsError('invalid-argument', 'You cannot follow yourself.');
  await mutateFollow(uid, target, follow);
  if (follow) {
    const recent = await db.collection('stories').where('userId', '==', target).where('deleted', '==', false).orderBy('createdAtMs', 'desc').limit(30).get();
    const batch = db.batch();
    for (const s of recent.docs) batch.set(account(uid).collection('feed').doc(s.id), {userId: target, createdAtMs: s.get('createdAtMs')});
    await batch.commit();
  }
  return {ok: true};
}
export async function friendship(uid, data) {
  const target = id(data.userId), action = data.action;
  if (!['send','cancel','accept','decline','remove'].includes(action)) throw new HttpsError('invalid-argument', 'Invalid friend action.');
  if (['send','accept'].includes(action)) await checkPair(uid, target);
  if (uid === target) throw new HttpsError('invalid-argument', 'Choose another member.');
  const me = profile(uid), other = profile(target);
  const incoming = me.collection('incoming').doc(target), outgoing = me.collection('outgoing').doc(target);
  const otherIncoming = other.collection('incoming').doc(uid), otherOutgoing = other.collection('outgoing').doc(uid);
  const mine = me.collection('friends').doc(target), theirs = other.collection('friends').doc(uid);
  await db.runTransaction(async tx => {
    const [request, pending, friend, a, b] = await Promise.all([tx.get(incoming),tx.get(outgoing),tx.get(mine),tx.get(me),tx.get(other)]);
    if (['send','accept'].includes(action)) await transactionActive(tx,uid,target);
    if (action === 'send') {
      if (friend.exists || pending.exists) return;
      if (request.exists) throw new HttpsError('failed-precondition', 'This member already invited you. Accept their request.');
      tx.set(outgoing, {userId: target, createdAtMs: Date.now()}); tx.set(otherIncoming, {userId: uid, createdAtMs: Date.now()});
    } else if (action === 'accept') {
      if (!request.exists) throw new HttpsError('not-found', 'This request is no longer available.');
      if (!friend.exists) {
        tx.set(mine, {userId: target, createdAtMs: Date.now()}); tx.set(theirs, {userId: uid, createdAtMs: Date.now()});
        tx.update(me, {friendsCount: (a.get('friendsCount') || 0) + 1}); tx.update(other, {friendsCount: (b.get('friendsCount') || 0) + 1});
      }
      for (const ref of [incoming,outgoing,otherIncoming,otherOutgoing]) tx.delete(ref);
    } else if (action === 'remove') {
      if (friend.exists) {
        tx.delete(mine); tx.delete(theirs);
        if (a.exists) tx.update(me, {friendsCount: Math.max(0, (a.get('friendsCount') || 0) - 1)});
        if (b.exists) tx.update(other, {friendsCount: Math.max(0, (b.get('friendsCount') || 0) - 1)});
      }
    } else if (action === 'decline') { tx.delete(incoming); tx.delete(otherOutgoing); }
    else { tx.delete(outgoing); tx.delete(otherIncoming); }
  });
  return {ok: true};
}
export async function setBlocked(uid, data) {
  const target=id(data.userId), value=bool(data.blocked);
  if(target===uid)throw new HttpsError('invalid-argument','Choose another member.');
  const me=profile(uid),other=profile(target),block=account(uid).collection('blocks').doc(target);
  await db.runTransaction(async tx=>{
    const [a,b,state,following,follower,friend]=await Promise.all([
      tx.get(me),tx.get(other),tx.get(account(uid)),tx.get(me.collection('following').doc(target)),
      tx.get(other.collection('following').doc(uid)),tx.get(me.collection('friends').doc(target))]);
    if(!a.exists || a.get('suspended') || !state.exists || state.get('deleting'))throw new HttpsError('failed-precondition','Your account is unavailable.');
    if(!value){tx.delete(block);return;}
    tx.set(block,{userId:target,createdAtMs:Date.now()});
    for(const [owner,member] of [[me,target],[other,uid]])for(const kind of ['following','followers','friends','incoming','outgoing'])tx.delete(owner.collection(kind).doc(member));
    tx.update(me,{followingCount:Math.max(0,(a.get('followingCount')||0)-(following.exists?1:0)),followersCount:Math.max(0,(a.get('followersCount')||0)-(follower.exists?1:0)),friendsCount:Math.max(0,(a.get('friendsCount')||0)-(friend.exists?1:0))});
    if(b.exists)tx.update(other,{followingCount:Math.max(0,(b.get('followingCount')||0)-(follower.exists?1:0)),followersCount:Math.max(0,(b.get('followersCount')||0)-(following.exists?1:0)),friendsCount:Math.max(0,(b.get('friendsCount')||0)-(friend.exists?1:0))});
  });
  return {ok:true};
}
export async function peoplePage(uid, data) {
  const owner = data.userId ? id(data.userId) : uid, kind = data.kind;
  if (!['following','followers','friends','incoming','outgoing','blocks'].includes(kind)) throw new HttpsError('invalid-argument', 'Invalid list.');
  if (['incoming','outgoing','blocks'].includes(kind) && owner !== uid) throw new HttpsError('permission-denied', 'This list is private.');
  if (owner !== uid && !await visible(uid, owner)) throw new HttpsError('not-found', 'Profile is unavailable.');
  const result = await page((kind === 'blocks' ? account(owner) : profile(owner)).collection(kind), data.cursor);
  const items = [];
  for (const d of result.docs) {
    const p = await profile(d.id).get();
    if (p.exists && (kind === 'blocks' || await visible(uid, d.id))) items.push(publicProfile(p));
  }
  return {items, cursor: result.cursor};
}
export async function searchPeople(uid, data) {
  const term = text(data.query, 30).toLowerCase();
  const docs = await db.collection('profiles').orderBy('username_lower').startAt(term).endAt(`${term}\uf8ff`).limit(30).get();
  const items = [];
  for (const doc of docs.docs) if (await visible(uid, doc.id)) items.push(publicProfile(doc));
  return {items};
}
export async function feedPage(uid, data) {
  const kind = data.kind || 'community', author = data.userId ? id(data.userId) : uid;
  if (!['community','following','profile'].includes(kind)) throw new HttpsError('invalid-argument', 'Invalid feed.');
  if (kind === 'profile' && !await visible(uid, author)) return {items: [], cursor: null};
  let query = kind === 'following' ? account(uid).collection('feed') : db.collection('stories').where('deleted', '==', false);
  if (kind === 'profile') query = query.where('userId', '==', author);
  const result = await page(query, data.cursor);
  const items = [];
  for (const d of result.docs) {
    const doc = kind === 'following' ? await story(d.id).get() : d;
    if (kind === 'following' && (!doc.exists || !(await profile(uid).collection('following').doc(doc.get('userId')).get()).exists)) continue;
    const post = await publishedPost(doc, uid);
    if (post) items.push(post);
  }
  return {items, cursor: result.cursor};
}
export async function publish(uid, data) {
  const postId = id(data.id), ref = story(postId), caption = text(data.caption, 3000), place = text(data.place || '', 120, false);
  const lat = data.latitude ?? null, lng = data.longitude ?? null;
  if ((lat === null) !== (lng === null) || lat !== null && (!Number.isFinite(lat) || !Number.isFinite(lng) || Math.abs(lat) > 90 || Math.abs(lng) > 180)) {
    throw new HttpsError('invalid-argument', 'Use valid latitude and longitude.');
  }
  const path = data.storagePath || '', file = path ? await uploaded(uid, path, data.fileUrl) : null;
  if (path && path !== `posts/${uid}/${postId}/attachment`) throw new HttpsError('invalid-argument', 'Upload path does not match this story.');
  const p = await profile(uid).get();
  const value = {userId: uid, username: p.get('username'), photoUrl: p.get('photoUrl'), authorAvatarPath: p.get('avatarPath') || '',
    caption, place, latitude: lat, longitude: lng, imageUrl: file?.type.startsWith('image/') ? file.url : '',
    attachmentUrl: file?.type === 'application/pdf' ? file.url : '', attachmentName: text(data.attachmentName || '', 200, false),
    storagePath: path, likeCount: 0, commentCount: 0, deleted: false, moderated: false, createdAtMs: Date.now()};
  await db.runTransaction(async tx => {
    await transactionActive(tx,uid);
    const existing = await tx.get(ref);
    if (existing.exists) {if(existing.get('userId')===uid)return; throw new HttpsError('already-exists','Story identifier already in use.');}
    tx.create(ref, value);
    tx.set(db.doc(`fanoutJobs/${postId}`), {storyId: postId, authorId: uid, cursor: null, status: 'pending', leaseUntil: 0, createdAtMs: value.createdAtMs});
  });
  return {id: postId};
}
export async function mutateLike(uid, postId, liked) {
  const ref = story(postId), edge = ref.collection('likes').doc(uid);
  await db.runTransaction(async tx => {
    const [p, e] = await Promise.all([tx.get(ref), tx.get(edge)]);
    if(liked){ if(!p.exists || p.get('deleted') || p.get('moderated'))throw new HttpsError('not-found','Story unavailable.'); await transactionActive(tx,uid,p.get('userId')); }
    if (e.exists === liked) return;
    if (liked) {
      if (!p.exists || p.get('deleted')) throw new HttpsError('not-found', 'Story unavailable.');
      tx.set(edge, {userId: uid, storyId: postId, createdAtMs: Date.now()});
    } else tx.delete(edge);
    if (p.exists) tx.update(ref, {likeCount: Math.max(0, (p.get('likeCount') || 0) + (liked ? 1 : -1))});
  });
}
export async function setLiked(uid, data) {
  const postId = id(data.postId), p = await story(postId).get();
  if (!p.exists || !await visible(uid, p.get('userId'))) throw new HttpsError('not-found', 'Story unavailable.');
  await mutateLike(uid, postId, bool(data.liked)); return {ok: true};
}
export async function tombstone(ref) {
  await ref.update({deleted: true, deletedAtMs: Date.now(), caption: '', imageUrl: '', attachmentUrl: '', attachmentName: '', latitude: null, longitude: null, place: ''});
}
export async function deletePost(uid, data) {
  const ref = story(id(data.postId)), p = await ref.get();
  if (!p.exists || p.get('userId') !== uid) throw new HttpsError('permission-denied', 'Only the author can delete this story.');
  await tombstone(ref); return {ok: true};
}
export async function addComment(uid, data) {
  const ref = story(id(data.postId)), p = await ref.get(), value = text(data.text, 1000);
  if (!p.exists || p.get('deleted') || !await visible(uid, p.get('userId'))) throw new HttpsError('not-found', 'Story unavailable.');
  const me = await profile(uid).get(), comment = ref.collection('comments').doc();
  await db.runTransaction(async tx => {
    const latest = await tx.get(ref);
    await transactionActive(tx,uid,p.get('userId'));
    if (!latest.exists || latest.get('deleted') || latest.get('moderated')) throw new HttpsError('not-found', 'Story unavailable.');
    tx.create(comment, {userId: uid, storyId: ref.id, username: me.get('username'), text: value, createdAtMs: Date.now(), deleted: false});
    tx.update(ref, {commentCount: FieldValue.increment(1)});
  });
  return {id: comment.id};
}
export async function commentsPage(uid, data) {
  const ref = story(id(data.postId)), p = await ref.get();
  if (!p.exists || p.get('deleted') || !await visible(uid, p.get('userId'))) throw new HttpsError('not-found', 'Story unavailable.');
  const result = await page(ref.collection('comments').where('deleted', '==', false), data.cursor);
  const items = [];
  for (const d of result.docs) if (await visible(uid, d.get('userId'))) items.push({id: d.id, ...d.data()});
  return {items, cursor: result.cursor};
}
export async function deleteComment(uid, data) {
  const ref = story(id(data.postId)).collection('comments').doc(id(data.commentId));
  await db.runTransaction(async tx => {
    const c = await tx.get(ref), p = await tx.get(ref.parent.parent);
    if (!c.exists || (c.get('userId') !== uid && p.get('userId') !== uid)) throw new HttpsError('permission-denied', 'You cannot delete this comment.');
    if (c.get('deleted')) return;
    tx.update(ref, {text: '', deleted: true});
    if (p.exists) tx.update(p.ref, {commentCount: Math.max(0, (p.get('commentCount') || 0) - 1)});
  });
  return {ok: true};
}
export async function report(uid, data) {
  const kind = data.kind;
  let target;
  if (kind === 'profile') target = profile(id(data.targetId));
  else if (kind === 'story') target = story(id(data.targetId));
  else if (kind === 'comment') target = story(id(data.postId)).collection('comments').doc(id(data.targetId));
  else throw new HttpsError('invalid-argument', 'Invalid report target.');
  const doc = await target.get();
  if (!doc.exists) throw new HttpsError('not-found', 'This content is no longer available.');
  await checkPair(uid,kind==='profile'?doc.id:doc.get('userId'));
  const reason = text(data.reason, 80), details = text(data.details || '', 1000, false), reportRef = db.doc(`reports/${hash(`${uid}:${target.path}`)}`);
  await db.runTransaction(async tx => {
    if ((await tx.get(reportRef)).exists) return;
    tx.create(reportRef, {reporterId: uid, targetPath: target.path, targetUserId: kind === 'profile' ? doc.id : doc.get('userId'),
      kind, reason, details, status: 'open', createdAtMs: Date.now()});
  });
  return {ok: true};
}
export async function moderationPage(uid, data) {
  const result = await page(db.collection('reports').where('status', '==', 'open'), data.cursor);
  const items = [];
  for (const d of result.docs) {
    const target = await db.doc(d.get('targetPath')).get();
    items.push({id: d.id, ...d.data(), preview: target.get('caption') || target.get('text') || target.get('bio') || '',
      imageUrl: target.get('imageUrl') || '', displayName: target.get('displayName') || target.get('username') || ''});
  }
  return {items, cursor: result.cursor};
}
export async function resolveReport(uid, data) {
  const ref=db.doc(`reports/${id(data.reportId)}`), action=data.action, note=text(data.note || '',500,false);
  if(!['dismiss','remove'].includes(action))throw new HttpsError('invalid-argument','Invalid resolution.');
  await db.runTransaction(async tx=>{
    const report=await tx.get(ref);
    if(!report.exists)throw new HttpsError('not-found','Report not found.');
    if(report.get('status')!=='open')return;
    const path=report.get('targetPath'), target=path?db.doc(path):null, doc=target?await tx.get(target):null;
    let parent;
    if(action==='remove' && doc?.exists && report.get('kind')==='comment')parent=await tx.get(target.parent.parent);
    if(action==='remove' && doc?.exists){
      if(report.get('kind')==='story')tx.update(target,{deleted:true,deletedAtMs:Date.now(),caption:'',imageUrl:'',attachmentUrl:'',attachmentName:'',latitude:null,longitude:null,place:''});
      else if(report.get('kind')==='comment'){
        tx.update(target,{deleted:true,text:''});
        if(parent?.exists&&!doc.get('deleted'))tx.update(parent.ref,{commentCount:Math.max(0,(parent.get('commentCount')||0)-1)});
      }else tx.update(target,{suspended:true});
    }
    tx.update(ref,{status:action==='dismiss'?'dismissed':'removed',resolvedBy:uid,resolvedAtMs:Date.now(),note});
  });
  return {ok:true};
}
