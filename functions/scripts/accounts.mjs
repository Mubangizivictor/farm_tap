// Support tool for closed accounts (decision 0024), the same as the control
// panel's "Deleted accounts" page:
//
//   node scripts/accounts.mjs list              # closed accounts and their restore-by date
//   node scripts/accounts.mjs restore <uid>     # bring an account and its farms back
//   node scripts/accounts.mjs erase <uid>       # erase now (cannot be undone)
//
// Needs `npm run build` first and Google application default credentials.
const { initializeApp, applicationDefault } = await import('firebase-admin/app');
const { getFirestore, FieldValue } = await import('firebase-admin/firestore');
const { getAuth } = await import('firebase-admin/auth');

initializeApp({ credential: applicationDefault(), projectId: process.env.FARMTAP_PROJECT ?? 'farm-tap-1dd15' });
const db = getFirestore();
const [cmd, uid] = process.argv.slice(2);
const day = 86400000;

if (cmd === 'list') {
  const s = await db.collection('deletionRequests').where('status', 'in', ['closed', 'requested']).get();
  for (const d of s.docs) {
    const at = d.get('closedAt')?.toDate?.();
    const by = at ? new Date(at.getTime() + 90 * day).toISOString().slice(0, 10) : '-';
    console.log(`${d.get('status').padEnd(9)} ${d.id}  ${d.get('email') ?? ''}  restore by ${by}`);
  }
} else if (cmd === 'restore' && uid) {
  const req = db.doc(`deletionRequests/${uid}`);
  const farms = (await req.get()).get('farms') ?? [];
  const b = db.batch();
  b.update(db.doc(`users/${uid}`), { deletion: FieldValue.delete() });
  for (const t of farms) b.update(db.doc(`tenants/${t}`), { closure: FieldValue.delete() });
  b.update(req, { status: 'restored', restoredAt: FieldValue.serverTimestamp(), restoredBy: 'support-script' });
  await b.commit();
  await getAuth().updateUser(uid, { disabled: false }).catch(() => {});
  console.log(`Restored ${uid} and ${farms.length} farm(s).`);
} else if (cmd === 'erase' && uid) {
  const { eraseAccount } = await import('../lib/accounts.js');
  const r = await eraseAccount(uid, uid);
  console.log(`Erased ${uid} and ${r.farms} farm(s).`);
} else {
  console.log('Use: list | restore <uid> | erase <uid>');
  process.exit(1);
}
