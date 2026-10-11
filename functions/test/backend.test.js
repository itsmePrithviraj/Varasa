import {test, before, after} from 'node:test';
import assert from 'node:assert/strict';
for(const name of ['FIRESTORE_EMULATOR_HOST','FIREBASE_AUTH_EMULATOR_HOST','FIREBASE_STORAGE_EMULATOR_HOST']) {
  if(!/^(127\.0\.0\.1|localhost):\d+$/.test(process.env[name] || ''))throw Error(`Refusing tests without local ${name}`);
}
const project='demo-varasa';
process.env.GCLOUD_PROJECT=project;
process.env.FIREBASE_CONFIG=JSON.stringify({projectId:project,storageBucket:`${project}.appspot.com`});
process.env.FUNCTIONS_EMULATOR='true';
const {db,auth,bucket}=await import('../src/base.js');
const social=await import('../src/social.js');
const jobs=await import('../src/jobs.js');
const tokens={};
async function create(uid){await auth.createUser({uid,email:`${uid}@example.test`,password:'local-test-password'});await social.ensureProfile(uid,{}, {auth:{token:{name:uid}}});const r=await fetch(`http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=fake`,{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify({email:`${uid}@example.test`,password:'local-test-password',returnSecureToken:true})});tokens[uid]=(await r.json()).idToken;}
const firestore=(path,uid,method='GET',body)=>fetch(`http://${process.env.FIRESTORE_EMULATOR_HOST}/v1/projects/${project}/databases/(default)/documents/${path}`,{method,headers:{...(uid?{authorization:`Bearer ${tokens[uid]}`}:{}) ,'content-type':'application/json'},body:body?JSON.stringify(body):undefined});
async function callable(name,uid,data={}){const r=await fetch(`http://127.0.0.1:5001/${project}/us-central1/${name}`,{method:'POST',signal:AbortSignal.timeout(30000),headers:{'content-type':'application/json',authorization:`Bearer ${tokens[uid]}`},body:JSON.stringify({data})});return {status:r.status,body:await r.json()};}
before(async()=>{for(const uid of ['alice','bob','carol'])await create(uid);});
after(async()=>{await db.terminate();});
test('unique handles are reserved atomically',async()=>{
 const values=await Promise.allSettled(['alice','bob'].map(uid=>social.updateProfile(uid,{name:uid,username:'same_handle',bio:''})));
 assert.equal(values.filter(v=>v.status==='fulfilled').length,1);
 assert.equal(values.filter(v=>v.status==='rejected')[0].reason.code,'already-exists');
});
test('follows, friendship and likes remain idempotent under retries',async()=>{
 await Promise.all(Array.from({length:4},()=>social.setFollowing('alice',{userId:'bob',follow:true})));
 assert.equal((await db.doc('profiles/bob').get()).get('followersCount'),1);
 await social.friendship('bob',{userId:'alice',action:'send'});
 await social.friendship('alice',{userId:'bob',action:'accept'});
 assert.equal((await db.doc('profiles/alice').get()).get('friendsCount'),1);
 await social.publish('bob',{id:'bob-story',caption:'A tradition',place:''});
 await Promise.all(Array.from({length:4},()=>social.setLiked('alice',{postId:'bob-story',liked:true})));
 assert.equal((await db.doc('stories/bob-story').get()).get('likeCount'),1);
 for(let i=0;i<100 && (await db.doc('fanoutJobs/bob-story').get()).get('status')!=='complete';i++){await jobs.runFanout(db.doc('fanoutJobs/bob-story'));await new Promise(r=>setTimeout(r,30));}
 assert.equal((await social.feedPage('alice',{kind:'following'})).items[0].id,'bob-story');
});
test('blocking removes relationships and prevents interactions and direct reads',async()=>{
 await social.setBlocked('alice',{userId:'bob',blocked:true});
 assert.equal((await db.doc('profiles/alice').get()).get('friendsCount'),0);
 assert.equal((await db.doc('profiles/bob').get()).get('followersCount'),0);
 await assert.rejects(social.setLiked('alice',{postId:'bob-story',liked:true}));
 await assert.rejects(social.friendship('bob',{userId:'alice',action:'send'}));
 assert.equal((await firestore('stories/bob-story','alice')).status,403);
 await social.setBlocked('alice',{userId:'bob',blocked:false});
 assert.equal((await firestore('stories/bob-story','alice')).status,200);
});
test('rules deny unauthenticated reads and all client data mutations',async()=>{
 assert.equal((await firestore('profiles/alice')).status,403);
 assert.equal((await firestore('profiles/alice','alice','PATCH',{fields:{displayName:{stringValue:'Tampered'}}})).status,403);
 assert.equal((await firestore('handles/same_handle','alice')).status,403);
 assert.equal((await firestore('profiles/alice','bob')).status,200);
});
test('callables authenticate callers, reject ordinary moderators and enforce rates',async()=>{
 assert.equal((await callable('ensureProfile','alice')).status,200);
 assert.equal((await callable('moderationPage','alice')).status,403);
 const results=[];
 for(let i=0;i<11;i++)results.push(await callable('updateProfile','carol',{name:'Carol',username:'carol',bio:''}));
 assert.equal(results[0].status,200);assert.equal(results.at(-1).status,429);
});
test('cursor pages progress with equal timestamps and a deleted boundary',async()=>{
 const batch=db.batch();for(let i=0;i<25;i++)batch.set(db.doc(`stories/page-${String(i).padStart(2,'0')}`),{userId:'carol',username:'carol',caption:'Paged',createdAtMs:1,deleted:false,moderated:false});await batch.commit();
 const first=await social.feedPage('alice',{});assert.equal(first.items.length,20);assert.ok(first.cursor);
 await db.doc(`stories/${first.items.at(-1).id}`).delete();
 const next=await social.feedPage('alice',{cursor:first.cursor});
 assert.equal(new Set([...first.items,...next.items].map(p=>p.id)).size,26);assert.equal(next.cursor,null);
});
test('comment ownership, reporting and moderator resolution',async()=>{
 const comment=await social.addComment('alice',{postId:'bob-story',text:'A memory'});
 await assert.rejects(social.deleteComment('carol',{postId:'bob-story',commentId:comment.id}));
 await social.report('carol',{kind:'comment',postId:'bob-story',targetId:comment.id,reason:'Abuse'});
 const report=(await social.moderationPage('carol',{})).items[0];
 await social.resolveReport('carol',{reportId:report.id,action:'remove',note:'Reviewed'});
 await social.resolveReport('carol',{reportId:report.id,action:'remove',note:'Retry'});
 assert.equal((await db.doc('stories/bob-story').get()).get('commentCount'),0);
});
test('export workers resume and private output can only be read by its owner',async()=>{
 const {id}=await jobs.requestExport('alice'),ref=db.doc(`maintenanceJobs/${id}`);
 for(let i=0;i<100 && (await ref.get()).get('status')!=='complete';i++){await jobs.runMaintenance(ref);await new Promise(r=>setTimeout(r,30));}
 assert.equal((await ref.get()).get('status'),'complete');
 const parts=await jobs.exportParts('alice',{jobId:id});assert.equal(parts.items.length,11);
 await assert.rejects(jobs.exportParts('bob',{jobId:id}));
 const [bytes]=await bucket.file(parts.items[0].path).download();assert.equal(JSON.parse(bytes).records[0].account.uid,'alice');
 const path=encodeURIComponent(parts.items[0].path);
 const storageRead=uid=>fetch(`http://${process.env.FIREBASE_STORAGE_EMULATOR_HOST}/v0/b/${bucket.name}/o/${path}?alt=media`,{headers:{authorization:`Bearer ${tokens[uid]}`}});
 assert.equal((await storageRead('alice')).status,200);assert.equal((await storageRead('bob')).status,403);
});
test('storage rejects impersonation, unsupported MIME and overwrite; publish verifies stored ownership',async()=>{
 const upload=(uid,path,type)=>fetch(`http://${process.env.FIREBASE_STORAGE_EMULATOR_HOST}/v0/b/${bucket.name}/o?uploadType=media&name=${encodeURIComponent(path)}`,{method:'POST',headers:{authorization:`Bearer ${tokens[uid]}`,'content-type':type},body:Buffer.from('fixture bytes')});
 assert.equal((await upload('bob','posts/alice/upload-story/attachment','image/png')).status,403);
 assert.equal((await upload('alice','posts/alice/invalid/attachment','text/html')).status,403);
 const path='posts/alice/upload-story/attachment',response=await upload('alice',path,'image/png');assert.equal(response.status,200);
 const metadata=await response.json();
 assert.equal((await upload('alice',path,'image/png')).status,403);
 const url=`http://${process.env.FIREBASE_STORAGE_EMULATOR_HOST}/v0/b/${bucket.name}/o/${encodeURIComponent(path)}?alt=media&token=${metadata.downloadTokens}`;
 await social.publish('alice',{id:'upload-story',caption:'Uploaded fixture',place:'',storagePath:path,fileUrl:url});
 await assert.rejects(social.publish('bob',{id:'stolen-story',caption:'Invalid ownership',storagePath:path,fileUrl:url}));
 assert.equal((await db.doc('stories/upload-story').get()).get('storagePath'),path);
});
test('deletion is resumable and removes owned records without counter drift',async()=>{
 await social.setFollowing('alice',{userId:'bob',follow:true});
 const {id}=await jobs.requestDeletion('alice'),ref=db.doc(`maintenanceJobs/${id}`);
 await assert.rejects(social.setFollowing('alice',{userId:'carol',follow:true}));
 for(let i=0;i<150 && (await ref.get()).get('status')!=='complete';i++){await jobs.runMaintenance(ref);await new Promise(r=>setTimeout(r,30));}
 assert.equal((await ref.get()).get('status'),'complete');
 assert.equal((await db.doc('profiles/alice').get()).exists,false);
 assert.equal((await db.doc('profiles/bob').get()).get('followersCount'),0);
 assert.equal((await db.doc('stories/bob-story').get()).get('likeCount'),0);
 await assert.rejects(auth.getUser('alice'));
 assert.equal((await callable('ensureProfile','alice')).status,401);
});
