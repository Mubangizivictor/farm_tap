// Payment providers (decision 0023). Each one starts a collection and reads
// its status back. Keys are passed in by the caller (from platformSecrets);
// nothing here is stored or logged. `fetch` is injectable for tests.
//
// - MTN MoMo Collection API: https://momodeveloper.mtn.com (requesttopay)
// - Airtel Money Collection API: https://developers.airtel.africa (merchant/v1/payments)
// - Card: Flutterwave Standard checkout: https://developer.flutterwave.com (v3/payments)

import type { PayStatus } from './billing';

export type Fetch = typeof fetch;

export interface StartInput {
  /** Our payment id; the provider's reference. */
  reference: string;
  amountUgx: number;
  msisdn?: string;
  description: string;
  callbackUrl: string;
  returnUrl?: string;
  email?: string;
  name?: string;
}

export interface StartOutput {
  providerRef: string;
  redirectUrl?: string;
}

export interface StatusOutput {
  status: PayStatus;
  /** What the provider says was paid, when it says it. */
  amount?: number;
  currency?: string;
  providerTxId?: string;
  reason?: string;
}

export class ProviderError extends Error {
  constructor(
    message: string,
    readonly detail: string = '',
  ) {
    super(message);
  }
}

async function jsonOf(res: Response): Promise<Record<string, unknown>> {
  const text = await res.text();
  if (!text) return {};
  try {
    return JSON.parse(text) as Record<string, unknown>;
  } catch {
    return { raw: text.slice(0, 300) };
  }
}

const obj = (v: unknown): Record<string, unknown> => (v && typeof v === 'object' ? (v as Record<string, unknown>) : {});

// ---------------------------------------------------------------- MTN MoMo

export interface MtnKeys {
  subscriptionKey: string;
  apiUser: string;
  apiKey: string;
  /** 'sandbox' or the live one MTN gives (e.g. 'mtnuganda'). */
  targetEnvironment: string;
  live: boolean;
}

export const mtnBase = (live: boolean) => (live ? 'https://proxy.momoapi.mtn.com' : 'https://sandbox.momodeveloper.mtn.com');

/** The MoMo sandbox only takes EUR; live Uganda takes UGX. */
export const mtnCurrency = (k: MtnKeys) => (k.targetEnvironment === 'sandbox' ? 'EUR' : 'UGX');

async function mtnToken(k: MtnKeys, f: Fetch): Promise<string> {
  const res = await f(`${mtnBase(k.live)}/collection/token/`, {
    method: 'POST',
    headers: {
      Authorization: `Basic ${Buffer.from(`${k.apiUser}:${k.apiKey}`).toString('base64')}`,
      'Ocp-Apim-Subscription-Key': k.subscriptionKey,
    },
  });
  const body = await jsonOf(res);
  if (!res.ok || typeof body.access_token !== 'string') throw new ProviderError('MTN MoMo did not accept the FarmTap keys.', `token ${res.status}`);
  return body.access_token;
}

export async function mtnStart(k: MtnKeys, input: StartInput, f: Fetch = fetch): Promise<StartOutput> {
  if (!input.msisdn) throw new ProviderError('Type the MTN number to pay from.');
  const token = await mtnToken(k, f);
  const res = await f(`${mtnBase(k.live)}/collection/v1_0/requesttopay`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${token}`,
      'X-Reference-Id': input.reference,
      'X-Target-Environment': k.targetEnvironment,
      'X-Callback-Url': input.callbackUrl,
      'Ocp-Apim-Subscription-Key': k.subscriptionKey,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      amount: String(input.amountUgx),
      currency: mtnCurrency(k),
      externalId: input.reference,
      payer: { partyIdType: 'MSISDN', partyId: input.msisdn },
      payerMessage: input.description.slice(0, 160),
      payeeNote: input.description.slice(0, 160),
    }),
  });
  // 202 Accepted: the prompt is on its way to the phone.
  if (res.status !== 202) {
    const body = await jsonOf(res);
    throw new ProviderError('MTN MoMo could not send the payment prompt. Check the number and try again.', `requesttopay ${res.status} ${String(body.code ?? body.message ?? '')}`);
  }
  return { providerRef: input.reference };
}

export async function mtnStatus(k: MtnKeys, providerRef: string, f: Fetch = fetch): Promise<StatusOutput> {
  const token = await mtnToken(k, f);
  const res = await f(`${mtnBase(k.live)}/collection/v1_0/requesttopay/${encodeURIComponent(providerRef)}`, {
    headers: { Authorization: `Bearer ${token}`, 'X-Target-Environment': k.targetEnvironment, 'Ocp-Apim-Subscription-Key': k.subscriptionKey },
  });
  const b = await jsonOf(res);
  if (res.status === 404) return { status: 'pending' };
  if (!res.ok) throw new ProviderError('Could not check the MTN payment.', `status ${res.status}`);
  const st = String(b.status ?? '').toUpperCase();
  const out: StatusOutput = { status: st === 'SUCCESSFUL' ? 'paid' : st === 'FAILED' ? 'failed' : st === 'REJECTED' ? 'cancelled' : st === 'TIMEOUT' ? 'expired' : 'pending' };
  if (b.amount != null) out.amount = Number(b.amount);
  if (typeof b.currency === 'string') out.currency = b.currency;
  if (typeof b.financialTransactionId === 'string') out.providerTxId = b.financialTransactionId;
  if (out.status !== 'paid' && out.status !== 'pending') out.reason = reasonText(String(obj(b.reason).code ?? b.reason ?? ''));
  return out;
}

// ---------------------------------------------------------------- Airtel Money

export interface AirtelKeys {
  clientId: string;
  clientSecret: string;
  live: boolean;
  country: string;
}

export const airtelBase = (live: boolean) => (live ? 'https://openapi.airtel.africa' : 'https://openapiuat.airtel.africa');

async function airtelToken(k: AirtelKeys, f: Fetch): Promise<string> {
  const res = await f(`${airtelBase(k.live)}/auth/oauth2/token`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Accept: '*/*' },
    body: JSON.stringify({ client_id: k.clientId, client_secret: k.clientSecret, grant_type: 'client_credentials' }),
  });
  const b = await jsonOf(res);
  if (!res.ok || typeof b.access_token !== 'string') throw new ProviderError('Airtel Money did not accept the FarmTap keys.', `token ${res.status}`);
  return b.access_token;
}

/** Airtel wants the number without the country code: 7XXXXXXXX. */
export const airtelMsisdn = (msisdn: string) => (msisdn.startsWith('256') ? msisdn.slice(3) : msisdn);

export async function airtelStart(k: AirtelKeys, input: StartInput, f: Fetch = fetch): Promise<StartOutput> {
  if (!input.msisdn) throw new ProviderError('Type the Airtel number to pay from.');
  const token = await airtelToken(k, f);
  const res = await f(`${airtelBase(k.live)}/merchant/v1/payments/`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
      Accept: '*/*',
      'X-Country': k.country,
      'X-Currency': 'UGX',
    },
    body: JSON.stringify({
      reference: input.description.slice(0, 64),
      subscriber: { country: k.country, currency: 'UGX', msisdn: airtelMsisdn(input.msisdn) },
      transaction: { amount: input.amountUgx, country: k.country, currency: 'UGX', id: input.reference },
    }),
  });
  const b = await jsonOf(res);
  const status = obj(b.status);
  if (!res.ok || status.success === false) {
    throw new ProviderError('Airtel Money could not send the payment prompt. Check the number and try again.', `payments ${res.status} ${String(status.response_code ?? status.code ?? '')}`);
  }
  return { providerRef: input.reference };
}

export async function airtelStatus(k: AirtelKeys, providerRef: string, f: Fetch = fetch): Promise<StatusOutput> {
  const token = await airtelToken(k, f);
  const res = await f(`${airtelBase(k.live)}/standard/v1/payments/${encodeURIComponent(providerRef)}`, {
    headers: { Authorization: `Bearer ${token}`, Accept: '*/*', 'X-Country': k.country, 'X-Currency': 'UGX' },
  });
  const b = await jsonOf(res);
  if (!res.ok) throw new ProviderError('Could not check the Airtel payment.', `status ${res.status}`);
  const tx = obj(obj(b.data).transaction);
  // TS = success, TF = failed, TA/TIP = still going, TE = expired.
  const st = String(tx.status ?? '').toUpperCase();
  const out: StatusOutput = { status: st === 'TS' ? 'paid' : st === 'TF' ? 'failed' : st === 'TE' ? 'expired' : 'pending' };
  if (typeof tx.airtel_money_id === 'string') out.providerTxId = tx.airtel_money_id;
  if (out.status === 'failed' || out.status === 'expired') out.reason = String(tx.message ?? '') || reasonText('');
  return out;
}

// ---------------------------------------------------------------- Card (Flutterwave)

export interface FlutterwaveKeys {
  secretKey: string;
}

const FLW = 'https://api.flutterwave.com/v3';

export async function cardStart(k: FlutterwaveKeys, input: StartInput, f: Fetch = fetch): Promise<StartOutput> {
  const res = await f(`${FLW}/payments`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${k.secretKey}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({
      tx_ref: input.reference,
      amount: input.amountUgx,
      currency: 'UGX',
      redirect_url: input.returnUrl,
      payment_options: 'card',
      customer: { email: input.email || 'payments@farmtap.ug', name: input.name || 'FarmTap farm' },
      customizations: { title: 'FarmTap', description: input.description.slice(0, 100) },
      meta: { farmtap_payment: input.reference },
    }),
  });
  const b = await jsonOf(res);
  const link = obj(b.data).link;
  if (!res.ok || b.status !== 'success' || typeof link !== 'string') throw new ProviderError('The card payment page could not open. Try again.', `payments ${res.status}`);
  return { providerRef: input.reference, redirectUrl: link };
}

export async function cardStatus(k: FlutterwaveKeys, providerRef: string, f: Fetch = fetch): Promise<StatusOutput> {
  const res = await f(`${FLW}/transactions/verify_by_reference?tx_ref=${encodeURIComponent(providerRef)}`, {
    headers: { Authorization: `Bearer ${k.secretKey}` },
  });
  const b = await jsonOf(res);
  if (res.status === 404 || (res.status === 400 && /no transaction/i.test(String(b.message ?? '')))) return { status: 'pending' };
  if (!res.ok) throw new ProviderError('Could not check the card payment.', `verify ${res.status}`);
  const d = obj(b.data);
  const st = String(d.status ?? '').toLowerCase();
  const out: StatusOutput = { status: st === 'successful' ? 'paid' : st === 'failed' ? 'failed' : st === 'cancelled' ? 'cancelled' : 'pending' };
  if (d.amount != null) out.amount = Number(d.amount);
  if (typeof d.currency === 'string') out.currency = d.currency;
  if (d.id != null) out.providerTxId = String(d.id);
  if (out.status === 'failed') out.reason = String(d.processor_response ?? '') || reasonText('');
  return out;
}

// ---------------------------------------------------------------- Shared

function reasonText(code: string): string {
  const c = code.toUpperCase();
  if (c.includes('NOT_ENOUGH') || c.includes('INSUFFICIENT')) return 'Not enough money on the account.';
  if (c.includes('REJECT') || c.includes('CANCEL')) return 'The payment was cancelled on the phone.';
  if (c.includes('TIMEOUT') || c.includes('EXPIRED')) return 'The phone did not approve in time.';
  if (c.includes('PAYER_NOT_FOUND') || c.includes('INVALID')) return 'That number is not registered for Mobile Money.';
  return 'The payment did not go through. Nothing was taken.';
}

/**
 * The provider says it was paid, and paid in full: the amount and currency
 * match what we asked (MTN's sandbox works in EUR, so only the amount is
 * checked there).
 */
export function paidInFull(s: StatusOutput, expectedUgx: number, sandboxCurrency = false): boolean {
  if (s.status !== 'paid') return false;
  if (s.amount != null && Math.round(s.amount) < expectedUgx) return false;
  if (!sandboxCurrency && s.currency && s.currency.toUpperCase() !== 'UGX') return false;
  return true;
}
