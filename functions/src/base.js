import {initializeApp} from 'firebase-admin/app';
import {getFirestore, FieldValue, FieldPath} from 'firebase-admin/firestore';
import {getAuth} from 'firebase-admin/auth';
import {getStorage} from 'firebase-admin/storage';
import {onCall, HttpsError} from 'firebase-functions/v2/https';
import {createHash} from 'node:crypto';
initializeApp();
export const db = getFirestore(), auth = getAuth(), bucket = getStorage().bucket();
export {FieldValue, FieldPath, HttpsError};
export const region = process.env.FUNCTIONS_REGION || 'us-central1';
export const emulator = process.env.FUNCTIONS_EMULATOR === 'true';
export const profile = uid => db.doc(`profiles/${uid}`);
export const account = uid => db.doc(`accounts/${uid}`);
export const story = id => db.doc(`stories/${id}`);
export const hash = value => createHash('sha256').update(value).digest('hex');
export function id(value) {
  if (typeof value !== 'string' || !/^[A-Za-z0-9_-]{1,128}$/.test(value)) throw new HttpsError('invalid-argument', 'Invalid identifier.');
  return value;
}
export function text(value, max, required = true) {
  if (typeof value !== 'string' || value.trim().length > max || (required && !value.trim())) {
    throw new HttpsError('invalid-argument', `Use ${required ? '1' : '0'}–${max} characters.`);
  }
  return value.trim();
}
export function bool(value) {
  if (typeof value !== 'boolean') throw new HttpsError('invalid-argument', 'A boolean value is required.');
  return value;
}
export function cursor(value) {
  if (value == null) return null;
  try {
    if (typeof value !== 'string' || value.length > 1024) throw Error();
    const parsed = JSON.parse(Buffer.from(value, 'base64url').toString());
    if (!Number.isSafeInteger(parsed.time) || parsed.time < 0) throw Error();
    id(parsed.id);
    return parsed;
  } catch { throw new HttpsError('invalid-argument', 'Invalid page cursor. Refresh the page.'); }
}
export function nextCursor(doc) {
  return Buffer.from(JSON.stringify({time: doc.get('createdAtMs'), id: doc.id})).toString('base64url');
}
export async function page(query, token, size = 20) {
  let q = query.orderBy('createdAtMs', 'desc').orderBy(FieldPath.documentId(), 'desc');
  const c = cursor(token);
  if (c) q = q.startAfter(c.time, c.id);
  const result = await q.limit(size + 1).get();
  const docs = result.docs.slice(0, size);
  return {docs, cursor: result.size > size ? nextCursor(docs.at(-1)) : null};
}
export async function blocked(a, b) {
  if (a === b) return false;
  const docs = await db.getAll(account(a).collection('blocks').doc(b), account(b).collection('blocks').doc(a));
  return docs.some(d => d.exists);
}
export async function available(uid) {
  const [p, a] = await db.getAll(profile(uid), account(uid));
  return p.exists && p.get('suspended') !== true && a.get('deleting') !== true;
}
export async function visible(viewer, author) {
  return await available(author) && !await blocked(viewer, author);
}
export async function checkPair(a, b) {
  if (a === b || !await visible(a, b)) throw new HttpsError('failed-precondition', 'This member is not available for this action.');
}
export async function rate(uid, name, limit, seconds) {
  const now = Date.now(), slot = Math.floor(now / (seconds * 1000));
  const ref = db.doc(`rateLimits/${hash(`${uid}:${name}:${slot}`)}`);
  await db.runTransaction(async tx => {
    const doc = await tx.get(ref);
    if ((doc.get('count') || 0) >= limit) throw new HttpsError('resource-exhausted', 'Please wait before trying again.');
    tx.set(ref, {count: (doc.get('count') || 0) + 1, expiresAtMs: (slot + 2) * seconds * 1000});
  });
}
export function callable(name, handler, {limit = 60, seconds = 60, allowInactive = false, recent = false, moderator = false} = {}) {
  return onCall({region, enforceAppCheck: !emulator, timeoutSeconds: 120, maxInstances: 20}, async req => {
    if (!req.auth) throw new HttpsError('unauthenticated', 'Please sign in again.');
    const uid = req.auth.uid;
    const user = await auth.getUser(uid).catch(() => null);
    if (!user || user.disabled || Number(req.auth.token.auth_time || 0) * 1000 < Date.parse(user.tokensValidAfterTime || '1970-01-01')) throw new HttpsError('unauthenticated', 'Please sign in again.');
    if (moderator && req.auth.token.moderator !== true) throw new HttpsError('permission-denied', 'Moderator access is required.');
    if (recent && Date.now() / 1000 - Number(req.auth.token.auth_time || 0) > 300) {
      throw new HttpsError('failed-precondition', 'Please sign in again before continuing.');
    }
    if (!allowInactive && !await available(uid)) throw new HttpsError('permission-denied', 'Your account is unavailable.');
    if (await account(uid).get().then(d => d.get('deleting') === true)) throw new HttpsError('failed-precondition', 'Account deletion is in progress.');
    await rate(uid, name, limit, seconds);
    return handler(uid, req.data || {}, req);
  });
}
export function publicProfile(doc) {
  const d = doc.data() || {};
  return {id: doc.id, displayName: d.displayName || 'Member', username: d.username || '', bio: d.bio || '',
    photoUrl: d.photoUrl || '', avatarPath: d.avatarPath || '', followersCount: d.followersCount || 0,
    followingCount: d.followingCount || 0, friendsCount: d.friendsCount || 0};
}
export async function publishedPost(doc, uid) {
  if (!doc.exists || doc.get('deleted') || doc.get('moderated') || !await visible(uid, doc.get('userId'))) return null;
  const liked = await doc.ref.collection('likes').doc(uid).get();
  return {id: doc.id, ...doc.data(), liked: liked.exists};
}

// Read guards in the SAME transaction as social writes, so blocking/deletion cannot race them.
export async function transactionActive(tx, uid, other = uid) {
  for (const member of new Set([uid, other])) {
    const [p,a] = await Promise.all([tx.get(profile(member)),tx.get(account(member))]);
    if (!p.exists || p.get('suspended') || !a.exists || a.get('deleting')) throw new HttpsError('failed-precondition','This account is unavailable.');
  }
  if (uid !== other) {
    const blocks = await Promise.all([tx.get(account(uid).collection('blocks').doc(other)),tx.get(account(other).collection('blocks').doc(uid))]);
    if (blocks.some(d=>d.exists)) throw new HttpsError('permission-denied','This member is unavailable.');
  }
}
