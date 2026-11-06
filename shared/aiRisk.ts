// FarmTap AI engine — every finding in one place: risk dashboard, alerts
// centre and "Today's AI farm insights" (decision 0025).

import { rankFindings, type AiModule, type Finding, type Severity } from './aiCore.ts';
import { moduleOn, seesMoney, type AiConfig, type FarmRole } from './aiAccess.ts';
import type { FarmData } from './aiData.ts';
import { breedingFindings, healthFindings } from './aiHerd.ts';
import { milkFindings, qualityFindings } from './aiMilk.ts';
import { financeFindings } from './aiMoney.ts';
import { drugFindings, feedFindings } from './aiStock.ts';

/** aiAlertStates body: someone acknowledged or resolved an alert (doc id = alert id). */
export interface AlertStateIn {
  status: 'acknowledged' | 'resolved';
  note?: string | null;
  byName?: string | null;
  at?: string;
}

export interface FindingWithState extends Finding {
  state: 'new' | 'acknowledged';
}

/**
 * All findings the person may see, ranked, with acknowledged ones marked
 * and resolved ones removed. A resolved alert comes back only as a new id
 * (a new day, month or batch), so a fixed problem stays fixed.
 */
export function allFindings(
  d: FarmData,
  opts: { role: FarmRole; cfg: AiConfig; farmAiOn?: boolean; states?: Map<string, AlertStateIn> },
): FindingWithState[] {
  const on = (m: AiModule) => moduleOn(m, opts.cfg, opts.role, opts.farmAiOn ?? true);
  const fs: Finding[] = [];
  const safe = (f: () => Finding[]) => {
    try {
      fs.push(...f());
    } catch {
      // One broken analysis (odd old record) must not hide every other alert.
    }
  };
  if (on('milk')) safe(() => milkFindings(d));
  if (on('quality')) safe(() => qualityFindings(d));
  if (on('health')) safe(() => healthFindings(d));
  if (on('breeding')) safe(() => breedingFindings(d));
  if (on('feed') || on('inventory')) safe(() => feedFindings(d));
  if (on('inventory')) safe(() => drugFindings(d));
  if (on('finance') && seesMoney(opts.role)) safe(() => financeFindings(d));
  const visible = fs.filter((f) => (f.module === 'finance' ? seesMoney(opts.role) : true));
  return rankFindings(visible)
    .filter((f) => opts.states?.get(f.id)?.status !== 'resolved')
    .map((f) => ({ ...f, state: opts.states?.get(f.id)?.status === 'acknowledged' ? 'acknowledged' : 'new' }));
}

export function countBySeverity(fs: Finding[]): Record<Severity, number> {
  const out: Record<Severity, number> = { critical: 0, high: 0, medium: 0, low: 0 };
  for (const f of fs) out[f.severity]++;
  return out;
}

/** Today's insights: the most serious new findings, then acknowledged ones. */
export function todaysInsights(fs: FindingWithState[], n: number): FindingWithState[] {
  return [...fs.filter((f) => f.state === 'new'), ...fs.filter((f) => f.state !== 'new')].slice(0, n);
}

export const severityLabel: Record<Severity, string> = { critical: 'Critical', high: 'High', medium: 'Medium', low: 'Low' };
