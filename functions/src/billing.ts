// Pure billing rules shared by the payment functions (decision 0023).
// No Firebase here, so they are unit tested with node:test.

export interface PlanDoc {
  name?: unknown;
  priceUgx?: unknown;
  months?: unknown;
  active?: unknown;
}

export interface Plan {
  id: string;
  name: string;
  priceUgx: number;
  months: number;
  active: boolean;
}

/** The plan Victor starts with when the panel has none (binding rule 3). */
export const STARTER_PLAN: Plan = { id: 'standard', name: 'Standard', priceUgx: 70000, months: 1, active: true };

export function planFrom(id: string, d: PlanDoc | undefined): Plan | null {
  if (!d) return null;
  const price = typeof d.priceUgx === 'number' && Number.isFinite(d.priceUgx) ? Math.round(d.priceUgx) : 0;
  const months = typeof d.months === 'number' && d.months >= 1 ? Math.round(d.months) : 1;
  return { id, name: typeof d.name === 'string' && d.name ? d.name : 'Plan', priceUgx: price, months, active: d.active !== false };
}

/** Periods a farm may buy at once: 1 to 12. */
export function cleanPeriods(n: unknown): number | null {
  if (typeof n !== 'number' || !Number.isInteger(n) || n < 1 || n > 12) return null;
  return n;
}

/** What the farm pays: always worked out here from the stored plan, never taken from the app. */
export const amountFor = (plan: Plan, periods: number) => plan.priceUgx * periods;

/**
 * New paid-until date: months added to the later of today and the current
 * paid-until, so paying early never loses days (same as the panel's
 * extendPaidUntil in webapp/src/lib/admin.ts).
 */
export function extendPaidUntil(current: Date | null, months: number, now: Date): Date {
  const base = current && current > now ? new Date(current) : new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const out = new Date(base);
  out.setMonth(out.getMonth() + months);
  return out;
}

/** 2567XXXXXXXX from 07XX..., +2567..., 7XX... ; null when not a Ugandan mobile number. */
export function ugMsisdn(phone: unknown): string | null {
  if (typeof phone !== 'string') return null;
  let d = phone.replace(/\D/g, '');
  if (d.startsWith('0')) d = `256${d.slice(1)}`;
  if (d.length === 9 && d.startsWith('7')) d = `256${d}`;
  return /^2567\d{8}$/.test(d) ? d : null;
}

export type PayStatus = 'pending' | 'paid' | 'failed' | 'cancelled' | 'expired';

/** A pending payment older than this is given up (the network prompt has long timed out). */
export const PENDING_LIMIT_MS = 30 * 60 * 1000;

/** Gateway settings from platform/config.payments.gateways (no secrets). */
export interface GatewayCfg {
  id: string;
  enabled: boolean;
  hidden: boolean;
  api: boolean;
}

export function gatewayFrom(list: unknown, id: string): GatewayCfg | null {
  if (!Array.isArray(list)) return null;
  const g = list.find((x) => x && typeof x === 'object' && (x as { id?: unknown }).id === id) as Record<string, unknown> | undefined;
  if (!g) return null;
  return { id, enabled: g.enabled === true, hidden: g.hidden === true, api: g.api !== false };
}

/** Why a gateway cannot take an in-app payment now, or null when it can. */
export function gatewayProblem(g: GatewayCfg | null): string | null {
  if (!g || g.hidden) return 'This way of paying is not offered.';
  if (!g.enabled) return 'This way of paying is coming soon. Choose another, or pay on WhatsApp.';
  if (!g.api) return 'This way of paying is confirmed by FarmTap support. Send the transaction ID instead.';
  return null;
}
