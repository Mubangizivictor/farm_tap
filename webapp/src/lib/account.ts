// Closing an account (decision 0024). Closing is immediate for the person:
// the account and every farm it owns stop working at once. The records are
// kept for 90 days so support can restore them; after that the daily server
// job erases them for good. Without the server job (before Blaze), support
// erases by hand with functions/scripts/accounts.mjs.

import { addDoc, collection, deleteField, doc, getDoc, serverTimestamp, updateDoc, writeBatch } from 'firebase/firestore';
import { firebase } from './firebase.ts';

export const HOLD_DAYS = 90;

export interface Closure {
  at: Date | null;
  /** Last day support can restore it. */
  restoreBy: Date | null;
}

export function restoreDeadline(at: Date | null): Date | null {
  return at ? new Date(at.getTime() + HOLD_DAYS * 86_400_000) : null;
}

export interface Profile {
  /** null when the account is open. */
  closed: Closure | null;
  /** The person's own picture: storage link, else the small saved copy. */
  photo: string | null;
}

export async function readProfile(uid: string): Promise<Profile> {
  const data = (await getDoc(doc(firebase().db, 'users', uid))).data() ?? {};
  const d = data.deletion as { at?: { toDate?: () => Date } } | undefined;
  const at = d ? (d.at?.toDate?.() ?? null) : null;
  const p = data.photo as { url?: string | null; thumb?: string } | undefined;
  return {
    closed: d ? { at, restoreBy: restoreDeadline(at) } : null,
    photo: p?.url || p?.thumb || null,
  };
}

/** Saves the person's picture on their account (users/{uid}.photo). */
export async function saveProfilePhoto(uid: string, thumb: string, url: string | null) {
  await updateDoc(doc(firebase().db, 'users', uid), { photo: { thumb, url, updatedAt: serverTimestamp() } });
}

export async function removeProfilePhoto(uid: string) {
  await updateDoc(doc(firebase().db, 'users', uid), { photo: deleteField() });
}

/** Farms this account owns: they close with it. */
export async function ownedFarmIds(uid: string): Promise<string[]> {
  const snap = await getDoc(doc(firebase().db, 'users', uid));
  const list = (snap.data()?.memberships as { tenantId: string; role?: string }[] | undefined) ?? [];
  return [...new Set(list.filter((m) => m.role === 'owner').map((m) => m.tenantId))];
}

/** One write: the request, the mark on the account and the farm closures. */
export async function closeAccount(input: { uid: string; email: string; name: string; reason: string; source: 'web' }) {
  const { db } = firebase();
  const farms = await ownedFarmIds(input.uid);
  const b = writeBatch(db);
  b.set(doc(db, 'deletionRequests', input.uid), {
    uid: input.uid,
    email: input.email,
    name: input.name,
    reason: input.reason.slice(0, 1000),
    status: 'closed',
    closedAt: serverTimestamp(),
    farms,
    source: input.source,
    confirmed: true,
  });
  b.update(doc(db, 'users', input.uid), { deletion: { at: serverTimestamp(), requestId: input.uid } });
  for (const t of farms) {
    b.update(doc(db, 'tenants', t), { closure: { at: serverTimestamp(), by: input.uid, requestId: input.uid } });
  }
  await b.commit();
  return farms;
}

/** Someone who cannot sign in asks by form; support checks who they are. */
export async function requestDeletion(input: { name: string; email: string; phone: string; farmName: string; reason: string }) {
  await addDoc(collection(firebase().db, 'deletionRequests'), {
    uid: null,
    name: input.name.trim().slice(0, 120),
    email: input.email.trim().slice(0, 160),
    phone: input.phone.trim().slice(0, 40),
    farmName: input.farmName.trim().slice(0, 160),
    reason: input.reason.trim().slice(0, 1000),
    status: 'requested',
    createdAt: serverTimestamp(),
    source: 'web-form',
  });
}
