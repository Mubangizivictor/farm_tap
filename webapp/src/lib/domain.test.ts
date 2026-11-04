import { test } from 'node:test';
import assert from 'node:assert/strict';
import { localIso, parseDate } from './dates.ts';
import { canWrite, dailyLitres, inWithdrawal, planState, type FarmRecord, type MilkBody } from './domain.ts';

const rec = (litres: number, at: Date, isDeleted = false): FarmRecord<MilkBody> => ({
  id: String(Math.random()),
  tenantId: 't',
  collection: 'milkRecords',
  body: { animalId: null, session: 'morning', litres },
  createdAt: localIso(at),
  updatedAt: localIso(at),
  createdBy: 'u',
  updatedBy: 'u',
  deviceId: 'd',
  version: 1,
  isDeleted,
});

test('local ISO round-trips like Dart toIso8601String', () => {
  const d = new Date(2026, 10, 3, 6, 5, 4, 3);
  assert.equal(localIso(d), '2026-11-03T06:05:04.003');
  assert.equal(parseDate(localIso(d))?.getTime(), d.getTime());
  // Dart microseconds
  assert.equal(parseDate('2026-11-03T06:05:04.003123')?.getTime(), d.getTime());
});

test('daily litres skip deleted records and bucket by day', () => {
  const now = new Date(2026, 10, 3, 18);
  const days = dailyLitres(
    [rec(10, new Date(2026, 10, 3, 6)), rec(5, new Date(2026, 10, 3, 17)), rec(7, new Date(2026, 10, 2, 6)), rec(99, now, true)],
    now,
    3,
  );
  assert.deepEqual(days.map((d) => d.litres), [0, 7, 15]);
});

test('trial, paid and read-only match the rules (no grace, decision 0023)', () => {
  const now = new Date(2026, 10, 3);
  assert.equal(planState({ trialStartedAt: null, trialEndsAt: new Date(2026, 10, 8), paidUntil: null }, now).kind, 'trial');
  assert.equal(planState({ trialStartedAt: null, trialEndsAt: new Date(2026, 10, 1), paidUntil: null }, now).kind, 'readOnly');
  assert.equal(planState({ trialStartedAt: null, trialEndsAt: null, paidUntil: new Date(2026, 10, 30) }, now).kind, 'paid');
  assert.equal(planState({ trialStartedAt: null, trialEndsAt: null, paidUntil: new Date(2026, 9, 30) }, now).kind, 'readOnly');
  assert.equal(canWrite({ trialStartedAt: null, trialEndsAt: null, paidUntil: new Date(2026, 9, 30) }, now), false);
  assert.equal(canWrite({ trialStartedAt: null, trialEndsAt: null, paidUntil: new Date(2026, 9, 1) }, now), false);
});

test('withdrawal ends on given day + withdrawal days', () => {
  const t = { animalId: 'a', condition: 'mastitis', drugId: 'x', withdrawalDays: 3, given: localIso(new Date(2026, 10, 1, 9)) };
  assert.equal(inWithdrawal(t, new Date(2026, 10, 3, 23)), true);
  assert.equal(inWithdrawal(t, new Date(2026, 10, 4, 0, 1)), false);
});
