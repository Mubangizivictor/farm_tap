// Shared look-ups for the control panel pages (decision 0020).
import type { AdminFarm } from './admin.ts';
import { planState } from './domain.ts';
import { starterPlan, type Plan } from './platform.ts';

export function farmPlan(f: AdminFarm, now: Date) {
  return planState({ trialStartedAt: f.trialStartedAt, trialEndsAt: f.trialEndsAt, paidUntil: f.paidUntil }, now);
}

export function farmStatus(f: AdminFarm, now: Date): { text: string; tone: 'ok' | 'warn' | 'bad' | 'brand' } {
  if (f.status === 'suspended') return { text: 'Suspended', tone: 'bad' };
  if (f.review === 'rejected') return { text: 'Rejected', tone: 'bad' };
  const p = farmPlan(f, now);
  switch (p.kind) {
    case 'paid':
      return { text: 'Paid', tone: 'ok' };
    case 'grace':
      return { text: 'Overdue', tone: 'warn' };
    case 'trial':
      return { text: `Trial, ${p.daysLeft}d left`, tone: p.daysLeft <= 2 ? 'warn' : 'brand' };
    case 'readOnly':
      return { text: f.paidUntil ? 'Lapsed' : 'Trial ended', tone: 'bad' };
  }
}

export function planOf(f: AdminFarm, plans: Plan[]): Plan {
  return plans.find((p) => p.id === f.planId) ?? plans.find((p) => p.active) ?? starterPlan;
}

