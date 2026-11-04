// Refunds (decision 0024). The control panel records a refund request
// (refunds/{id}, status 'requested'); someone with Money access approves it.
//   - Paid by hand (cash, bank, or any refund while refundsApi is off):
//     the panel marks it 'done' with the reference and makes the refund note.
//   - MTN, Airtel or card with refundsApi on: this code sends it back through
//     the provider ('sending' -> 'sent' or 'failed') and makes the refund note.

import { FieldValue } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions';
import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import { airtelRefund, cardRefund, mtnRefund, type RefundResult } from './refundProviders';
import { billingFromDoc, refundDoc } from './shared/billing';
import { db, integrations, secret, switchOn } from './server';

export async function issueRefundNote(refundId: string): Promise<void> {
  const ref = db().doc(`refunds/${refundId}`);
  await db().runTransaction(async (tx) => {
    const r = await tx.get(ref);
    const d = r.data() ?? {};
    if (d.refundDocId || !['sent', 'done'].includes(String(d.status))) return;
    const [of, counter] = await Promise.all([tx.get(db().doc(`billingDocs/${String(d.paymentId)}`)), tx.get(db().doc('counters/billing'))]);
    if (!of.exists) return;
    const seq = typeof counter.get('next') === 'number' ? (counter.get('next') as number) : 1;
    const noteId = `refund-${refundId}`;
    const note = refundDoc(billingFromDoc(of.id, of.data()), refundId, Number(d.amountUgx) || 0, seq, String(d.method ?? ''), String(d.providerRef ?? d.reference ?? ''), String(d.reason ?? ''), new Date());
    tx.set(db().doc(`billingDocs/${noteId}`), { ...note, id: noteId, createdAt: FieldValue.serverTimestamp(), createdBy: 'system' });
    tx.set(db().doc('counters/billing'), { next: seq + 1, lastDoc: noteId }, { merge: true });
    tx.update(ref, { refundDocId: noteId, refundNo: note.refundNo });
  });
}

async function sendThroughProvider(d: Record<string, unknown>): Promise<RefundResult> {
  const pay = ((await db().doc(`platformPayments/${String(d.paymentId)}`).get()).data() ?? {}) as Record<string, unknown>;
  const p = ((await integrations()).payments ?? {}) as Record<string, unknown>;
  const live = p.mode === 'live';
  const method = String(d.method ?? pay.method ?? '');
  const amount = Number(d.amountUgx) || 0;
  if (method === 'mtn') {
    const [subscriptionKey, apiUser, apiKey] = await Promise.all([secret('mtn_disbursement_key'), secret('mtn_disbursement_user'), secret('mtn_disbursement_api_key')]);
    if (!subscriptionKey || !apiUser || !apiKey) return { status: 'failed', providerRef: '', reason: 'MTN refund keys are not set (APIs and keys).' };
    const msisdn = String(d.phone ?? pay.phone ?? '').replace(/\D/g, '');
    if (!/^2567\d{8}$/.test(msisdn)) return { status: 'failed', providerRef: '', reason: 'No MTN number to send the refund to.' };
    return mtnRefund({ subscriptionKey, apiUser, apiKey, targetEnvironment: live ? String(p.mtnEnvironment || 'mtnuganda') : 'sandbox', live }, msisdn, amount, String(d.id ?? ''), String(d.reason ?? ''));
  }
  if (method === 'airtel') {
    const [clientId, clientSecret] = await Promise.all([secret('airtel_client_id'), secret('airtel_client_secret')]);
    if (!clientId || !clientSecret) return { status: 'failed', providerRef: '', reason: 'Airtel keys are not set (APIs and keys).' };
    return airtelRefund({ clientId, clientSecret, live, country: String(p.airtelCountry || 'UG') }, String(pay.reference ?? ''));
  }
  if (method === 'card') {
    const secretKey = await secret('flutterwave_secret_key');
    if (!secretKey) return { status: 'failed', providerRef: '', reason: 'Card keys are not set (APIs and keys).' };
    return cardRefund({ secretKey }, String(pay.reference ?? ''), amount);
  }
  return { status: 'failed', providerRef: '', reason: 'This way of paying is refunded by hand.' };
}

export const processRefund = onDocumentWritten({ document: 'refunds/{id}', timeoutSeconds: 120 }, async (event) => {
  const after = event.data?.after?.data();
  if (!after) return;
  const ref = event.data!.after.ref;
  if (['sent', 'done'].includes(String(after.status)) && !after.refundDocId) {
    await issueRefundNote(event.params.id);
    return;
  }
  if (after.status !== 'approved' || after.byHand === true) return;
  if (!(await switchOn('refundsApi'))) return;
  // Claim it so it is sent once.
  const claimed = await db().runTransaction(async (tx) => {
    const cur = await tx.get(ref);
    if (cur.get('status') !== 'approved') return false;
    tx.update(ref, { status: 'sending', sendingAt: FieldValue.serverTimestamp() });
    return true;
  });
  if (!claimed) return;
  let r: RefundResult;
  try {
    r = await sendThroughProvider({ ...after, id: event.params.id });
  } catch (e) {
    r = { status: 'failed', providerRef: '', reason: e instanceof Error ? e.message : String(e) };
  }
  if (r.status === 'failed') logger.warn('refund failed', { id: event.params.id, reason: r.reason });
  await ref.update({
    status: r.status === 'failed' ? 'failed' : 'sent',
    providerRef: r.providerRef,
    providerStatus: r.status,
    failReason: r.reason ?? null,
    sentAt: r.status === 'failed' ? null : FieldValue.serverTimestamp(),
  });
});
