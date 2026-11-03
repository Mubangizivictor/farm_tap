// Firestore rules tests (decision 0014). Run: cd firestore && npm install && npm test
import { readFileSync } from 'node:fs';
import { afterAll, beforeAll, beforeEach, describe, test } from 'vitest';
import { assertFails, assertSucceeds, initializeTestEnvironment } from '@firebase/rules-unit-testing';
import { Timestamp, doc, getDoc, serverTimestamp, setDoc, deleteDoc, updateDoc } from 'firebase/firestore';

const days = (n) => Timestamp.fromMillis(Date.now() + n * 86400000);

const T = 'farm-rwemera';
let env;

beforeAll(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-farmtap',
    firestore: { rules: readFileSync('../firestore.rules', 'utf8'), host: '127.0.0.1', port: 8080 },
  });
});
afterAll(() => env.cleanup());

beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, `tenants/${T}`), { ownerUid: 'owner', name: 'Rwemera', subscription: { trialStartedAt: days(-5), trialEndsAt: days(9) } });
    await setDoc(doc(db, `tenants/${T}/members/owner`), { role: 'owner' });
    await setDoc(doc(db, `tenants/${T}/members/worker`), { role: 'worker' });
    await setDoc(doc(db, 'tenants/other'), { ownerUid: 'stranger' });
    await setDoc(doc(db, 'tenants/other/members/stranger'), { role: 'owner' });
  });
});

const as = (uid) => env.authenticatedContext(uid).firestore();

function rec(collection, id, extra = {}) {
  return {
    collection, id, tenantId: T, body: { litres: 9.5 }, version: 1, isDeleted: false,
    createdAt: '2026-11-07T06:52:00.000', updatedAt: '2026-11-07T06:52:00.000',
    createdBy: 'staff-amos', updatedBy: 'staff-amos', deviceId: 'phone-a',
    serverUpdatedAt: serverTimestamp(), ...extra,
  };
}

describe('farm data stays in the farm', () => {
  test('a member reads and writes records', async () => {
    const db = as('worker');
    await assertSucceeds(setDoc(doc(db, `tenants/${T}/milkRecords/m1`), rec('milkRecords', 'm1')));
    await assertSucceeds(getDoc(doc(db, `tenants/${T}/milkRecords/m1`)));
  });

  test('another farm cannot read or write', async () => {
    const db = as('stranger');
    await assertFails(getDoc(doc(db, `tenants/${T}/milkRecords/m1`)));
    await assertFails(setDoc(doc(db, `tenants/${T}/milkRecords/m1`), rec('milkRecords', 'm1')));
  });

  test('signed out: nothing', async () => {
    const db = env.unauthenticatedContext().firestore();
    await assertFails(getDoc(doc(db, `tenants/${T}`)));
  });

  test('record must match its path and carry base fields', async () => {
    const db = as('worker');
    await assertFails(setDoc(doc(db, `tenants/${T}/milkRecords/m1`), rec('milkRecords', 'OTHER')));
    await assertFails(setDoc(doc(db, `tenants/${T}/milkRecords/m1`), rec('animals', 'm1')));
    await assertFails(setDoc(doc(db, `tenants/${T}/milkRecords/m1`), rec('milkRecords', 'm1', { tenantId: 'other' })));
    await assertFails(setDoc(doc(db, `tenants/${T}/milkRecords/m1`), rec('milkRecords', 'm1', { version: 0 })));
  });
});

describe('append-only and soft delete', () => {
  test('a retried send of the same milk record is fine; an edit is not', async () => {
    const db = as('worker');
    const ref = doc(db, `tenants/${T}/milkRecords/m1`);
    await assertSucceeds(setDoc(ref, rec('milkRecords', 'm1')));
    await assertSucceeds(setDoc(ref, rec('milkRecords', 'm1')));
    await assertFails(setDoc(ref, rec('milkRecords', 'm1', { version: 2, body: { litres: 19.5 } })));
  });

  test('normal records can be edited (new version)', async () => {
    const db = as('worker');
    const ref = doc(db, `tenants/${T}/animals/a1`);
    await assertSucceeds(setDoc(ref, rec('animals', 'a1')));
    await assertSucceeds(setDoc(ref, rec('animals', 'a1', { version: 2, body: { name: 'Bihogo' } })));
  });

  test('nobody hard-deletes', async () => {
    const db = as('owner');
    const ref = doc(db, `tenants/${T}/animals/a1`);
    await assertSucceeds(setDoc(ref, rec('animals', 'a1')));
    await assertFails(deleteDoc(ref));
  });
});

describe('roles and money', () => {
  test('a worker cannot write wages or staff; the owner can', async () => {
    await assertFails(setDoc(doc(as('worker'), `tenants/${T}/wages/w1`), rec('wages', 'w1')));
    await assertFails(setDoc(doc(as('worker'), `tenants/${T}/staff/s1`), rec('staff', 's1')));
    await assertSucceeds(setDoc(doc(as('owner'), `tenants/${T}/wages/w1`), rec('wages', 'w1')));
  });

  test('a payment can only be submitted, never confirmed from the app', async () => {
    const db = as('owner');
    await assertSucceeds(setDoc(doc(db, `tenants/${T}/payments/p1`),
      rec('payments', 'p1', { body: { status: 'submitted', amount: 70000 } })));
    await assertFails(setDoc(doc(db, `tenants/${T}/payments/p2`),
      rec('payments', 'p2', { body: { status: 'confirmed', amount: 70000 } })));
  });

  test('subscription cannot be changed from the app', async () => {
    await assertFails(updateDoc(doc(as('owner'), `tenants/${T}`), { 'subscription.paidUntil': days(365) }));
    await assertSucceeds(updateDoc(doc(as('owner'), `tenants/${T}`), { name: 'Rwemera Dairy' }));
  });

  test('a worker cannot make themselves owner', async () => {
    await assertFails(setDoc(doc(as('worker'), `tenants/${T}/members/worker`), { role: 'owner' }));
  });

  test('read-only after the trial: no new records', async () => {
    await env.withSecurityRulesDisabled((ctx) =>
      updateDoc(doc(ctx.firestore(), `tenants/${T}`), { 'subscription.trialEndsAt': days(-3) }));
    await assertFails(setDoc(doc(as('owner'), `tenants/${T}/milkRecords/m9`), rec('milkRecords', 'm9')));
    await assertSucceeds(getDoc(doc(as('owner'), `tenants/${T}`)));
  });

  test('a phone offline when the trial ended can still send for 2 days', async () => {
    await env.withSecurityRulesDisabled((ctx) =>
      updateDoc(doc(ctx.firestore(), `tenants/${T}`), { 'subscription.trialEndsAt': days(-1) }));
    await assertSucceeds(setDoc(doc(as('owner'), `tenants/${T}/milkRecords/m9`), rec('milkRecords', 'm9')));
  });

  test('paid farms write; overdue past grace do not', async () => {
    await env.withSecurityRulesDisabled((ctx) =>
      updateDoc(doc(ctx.firestore(), `tenants/${T}`), { 'subscription.trialEndsAt': days(-60), 'subscription.paidUntil': days(-3) }));
    await assertSucceeds(setDoc(doc(as('owner'), `tenants/${T}/milkRecords/m1`), rec('milkRecords', 'm1')));
    await env.withSecurityRulesDisabled((ctx) =>
      updateDoc(doc(ctx.firestore(), `tenants/${T}`), { 'subscription.paidUntil': days(-20) }));
    await assertFails(setDoc(doc(as('owner'), `tenants/${T}/milkRecords/m2`), rec('milkRecords', 'm2')));
  });
});

describe('onboarding', () => {
  test('a new user creates their farm on trial and becomes its owner', async () => {
    const db = as('newbie');
    await assertSucceeds(setDoc(doc(db, 'tenants/new-farm'),
      { ownerUid: 'newbie', name: 'New', subscription: { trialStartedAt: days(0), trialEndsAt: days(14) } }));
    await assertSucceeds(setDoc(doc(db, 'tenants/new-farm/members/newbie'), { role: 'owner' }));
  });

  test('cannot create a farm already paid, or for someone else', async () => {
    const db = as('newbie');
    await assertFails(setDoc(doc(db, 'tenants/f2'),
      { ownerUid: 'newbie', subscription: { trialEndsAt: days(14), paidUntil: days(365) } }));
    await assertFails(setDoc(doc(db, 'tenants/f3'), { ownerUid: 'newbie', subscription: { trialEndsAt: days(90) } }));
    await assertFails(setDoc(doc(db, 'tenants/f4'), { ownerUid: 'someone', subscription: { trialEndsAt: days(14) } }));
  });
});
