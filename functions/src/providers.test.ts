import assert from 'node:assert/strict';
import { test } from 'node:test';
import { airtelStart, airtelStatus, cardStart, cardStatus, mtnStart, mtnStatus, paidInFull, type Fetch } from './providers';

type Call = { url: string; init?: RequestInit };

function fake(responses: Array<{ status: number; body?: unknown }>): { f: Fetch; calls: Call[] } {
  const calls: Call[] = [];
  const f = (async (url: string, init?: RequestInit) => {
    calls.push({ url, init });
    const r = responses.shift() ?? { status: 500 };
    return new Response(r.body === undefined ? '' : JSON.stringify(r.body), { status: r.status });
  }) as unknown as Fetch;
  return { f, calls };
}

const input = { reference: 'pay-1', amountUgx: 70000, msisdn: '256772123456', description: 'FarmTap Monthly', callbackUrl: 'https://x/mtn' };
const mtn = { subscriptionKey: 'sub', apiUser: 'user', apiKey: 'key', targetEnvironment: 'sandbox', live: false };

test('MTN: token, then request to pay with our reference', async () => {
  const { f, calls } = fake([{ status: 200, body: { access_token: 'tok' } }, { status: 202 }]);
  const out = await mtnStart(mtn, input, f);
  assert.equal(out.providerRef, 'pay-1');
  assert.match(calls[0].url, /sandbox\.momodeveloper\.mtn\.com\/collection\/token\/$/);
  const h = calls[1].init!.headers as Record<string, string>;
  assert.equal(h['X-Reference-Id'], 'pay-1');
  assert.equal(h['X-Target-Environment'], 'sandbox');
  const b = JSON.parse(String(calls[1].init!.body));
  assert.equal(b.amount, '70000');
  assert.equal(b.currency, 'EUR');
  assert.equal(b.payer.partyId, '256772123456');
});

test('MTN live uses UGX and the live host', async () => {
  const { f, calls } = fake([{ status: 200, body: { access_token: 'tok' } }, { status: 202 }]);
  await mtnStart({ ...mtn, live: true, targetEnvironment: 'mtnuganda' }, input, f);
  assert.match(calls[1].url, /^https:\/\/proxy\.momoapi\.mtn\.com/);
  assert.equal(JSON.parse(String(calls[1].init!.body)).currency, 'UGX');
});

test('MTN refuses: friendly error, no key in the message', async () => {
  const { f } = fake([{ status: 200, body: { access_token: 'tok' } }, { status: 400, body: { code: 'PAYER_NOT_FOUND' } }]);
  await assert.rejects(mtnStart(mtn, input, f), (e: Error) => /could not send/.test(e.message) && !/key/.test(e.message));
});

test('MTN status mapping', async () => {
  for (const [st, want] of [['SUCCESSFUL', 'paid'], ['FAILED', 'failed'], ['PENDING', 'pending'], ['REJECTED', 'cancelled'], ['TIMEOUT', 'expired']] as const) {
    const { f } = fake([{ status: 200, body: { access_token: 't' } }, { status: 200, body: { status: st, amount: '70000', currency: 'UGX', financialTransactionId: '9' } }]);
    assert.equal((await mtnStatus(mtn, 'pay-1', f)).status, want);
  }
});

test('Airtel: number without 256, UGX headers, status TS = paid', async () => {
  const k = { clientId: 'c', clientSecret: 's', live: false, country: 'UG' };
  const { f, calls } = fake([{ status: 200, body: { access_token: 'tok' } }, { status: 200, body: { status: { success: true } } }]);
  await airtelStart(k, input, f);
  const b = JSON.parse(String(calls[1].init!.body));
  assert.equal(b.subscriber.msisdn, '772123456');
  assert.equal(b.transaction.id, 'pay-1');
  assert.equal((calls[1].init!.headers as Record<string, string>)['X-Currency'], 'UGX');
  const s = fake([{ status: 200, body: { access_token: 'tok' } }, { status: 200, body: { data: { transaction: { status: 'TS', airtel_money_id: 'A1' } } } }]);
  const st = await airtelStatus(k, 'pay-1', s.f);
  assert.equal(st.status, 'paid');
  assert.equal(st.providerTxId, 'A1');
});

test('Card: returns the hosted page link; verify maps status and amount', async () => {
  const { f, calls } = fake([{ status: 200, body: { status: 'success', data: { link: 'https://checkout/x' } } }]);
  const out = await cardStart({ secretKey: 'sk' }, { ...input, returnUrl: 'https://farmtap/settings/' }, f);
  assert.equal(out.redirectUrl, 'https://checkout/x');
  assert.equal(JSON.parse(String(calls[0].init!.body)).currency, 'UGX');
  const v = fake([{ status: 200, body: { status: 'success', data: { status: 'successful', amount: 70000, currency: 'UGX', id: 77 } } }]);
  const st = await cardStatus({ secretKey: 'sk' }, 'pay-1', v.f);
  assert.equal(st.status, 'paid');
  assert.ok(paidInFull(st, 70000));
});

test('paid in full: less money or another currency does not count', () => {
  assert.ok(paidInFull({ status: 'paid', amount: 70000, currency: 'UGX' }, 70000));
  assert.ok(!paidInFull({ status: 'paid', amount: 7000, currency: 'UGX' }, 70000));
  assert.ok(!paidInFull({ status: 'paid', amount: 70000, currency: 'USD' }, 70000));
  assert.ok(paidInFull({ status: 'paid', amount: 70000, currency: 'EUR' }, 70000, true));
  assert.ok(!paidInFull({ status: 'pending' }, 70000));
});
