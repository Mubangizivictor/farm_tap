'use client';

// Send the control panel's lists to the owner's own Google Sheet (free, no Blaze).
// The sheet holds a small Google Apps Script web app (docs/GOOGLE_SHEETS.md,
// tools/google-sheets/Code.gs); the panel posts the data to it with a secret
// word, and the script writes one styled tab per list plus an About summary.
// Every send replaces all rows, so removed farms disappear from the sheet on the
// next send. Sends happen on the button, right after any change made in the
// panel, and when the panel is opened (at most every 10 minutes).
//
// Nothing here runs on a server: the admin's browser builds the lists from what
// that admin may already read, so the sheet never gets more than the panel shows.

import { collection, getDocs } from 'firebase/firestore';
import { loadAllFarms, loadAudit, loadPayments, loadPlans, paymentMethods } from './admin.ts';
import { farmPlan, farmStatus, planOf } from './adminView.ts';
import { firebase } from './firebase.ts';
import { sectorName } from './labels.ts';
import type { Permission } from './platform.ts';

export interface SheetsSettings {
  /** The Apps Script web app link (https://script.google.com/macros/s/…/exec). */
  url: string;
  /** Must match SECRET in the script. */
  secret: string;
  /** Keep the sheet up to date by itself (after changes, and when the panel opens). */
  auto: boolean;
}

export const sheetsUrlOk = (url: string) => /^https:\/\/script\.google\.com\/macros\/s\/[\w-]+\/exec$/.test(url.trim());

type Cell = string | number;
/** How the script formats a column: plain text, a count, money, a date, or a date and time. */
export type ColType = 'text' | 'number' | 'ugx' | 'date' | 'datetime' | 'status';

interface Tab {
  headers: string[];
  types: ColType[];
  rows: Cell[][];
}

const LAST_KEY = 'farmtap.sheets.lastSent';
/** Opening the panel sends again only if the last send is older than this. */
export const SHEETS_REFRESH_MS = 10 * 60_000;

/** "2026-11-07" (the script turns it into a real date cell). */
const day = (d: Date | null) => (d ? `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}` : '');
const when = (d: Date | null) => (d ? d.toISOString() : '');

export interface SheetsData {
  tabs: Record<string, Tab>;
  /** Headline numbers for the About tab. */
  summary: [string, Cell, ColType][];
}

/** Builds every list the signed-in admin may read. A list they may not read is left out, not an error. */
export async function buildTabs(can: (p: Permission) => boolean): Promise<SheetsData> {
  const tabs: Record<string, Tab> = {};
  const summary: [string, Cell, ColType][] = [];
  const now = new Date();
  const seeFarms = can('farms') || can('finance') || can('support') || can('users');
  const [allFarms, plans] = await Promise.all([seeFarms ? loadAllFarms().catch(() => []) : Promise.resolve([]), loadPlans().catch(() => [])]);
  // Removed farms (demo, fake, deleted accounts) are left out completely.
  const farms = allFarms.filter((f) => !f.closed);
  if (seeFarms) {
    tabs.Farms = {
      headers: ['Farm', 'Status', 'Plan', 'Sector', 'Type', 'District', 'Owner', 'Email', 'WhatsApp', 'Trial ends', 'Paid until', 'Joined', 'Last seen', 'Farm ID'],
      types: ['text', 'status', 'text', 'text', 'text', 'text', 'text', 'text', 'text', 'date', 'date', 'date', 'datetime', 'text'],
      rows: farms.map((f) => [
        f.name,
        farmStatus(f, now).text,
        planOf(f, plans).name,
        sectorName[f.sector] ?? f.sector,
        f.type === 'centre' ? 'Collection centre' : f.type === 'both' ? 'Farm and centre' : 'Farm',
        f.district,
        f.owner.name,
        f.owner.email,
        f.whatsapp,
        day(f.trialEndsAt),
        day(f.paidUntil),
        day(f.createdAt),
        when(f.lastSeenAt),
        f.id,
      ]),
    };
    const live = farms.filter((f) => f.status !== 'suspended');
    summary.push(['Farms', farms.length, 'number']);
    summary.push(['Paying', live.filter((f) => ['paid', 'grace'].includes(farmPlan(f, now).kind)).length, 'number']);
    summary.push(['On trial', live.filter((f) => farmPlan(f, now).kind === 'trial').length, 'number']);
    summary.push(['Waiting for review', farms.filter((f) => f.review === 'pending').length, 'number']);
  }
  if (can('finance')) {
    const pays = await loadPayments().catch(() => null);
    if (pays) {
      tabs.Payments = {
        headers: ['Paid on', 'Farm', 'Amount', 'For', 'Method', 'Transaction ID', 'Months', 'SMS credits', 'Paid until', 'Status', 'Recorded by', 'Note'],
        types: ['date', 'text', 'ugx', 'text', 'text', 'text', 'number', 'number', 'date', 'status', 'text', 'text'],
        rows: pays.map((p) => [
          day(p.paidAt),
          p.farmName,
          p.amountUgx,
          p.kind === 'sms' ? 'SMS credits' : 'Plan',
          paymentMethods[p.method] ?? p.method,
          p.reference,
          p.months,
          p.smsCredits,
          day(p.newPaidUntil),
          p.status === 'void' ? 'Void' : 'Received',
          p.recordedByName,
          p.note,
        ]),
      };
      const ok = pays.filter((p) => p.status === 'received');
      const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);
      summary.push(['Received this month', ok.filter((p) => p.paidAt && p.paidAt >= monthStart).reduce((t, p) => t + p.amountUgx, 0), 'ugx']);
      summary.push(['Received in total', ok.reduce((t, p) => t + p.amountUgx, 0), 'ugx']);
    }
  }
  if (can('users')) {
    const users = await getDocs(collection(firebase().db, 'users')).catch(() => null);
    if (users) {
      const farmName = new Map(farms.map((f) => [f.id, f.name]));
      const removed = new Set(allFarms.filter((f) => f.closed).map((f) => f.id));
      const owners = new Map(allFarms.map((f) => [f.owner.uid, f.owner]));
      const rows: Cell[][] = [];
      for (const d of users.docs) {
        const u = d.data();
        const ms = ((u.memberships as { tenantId: string; role?: string }[] | undefined) ?? []).filter((m) => !removed.has(m.tenantId));
        // People whose only farms were removed (demo accounts) are left out too.
        if (!ms.length && (u.memberships as unknown[] | undefined)?.length) continue;
        if (u.deletion) continue;
        const owner = owners.get(d.id);
        rows.push([
          String(u.name || owner?.name || ''),
          String(owner?.email || u.email || ''),
          String(u.phone ?? ''),
          ms.map((m) => `${farmName.get(m.tenantId) ?? m.tenantId}${m.role ? ` (${m.role})` : ''}`).join(', '),
          u.staffLogin ? 'Worker login' : 'Account',
          u.disabled === true ? 'Disabled' : 'Active',
          d.id,
        ]);
      }
      tabs.Users = {
        headers: ['Name', 'Email', 'Phone', 'Farms', 'Kind', 'Status', 'User ID'],
        types: ['text', 'text', 'text', 'text', 'text', 'status', 'text'],
        rows,
      };
      summary.push(['People with an account', rows.length, 'number']);
    }
  }
  if (can('audit')) {
    const audit = await loadAudit(2000).catch(() => null);
    if (audit)
      tabs['Audit log'] = {
        headers: ['Time', 'Who', 'Action', 'Target', 'Details'],
        types: ['datetime', 'text', 'text', 'text', 'text'],
        rows: audit.map((e) => [when(e.at), e.byName, e.action, e.target, Object.keys(e.details).length ? JSON.stringify(e.details).slice(0, 2000) : '']),
      };
  }
  return { tabs, summary };
}

/** Posts the lists to the sheet. Throws a plain-words Error when it did not work. */
export async function sendToSheets(s: SheetsSettings, can: (p: Permission) => boolean, by: string): Promise<string[]> {
  if (!sheetsUrlOk(s.url)) throw new Error('The Google Sheets link is not set, or it is not a web app link ending in /exec.');
  if (!s.secret) throw new Error('The secret word is missing.');
  const { tabs, summary } = await buildTabs(can);
  let res: Response;
  try {
    // text/plain keeps this a simple request, which Apps Script accepts from a browser.
    res = await fetch(s.url.trim(), { method: 'POST', headers: { 'Content-Type': 'text/plain;charset=utf-8' }, body: JSON.stringify({ secret: s.secret, by, tabs, summary }) });
  } catch {
    throw new Error('Could not reach Google Sheets. Check the internet, or that the web app is deployed with access "Anyone".');
  }
  const out = (await res.json().catch(() => null)) as { ok?: boolean; tabs?: string[]; error?: string } | null;
  if (!out?.ok) throw new Error(out?.error === 'wrong secret' ? 'Google Sheets refused the secret word. It must match SECRET in the script.' : 'Google Sheets did not accept the data. Open the web app link to check it is live.');
  try {
    localStorage.setItem(LAST_KEY, String(Date.now()));
  } catch {
    /* fine */
  }
  return out.tabs ?? [];
}

/** True when this browser has not sent recently (for the send on opening the panel). */
export function sheetsDue(): boolean {
  try {
    const last = Number(localStorage.getItem(LAST_KEY) ?? 0);
    return Date.now() - last > SHEETS_REFRESH_MS;
  } catch {
    return false;
  }
}

export function lastSent(): Date | null {
  try {
    const last = Number(localStorage.getItem(LAST_KEY) ?? 0);
    return last ? new Date(last) : null;
  } catch {
    return null;
  }
}
