// Decision 0024 server code: messages, reminders, receipts, refunds, deletion hold.
import assert from 'node:assert/strict';
import { test } from 'node:test';
import * as PdfLib from 'pdf-lib';
import { holdOver } from './accounts';
import { intl } from './alerts';
import { africasTalking, routeFor, smsSender, twilio, whatsappCloud } from './messaging';
import { airtelRefund, cardRefund, mtnRefund } from './refundProviders';
import { alertSettingsFrom, alertsFor, defaultAlertSettings, kampalaToday, type AlertInput } from './shared/alerts';
import { billingDocForPayment, billingFromDoc, docNumber, imageFromDataUrl, refundDoc, renderBillingPdf, viewNumber } from './shared/billing';
import { DEFAULT_LEGAL, fillOperator, legalFromDoc, parseMarkdown } from './shared/legal';

type Call = { url: string; init?: RequestInit };
function fakeFetch(replies: { status?: number; body: unknown }[]) {
  const calls: Call[] = [];
  const f = (async (url: string, init?: RequestInit) => {
    calls.push({ url, init });
    const r = replies[Math.min(calls.length - 1, replies.length - 1)];
    return new Response(JSON.stringify(r.body), { status: r.status ?? 200 });
  }) as unknown as typeof fetch;
  return { f, calls };
}

// ---------------------------------------------------------------- Messages

test("Africa's Talking: sends the form and reads the cost", async () => {
  const { f, calls } = fakeFetch([{ status: 201, body: { SMSMessageData: { Recipients: [{ status: 'Success', messageId: 'ATX1', cost: 'UGX 27.0000' }] } } }]);
  const r = await africasTalking('+256772451908', 'Hi', { username: 'farmtap', from: 'FARMTAP', apiKey: 'k' }, f);
  assert.deepEqual(r, { ok: true, providerId: 'ATX1', cost: 'UGX 27.0000' });
  assert.match(calls[0].url, /api\.africastalking\.com/);
  assert.match(String(calls[0].init?.body), /to=%2B256772451908/);
  const sandbox = fakeFetch([{ status: 201, body: { SMSMessageData: { Recipients: [{ status: 'InvalidPhoneNumber' }] } } }]);
  const bad = await africasTalking('+2561', 'Hi', { username: 'sandbox', from: '', apiKey: 'k' }, sandbox.f);
  assert.equal(bad.ok, false);
  assert.match(sandbox.calls[0].url, /sandbox/);
});

test('Twilio and the provider switch', async () => {
  const { f } = fakeFetch([{ status: 201, body: { sid: 'SM1', price: '-0.26' } }]);
  assert.equal((await twilio('+256772451908', 'Hi', { username: 'AC1', from: '+1555', apiKey: 't' }, f)).ok, true);
  assert.equal(smsSender('none'), null);
  assert.equal(smsSender('africastalking'), africasTalking);
});

test('WhatsApp Cloud: template message with the text as its variable', async () => {
  const { f, calls } = fakeFetch([{ body: { messages: [{ id: 'wamid.1' }] } }]);
  const r = await whatsappCloud('+256 772 451908', 'Milk receipt', { phoneNumberId: '123', token: 't', template: 'farmtap_update', language: 'en' }, f);
  assert.equal(r.ok, true);
  const body = JSON.parse(String(calls[0].init?.body));
  assert.equal(body.to, '256772451908');
  assert.equal(body.template.name, 'farmtap_update');
  assert.equal(body.template.components[0].parameters[0].text, 'Milk receipt');
  const failed = fakeFetch([{ status: 400, body: { error: { message: 'bad token' } } }]);
  assert.deepEqual(await whatsappCloud('+256772451908', 'x', { phoneNumberId: '1', token: 'x', template: '', language: 'en' }, failed.f), { ok: false, error: 'bad token' });
});

test('route: WhatsApp when asked and on, else SMS, else nothing', () => {
  assert.equal(routeFor({ via: 'whatsapp' }, true, true), 'whatsapp');
  assert.equal(routeFor({ via: 'whatsapp' }, true, false), 'sms');
  assert.equal(routeFor({}, false, true), 'whatsapp');
  assert.equal(routeFor({}, false, false), null);
});

// ---------------------------------------------------------------- Reminders

const base = (over: Partial<AlertInput> = {}): AlertInput => ({
  today: '2026-11-09', // a Monday
  duties: [],
  absences: [],
  vaccinations: [],
  breeding: [],
  animals: [{ id: 'c1', body: { name: 'Kasheshe', tagNumber: 'RW-014', status: 'active' } }],
  staffNames: { s1: 'Akello', s2: 'Byaruhanga' },
  trialEndsAt: null,
  paidUntil: null,
  settings: defaultAlertSettings,
  ...over,
});

test('duties: the person on, or the stand-in when they are away', () => {
  const duties = [{ id: 'd1', body: { activity: 'milking', staffId: 's1', standInId: 's2', days: [1], shift: 'morning' } }];
  const on = alertsFor(base({ duties }));
  assert.equal(on.length, 1);
  assert.equal(on[0].id, 'duty-2026-11-09-d1');
  assert.deepEqual(on[0].staffIds, ['s1']);
  const away = alertsFor(base({ duties, absences: [{ id: 'a', body: { staffId: 's1', from: '2026-11-08', to: '2026-11-10' } }] }));
  assert.deepEqual(away[0].staffIds, ['s2']);
  assert.match(away[0].body, /stand in for Akello/);
  // Not a Tuesday duty.
  assert.equal(alertsFor(base({ duties: [{ id: 'd2', body: { activity: 'feeding', staffId: 's1', days: [2] } }] })).length, 0);
  // Switched off.
  assert.equal(alertsFor(base({ duties, settings: { ...defaultAlertSettings, duties: false } })).length, 0);
});

test('vaccinations due tomorrow, today, overdue; not after a later dose', () => {
  const v = (id: string, nextDue: string) => ({ id, body: { vaccine: 'Lumpy skin', animalIds: [], nextDue } });
  assert.match(alertsFor(base({ vaccinations: [v('v1', '2026-11-10')] }))[0].title, /tomorrow/);
  assert.match(alertsFor(base({ vaccinations: [v('v1', '2026-11-09')] }))[0].title, /today/);
  assert.match(alertsFor(base({ vaccinations: [v('v1', '2026-11-05')] }))[0].title, /overdue/);
  assert.equal(alertsFor(base({ vaccinations: [v('v1', '2026-11-20')] })).length, 0);
  assert.equal(alertsFor(base({ vaccinations: [v('v1', '2026-11-09'), v('v2', '2027-05-09')] })).length, 0);
});

test('calving 7 days, 1 day and the day; pregnancy check at 60 days; heat every 21', () => {
  const served = (at: string) => ({ id: 'b1', body: { type: 'ai', kind: 'ai', animalId: 'c1', at } });
  // 283 days before 2026-11-16 is 2026-02-06.
  assert.match(alertsFor(base({ breeding: [served('2026-02-06T08:00:00')] }))[0].title, /calves in 7 days/);
  assert.match(alertsFor(base({ breeding: [served('2026-01-30T08:00:00')] }))[0].title, /due to calve today/);
  assert.equal(alertsFor(base({ breeding: [served('2026-02-01T08:00:00')] })).length, 0);
  const check = alertsFor(base({ breeding: [served('2026-09-10T08:00:00')] }));
  assert.equal(check[0].kind, 'pregnancyCheck');
  const heat = alertsFor(base({ breeding: [{ id: 'h', body: { type: 'service', kind: 'heat', animalId: 'c1', at: '2026-10-19' } }] }));
  assert.equal(heat[0].kind, 'heat');
  assert.equal(heat[0].id, 'heat-2026-11-09-c1');
});

test('trial and plan ending reminders, 3 days and 1 day before', () => {
  assert.match(alertsFor(base({ trialEndsAt: '2026-11-12T00:00:00Z' }))[0].title, /Free trial ends in 3 days/);
  assert.match(alertsFor(base({ trialEndsAt: '2026-11-10T00:00:00Z' }))[0].title, /1 day/);
  assert.equal(alertsFor(base({ trialEndsAt: '2026-11-11T00:00:00Z' })).length, 0);
  assert.equal(alertsFor(base({ paidUntil: '2026-11-12T00:00:00Z', trialEndsAt: '2026-10-01' }))[0].kind, 'plan');
});

test('alert settings fall back to defaults; Kampala date', () => {
  assert.deepEqual(alertSettingsFrom(undefined), defaultAlertSettings);
  assert.equal(alertSettingsFrom({ hour: 30, sms: true }).hour, 6);
  assert.equal(alertSettingsFrom({ sms: true }).sms, true);
  assert.equal(kampalaToday(new Date('2026-11-08T22:30:00Z')), '2026-11-09');
  assert.equal(intl('0772 451908'), '+256772451908');
  assert.equal(intl(''), '');
});

// ---------------------------------------------------------------- Receipts

test('numbers and the record for a payment', () => {
  assert.equal(docNumber('receipt', 2026, 12), 'RCT-2026-000012');
  assert.equal(docNumber('invoice', 2026, 12), 'INV-2026-000012');
  const d = billingDocForPayment(
    'p1',
    { tenantId: 't1', farmName: 'Rwemera Dairy', amountUgx: 195000, method: 'mtn', reference: 'MP123', months: 3, periods: 1, planName: '3 months', paidAt: '2026-11-04T09:00:00Z', newPaidUntil: '2027-02-16T00:00:00Z', kind: 'subscription' },
    { name: 'Rwemera Dairy', district: 'Mbarara', village: 'Kashari' },
    { name: 'Victor', email: 'v@example.com' },
    12,
    new Date('2026-11-04T09:01:00Z'),
  );
  assert.equal(d.receiptNo, 'RCT-2026-000012');
  assert.equal(d.totalUgx, 195000);
  assert.equal(d.items[0].description, 'FarmTap 3 months plan (3 months)');
  assert.equal(d.farmPlace, 'Kashari, Mbarara');
  assert.equal(d.periodFrom?.slice(0, 10), '2026-11-16');
  const r = refundDoc({ ...d, id: 'p1' }, 'r1', 65000, 13, 'mtn', 'R1', 'Paid twice', new Date('2026-11-05T09:00:00Z'));
  assert.equal(r.refundNo, 'RFD-2026-000013');
  assert.equal(r.refundOf, 'RCT-2026-000012');
  assert.equal(viewNumber({ ...r, id: 'x' }, 'refund'), 'RFD-2026-000013');
  assert.equal(billingFromDoc('x', { receiptNo: 'A', totalUgx: 5 }).totalUgx, 5);
});

test('the PDF draws with and without logo, stamp and signature', async () => {
  // 1x1 PNG.
  const png = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';
  assert.equal(imageFromDataUrl('data:text/plain;base64,aGk=') , null);
  const img = imageFromDataUrl(png);
  assert.equal(img?.type, 'png');
  const doc = { ...billingDocForPayment('p1', { tenantId: 't', amountUgx: 70000, months: 1, method: 'airtel', reference: 'X', paidAt: '2026-11-04T09:00:00Z' }, {}, {}, 1, new Date()), id: 'p1' };
  const brand = { company: 'Victorbee Technologies', address: 'Mbarara', phone: '+256 793 128 137', email: 'a@b.c', website: 'https://farmtap.victorbee.com', tin: '1000', signatoryName: 'Victor Mubangizi', signatoryTitle: 'CEO' };
  for (const view of ['receipt', 'invoice', 'refund'] as const) {
    const plain = await renderBillingPdf(PdfLib, doc, view, brand);
    assert.equal(Buffer.from(plain.slice(0, 5)).toString(), '%PDF-');
  }
  const branded = await renderBillingPdf(PdfLib, doc, 'receipt', { ...brand, logo: img, stamp: img, signature: img });
  assert.ok(branded.length > 1000);
  const loaded = await PdfLib.PDFDocument.load(branded);
  assert.equal(loaded.getPageCount(), 1);
  assert.match(loaded.getTitle() ?? '', /RECEIPT RCT-/);
});

// ---------------------------------------------------------------- Refunds

test('MTN refund: token, then a 202 transfer is pending', async () => {
  const { f, calls } = fakeFetch([{ body: { access_token: 'T' } }, { status: 202, body: {} }]);
  const r = await mtnRefund({ subscriptionKey: 's', apiUser: 'u', apiKey: 'k', targetEnvironment: 'sandbox', live: false }, '256772451908', 70000, 'r1', 'Paid twice', f);
  assert.equal(r.status, 'pending');
  assert.match(calls[1].url, /disbursement\/v1_0\/transfer/);
  assert.equal(JSON.parse(String(calls[1].init?.body)).currency, 'EUR');
  const refused = fakeFetch([{ body: { access_token: 'T' } }, { status: 500, body: {} }]);
  assert.equal((await mtnRefund({ subscriptionKey: 's', apiUser: 'u', apiKey: 'k', targetEnvironment: 'mtnuganda', live: true }, '256772451908', 1, 'r', '', refused.f)).status, 'failed');
});

test('Airtel and card refunds', async () => {
  const a = fakeFetch([{ body: { access_token: 'T' } }, { body: { status: { success: true, response_code: 'DP00800001001' }, data: { transaction: { airtel_money_id: 'AM1', status: 'TS' } } } }]);
  assert.deepEqual(await airtelRefund({ clientId: 'c', clientSecret: 's', live: false, country: 'UG' }, 'AM1', a.f), { status: 'sent', providerRef: 'AM1' });
  const c = fakeFetch([{ body: { status: 'success', data: { id: 99, status: 'completed' } } }]);
  assert.deepEqual(await cardRefund({ secretKey: 'k' }, '123', 70000, c.f), { status: 'sent', providerRef: '99' });
  assert.match(c.calls[0].url, /transactions\/123\/refund/);
  const bad = fakeFetch([{ status: 400, body: { status: 'error', message: 'Too late' } }]);
  assert.equal((await cardRefund({ secretKey: 'k' }, '123', 1, bad.f)).reason, 'Too late');
});

// ---------------------------------------------------------------- Deletion and legal

test('the 90-day hold', () => {
  const closed = new Date('2026-11-04T10:00:00Z');
  assert.equal(holdOver(closed, new Date('2027-02-01T10:00:00Z')), false);
  assert.equal(holdOver(closed, new Date('2027-02-02T10:00:00Z')), true);
});

test('legal defaults read and render', () => {
  const p = legalFromDoc('privacy', undefined);
  assert.equal(p.version, 1);
  assert.match(p.body, /Data Protection and Privacy Act, 2019/);
  assert.match(p.body, /90 days/);
  assert.equal(legalFromDoc('terms', { version: 3, body: 'Hi', effectiveDate: 'bad' }).effectiveDate, DEFAULT_LEGAL.terms.effectiveDate);
  const blocks = parseMarkdown(fillOperator(DEFAULT_LEGAL.terms.body));
  assert.ok(blocks.some((b) => b.type === 'h2' && b.text.startsWith('4. Refunds')));
  assert.ok(!fillOperator(DEFAULT_LEGAL.privacy.body).includes('{'));
  assert.ok(!/firebase/i.test(DEFAULT_LEGAL.privacy.body + DEFAULT_LEGAL.terms.body));
});
