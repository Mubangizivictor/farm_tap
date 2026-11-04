// Firestore rules tests (decision 0014). Run: cd firestore && npm install && npm test
import { readFileSync } from 'node:fs';
import { afterAll, beforeAll, beforeEach, describe, test } from 'vitest';
import { assertFails, assertSucceeds, initializeTestEnvironment } from '@firebase/rules-unit-testing';
import { Timestamp, doc, getDoc, serverTimestamp, setDoc, deleteDoc, updateDoc, writeBatch, increment, arrayUnion } from 'firebase/firestore';

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

  test('a delivery can be undone (soft delete) but not changed', async () => {
    const db = as('worker');
    const ref = doc(db, `tenants/${T}/deliveries/d1`);
    await assertSucceeds(setDoc(ref, rec('deliveries', 'd1')));
    await assertFails(setDoc(ref, rec('deliveries', 'd1', { version: 2, isDeleted: true, body: { litres: 99 } })));
    await assertSucceeds(setDoc(ref, rec('deliveries', 'd1', { version: 2, isDeleted: true })));
  });

  test('normal records can be edited (new version)', async () => {
    const db = as('worker');
    const ref = doc(db, `tenants/${T}/animals/a1`);
    await assertSucceeds(setDoc(ref, rec('animals', 'a1')));
    await assertSucceeds(setDoc(ref, rec('animals', 'a1', { version: 2, body: { name: 'Bihogo' } })));
  });

  test('a worker ticks a task done from their phone, but cannot rewrite it', async () => {
    const task = { title: 'Spray the calves', staffId: 'staff-amos', due: '2026-11-07T18:00:00.000', when: '', doneAt: null };
    await assertSucceeds(setDoc(doc(as('owner'), `tenants/${T}/tasks/k1`), rec('tasks', 'k1', { body: task })));
    const db = as('worker');
    const ref = doc(db, `tenants/${T}/tasks/k1`);
    await assertSucceeds(setDoc(ref, rec('tasks', 'k1', { version: 2, deviceId: 'phone-b', body: { ...task, doneAt: '2026-11-07T15:00:00.000' } })));
    await assertFails(setDoc(ref, rec('tasks', 'k1', { version: 3, body: { ...task, title: 'Nothing' } })));
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

  test('an SMS can only be queued, never marked sent from the app', async () => {
    const db = as('worker');
    await assertSucceeds(setDoc(doc(db, `tenants/${T}/smsOutbox/s1`),
      rec('smsOutbox', 's1', { body: { status: 'queued', to: '+256772451908', text: 'Hi' } })));
    await assertFails(setDoc(doc(db, `tenants/${T}/smsOutbox/s2`),
      rec('smsOutbox', 's2', { body: { status: 'sent', to: '+256772451908', text: 'Hi' } })));
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

  test('the moment the trial ends, nothing can be written (decision 0023)', async () => {
    await env.withSecurityRulesDisabled((ctx) =>
      updateDoc(doc(ctx.firestore(), `tenants/${T}`), { 'subscription.trialEndsAt': Timestamp.fromMillis(Date.now() - 60000) }));
    await assertFails(setDoc(doc(as('owner'), `tenants/${T}/milkRecords/m9`), rec('milkRecords', 'm9')));
  });

  test('paid farms write until paid-until, with no grace after', async () => {
    await env.withSecurityRulesDisabled((ctx) =>
      updateDoc(doc(ctx.firestore(), `tenants/${T}`), { 'subscription.trialEndsAt': days(-60), 'subscription.paidUntil': days(3) }));
    await assertSucceeds(setDoc(doc(as('owner'), `tenants/${T}/milkRecords/m1`), rec('milkRecords', 'm1')));
    await env.withSecurityRulesDisabled((ctx) =>
      updateDoc(doc(ctx.firestore(), `tenants/${T}`), { 'subscription.paidUntil': Timestamp.fromMillis(Date.now() - 60000) }));
    await assertFails(setDoc(doc(as('owner'), `tenants/${T}/milkRecords/m2`), rec('milkRecords', 'm2')));
  });
});

// The app creates a farm in one batch: farm, owner membership, and the
// account's ownedFarms going up by one (decision 0018).
function createFarm(db, uid, id, farm = {}) {
  const b = writeBatch(db);
  b.set(doc(db, `tenants/${id}`), {
    ownerUid: uid, name: 'New', subscription: { trialStartedAt: days(0), trialEndsAt: days(7) },
    review: { status: 'pending' }, ...farm,
  });
  b.set(doc(db, `tenants/${id}/members/${uid}`), { role: 'owner' });
  b.set(doc(db, `users/${uid}`), { memberships: arrayUnion({ tenantId: id, role: 'owner' }), ownedFarms: increment(1) },
    { merge: true });
  return b.commit();
}

describe('onboarding', () => {
  test('a new user creates their farm on trial and becomes its owner', async () => {
    const db = as('newbie');
    await assertSucceeds(createFarm(db, 'newbie', 'new-farm'));
    await assertSucceeds(getDoc(doc(db, 'tenants/new-farm')));
  });

  test('a new farm waits for review; the owner cannot approve it', async () => {
    const db = as('newbie');
    const farm = { subscription: { trialEndsAt: days(7) } };
    await assertFails(createFarm(db, 'newbie', 'f5', { ...farm, review: null }));
    await assertFails(createFarm(db, 'newbie', 'f5', { ...farm, review: { status: 'approved' } }));
    await assertSucceeds(createFarm(db, 'newbie', 'f5', farm));
    await assertFails(updateDoc(doc(db, 'tenants/f5'), { review: { status: 'approved' } }));
    await assertSucceeds(updateDoc(doc(db, 'tenants/f5'), { name: 'New name' }));
  });

  test('cannot create a farm already paid, or for someone else', async () => {
    const db = as('newbie');
    await assertFails(createFarm(db, 'newbie', 'f2', { subscription: { trialEndsAt: days(14), paidUntil: days(365) } }));
    // A 14-day trial (the default): 16 days is too long.
    await assertFails(createFarm(db, 'newbie', 'f3', { subscription: { trialEndsAt: days(16) } }));
    await assertFails(createFarm(db, 'newbie', 'f4', { ownerUid: 'someone' }));
  });
});

describe('one farm per account (decision 0018)', () => {
  test('a second farm is refused', async () => {
    const db = as('newbie');
    await assertSucceeds(createFarm(db, 'newbie', 'first'));
    await assertFails(createFarm(db, 'newbie', 'second'));
  });

  test('a farm without counting it is refused', async () => {
    const db = as('newbie');
    await assertFails(setDoc(doc(db, 'tenants/sneaky'), {
      ownerUid: 'newbie', name: 'New', subscription: { trialStartedAt: days(0), trialEndsAt: days(7) },
      review: { status: 'pending' },
    }));
  });

  test('the count cannot be reset, the limit cannot be raised, the account cannot be deleted', async () => {
    const db = as('newbie');
    await assertSucceeds(createFarm(db, 'newbie', 'first'));
    await assertFails(updateDoc(doc(db, 'users/newbie'), { ownedFarms: 0 }));
    await assertFails(updateDoc(doc(db, 'users/newbie'), { farmLimit: 5 }));
    await assertFails(deleteDoc(doc(db, 'users/newbie')));
    await assertFails(setDoc(doc(db, 'users/other-new'), { farmLimit: 3 }));
    // Other profile fields still save.
    await assertSucceeds(updateDoc(doc(db, 'users/newbie'), { phone: '+256700000000' }));
  });

  test('a multi-farm plan (set by Victorbee) allows more farms', async () => {
    await env.withSecurityRulesDisabled((ctx) => setDoc(doc(ctx.firestore(), 'users/big'), { farmLimit: 2 }));
    const db = as('big');
    await assertSucceeds(createFarm(db, 'big', 'one'));
    await assertSucceeds(createFarm(db, 'big', 'two'));
    await assertFails(createFarm(db, 'big', 'three'));
  });

  test("cannot join someone else's farm as owner", async () => {
    const db = as('newbie');
    await assertFails(setDoc(doc(db, `tenants/${T}/members/newbie`), { role: 'owner' }));
  });
});

describe('worker phone sign-in and PINs (decision 0016)', () => {
  beforeEach(async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      const db = ctx.firestore();
      await setDoc(doc(db, `tenants/${T}/members/amos-uid`), { role: 'worker', staffId: 'staff-ta' });
      await setDoc(doc(db, `tenants/${T}/members/tom-uid`), { role: 'manager', staffId: 'staff-tm' });
    });
  });

  const login = { tenantId: T, staffId: 'staff-ta', uid: 'amos-uid', v: 1 };

  test('the owner gives a worker a phone login; anyone can find which version it is', async () => {
    const db = as('owner');
    await assertSucceeds(setDoc(doc(db, `tenants/${T}/members/new-uid`), { role: 'worker', staffId: 'staff-np', name: 'Peter' }));
    await assertSucceeds(setDoc(doc(db, 'staffLogins/701220318'), login));
    await assertSucceeds(getDoc(doc(env.unauthenticatedContext().firestore(), 'staffLogins/701220318')));
  });

  test('only the owner makes managers; nobody makes an owner', async () => {
    await assertFails(setDoc(doc(as('tom-uid'), `tenants/${T}/members/x`), { role: 'manager', staffId: 'staff-x' }));
    await assertSucceeds(setDoc(doc(as('tom-uid'), `tenants/${T}/members/y`), { role: 'clerk', staffId: 'staff-y' }));
    await assertFails(setDoc(doc(as('owner'), `tenants/${T}/members/z`), { role: 'owner', staffId: 'staff-z' }));
    await assertFails(setDoc(doc(as('owner'), `tenants/${T}/members/w`), { role: 'worker' }));
  });

  test('a worker cannot make logins or point a phone at another farm', async () => {
    await assertFails(setDoc(doc(as('amos-uid'), `tenants/${T}/members/x`), { role: 'worker', staffId: 'staff-x' }));
    await assertFails(setDoc(doc(as('amos-uid'), 'staffLogins/701220318'), login));
    await env.withSecurityRulesDisabled((ctx) => setDoc(doc(ctx.firestore(), 'staffLogins/701220318'), login));
    await assertFails(setDoc(doc(as('stranger'), 'staffLogins/701220318'), { ...login, tenantId: 'other', v: 2 }));
    await assertSucceeds(setDoc(doc(as('owner'), 'staffLogins/701220318'), { ...login, uid: 'amos-2', v: 2 }));
  });

  test("a worker saves their own PIN, never someone else's", async () => {
    const db = as('amos-uid');
    await assertSucceeds(setDoc(doc(db, `tenants/${T}/staffPins/staff-ta`), rec('staffPins', 'staff-ta')));
    await assertFails(setDoc(doc(db, `tenants/${T}/staffPins/staff-tm`), rec('staffPins', 'staff-tm')));
    await assertSucceeds(setDoc(doc(as('owner'), `tenants/${T}/staffPins/staff-tm`), rec('staffPins', 'staff-tm')));
  });
});

describe('platform control panel (decision 0020)', () => {
  beforeEach(async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      const db = ctx.firestore();
      await setDoc(doc(db, 'platformAdmins/victor'), { role: 'owner', active: true });
      await setDoc(doc(db, 'platformAdmins/fin'), { role: 'finance', perms: ['finance'], active: true });
      await setDoc(doc(db, 'platformAdmins/gone'), { role: 'support', perms: ['support', 'farms'], active: false });
      await setDoc(doc(db, 'platform/config'), { trialDays: 7, maintenance: { on: false } });
      await setDoc(doc(db, 'platformSecrets/sms_api_key'), { value: 'secret-123' });
    });
  });

  // An admin write plus its audit entry, in one batch.
  function audited(db, ref, data, auditId = `a-${Math.random()}`, merge = true) {
    const b = writeBatch(db);
    b.set(doc(db, `adminAudit/${auditId}`), { by: db._uid, at: serverTimestamp(), action: 'test' });
    b.set(ref, { ...data, lastAudit: auditId }, { merge });
    return b.commit();
  }
  const adminDb = (uid) => {
    const db = as(uid);
    db._uid = uid;
    return db;
  };

  test('the apps read the public config even signed out; nobody reads secrets', async () => {
    await assertSucceeds(getDoc(doc(env.unauthenticatedContext().firestore(), 'platform/config')));
    await assertFails(getDoc(doc(adminDb('victor'), 'platformSecrets/sms_api_key')));
  });

  test('the owner changes settings with an audit entry, never without', async () => {
    const db = adminDb('victor');
    await assertSucceeds(audited(db, doc(db, 'platform/config'), { trialDays: 10 }));
    await assertFails(setDoc(doc(db, 'platform/config'), { trialDays: 30 }, { merge: true }));
  });

  test('an old audit entry cannot be reused', async () => {
    const db = adminDb('victor');
    await assertSucceeds(audited(db, doc(db, 'platform/config'), { trialDays: 10 }, 'once'));
    await assertFails(setDoc(doc(db, 'platform/config'), { trialDays: 40, lastAudit: 'once' }, { merge: true }));
  });

  test('a farm owner or stranger cannot change settings or plans', async () => {
    const db = adminDb('owner');
    await assertFails(audited(db, doc(db, 'platform/config'), { trialDays: 99 }));
    await assertFails(audited(db, doc(db, 'plans/basic'), { name: 'Free', priceUgx: 0 }));
  });

  test('finance staff record payments and extend paid-until, but not settings', async () => {
    const db = adminDb('fin');
    await assertSucceeds(audited(db, doc(db, 'platformPayments/p1'), { tenantId: T, amountUgx: 70000, status: 'received' }, undefined, false));
    await assertSucceeds(audited(db, doc(db, `tenants/${T}`), { subscription: { trialEndsAt: days(9), paidUntil: days(30) } }));
    await assertFails(audited(db, doc(db, 'platform/config'), { trialDays: 10 }));
    await assertFails(audited(db, doc(db, `tenants/${T}`), { status: 'suspended' }));
  });

  test('turned-off staff can do nothing', async () => {
    const db = adminDb('gone');
    await assertFails(getDoc(doc(db, `tenants/${T}`)));
  });

  test('secrets are write-only for the owner', async () => {
    const db = adminDb('victor');
    await assertSucceeds(audited(db, doc(db, 'platformSecrets/mtn_api_key'), { value: 'k-999' }, undefined, false));
    await assertFails(getDoc(doc(db, 'platformSecrets/mtn_api_key')));
  });

  test('suspending a farm stops its writes', async () => {
    const db = adminDb('victor');
    await assertSucceeds(audited(db, doc(db, `tenants/${T}`), { status: 'suspended' }));
    await assertFails(setDoc(doc(as('worker'), `tenants/${T}/milkRecords/m9`), rec('milkRecords', 'm9')));
  });

  test('a farm cannot set panel fields on itself', async () => {
    await assertFails(updateDoc(doc(as('owner'), `tenants/${T}`), { status: 'active', features: { exports: true } }));
    await assertFails(updateDoc(doc(as('owner'), `tenants/${T}`), { smsCredits: 1000 }));
  });

  test('admins open any farm read-only', async () => {
    const db = adminDb('victor');
    await assertSucceeds(getDoc(doc(db, `tenants/${T}/milkRecords/x`)));
    await assertFails(setDoc(doc(db, `tenants/${T}/milkRecords/m1`), rec('milkRecords', 'm1')));
  });

  test('the audit log cannot be edited or deleted', async () => {
    const db = adminDb('victor');
    await assertSucceeds(audited(db, doc(db, 'platform/config'), { trialDays: 8 }, 'keep'));
    await assertFails(updateDoc(doc(db, 'adminAudit/keep'), { action: 'nothing happened' }));
    await assertFails(deleteDoc(doc(db, 'adminAudit/keep')));
  });

  test('the panel never makes an owner; staff need the staff permission', async () => {
    const v = adminDb('victor');
    await assertSucceeds(audited(v, doc(v, 'platformAdmins/amy'), { role: 'support', perms: ['support'], active: true }, undefined, false));
    await assertFails(audited(v, doc(v, 'platformAdmins/bob'), { role: 'owner', perms: [], active: true }, undefined, false));
    const f = adminDb('fin');
    await assertFails(audited(f, doc(f, 'platformAdmins/fin2'), { role: 'finance', perms: ['finance', 'staff'], active: true }, undefined, false));
  });

  test('an invited person joins with exactly the invited permissions', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'adminInvites/sam@example.com'), { role: 'support', perms: ['support'], active: true });
    });
    const sam = env.authenticatedContext('sam', { email: 'Sam@example.com', email_verified: true }).firestore();
    await assertFails(setDoc(doc(sam, 'platformAdmins/sam'), { role: 'support', perms: ['support', 'secrets'], active: true, email: 'sam@example.com' }));
    await assertSucceeds(setDoc(doc(sam, 'platformAdmins/sam'), { role: 'support', perms: ['support'], active: true, email: 'sam@example.com' }));
  });

  test('an account cannot undo its own disabling', async () => {
    const v = adminDb('victor');
    await assertSucceeds(setDoc(doc(as('owner'), 'users/owner'), { memberships: [], ownedFarms: 1 }));
    await assertSucceeds(audited(v, doc(v, 'users/owner'), { disabled: true }));
    await assertFails(setDoc(doc(as('owner'), 'users/owner'), { disabled: false }, { merge: true }));
  });

  test('support resets a card PIN with a new version', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), `tenants/${T}/staffPins/s1`), rec('staffPins', 's1', { body: { pinHash: 'x', mustChange: false } }));
      await setDoc(doc(ctx.firestore(), 'platformAdmins/sup'), { role: 'support', perms: ['users', 'support'], active: true });
    });
    const db = adminDb('sup');
    await assertSucceeds(audited(db, doc(db, `tenants/${T}/staffPins/s1`), rec('staffPins', 's1', { version: 2, body: { pinHash: 'y', mustChange: true } }), undefined, false));
  });
});

describe('supplier portal invites', () => {
  const invite = { tenantId: T, farmerId: 'farmer-1', farmerName: 'John', farmName: 'Rwemera', createdAt: '2026-11-04T08:00:00.000', expiresAt: '2026-11-11T08:00:00.000', used: false };
  const accept = (db, uid, code, links = [{ tenantId: T, farmerId: 'farmer-1' }]) => {
    const b = writeBatch(db);
    b.set(doc(db, `users/${uid}`), { farmerLinks: links, inviteCode: code }, { merge: true });
    b.update(doc(db, `farmerInvites/${code}`), { used: true, usedBy: uid, usedAt: '2026-11-04T09:00:00.000' });
    return b.commit();
  };
  beforeEach(async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      const db = ctx.firestore();
      await setDoc(doc(db, `tenants/${T}/deliveries/d1`), rec('deliveries', 'd1', { body: { farmerId: 'farmer-1', litres: 20 } }));
      await setDoc(doc(db, `tenants/${T}/deliveries/d2`), rec('deliveries', 'd2', { body: { farmerId: 'farmer-2', litres: 15 } }));
    });
  });

  test('a manager makes an invite; a worker cannot', async () => {
    await assertSucceeds(setDoc(doc(as('owner'), 'farmerInvites/ABC123'), invite));
    await assertFails(setDoc(doc(as('worker'), 'farmerInvites/XYZ999'), invite));
  });

  test('the farmer accepts once and then sees only their own deliveries', async () => {
    await setDoc(doc(as('owner'), 'farmerInvites/ABC123'), invite);
    const db = as('john');
    await assertSucceeds(accept(db, 'john', 'ABC123'));
    await assertSucceeds(getDoc(doc(db, `tenants/${T}/deliveries/d1`)));
    await assertFails(getDoc(doc(db, `tenants/${T}/deliveries/d2`)));
    // Used: nobody can accept it again.
    await assertFails(accept(as('rose'), 'rose', 'ABC123'));
  });

  test('nobody links themselves to a farmer without an invite', async () => {
    await assertFails(setDoc(doc(as('mallory'), 'users/mallory'), { farmerLinks: [{ tenantId: T, farmerId: 'farmer-2' }] }));
    await setDoc(doc(as('owner'), 'farmerInvites/ABC123'), invite);
    // An invite for farmer-1 cannot be used to link farmer-2.
    await assertFails(accept(as('mallory'), 'mallory', 'ABC123', [{ tenantId: T, farmerId: 'farmer-2' }]));
  });
});


describe('locked after the trial or plan ends (decision 0023)', () => {
  const lock = () =>
    env.withSecurityRulesDisabled(async (ctx) => {
      const db = ctx.firestore();
      await setDoc(doc(db, `tenants/${T}/tasks/t1`), rec('tasks', 't1', { body: { title: 'Dip', staffId: 's1', due: '2026-11-07', when: '', doneAt: null } }));
      await setDoc(doc(db, `tenants/${T}/milkRecords/old`), rec('milkRecords', 'old'));
      await updateDoc(doc(db, `tenants/${T}`), { 'subscription.trialEndsAt': days(-1) });
    });

  test('members can still read their records', async () => {
    await lock();
    await assertSucceeds(getDoc(doc(as('worker'), `tenants/${T}/milkRecords/old`)));
    await assertSucceeds(getDoc(doc(as('owner'), `tenants/${T}`)));
  });

  test('no adding, editing, removing, cards, tasks or farm changes', async () => {
    await lock();
    const owner = as('owner');
    await assertFails(setDoc(doc(owner, `tenants/${T}/animals/a1`), rec('animals', 'a1', { body: { tagNumber: 'FT-001' } })));
    await assertFails(setDoc(doc(owner, `tenants/${T}/nfcCards/0042`), rec('nfcCards', '0042', { body: { personId: 's1', status: 'active' } })));
    await assertFails(updateDoc(doc(owner, `tenants/${T}/milkRecords/old`), { isDeleted: true, version: 2, serverUpdatedAt: serverTimestamp() }));
    await assertFails(updateDoc(doc(as('worker'), `tenants/${T}/tasks/t1`), {
      body: { title: 'Dip', staffId: 's1', due: '2026-11-07', when: '', doneAt: '2026-11-07T08:00:00.000' }, version: 2, serverUpdatedAt: serverTimestamp(),
    }));
    await assertFails(updateDoc(doc(owner, `tenants/${T}`), { name: 'Renamed' }));
    await assertFails(setDoc(doc(owner, 'staffLogins/256772000000'), { tenantId: T, staffId: 's1', uid: 'x', v: 1 }));
    await assertFails(setDoc(doc(owner, `tenants/${T}/members/newworker`), { role: 'worker', staffId: 's1' }));
  });

  test('the owner can still send a payment claim, and only that', async () => {
    await lock();
    await assertSucceeds(setDoc(doc(as('owner'), `tenants/${T}/payments/p1`), rec('payments', 'p1', { body: { status: 'submitted', amount: 70000, method: 'mtn', reference: 'X1' } })));
    await assertFails(setDoc(doc(as('owner'), `tenants/${T}/payments/p2`), rec('payments', 'p2', { body: { status: 'confirmed', amount: 70000 } })));
    await assertFails(setDoc(doc(as('worker'), `tenants/${T}/payments/p3`), rec('payments', 'p3', { body: { status: 'submitted', amount: 70000 } })));
  });

  test('a suspended farm is locked even on trial', async () => {
    await env.withSecurityRulesDisabled((ctx) => updateDoc(doc(ctx.firestore(), `tenants/${T}`), { status: 'suspended' }));
    await assertFails(setDoc(doc(as('owner'), `tenants/${T}/milkRecords/m1`), rec('milkRecords', 'm1')));
  });

  test('nobody in the farm can start their own plan', async () => {
    const owner = as('owner');
    await assertFails(updateDoc(doc(owner, `tenants/${T}`), { 'subscription.paidUntil': days(365) }));
    await assertFails(setDoc(doc(owner, `tenants/${T}/subscriptionPayments/x`), rec('subscriptionPayments', 'x', { body: { status: 'paid' } })));
    await assertFails(setDoc(doc(owner, 'paymentRefs/x'), { tenantId: T }));
    await assertFails(getDoc(doc(owner, 'paymentRefs/x')));
  });

  test('in-app payments: the farm reads them, nobody writes them', async () => {
    await env.withSecurityRulesDisabled((ctx) =>
      setDoc(doc(ctx.firestore(), `tenants/${T}/subscriptionPayments/sp1`), { status: 'pending', amountUgx: 70000, method: 'mtn' }));
    await assertSucceeds(getDoc(doc(as('owner'), `tenants/${T}/subscriptionPayments/sp1`)));
    await assertFails(updateDoc(doc(as('owner'), `tenants/${T}/subscriptionPayments/sp1`), { status: 'paid' }));
    await assertFails(getDoc(doc(as('stranger'), `tenants/${T}/subscriptionPayments/sp1`)));
  });
});

describe('linked spending (decision 0023)', () => {
  const buy = (db, id, eid) => {
    const b = writeBatch(db);
    b.set(doc(db, `tenants/${T}/stockMovements/${id}`), rec('stockMovements', id, { body: { kind: 'purchase', feed: 'dairyMeal', amount: 10, pricePerUnit: 60000, at: '2026-11-07T08:00:00.000' } }));
    b.set(doc(db, `tenants/${T}/expenses/${eid}`), rec('expenses', eid, { body: { category: 'feed', amount: 600000, at: '2026-11-07T08:00:00.000', sourceId: id, sourceType: 'feedPurchase' } }));
    return b.commit();
  };

  test('a feed purchase and its expense are saved together; a worker cannot', async () => {
    await assertSucceeds(buy(as('owner'), 'buy1', 'e1'));
    await assertFails(buy(as('worker'), 'buy2', 'e2'));
  });

  test('an edit removes the old pair and saves a new pair in one write', async () => {
    const db = as('owner');
    await buy(db, 'buy1', 'e1');
    const b = writeBatch(db);
    for (const [c, id] of [['stockMovements', 'buy1'], ['expenses', 'e1']]) {
      b.update(doc(db, `tenants/${T}/${c}/${id}`), { isDeleted: true, version: 2, updatedBy: 'owner', serverUpdatedAt: serverTimestamp() });
    }
    b.set(doc(db, `tenants/${T}/stockMovements/buy1b`), rec('stockMovements', 'buy1b', { body: { kind: 'purchase', feed: 'dairyMeal', amount: 12, pricePerUnit: 60000, at: '2026-11-07T08:00:00.000' } }));
    b.set(doc(db, `tenants/${T}/expenses/e1b`), rec('expenses', 'e1b', { body: { category: 'feed', amount: 720000, at: '2026-11-07T08:00:00.000', sourceId: 'buy1b' } }));
    await assertSucceeds(b.commit());
  });

  test('an expense amount cannot be changed in place', async () => {
    const db = as('owner');
    await buy(db, 'buy1', 'e1');
    await assertFails(updateDoc(doc(db, `tenants/${T}/expenses/e1`), { body: { category: 'feed', amount: 1, at: '2026-11-07T08:00:00.000' }, version: 2, serverUpdatedAt: serverTimestamp() }));
  });

  test('contacts and the duty roster: any member reads; managers write', async () => {
    await assertSucceeds(setDoc(doc(as('owner'), `tenants/${T}/contacts/c1`), rec('contacts', 'c1', { body: { name: 'Dr Okello', kind: 'vet', phone: '0772000000' } })));
    await assertSucceeds(getDoc(doc(as('worker'), `tenants/${T}/contacts/c1`)));
    await assertSucceeds(setDoc(doc(as('owner'), `tenants/${T}/duties/d1`), rec('duties', 'd1', { body: { activity: 'milking', staffId: 's1', days: [], shift: 'morning' } })));
    await assertSucceeds(getDoc(doc(as('worker'), `tenants/${T}/duties/d1`)));
    await assertFails(setDoc(doc(as('worker'), `tenants/${T}/duties/d2`), rec('duties', 'd2', { body: { activity: 'milking', staffId: 'me', days: [], shift: 'morning' } })));
    await assertFails(setDoc(doc(as('worker'), `tenants/${T}/contacts/c2`), rec('contacts', 'c2', { body: { name: 'x', kind: 'vet', phone: '1' } })));
  });
});
