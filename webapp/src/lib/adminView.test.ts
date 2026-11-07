import assert from 'node:assert/strict';
import { test } from 'node:test';
import { trialLength } from './adminView.ts';

const d = (s: string) => new Date(`${s}T00:00:00`);

test('trial length counts the whole trial from sign-up, not extra days', () => {
  assert.equal(trialLength({ trialStartedAt: d('2026-11-02'), trialEndsAt: d('2026-11-16'), createdAt: null }, 14), 14);
  assert.equal(trialLength({ trialStartedAt: d('2026-11-02'), trialEndsAt: d('2026-11-04'), createdAt: null }, 14), 2);
});

test('trial length falls back to the sign-up date, then the default', () => {
  assert.equal(trialLength({ trialStartedAt: null, trialEndsAt: d('2026-11-09'), createdAt: d('2026-11-02') }, 14), 7);
  assert.equal(trialLength({ trialStartedAt: null, trialEndsAt: null, createdAt: d('2026-11-02') }, 10), 10);
});

test('a trial ended before it started counts as 0 days', () => {
  assert.equal(trialLength({ trialStartedAt: d('2026-11-05'), trialEndsAt: d('2026-11-02'), createdAt: null }, 14), 0);
});
