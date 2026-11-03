const test = require('node:test');
const assert = require('node:assert');
const { providerFor, africasTalking, twilio } = require('../providers');

const fakeFetch = (status, json, seen) => async (url, init) => {
  seen.push({ url, init });
  return { ok: status < 300, status, json: async () => json };
};

test('none or unknown provider sends nothing', () => {
  assert.strictEqual(providerFor('none'), null);
  assert.strictEqual(providerFor(undefined), null);
  assert.strictEqual(providerFor('AfricasTalking'), africasTalking);
});

test("Africa's Talking posts the form and reads the result", async () => {
  const seen = [];
  const res = await africasTalking(
    { to: '+256772451908', text: 'FarmTap: 38 L' },
    { username: 'farmtap', from: 'FARMTAP', apiKey: 'k' },
    fakeFetch(201, { SMSMessageData: { Recipients: [{ status: 'Success', messageId: 'ATX1', cost: 'UGX 27.0000' }] } }, seen),
  );
  assert.deepStrictEqual(res, { ok: true, providerId: 'ATX1', cost: 'UGX 27.0000' });
  assert.strictEqual(seen[0].url, 'https://api.africastalking.com/version1/messaging');
  assert.strictEqual(seen[0].init.headers.apiKey, 'k');
  const body = new URLSearchParams(seen[0].init.body);
  assert.strictEqual(body.get('to'), '+256772451908');
  assert.strictEqual(body.get('from'), 'FARMTAP');
});

test("Africa's Talking sandbox and failures", async () => {
  const seen = [];
  const res = await africasTalking(
    { to: '+256700000000', text: 'x' },
    { username: 'sandbox', from: '', apiKey: 'k' },
    fakeFetch(201, { SMSMessageData: { Recipients: [{ status: 'InsufficientBalance' }] } }, seen),
  );
  assert.deepStrictEqual(res, { ok: false, error: 'InsufficientBalance' });
  assert.match(seen[0].url, /sandbox/);
  assert.strictEqual(new URLSearchParams(seen[0].init.body).get('from'), null);
});

test('Twilio uses basic auth', async () => {
  const seen = [];
  const res = await twilio(
    { to: '+256772451908', text: 'x' },
    { username: 'AC1', from: '+15550001', apiKey: 'tok' },
    fakeFetch(201, { sid: 'SM1', price: null }, seen),
  );
  assert.strictEqual(res.ok, true);
  assert.match(seen[0].init.headers.Authorization, /^Basic /);
  assert.strictEqual(new URLSearchParams(seen[0].init.body).get('From'), '+15550001');
});
