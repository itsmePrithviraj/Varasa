// Only for a local demo emulator project. Schedulers do not tick in emulators.
const project=process.env.GCLOUD_PROJECT || 'demo-varasa';
if(!project.startsWith('demo-'))throw Error('Local workers require a demo- project.');
process.env.GCLOUD_PROJECT=project;
process.env.FIRESTORE_EMULATOR_HOST='127.0.0.1:8080';
process.env.FIREBASE_AUTH_EMULATOR_HOST='127.0.0.1:9099';
process.env.FIREBASE_STORAGE_EMULATOR_HOST='127.0.0.1:9199';
process.env.FIREBASE_CONFIG=JSON.stringify({projectId:project,storageBucket:`${project}.appspot.com`});
const {drainJobs}=await import('../src/jobs.js');
console.log(`Local queue worker: ${project}. Ctrl+C to stop.`);
while(true){try{await drainJobs();}catch(error){console.error(error.message);}await new Promise(resolve=>setTimeout(resolve,5000));}
