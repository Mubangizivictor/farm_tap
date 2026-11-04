import assert from 'node:assert/strict';
import { test } from 'node:test';
import { amountFor, cleanPeriods, extendPaidUntil, gatewayFrom, gatewayProblem, planFrom, ugMsisdn } from './billing';

test('price comes from the stored plan times periods', () => {
  const p = planFrom('monthly', { name: 'Monthly', priceUgx: 70000, months: 1 })!;
  assert.equal(amountFor(p, 3), 210000);
  assert.equal(cleanPeriods(0), null);
  assert.equal(cleanPeriods(13), null);
  assert.equal(cleanPeriods(1.5), null);
  assert.equal(cleanPeriods('2'), null);
  assert.equal(cleanPeriods(12), 12);
});

test('paying early adds after the current end; paying late starts today', () => {
  const now = new Date(2026, 10, 4, 15);
  assert.deepEqual(extendPaidUntil(new Date(2026, 10, 20), 1, now), new Date(2026, 11, 20));
  assert.deepEqual(extendPaidUntil(new Date(2026, 9, 1), 1, now), new Date(2026, 11, 4));
  assert.deepEqual(extendPaidUntil(null, 12, now), new Date(2027, 10, 4));
});

test('Ugandan mobile numbers', () => {
  assert.equal(ugMsisdn('0772 123 456'), '256772123456');
  assert.equal(ugMsisdn('+256 700-123456'), '256700123456');
  assert.equal(ugMsisdn('772123456'), '256772123456');
  assert.equal(ugMsisdn('0414 123 456'), null);
  assert.equal(ugMsisdn(42), null);
});

test('a muted, hidden or manual gateway cannot take an in-app payment', () => {
  const list = [
    { id: 'mtn', enabled: true, api: true },
    { id: 'airtel', enabled: false, api: true },
    { id: 'card', enabled: true, hidden: true },
    { id: 'bank', enabled: true, api: false },
  ];
  assert.equal(gatewayProblem(gatewayFrom(list, 'mtn')), null);
  assert.match(gatewayProblem(gatewayFrom(list, 'airtel'))!, /coming soon/);
  assert.match(gatewayProblem(gatewayFrom(list, 'card'))!, /not offered/);
  assert.match(gatewayProblem(gatewayFrom(list, 'bank'))!, /support/);
  assert.match(gatewayProblem(gatewayFrom(list, 'nope'))!, /not offered/);
  assert.match(gatewayProblem(gatewayFrom(undefined, 'mtn'))!, /not offered/);
});
