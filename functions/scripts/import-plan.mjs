// Offline inspection by default. Applying requires explicit target and reviewed plan.
import {readFile} from 'node:fs/promises';
import {initializeApp} from 'firebase-admin/app';
import {getAuth} from 'firebase-admin/auth';
import {getFirestore} from 'firebase-admin/firestore';
const args=process.argv.slice(2),option=key=>args.includes(key)?args[args.indexOf(key)+1]:null;
const file=option('--plan'),project=option('--project');
if(!file||!project)throw Error('Provide --plan FILE --project PROJECT. Default: dry run.');
const plan=JSON.parse(await readFile(file,'utf8'));
if(plan.schemaVersion!==2||!plan.documents)throw Error('Unsupported plan.');
const entries=Object.entries(plan.documents);
const allowed=/^(profiles\/[A-Za-z0-9_-]+(?:\/(following|followers|friends|incoming|outgoing)\/[A-Za-z0-9_-]+)?|accounts\/[A-Za-z0-9_-]+|handles\/[a-z0-9_]+|stories\/[A-Za-z0-9_-]+(?:\/(likes|comments)\/[A-Za-z0-9_-]+)?)$/;
for(const [path,data] of entries)if(!allowed.test(path)||!data||typeof data!=='object')throw Error('Invalid plan document.');
console.log(`${entries.length} planned documents. Review notes: ${plan.warnings?.length || 0}.`);
if(!args.includes('--apply')){console.log('Dry run complete. No database connection or writes.');process.exit(0);}
if(option('--confirm-project')!==project||!args.includes('--reviewed'))throw Error('Apply requires --reviewed --confirm-project matching --project.');
initializeApp({projectId:project});const db=getFirestore(),auth=getAuth();
// Fail before writing if identity mappings are unresolved.
for(const [path] of entries.filter(([p])=>/^profiles\/[^/]+$/.test(p)))await auth.getUser(path.split('/')[1]);
// Refuse to merge into active v2 data. Import into an isolated empty development project first.
for(const collection of ['profiles','stories','handles','accounts'])if(!(await db.collection(collection).limit(1).get()).empty)throw Error('Destination v2 collections must be empty.');
for(let i=0;i<entries.length;i+=200){const batch=db.batch();for(const [path,data] of entries.slice(i,i+200))batch.create(db.doc(path),data);await batch.commit();console.log(`Imported ${Math.min(i+200,entries.length)}/${entries.length}`);}
console.log('Import complete. Inspect the isolated destination before any cutover.');
