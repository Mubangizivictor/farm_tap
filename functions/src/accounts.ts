// Deleting an account (decision 0024, Google Play and App Store rules).
//
// A person asks in the app or on /delete-account/. After they confirm, the
// account is CLOSED at once: users/{uid}.deletion is set, the farms they own
// are closed (tenants/{t}.closure) and nobody can record on them. Nothing is
// erased for 90 days, so support can bring it back (control panel ->
// Account deletion -> Restore, or `node functions/scripts/accounts.mjs restore <uid>`).
// After 90 days the erase job removes the account and the farms for good,
// except payment records, receipts and invoices (kept 7 years for tax).

import { getAuth } from 'firebase-admin/auth';
import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';
import { logger } from 'firebase-functions';
import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { db, switchOn } from './server';

export const HOLD_DAYS = 90;

/** True when the hold has passed. */
export const holdOver = (closedAt: Date, now: Date, days = HOLD_DAYS) => now.getTime() - closedAt.getTime() >= days * 86400000;

/** Erases one closed account: its farms (every record), its sign-in and its files. */
export async function eraseAccount(uid: string, requestId: string): Promise<{ farms: number }> {
  const owned = await db().collection('tenants').where('ownerUid', '==', uid).get();
  for (const t of owned.docs) {
    await db().recursiveDelete(t.ref);
    try {
      await getStorage().bucket().deleteFiles({ prefix: `tenants/${t.id}/` });
    } catch (e) {
      logger.warn('storage erase failed', { t: t.id, error: String(e) });
    }
  }
  // Memberships on other people's farms.
  const memberOf = await db().collectionGroup('members').where('uid', '==', uid).get().catch(() => null);
  for (const m of memberOf?.docs ?? []) await m.ref.delete();
  await db().recursiveDelete(db().doc(`users/${uid}`));
  try {
    await getStorage().bucket().deleteFiles({ prefix: `profiles/${uid}/` });
  } catch {
    // No files.
  }
  try {
    await getAuth().deleteUser(uid);
  } catch (e) {
    logger.warn('auth erase failed', { uid, error: String(e) });
  }
  await db()
    .doc(`deletionRequests/${requestId}`)
    .update({ status: 'erased', erasedAt: FieldValue.serverTimestamp(), farmsErased: owned.size });
  return { farms: owned.size };
}

/** Closing turns sign-in off; restoring turns it back on. */
export const onDeletionChange = onDocumentWritten({ document: 'deletionRequests/{id}' }, async (event) => {
  const after = event.data?.after?.data();
  const before = event.data?.before?.data();
  if (!after || !(await switchOn('accountErase'))) return;
  const uid = typeof after.uid === 'string' ? after.uid : '';
  if (!uid || before?.status === after.status) return;
  try {
    if (after.status === 'closed') {
      await getAuth().updateUser(uid, { disabled: true });
      await getAuth().revokeRefreshTokens(uid);
    } else if (after.status === 'restored') {
      await getAuth().updateUser(uid, { disabled: false });
    }
  } catch (e) {
    logger.warn('auth switch failed', { uid, error: String(e) });
  }
});

/** Every day: erase accounts closed more than 90 days ago. */
export const eraseClosedAccounts = onSchedule({ schedule: '30 2 * * *', timeZone: 'Africa/Kampala', timeoutSeconds: 540, memory: '512MiB' }, async () => {
  if (!(await switchOn('accountErase'))) return;
  const cutoff = Timestamp.fromMillis(Date.now() - HOLD_DAYS * 86400000);
  const due = await db().collection('deletionRequests').where('status', '==', 'closed').where('closedAt', '<=', cutoff).limit(50).get();
  for (const r of due.docs) {
    const uid = r.get('uid');
    if (typeof uid !== 'string' || !uid) continue;
    try {
      await eraseAccount(uid, r.id);
    } catch (e) {
      logger.error('erase failed', { uid, error: String(e) });
    }
  }
});
