'use client';

// Paying for FarmTap from the app (decision 0023). The browser never sees a
// provider key: it asks FarmTap's server (functions/) to start a payment,
// then watches the payment record the server keeps up to date.

import { httpsCallable } from 'firebase/functions';
import { functions } from './firebase.ts';

export type PayStatus = 'pending' | 'paid' | 'failed' | 'cancelled' | 'expired';

export interface StartResult {
  paymentId: string;
  status: PayStatus;
  /** Card payments: the secure page to finish paying on. */
  redirectUrl?: string | null;
  message?: string | null;
}

export interface CheckResult {
  status: PayStatus;
  paidUntil?: string | null;
  message?: string | null;
}

/** A payment as the server records it: tenants/{t}/subscriptionPayments/{id}. */
export interface SubscriptionPayment {
  id: string;
  planId: string;
  planName: string;
  periods: number;
  months: number;
  amountUgx: number;
  method: string;
  phone?: string | null;
  status: PayStatus;
  reason?: string | null;
  createdAt?: { toDate(): Date } | null;
  paidAt?: { toDate(): Date } | null;
  byName?: string | null;
}

export async function startPayment(input: { tenantId: string; planId: string; periods: number; method: string; phone?: string; returnUrl?: string }) {
  const call = httpsCallable<typeof input, StartResult>(functions(), 'startPayment');
  return (await call(input)).data;
}

export async function checkPayment(input: { tenantId: string; paymentId: string }) {
  const call = httpsCallable<typeof input, CheckResult>(functions(), 'checkPayment');
  return (await call(input)).data;
}

/** Ugandan mobile number in the form the networks want: 2567XXXXXXXX. */
export function msisdn(phone: string): string | null {
  let d = phone.replace(/\D/g, '');
  if (d.startsWith('0')) d = `256${d.slice(1)}`;
  if (d.length === 9 && d.startsWith('7')) d = `256${d}`;
  return /^2567\d{8}$/.test(d) ? d : null;
}

/** Which network a number is on, from its prefix (MTN 076-078, 039; Airtel 070, 074-075). */
export function networkOf(phone: string): 'mtn' | 'airtel' | null {
  const m = msisdn(phone);
  if (!m) return null;
  const p = m.slice(3, 5);
  if (['76', '77', '78', '79'].includes(p)) return 'mtn';
  if (['70', '74', '75'].includes(p)) return 'airtel';
  return null;
}

export function payError(e: unknown): string {
  const code = (e as { code?: string }).code ?? '';
  const msg = (e as { message?: string }).message ?? '';
  if (code.endsWith('unavailable') || code.endsWith('internal') && !msg) return 'Could not reach FarmTap. Check the internet and try again.';
  if (code.endsWith('failed-precondition') || code.endsWith('invalid-argument') || code.endsWith('permission-denied')) return msg || 'This payment could not start.';
  if (code.endsWith('not-found')) return 'Payments are not switched on yet. Pay on WhatsApp for now.';
  return msg && !/firebase/i.test(msg) ? msg : 'Could not start the payment. Try again, or pay on WhatsApp.';
}
