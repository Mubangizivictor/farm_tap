// Fake data for the Firebase emulators (never the real project).
// Start: cd firestore && npx firebase emulators:start --only auth,firestore,functions --project demo-farmtap --config ../firebase.json
// Then:  cd functions && node scripts/seed-emulator.mjs
// Sign in on the web (NEXT_PUBLIC_FIREBASE_EMULATORS=true) as owner@test.ug / farmtap123
// (farm on trial) or locked@test.ug / farmtap123 (trial ended: lock screen).
process.env.FIRESTORE_EMULATOR_HOST ??= '127.0.0.1:8080';
process.env.FIREBASE_AUTH_EMULATOR_HOST ??= '127.0.0.1:9099';

const { initializeApp } = await import('firebase-admin/app');
const { getAuth } = await import('firebase-admin/auth');
const { getFirestore, Timestamp, FieldValue } = await import('firebase-admin/firestore');

initializeApp({ projectId: 'demo-farmtap' });
const db = getFirestore();
const auth = getAuth();
const day = 86400000;
const at = (d, h = 7) => {
  const x = new Date(Date.now() + d * day);
  x.setHours(h, 0, 0, 0);
  const p = (n) => String(n).padStart(2, '0');
  return `${x.getFullYear()}-${p(x.getMonth() + 1)}-${p(x.getDate())}T${p(x.getHours())}:00:00.000`;
};

async function user(email, name) {
  try {
    return (await auth.getUserByEmail(email)).uid;
  } catch {
    return (await auth.createUser({ email, password: 'farmtap123', displayName: name, emailVerified: true })).uid;
  }
}

function rec(t, c, id, body, uid, when = at(0)) {
  return db.doc(`tenants/${t}/${c}/${id}`).set({
    id, tenantId: t, collection: c, body, createdAt: when, updatedAt: when, createdBy: uid, updatedBy: uid,
    deviceId: 'seed', version: 1, isDeleted: false, serverUpdatedAt: FieldValue.serverTimestamp(),
  });
}

const owner = await user('owner@test.ug', 'Victor Owner');
const locked = await user('locked@test.ug', 'Late Payer');

await db.doc('platform/config').set({
  trialDays: 14,
  payments: {
    gateways: [
      { id: 'mtn', name: 'MTN Mobile Money', enabled: true, hidden: false, api: true },
      { id: 'airtel', name: 'Airtel Money', enabled: false, hidden: false, api: true },
      { id: 'card', name: 'Visa or Mastercard', enabled: true, hidden: false, api: true },
      { id: 'bank', name: 'Bank transfer', enabled: true, hidden: false, api: false, payCode: '9030012345678', accountName: 'Victorbee Technologies', instructions: 'Stanbic Mbarara. Use the farm name as the reference.' },
    ],
    manualNote: 'After paying, send the transaction ID.',
  },
});
const plans = [
  ['monthly', { name: 'Monthly', priceUgx: 70000, months: 1, description: 'Pay month by month.', highlights: ['Milk, herd, health and breeding', 'Feeds, stock and suppliers', 'Workers, duty roster and pay', 'Money and monthly reports'], badge: '', sample: true, active: true, sort: 1 }],
  ['quarterly', { name: '3 months', priceUgx: 195000, months: 3, description: 'Save on three months.', highlights: ['Everything in Monthly', 'Save UGX 15,000'], badge: 'Most popular', sample: true, active: true, sort: 2 }],
  ['yearly', { name: 'Yearly', priceUgx: 700000, months: 12, description: 'Two months free.', highlights: ['Everything in Monthly', 'Priority WhatsApp support'], badge: 'Best value', sample: true, active: true, sort: 3 }],
];
for (const [id, p] of plans) await db.doc(`plans/${id}`).set({ features: {}, smsCreditsPerMonth: 0, maxWorkers: 0, farmLimit: 1, ...p });

async function farm(t, uid, name, trialEnds) {
  await db.doc(`users/${uid}`).set({ memberships: [{ tenantId: t, role: 'owner' }], ownedFarms: 1 });
  await db.doc(`tenants/${t}`).set({
    ownerUid: uid, name, place: 'Mbarara', district: 'Mbarara', village: 'Rwemera', type: 'farm', sector: 'dairy', cows: 6,
    contacts: { whatsapp: '0772 123 456', sms: '0772 123 456' }, review: { status: 'approved' },
    subscription: { trialStartedAt: Timestamp.fromMillis(trialEnds - 14 * day), trialEndsAt: Timestamp.fromMillis(trialEnds) },
  });
  await db.doc(`tenants/${t}/members/${uid}`).set({ role: 'owner' });
}

const T = 'farm1';
await farm(T, owner, 'Rwemera Dairy', Date.now() + 10 * day);
await farm('farm2', locked, 'Kashari Heights', Date.now() - day);

const staff = [
  ['s-amos', { name: 'Amos Tumusiime', role: 'herdsman', phone: '0772 111 222', payType: 'monthly', payRate: 250000, monthlyWage: 250000, payMethod: 'mtn', payAccount: '0772 111 222', active: true }],
  ['s-grace', { name: 'Grace Ainembabazi', role: 'worker', phone: '0701 333 444', payType: 'daily', payRate: 10000, monthlyWage: null, payMethod: 'airtel', payAccount: '0701 333 444', active: true }],
  ['s-john', { name: 'John Mugisha', role: 'manager', phone: '0782 555 666', payType: 'monthly', payRate: 400000, monthlyWage: 400000, payMethod: 'bank', payAccount: 'Stanbic 9030012345678', active: true }],
];
for (const [id, b] of staff) await rec(T, 'staff', id, b, owner, at(-30));

const cows = ['Kyakimwa', 'Bihogo', 'Kaaki', 'Nyinabo', 'Rwemera', 'Kashaija'];
for (let i = 0; i < cows.length; i++) {
  await rec(T, 'animals', `a${i + 1}`, { tagNumber: `FT-00${i + 1}`, name: cows[i], sex: 'female', breed: 'Friesian', dateOfBirth: '2021-03-01', status: 'active', dairyStatus: i === 5 ? 'dry' : 'milking', avatarIndex: i + 1 }, owner, at(-60));
}
for (let d = -6; d <= 0; d++) {
  await rec(T, 'milkRecords', `m${d}am`, { animalId: null, session: 'morning', litres: 38 + d, recordedBy: 'Amos', cowsMilked: 5 }, owner, at(d, 6));
  if (d < 0) await rec(T, 'milkRecords', `m${d}pm`, { animalId: null, session: 'evening', litres: 30 + d, recordedBy: 'Grace', cowsMilked: 4, cowIds: ['a1', 'a2', 'a3', 'a4'] }, owner, at(d, 17));
}
await rec(T, 'milkSales', 'sale1', { buyer: 'Mbarara Dairy Co-op', kind: 'centre', litres: 200, pricePerLitre: 1200, paid: true }, owner, at(-2));

await rec(T, 'contacts', 'c-vet', { name: 'Dr Okello Patrick', kind: 'vet', phone: '0772 900 100', org: 'Mbarara Vet Clinic', place: 'Mbarara town', showWorkers: true }, owner, at(-20));
await rec(T, 'contacts', 'c-feed', { name: 'Kakoba Agro Supplies', kind: 'feedSupplier', phone: '0703 200 300', org: 'Kakoba', showWorkers: true }, owner, at(-20));
await rec(T, 'contacts', 'c-ai', { name: 'Musa (AI)', kind: 'aiTechnician', phone: '0754 400 500', showWorkers: false }, owner, at(-20));

await rec(T, 'stockMovements', 'count1', { kind: 'count', feed: 'dairyMeal', amount: 4, at: at(-10) }, owner, at(-10));
await rec(T, 'stockMovements', 'buy1', { kind: 'purchase', feed: 'dairyMeal', amount: 10, pricePerUnit: 60000, supplier: 'Kakoba Agro Supplies', supplierId: 'c-feed', payMethod: 'mtn', at: at(-5) }, owner, at(-5));
await rec(T, 'expenses', 'e-buy1', { category: 'feed', amount: 600000, at: at(-5), note: '10 bags Dairy meal · Kakoba Agro Supplies', sourceId: 'buy1', sourceType: 'feedPurchase', supplierId: 'c-feed', payMethod: 'mtn', photo: null }, owner, at(-5));
for (let d = -6; d <= -1; d++) await rec(T, 'feedUsage', `fu${d}`, { feed: 'dairyMeal', group: 'milkingCows', amount: 1.5, at: at(d, 8), fedBy: 's-grace' }, owner, at(d, 8));

await rec(T, 'treatments', 't1', { animalId: 'a2', animalName: 'Bihogo', tag: 'FT-002', condition: 'mastitis', drugId: 'drug-penstrep', withdrawalDays: 4, given: at(-1, 12), courseDays: 3, route: 'injection', givenBy: 'Dr Okello Patrick', cost: 45000, vetId: 'c-vet' }, owner, at(-1));
await rec(T, 'expenses', 'e-t1', { category: 'vet', amount: 45000, at: at(-1, 12), note: 'Bihogo · Mastitis', sourceId: 't1', sourceType: 'treatment', supplierId: 'c-vet', payMethod: 'cash', photo: null }, owner, at(-1));
await rec(T, 'vaccinations', 'v1', { vaccine: 'Foot and mouth (FMD)', animalIds: [], given: at(-170, 12), nextDue: at(10, 12), cost: null }, owner, at(-170));
await rec(T, 'wages', 'w1', { staffId: 's-grace', kind: 'wage', amount: 50000, at: at(-3), payMethod: 'airtel', units: 5, payType: 'daily' }, owner, at(-3));
await rec(T, 'expenses', 'e-w1', { category: 'wages', amount: 50000, at: at(-3), note: 'Grace Ainembabazi · 5 days', sourceId: 'w1', sourceType: 'wage', payMethod: 'airtel', photo: null }, owner, at(-3));
await rec(T, 'expenses', 'e-fuel', { category: 'fuel', amount: 30000, at: at(-2), note: 'Milk run', sourceId: null, payMethod: 'cash', photo: null }, owner, at(-2));

await rec(T, 'duties', 'd-milk', { activity: 'milking', staffId: 's-amos', standInId: 's-grace', days: [], shift: 'morning', note: 'Milk at 5 am; wash the cans' }, owner, at(-7));
await rec(T, 'duties', 'd-feed', { activity: 'feeding', staffId: 's-grace', standInId: 's-amos', days: [], shift: 'allDay', contactId: 'c-feed' }, owner, at(-7));
await rec(T, 'duties', 'd-health', { activity: 'health', staffId: 's-amos', standInId: 's-john', days: [1, 3, 5], shift: 'afternoon', contactId: 'c-vet' }, owner, at(-7));
await rec(T, 'duties', 'd-boss', { activity: 'manager', staffId: 's-john', standInId: 's-amos', days: [], shift: 'allDay' }, owner, at(-7));
await rec(T, 'absences', 'ab1', { staffId: 's-john', from: at(0, 0), to: at(2, 0), reason: 'leave' }, owner, at(0));

await rec(T, 'breedingEvents', 'b1', { type: 'ai', kind: 'ai', animalId: 'a3', at: at(-70, 9), straw: 'Friesian 4421', technician: 'Musa (AI)', cost: 30000 }, owner, at(-70));
await rec(T, 'breedingEvents', 'b2', { type: 'service', kind: 'heat', animalId: 'a4', at: at(-20, 9) }, owner, at(-20));

console.log('Seeded. owner@test.ug / farmtap123 (trial), locked@test.ug / farmtap123 (locked).');
process.exit(0);
