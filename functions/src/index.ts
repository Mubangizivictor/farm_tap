// FarmTap server code (decision 0023): farms pay for their plan inside the
// app with MTN MoMo, Airtel Money or a card, and the plan starts by itself.
//
// - API keys are pasted in the control panel (APIs and keys) and stored in
//   platformSecrets/{name}, which no app can read; only this code reads them.
// - The price is always taken from plans/{id} here, never from the app.
// - A payment counts only after the provider itself says it was paid in
//   full (we ask it; a webhook is only a nudge to ask).
// - Activation is one transaction: the payment, the farm's paid-until, a
//   platformPayments record for the panel and an audit line.

import { initializeApp } from 'firebase-admin/app';
import { FieldValue, Timestamp, getFirestore, type DocumentReference, type Firestore } from 'firebase-admin/firestore';
import { setGlobalOptions } from 'firebase-functions/v2';
import { HttpsError, onCall, onRequest, type CallableRequest } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { logger } from 'firebase-functions';
import { STARTER_PLAN, PENDING_LIMIT_MS, amountFor, cleanPeriods, extendPaidUntil, gatewayFrom, gatewayProblem, planFrom, ugMsisdn, type Plan, type PayStatus } from './billing';
import {
  ProviderError,
  airtelStart,
  airtelStatus,
  cardStart,
  cardStatus,
  mtnStart,
  mtnStatus,
  paidInFull,
  type AirtelKeys,
  type FlutterwaveKeys,
  type MtnKeys,
  type StartOutput,
  type StatusOutput,
} from './providers';

initializeApp();
export const REGION = 'europe-west1';
setGlobalOptions({ region: REGION, maxInstances: 10 });

const db = (): Firestore => getFirestore();

type Method = 'mtn' | 'airtel' | 'card';
const METHODS: Method[] = ['mtn', 'airtel', 'card'];

interface PaymentDoc {
  tenantId: string;
  planId: string;
  planName: string;
  periods: number;
  months: number;
  amountUgx: number;
  method: Method;
  phone: string | null;
  status: PayStatus;
  live: boolean;
  providerRef: string;
  providerTxId?: string | null;
  reason?: string | null;
  createdAt: Timestamp;
  createdBy: string;
  byName: string;
}

// ---------------------------------------------------------------- Settings and keys

async function secret(name: string): Promise<string> {
  const v = (await db().doc(`platformSecrets/${name}`).get()).get('value');
  return typeof v === 'string' ? v.trim() : '';
}

interface PaySettings {
  live: boolean;
  mtnEnvironment: string;
  airtelCountry: string;
  callbackBase: string;
}

async function settings(): Promise<PaySettings> {
  const p = ((await db().doc('platform/integrations').get()).get('payments') ?? {}) as Record<string, unknown>;
  const project = process.env.GCLOUD_PROJECT ?? process.env.GCP_PROJECT ?? 'farm-tap-1dd15';
  const base = typeof p.callbackUrl === 'string' && /^https:\/\//.test(p.callbackUrl) ? p.callbackUrl : `https://${REGION}-${project}.cloudfunctions.net/paymentWebhook`;
  return {
    live: p.mode === 'live',
    mtnEnvironment: typeof p.mtnEnvironment === 'string' && p.mtnEnvironment ? p.mtnEnvironment : 'sandbox',
    airtelCountry: typeof p.airtelCountry === 'string' && p.airtelCountry ? p.airtelCountry : 'UG',
    callbackBase: base.replace(/\/+$/, ''),
  };
}

async function mtnKeys(s: PaySettings): Promise<MtnKeys> {
  const [subscriptionKey, apiUser, apiKey] = await Promise.all([secret('mtn_subscription_key'), secret('mtn_api_user'), secret('mtn_api_key')]);
  if (!subscriptionKey || !apiUser || !apiKey) throw new HttpsError('failed-precondition', 'MTN MoMo is not set up yet. Choose another way, or pay on WhatsApp.');
  return { subscriptionKey, apiUser, apiKey, targetEnvironment: s.live ? s.mtnEnvironment : 'sandbox', live: s.live };
}

async function airtelKeys(s: PaySettings): Promise<AirtelKeys> {
  const [clientId, clientSecret] = await Promise.all([secret('airtel_client_id'), secret('airtel_client_secret')]);
  if (!clientId || !clientSecret) throw new HttpsError('failed-precondition', 'Airtel Money is not set up yet. Choose another way, or pay on WhatsApp.');
  return { clientId, clientSecret, live: s.live, country: s.airtelCountry };
}

async function cardKeys(): Promise<FlutterwaveKeys> {
  const secretKey = await secret('flutterwave_secret_key');
  if (!secretKey) throw new HttpsError('failed-precondition', 'Card payments are not set up yet. Choose another way, or pay on WhatsApp.');
  return { secretKey };
}

async function providerStatus(p: PaymentDoc): Promise<StatusOutput> {
  const s = await settings();
  if (p.method === 'mtn') return mtnStatus(await mtnKeys({ ...s, live: p.live }), p.providerRef);
  if (p.method === 'airtel') return airtelStatus(await airtelKeys({ ...s, live: p.live }), p.providerRef);
  return cardStatus(await cardKeys(), p.providerRef);
}

// ---------------------------------------------------------------- Who may pay

async function requireManager(req: CallableRequest, tenantId: unknown): Promise<{ uid: string; name: string; email: string; tenantId: string }> {
  if (!req.auth) throw new HttpsError('unauthenticated', 'Sign in first.');
  if (typeof tenantId !== 'string' || !/^[\w-]{1,128}$/.test(tenantId)) throw new HttpsError('invalid-argument', 'Which farm?');
  const m = await db().doc(`tenants/${tenantId}/members/${req.auth.uid}`).get();
  if (!m.exists || !['owner', 'manager'].includes(String(m.get('role')))) {
    throw new HttpsError('permission-denied', 'Only the farm owner or a manager can pay for FarmTap.');
  }
  const t = req.auth.token as Record<string, unknown>;
  return { uid: req.auth.uid, name: String(t.name ?? t.email ?? 'Farm'), email: String(t.email ?? ''), tenantId };
}

// ---------------------------------------------------------------- Start

export const startPayment = onCall({ timeoutSeconds: 60 }, async (req) => {
  const d = (req.data ?? {}) as Record<string, unknown>;
  const who = await requireManager(req, d.tenantId);
  const method = d.method as Method;
  if (!METHODS.includes(method)) throw new HttpsError('invalid-argument', 'Choose MTN MoMo, Airtel Money or card.');
  const periods = cleanPeriods(d.periods);
  if (!periods) throw new HttpsError('invalid-argument', 'Choose how many months to pay for.');

  const [tenant, cfg] = await Promise.all([db().doc(`tenants/${who.tenantId}`).get(), db().doc('platform/config').get()]);
  if (!tenant.exists) throw new HttpsError('not-found', 'Farm not found.');
  if (tenant.get('status') === 'suspended') throw new HttpsError('failed-precondition', 'This farm is paused. Contact FarmTap support.');
  const problem = gatewayProblem(gatewayFrom(cfg.get('payments.gateways'), method));
  if (problem) throw new HttpsError('failed-precondition', problem);

  // The plan and its price come from the panel's plans, never from the app.
  const planId = typeof d.planId === 'string' ? d.planId : '';
  let plan: Plan | null = null;
  if (planId && /^[\w-]{1,128}$/.test(planId)) plan = planFrom(planId, (await db().doc(`plans/${planId}`).get()).data());
  if (!plan) {
    const any = await db().collection('plans').limit(1).get();
    if (any.empty && (planId === STARTER_PLAN.id || !planId)) plan = STARTER_PLAN;
  }
  if (!plan || !plan.active || plan.priceUgx <= 0) throw new HttpsError('failed-precondition', 'That plan is not offered any more. Refresh and choose again.');

  let msisdn: string | null = null;
  if (method !== 'card') {
    msisdn = ugMsisdn(d.phone);
    if (!msisdn) throw new HttpsError('invalid-argument', 'Type a Ugandan Mobile Money number, e.g. 0772 123 456.');
  }

  // No more than 5 tries in 10 minutes for one farm.
  const recent = await db()
    .collection(`tenants/${who.tenantId}/subscriptionPayments`)
    .where('createdAt', '>', Timestamp.fromMillis(Date.now() - 10 * 60 * 1000))
    .get();
  if (recent.size >= 5) throw new HttpsError('resource-exhausted', 'Too many tries. Wait 10 minutes, or pay on WhatsApp.');

  const s = await settings();
  const amountUgx = amountFor(plan, periods);
  const ref = db().collection(`tenants/${who.tenantId}/subscriptionPayments`).doc();
  const id = ref.id;
  const description = `FarmTap ${plan.name} ${String(tenant.get('name') ?? '')}`.trim();
  const returnUrl = typeof d.returnUrl === 'string' && /^https:\/\/[^\s]+$/.test(d.returnUrl) ? d.returnUrl.replace('{id}', id) : undefined;
  const pay: PaymentDoc = {
    tenantId: who.tenantId,
    planId: plan.id,
    planName: plan.name,
    periods,
    months: plan.months * periods,
    amountUgx,
    method,
    phone: msisdn,
    status: 'pending',
    live: s.live,
    providerRef: id,
    createdAt: Timestamp.now(),
    createdBy: who.uid,
    byName: who.name,
  };
  await ref.set(pay);
  await db().doc(`paymentRefs/${id}`).set({ tenantId: who.tenantId, method, createdAt: pay.createdAt });

  let out: StartOutput;
  try {
    const input = { reference: id, amountUgx, msisdn: msisdn ?? undefined, description, callbackUrl: `${s.callbackBase}/${method === 'card' ? 'flutterwave' : method}`, returnUrl, email: who.email, name: who.name };
    if (method === 'mtn') out = await mtnStart(await mtnKeys(s), input);
    else if (method === 'airtel') out = await airtelStart(await airtelKeys(s), input);
    else out = await cardStart(await cardKeys(), input);
  } catch (e) {
    const msg = e instanceof HttpsError || e instanceof ProviderError ? e.message : 'The payment could not start. Try again.';
    logger.warn('payment start failed', { tenantId: who.tenantId, id, method, detail: e instanceof ProviderError ? e.detail : String(e) });
    await ref.update({ status: 'failed', reason: msg });
    if (e instanceof HttpsError) throw e;
    throw new HttpsError('unavailable', msg);
  }
  if (out.providerRef !== id) await ref.update({ providerRef: out.providerRef });
  return { paymentId: id, status: 'pending' as PayStatus, redirectUrl: out.redirectUrl ?? null, message: null };
});

// ---------------------------------------------------------------- Check and activate

/** Asks the provider and, when paid in full, starts the plan. Safe to call any number of times. */
async function settle(ref: DocumentReference): Promise<{ status: PayStatus; paidUntil: string | null; reason: string | null }> {
  const snap = await ref.get();
  if (!snap.exists) throw new HttpsError('not-found', 'Payment not found.');
  const p = snap.data() as PaymentDoc;
  if (p.status !== 'pending') return { status: p.status, paidUntil: null, reason: p.reason ?? null };

  let st: StatusOutput;
  try {
    st = await providerStatus(p);
  } catch (e) {
    logger.warn('payment status failed', { path: ref.path, detail: e instanceof ProviderError ? e.detail : String(e) });
    return { status: 'pending', paidUntil: null, reason: null };
  }

  // MTN's sandbox only works in EUR; live money must be UGX.
  const sandboxCurrency = p.method === 'mtn' && !p.live;
  if (st.status === 'paid' && !paidInFull(st, p.amountUgx, sandboxCurrency)) {
    logger.error('payment amount mismatch', { path: ref.path, expected: p.amountUgx, got: st.amount, currency: st.currency });
    st = { status: 'failed', reason: 'The amount paid does not match the plan. Contact FarmTap support.' };
  }

  if (st.status === 'pending') {
    if (Date.now() - p.createdAt.toMillis() > PENDING_LIMIT_MS) {
      await ref.update({ status: 'expired', reason: 'The phone did not approve in time.' });
      return { status: 'expired', paidUntil: null, reason: 'The phone did not approve in time.' };
    }
    return { status: 'pending', paidUntil: null, reason: null };
  }

  if (st.status !== 'paid') {
    await ref.update({ status: st.status, reason: st.reason ?? null, checkedAt: FieldValue.serverTimestamp() });
    return { status: st.status, paidUntil: null, reason: st.reason ?? null };
  }

  return db().runTransaction(async (tx) => {
    const again = await tx.get(ref);
    const cur = again.data() as PaymentDoc;
    if (cur.status === 'paid') return { status: 'paid' as PayStatus, paidUntil: null, reason: null };
    const tenantRef = db().doc(`tenants/${cur.tenantId}`);
    const tenant = await tx.get(tenantRef);
    const now = new Date();
    const currentUntil = (tenant.get('subscription.paidUntil') as Timestamp | undefined)?.toDate() ?? null;
    const until = extendPaidUntil(currentUntil, cur.months, now);
    const audit = db().collection('adminAudit').doc();
    tx.update(ref, { status: 'paid', paidAt: FieldValue.serverTimestamp(), providerTxId: st.providerTxId ?? null, newPaidUntil: Timestamp.fromDate(until), reason: null });
    tx.update(tenantRef, {
      'subscription.paidUntil': Timestamp.fromDate(until),
      planId: cur.planId,
      'billing.lastPaymentAt': FieldValue.serverTimestamp(),
      'billing.lastPaymentUgx': cur.amountUgx,
      'billing.lastMethod': cur.method,
      lastAudit: audit.id,
    });
    tx.set(db().doc(`platformPayments/${ref.id}`), {
      tenantId: cur.tenantId,
      farmName: String(tenant.get('name') ?? ''),
      kind: 'subscription',
      amountUgx: cur.amountUgx,
      method: cur.method,
      reference: st.providerTxId ?? ref.id,
      planId: cur.planId,
      months: cur.months,
      smsCredits: 0,
      paidAt: Timestamp.fromDate(now),
      newPaidUntil: Timestamp.fromDate(until),
      status: 'received',
      recordedBy: 'system',
      recordedByName: cur.live ? 'Paid in the app' : 'Paid in the app (test mode)',
      note: `${cur.planName}, ${cur.periods} × by ${cur.byName}`,
      createdAt: FieldValue.serverTimestamp(),
      auto: true,
    });
    tx.set(audit, {
      by: 'system',
      byName: 'FarmTap payments',
      at: FieldValue.serverTimestamp(),
      action: 'payment.auto',
      target: `platformPayments/${ref.id}`,
      tenantId: cur.tenantId,
      details: { amountUgx: cur.amountUgx, method: cur.method, months: cur.months, live: cur.live, paidUntil: until.toISOString() },
    });
    return { status: 'paid' as PayStatus, paidUntil: until.toISOString(), reason: null };
  });
}

export const checkPayment = onCall({ timeoutSeconds: 60 }, async (req) => {
  const d = (req.data ?? {}) as Record<string, unknown>;
  const who = await requireManager(req, d.tenantId);
  if (typeof d.paymentId !== 'string' || !/^[\w-]{1,64}$/.test(d.paymentId)) throw new HttpsError('invalid-argument', 'Which payment?');
  const r = await settle(db().doc(`tenants/${who.tenantId}/subscriptionPayments/${d.paymentId}`));
  return { status: r.status, paidUntil: r.paidUntil, message: r.reason };
});

// ---------------------------------------------------------------- Webhooks

/**
 * /mtn, /airtel and /flutterwave. The body is never trusted: it only tells
 * us which payment to ask the provider about.
 */
export const paymentWebhook = onRequest({ timeoutSeconds: 60 }, async (req, res) => {
  if (req.method !== 'POST' && req.method !== 'PUT') {
    res.status(405).send('POST only');
    return;
  }
  const provider = req.path.replace(/^\/+|\/+$/g, '').split('/').pop() ?? '';
  const body = (typeof req.body === 'object' && req.body ? req.body : {}) as Record<string, unknown>;
  let ref = '';
  if (provider === 'flutterwave') {
    const want = await secret('flutterwave_webhook_hash');
    if (!want || req.get('verif-hash') !== want) {
      res.status(401).send('bad signature');
      return;
    }
    const data = (body.data ?? {}) as Record<string, unknown>;
    ref = String(data.tx_ref ?? body.txRef ?? '');
  } else if (provider === 'mtn') {
    const token = await secret('mtn_callback_token');
    if (token && req.query.t !== token) {
      res.status(401).send('bad token');
      return;
    }
    ref = String(body.externalId ?? body.referenceId ?? '');
  } else if (provider === 'airtel') {
    const token = await secret('airtel_callback_token');
    if (token && req.query.t !== token) {
      res.status(401).send('bad token');
      return;
    }
    const tx = (body.transaction ?? {}) as Record<string, unknown>;
    ref = String(tx.id ?? '');
  } else {
    res.status(404).send('unknown provider');
    return;
  }
  if (!/^[\w-]{1,64}$/.test(ref)) {
    res.status(200).send('ignored');
    return;
  }
  const idx = await db().doc(`paymentRefs/${ref}`).get();
  if (!idx.exists) {
    res.status(200).send('unknown payment');
    return;
  }
  try {
    await settle(db().doc(`tenants/${String(idx.get('tenantId'))}/subscriptionPayments/${ref}`));
  } catch (e) {
    logger.error('webhook settle failed', { ref, provider, error: String(e) });
  }
  res.status(200).send('ok');
});

// ---------------------------------------------------------------- Sweep

/** Every 10 minutes: settle payments still waiting (a webhook may never come). */
export const sweepPayments = onSchedule({ schedule: 'every 10 minutes', timeZone: 'Africa/Kampala' }, async () => {
  const since = Timestamp.fromMillis(Date.now() - 2 * 60 * 60 * 1000);
  const waiting = await db().collectionGroup('subscriptionPayments').where('status', '==', 'pending').where('createdAt', '>', since).limit(100).get();
  for (const d of waiting.docs) {
    try {
      await settle(d.ref);
    } catch (e) {
      logger.warn('sweep settle failed', { path: d.ref.path, error: String(e) });
    }
  }
});

// ---------------------------------------------------------------- Decision 0024
// Each of these does nothing until its switch in platform/config.server is on
// (tool/activate-blaze.sh switches them on after the Blaze upgrade).
export { sendQueuedMessage } from './sms';
export { farmAlerts } from './alerts';
export { issueBillingDocs, issueRefundDocs } from './billingDocs';
export { processRefund } from './refunds';
export { onDeletionChange, eraseClosedAccounts } from './accounts';
