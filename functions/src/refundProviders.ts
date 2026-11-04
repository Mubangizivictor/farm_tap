// Sending a refund back through the provider that took the payment
// (decision 0024). Only used for refunds the control panel approved, and
// only once Victor switches refundsApi on. `fetch` is injectable for tests.

import { randomUUID } from 'node:crypto';
import { ProviderError, airtelBase, mtnBase, type AirtelKeys, type Fetch, type FlutterwaveKeys } from './providers';

export interface RefundResult {
  status: 'sent' | 'pending' | 'failed';
  providerRef: string;
  reason?: string;
}

async function json(res: Response): Promise<Record<string, unknown>> {
  try {
    return (await res.json()) as Record<string, unknown>;
  } catch {
    return {};
  }
}
const o = (v: unknown): Record<string, unknown> => (v && typeof v === 'object' ? (v as Record<string, unknown>) : {});

/** MTN: the Disbursement product (separate keys), a transfer to the payer's number. */
export interface MtnDisbursementKeys {
  subscriptionKey: string;
  apiUser: string;
  apiKey: string;
  targetEnvironment: string;
  live: boolean;
}

export async function mtnRefund(k: MtnDisbursementKeys, msisdn: string, amountUgx: number, externalId: string, note: string, f: Fetch = fetch): Promise<RefundResult> {
  const base = mtnBase(k.live);
  const tok = await f(`${base}/disbursement/token/`, {
    method: 'POST',
    headers: { Authorization: `Basic ${Buffer.from(`${k.apiUser}:${k.apiKey}`).toString('base64')}`, 'Ocp-Apim-Subscription-Key': k.subscriptionKey },
  });
  const t = await json(tok);
  if (!tok.ok || typeof t.access_token !== 'string') throw new ProviderError('MTN did not accept the disbursement keys.', `token ${tok.status}`);
  const ref = randomUUID();
  const res = await f(`${base}/disbursement/v1_0/transfer`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${t.access_token}`,
      'X-Reference-Id': ref,
      'X-Target-Environment': k.targetEnvironment,
      'Ocp-Apim-Subscription-Key': k.subscriptionKey,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      amount: String(Math.round(amountUgx)),
      currency: k.targetEnvironment === 'sandbox' ? 'EUR' : 'UGX',
      externalId,
      payee: { partyIdType: 'MSISDN', partyId: msisdn },
      payerMessage: 'FarmTap refund',
      payeeNote: note.slice(0, 160) || 'FarmTap refund',
    }),
  });
  if (res.status !== 202) return { status: 'failed', providerRef: ref, reason: `MTN refused the refund (${res.status}).` };
  return { status: 'pending', providerRef: ref };
}

/** Airtel: the Collection refund API on the original Airtel Money transaction id. */
export async function airtelRefund(k: AirtelKeys, airtelMoneyId: string, f: Fetch = fetch): Promise<RefundResult> {
  const tok = await f(`${airtelBase(k.live)}/auth/oauth2/token`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Accept: '*/*' },
    body: JSON.stringify({ client_id: k.clientId, client_secret: k.clientSecret, grant_type: 'client_credentials' }),
  });
  const t = await json(tok);
  if (!tok.ok || typeof t.access_token !== 'string') throw new ProviderError('Airtel did not accept the keys.', `token ${tok.status}`);
  const res = await f(`${airtelBase(k.live)}/standard/v1/payments/refund`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${t.access_token}`, 'Content-Type': 'application/json', Accept: '*/*', 'X-Country': k.country, 'X-Currency': 'UGX' },
    body: JSON.stringify({ transaction: { airtel_money_id: airtelMoneyId } }),
  });
  const b = await json(res);
  const st = o(b.status);
  const ok = res.ok && (st.success === true || String(st.response_code ?? '').startsWith('DP'));
  const data = o(o(b.data).transaction);
  return ok
    ? { status: String(data.status ?? '').toUpperCase() === 'TS' ? 'sent' : 'pending', providerRef: String(data.airtel_money_id ?? airtelMoneyId) }
    : { status: 'failed', providerRef: airtelMoneyId, reason: String(st.message ?? `Airtel refused the refund (${res.status}).`) };
}

/** Flutterwave: refund a card transaction by its Flutterwave id. */
export async function cardRefund(k: FlutterwaveKeys, transactionId: string, amountUgx: number, f: Fetch = fetch): Promise<RefundResult> {
  const res = await f(`https://api.flutterwave.com/v3/transactions/${encodeURIComponent(transactionId)}/refund`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${k.secretKey}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ amount: Math.round(amountUgx) }),
  });
  const b = await json(res);
  const d = o(b.data);
  if (!res.ok || b.status !== 'success') return { status: 'failed', providerRef: transactionId, reason: String(b.message ?? `Flutterwave refused the refund (${res.status}).`) };
  const st = String(d.status ?? '').toLowerCase();
  return { status: st === 'completed' || st === 'successful' ? 'sent' : 'pending', providerRef: String(d.id ?? transactionId) };
}
