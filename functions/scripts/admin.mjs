import {initializeApp} from 'firebase-admin/app';
import {getAuth} from 'firebase-admin/auth';
import {getFirestore} from 'firebase-admin/firestore';
const args=process.argv.slice(2), command=args[0];
const value=key=>args[args.indexOf(key)+1];
const project=args.includes('--project')?value('--project'):null;
const uid=args.includes('--uid')?value('--uid'):null;
if(!project || !uid || !['moderator','unsuspend','retry-deletion'].includes(command)) {
  console.error('Usage: npm run admin -- moderator|unsuspend|retry-deletion --project PROJECT --uid UID [--revoke] [--apply --confirm-project PROJECT]');process.exit(1);
}
if(!args.includes('--apply')){console.log(`Dry run: ${command} for the specified UID in ${project}. No changes made.`);process.exit(0);}
if(!args.includes('--confirm-project')||value('--confirm-project')!==project)throw Error('Confirm the exact target project.');
initializeApp({projectId:project});
const auth=getAuth(),db=getFirestore();
if(command==='moderator'){
 const user=await auth.getUser(uid);await auth.setCustomUserClaims(uid,{...user.customClaims,moderator:!args.includes('--revoke')});
 console.log('Role updated. The user must sign out and sign in to refresh claims.');
}else if(command==='unsuspend'){
 await db.doc(`profiles/${uid}`).update({suspended:false});console.log('Profile suspension removed.');
}else{
 const ref=db.doc(`maintenanceJobs/delete_${uid}`);
 await db.runTransaction(async tx=>{const job=await tx.get(ref);if(job.get('type')!=='delete'||job.get('status')!=='failed')throw Error('Only failed deletion jobs can be retried.');tx.update(ref,{status:'pending',attempts:0,leaseUntil:0,errorCode:''});});
 console.log('Deletion queued to resume from its saved checkpoint.');
}
