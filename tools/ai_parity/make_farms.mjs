// Makes test/core/ai/fixtures/farms.json: seeded sample farms for the parity
// test (rich, sparse, odd and early-morning). `node tools/ai_parity/make_farms.mjs`
import { writeFileSync, mkdirSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
const root = join(dirname(fileURLToPath(import.meta.url)), '..', '..');
const { addDays } = await import(join(root, 'shared', 'aiCore.ts'));

function rng(seed) {
  let a = seed;
  return () => {
    a |= 0;
    a = (a + 0x6d2b79f5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}
const pad = (n) => String(n).padStart(2, '0');

function richFarm(seed, now, opts = {}) {
  const R = rng(seed);
  const day = now.slice(0, 10);
  let n = 0;
  const id = (p) => `${p}${++n}`;
  const rec = (p, body, createdAt) => ({ id: id(p), createdAt, body });
  const names = ['Bella', 'Zuri', 'Nyabo', 'Kemi', 'Atim', 'Rosa', 'Mama Tito', 'Lulu', 'Daisy', 'Grace', 'Tulip', 'Moo'];
  const animals = names.map((name, i) => ({
    id: `a${i + 1}`,
    createdAt: `${addDays(day, -400)}T08:00:00`,
    body: { name: i === 10 ? '' : name, tagNumber: `FT-${100 + i}`, sex: i === 11 ? 'male' : 'female', status: i === 9 ? 'sold' : 'active', dairyStatus: i === 11 ? 'bull' : i === 8 ? 'dry' : i === 7 ? 'calf' : i === 5 ? 'treated' : 'milking' },
  }));
  const milk = [];
  const cows = animals.filter((a) => ['milking', 'treated'].includes(a.body.dairyStatus));
  for (let b = 0; b <= 60; b++) {
    const dd = addDays(day, -b);
    if (b % 17 === 9) continue; // a day with no records at all
    for (const [i, c] of cows.entries()) {
      let base = 9 + i * 1.3;
      if (c.id === 'a2' && b < 9) base *= 0.6; // dropping cow
      if (c.id === 'a4') base *= 1 + Math.sin(b / 3) * 0.1;
      if (b === 12) base *= 0.35; // unusual day
      for (const session of ['morning', 'evening']) {
        if (b === 0 && session === 'evening') continue;
        if (R() < 0.04) continue;
        const litres = Math.round((base * (session === 'morning' ? 0.6 : 0.4) + (R() - 0.5) * 1.2) * 10) / 10;
        milk.push(rec('m', { animalId: c.id, session, litres, notForSale: R() < 0.05 }, `${dd}T${session === 'morning' ? '06' : '17'}:${pad(Math.floor(R() * 60))}:00`));
      }
    }
  }
  const treatments = [];
  const t = (animalId, back, condition, extra = {}) => treatments.push(rec('t', { animalId, condition, given: `${addDays(day, -back)}T09:00:00`, withdrawalDays: 3, courseDays: 1, cost: 15000, ...extra }, `${addDays(day, -back)}T09:00:00`));
  t('a1', 40, 'Mastitis'); t('a1', 25, 'mastitis'); t('a1', 5, 'Mastitis', { courseDays: 5, withdrawalDays: 4 }); t('a3', 70, 'Foot rot'); t('a3', 20, 'Worms'); t('a3', 3, 'Fever', { courseDays: 3 }); t('a2', 1, 'Mastitis', { withdrawalDays: 5, drugId: 'd1' }); t('a5', 100, 'Bloat'); t('a4', 8, ''); t('a4', 6, undefined);
  const vaccinations = [
    rec('v', { vaccine: 'Foot and mouth', animalIds: [], given: addDays(day, -190), nextDue: addDays(day, -10) }, `${addDays(day, -190)}T10:00:00`),
    rec('v', { vaccine: 'Lumpy skin', animalIds: ['a1', 'a2'], given: addDays(day, -360), nextDue: addDays(day, 4) }, `${addDays(day, -360)}T10:00:00`),
    rec('v', { vaccine: 'Lumpy skin', animalIds: ['a1'], given: addDays(day, -2), nextDue: addDays(day, 360) }, `${addDays(day, -2)}T10:00:00`),
    rec('v', { vaccine: 'Brucellosis', animalIds: ['a3', 'a4', 'a5', 'a6', 'a7'], given: addDays(day, -330), nextDue: addDays(day, -40) }, `${addDays(day, -330)}T10:00:00`),
  ];
  const br = (type, animalId, back, extra = {}) => ({ id: id('b'), createdAt: `${addDays(day, -back)}T09:00:00`, body: { type, animalId, at: `${addDays(day, -back)}T09:00:00`, ...extra } });
  const breeding = [
    br('calving', 'a1', 320), br('ai', 'a1', 250), br('pregnancyCheck', 'a1', 190, { pregnant: true }),
    br('calving', 'a2', 130), br('service', 'a2', 40, { kind: 'heat' }),
    br('calving', 'a3', 400), br('ai', 'a3', 330), br('ai', 'a3', 300), br('ai', 'a3', 270), br('ai', 'a3', 240),
    br('calving', 'a4', 700), br('calving', 'a4', 340), br('ai', 'a4', 285),
    br('service', 'a5', 19, { kind: 'heat' }), br('ai', 'a6', 62),
    br('calving', 'a7', 75), br('ai', 'a7', 20),
  ];
  breeding[2].body.serviceId = breeding[1].id;
  breeding.push({ id: id('b'), createdAt: '', body: { type: 'pregnancyCheck', animalId: 'a3', at: `${addDays(day, -200)}T09:00:00`, pregnant: false, serviceId: breeding[6].id } });
  const expenses = [];
  const cats = ['feed', 'vet', 'wages', 'transport', 'fuel', 'equipment', 'other', 'breeding', 'waterBill'];
  for (let m = 0; m < 160; m++) {
    const back = Math.floor(R() * 150);
    const cat = cats[Math.floor(R() * cats.length)];
    let amount = Math.round((20000 + R() * 120000) / 1000) * 1000;
    if (m === 7) amount = 900000;
    expenses.push(rec('e', { category: cat === 'feed' && R() < 0.3 ? 'feed' : cat, amount, at: `${addDays(day, -back)}T11:00:00` }, `${addDays(day, -back)}T11:00:00`));
  }
  expenses.push(rec('e', { category: 'feed', amount: 2400000, at: `${addDays(day, -2)}T11:00:00` }, `${addDays(day, -2)}T11:00:00`));
  const income = Array.from({ length: 12 }, (_, i) => rec('i', { source: 'calfSale', amount: 100000 + i * 30000, at: `${addDays(day, -i * 12)}T12:00:00` }, `${addDays(day, -i * 12)}T12:00:00`));
  const milkSales = Array.from({ length: 70 }, (_, i) => rec('s', { buyer: 'Dairy', litres: 40 + Math.floor(R() * 30), pricePerLitre: 1100 + Math.floor(R() * 200) }, `${addDays(day, -i)}T10:00:00`));
  const feedUses = [];
  for (let b = 0; b <= 45; b++) for (const f of ['dairyMeal', 'hay', 'cust1']) feedUses.push(rec('u', { feed: f, group: 'milking', amount: f === 'hay' ? 3 + Math.floor(R() * 2) : 18 + Math.floor(R() * 6) + (b === 4 && f === 'dairyMeal' ? 80 : 0), at: `${addDays(day, -b)}T07:00:00` }, `${addDays(day, -b)}T07:00:00`));
  const stockMoves = [
    rec('k', { kind: 'count', feed: 'dairyMeal', amount: 900, at: `${addDays(day, -30)}T08:00:00` }, `${addDays(day, -30)}T08:00:00`),
    rec('k', { kind: 'purchase', feed: 'dairyMeal', amount: 300, pricePerUnit: 1800, at: `${addDays(day, -12)}T08:00:00` }, `${addDays(day, -12)}T08:00:00`),
    rec('k', { kind: 'purchase', feed: 'hay', amount: 200, pricePerUnit: 6000, at: `${addDays(day, -20)}T08:00:00` }, `${addDays(day, -20)}T08:00:00`),
    rec('k', { kind: 'purchase', feed: 'cust1', amount: 50, pricePerUnit: 500, at: `${addDays(day, -5)}T08:00:00` }, `${addDays(day, -5)}T08:00:00`),
  ];
  const feedTypes = [{ id: 'cust1', createdAt: '', body: { name: 'Sweet potato vines', unit: 'kg', lowAt: 200 } }];
  const stockItems = [
    rec('x', { kind: 'drug', name: 'Oxytetracycline', stock: 0, unit: 'bottles', lowAt: 2 }), rec('x', { kind: 'drug', name: ' ', stock: 1, unit: 'vials', reorderAt: 3 }), rec('x', { kind: 'drug', name: 'Dewormer', unit: 'doses' }), rec('x', { kind: 'feed', name: 'Not a drug', stock: 1 }),
  ];
  stockItems[0].id = 'd1';
  const deliveries = Array.from({ length: 24 }, (_, i) => rec('l', { farmerId: `f${(i % 3) + 1}`, litres: 30 + i, session: 'morning', test: i % 4 === 0 ? 'failed' : i % 5 === 0 ? 'notDone' : 'passed', at: `${addDays(day, -(i % 25))}T06:00:00` }, `${addDays(day, -(i % 25))}T06:00:00`));
  const milkBatches = [
    rec('p', { litres: 40, collectedAt: `${addDays(day, -1)}T18:00:00`, cooled: true, place: 'Cooler 1', status: 'stored' }),
    rec('p', { litres: 22, collectedAt: `${addDays(day, -2)}T06:00:00`, cooled: true, place: 'Cooler 1', status: 'stored' }),
    rec('p', { litres: 15, collectedAt: `${day}T05:00:00`, cooled: true, place: 'Cooler 2', status: 'stored' }),
    rec('p', { litres: 12, collectedAt: `${day}T06:30:00`, cooled: false, place: 'Can A', status: 'stored' }),
    rec('p', { litres: 9, collectedAt: `${day}T04:00:00`, cooled: true, place: 'Can B', status: 'stored' }),
    rec('p', { litres: 30, collectedAt: `${addDays(day, -3)}T06:00:00`, cooled: true, place: 'Cooler 1', status: 'discarded', closedAt: `${addDays(day, -2)}T08:00:00` }),
    rec('p', { litres: 18, collectedAt: `${addDays(day, -4)}T06:00:00`, cooled: true, place: 'Cooler 1', status: 'sold', closedAt: `${addDays(day, -3)}T08:00:00` }),
  ];
  const storageReadings = [
    rec('q', { place: 'Cooler 1', tempC: 3.4, at: `${addDays(day, -1)}T20:00:00` }),
    rec('q', { place: 'cooler 1 ', tempC: 3.9, at: `${addDays(day, -2)}T07:00:00` }),
    rec('q', { batchId: milkBatches[2].id, tempC: 9.5, at: `${day}T06:00:00` }),
    rec('q', { place: 'Can B', tempC: 3, at: `${day}T05:00:00` }),
    rec('q', { place: 'Cooler 2', tempC: 6, at: `${addDays(day, -3)}T05:00:00` }),
  ];
  animals[9].body.status = 'sold';
  return { now, animals, milk, treatments, vaccinations, breeding, expenses, income, milkSales, feedUses, stockMoves, feedTypes, stockItems, deliveries, milkBatches, storageReadings, ...opts };
}

function sparseFarm() {
  const now = '2026-11-07T09:00:00';
  return {
    now,
    animals: [{ id: 'a1', body: { name: 'Bella', sex: 'female', status: 'active', dairyStatus: 'milking' } }, { id: 'a2', body: { tagNumber: 'FT-9' } }],
    milk: Array.from({ length: 6 }, (_, i) => ({ id: `m${i}`, createdAt: `${addDays('2026-11-07', -i - 1)}T06:00:00`, body: { animalId: null, session: 'morning', litres: 30 + i } })),
    expenses: [{ id: 'e1', createdAt: '2026-11-03T10:00:00', body: { category: 'feed', amount: 50000 } }],
  };
}

function oddFarm() {
  const now = '2026-02-28T23:50:00';
  const f = richFarm(99, now);
  // damaged and odd records must never break the analysis
  f.milk.push({ id: 'bad1', body: { litres: 'abc' }, createdAt: 'nonsense' });
  f.milk.push({ id: 'bad2', body: { litres: '12.5', animalId: 'a1' }, createdAt: '2026-02-28T05:00:00' });
  f.milk.push({ id: 'bad3', isDeleted: true, body: { litres: 500 }, createdAt: '2026-02-28T05:00:00' });
  f.milk.push({ id: 'bad4', body: { litres: NaN === 1 ? 1 : 7, animalId: 'ghost' }, createdAt: '2026-02-27T05:00:00' });
  f.treatments.push({ id: 'bad5', body: { animalId: 'ghost', condition: 'X', given: 'not-a-date' }, createdAt: '2026-02-20T05:00:00' });
  f.expenses.push({ id: 'bad6', body: { category: '', amount: '1500' }, createdAt: '2026-02-20T05:00:00' });
  f.animals.push({ id: 'a99', isDeleted: true, body: { name: 'Gone' } });
  f.breeding.push({ id: 'bad7', body: { type: 'ai', animalId: 'a1' } });
  f.milkBatches.push({ id: 'bad8', body: { litres: 5, collectedAt: 'bad', cooled: true, place: '' } });
  return f;
}

const farms = [
  richFarm(1, '2026-11-07T14:30:00'),
  richFarm(2, '2026-11-07T09:00:00'),
  richFarm(3, '2026-03-12T12:00:00', { shelfRules: [{ product: 'rawMilk', label: 'Raw milk', cooledHours: 36, warmHours: 2, maxTempC: 5 }] }),
  sparseFarm(),
  oddFarm(),
  { now: '2026-11-07T09:00:00' },
];
mkdirSync(join(root, 'test', 'core', 'ai', 'fixtures'), { recursive: true });
writeFileSync(join(root, 'test', 'core', 'ai', 'fixtures', 'farms.json'), JSON.stringify(farms));
console.log('wrote farms.json', farms.map((f) => JSON.stringify(f).length));
