// End-to-end payment test against the Firestore emulator (no real money,
// no network: the provider is stubbed). Run with the emulator up:
//   cd functions && npm run build && node scripts/payment-flow.emulator.mjs
process.env.FIRESTORE_EMULATOR_HOST ??= '127.0.0.1:8080';
process.env.GCLOUD_PROJECT = 'demo-farmtap';
process.env.FIREBASE_CONFIG = JSON.stringify({ projectId: 'demo-farmtap' });
import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
const require = createRequire(import.meta.url);

let mtnStatus = 'SUCCESSFUL';
let mtnAmount = '70000';
const calls = [];
globalThis.fetch = async (url, init) => {
  calls.push(String(url));
  const json = (status, body) => new Response(body === undefined ? '' : JSON.stringify(body), { status });
  if (String(url).includes('/collection/token/')) return json(200, { access_token: 'tok' });
  if (String(url).endsWith('/collection/v1_0/requesttopay')) return json(202);
  if (String(url).includes('/collection/v1_0/requesttopay/')) return json(200, { status: mtnStatus, amount: mtnAmount, currency: 'EUR', financialTransactionId: 'MTN-1' });
  return json(500, {});
};

const fns = require('../lib/index.js');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');
const db = getFirestore();
const T = 'farm1';
const tenant = await db.doc(`tenants/${T}`).get();
const ownerUid = tenant.get('ownerUid');
const asOwner = (data) => ({ auth: { uid: ownerUid, token: { name: 'Victor Owner', email: 'owner@test.ug' } }, data, rawRequest: {} });

// No keys yet: a clear error, nothing charged.
await assert.rejects(fns.startPayment.run(asOwner({ tenantId: T, planId: 'monthly', periods: 1, method: 'mtn', phone: '0772123456' })), /not set up/);
// Muted gateway.
await assert.rejects(fns.startPayment.run(asOwner({ tenantId: T, planId: 'monthly', periods: 1, method: 'airtel', phone: '0701123456' })), /coming soon/);
// A worker or stranger cannot pay.
await assert.rejects(fns.startPayment.run({ auth: { uid: 'stranger', token: {} }, data: { tenantId: T, planId: 'monthly', periods: 1, method: 'mtn', phone: '0772123456' }, rawRequest: {} }), /owner or a manager/);

for (const [k, v] of [['mtn_subscription_key', 'sub'], ['mtn_api_user', 'user'], ['mtn_api_key', 'key']]) await db.doc(`platformSecrets/${k}`).set({ value: v });
const before = tenant.get('subscription.paidUntil') ?? null;

// The app cannot set the price: 3 x Monthly is 210,000 from the stored plan.
const r = await fns.startPayment.run(asOwner({ tenantId: T, planId: 'monthly', periods: 3, method: 'mtn', phone: '0772 123 456', amountUgx: 1 }));
assert.equal(r.status, 'pending');
const pay = await db.doc(`tenants/${T}/subscriptionPayments/${r.paymentId}`).get();
assert.equal(pay.get('amountUgx'), 210000);
assert.equal(pay.get('phone'), '256772123456');

// Provider says paid but for less: refused.
mtnAmount = '1000';
let c = await fns.checkPayment.run(asOwner({ tenantId: T, paymentId: r.paymentId }));
assert.equal(c.status, 'failed');
assert.equal((await db.doc(`tenants/${T}`).get()).get('subscription.paidUntil') ?? null, before);

// A second payment, paid in full: the plan starts.
mtnAmount = '70000';
const r2 = await fns.startPayment.run(asOwner({ tenantId: T, planId: 'monthly', periods: 1, method: 'mtn', phone: '0772123456' }));
c = await fns.checkPayment.run(asOwner({ tenantId: T, paymentId: r2.paymentId }));
assert.equal(c.status, 'paid');
const after = (await db.doc(`tenants/${T}`).get()).data();
assert.ok(after.subscription.paidUntil instanceof Timestamp);
assert.ok(after.subscription.paidUntil.toMillis() > Date.now() + 27 * 86400000);
assert.equal(after.planId, 'monthly');
const pp = await db.doc(`platformPayments/${r2.paymentId}`).get();
assert.equal(pp.get('status'), 'received');
assert.equal(pp.get('amountUgx'), 70000);
const audit = await db.collection('adminAudit').where('target', '==', `platformPayments/${r2.paymentId}`).get();
assert.equal(audit.size, 1);

// Checking again changes nothing (no double months).
const until = after.subscription.paidUntil.toMillis();
c = await fns.checkPayment.run(asOwner({ tenantId: T, paymentId: r2.paymentId }));
assert.equal(c.status, 'paid');
assert.equal((await db.doc(`tenants/${T}`).get()).get('subscription.paidUntil').toMillis(), until);

console.log('payment flow: all checks passed', calls.length, 'provider calls (stubbed)');
// Put the farm back on trial for the screenshots.
await db.doc(`tenants/${T}`).update({ 'subscription.paidUntil': null, planId: null });
process.exit(0);
