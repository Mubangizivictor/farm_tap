'use client';

// Send the control panel's lists to Victor's own Google Sheet (free, no Blaze).
// The sheet holds a small Google Apps Script web app (docs/GOOGLE_SHEETS.md);
// the panel posts the data to it with a secret word, and the script writes one
// tab per list: Farms, Payments, Users, Audit log. Each send replaces the old rows.
//
// Nothing here runs on a server: the admin's browser builds the lists from what
// that admin may already read, so the sheet never gets more than the panel shows.

import { collection, getDocs } from 'firebase/firestore';
import { loadAllFarms, loadAudit, loadPayments, loadPlans, paymentMethods } from './admin.ts';
import { farmStatus, planOf } from './adminView.ts';
import { firebase } from './firebase.ts';
import { date } from './format.ts';
import { sectorName } from './labels.ts';
import type { Permission } from './platform.ts';

export interface SheetsSettings {
  /** The Apps Script web app link (https://script.google.com/macros/s/…/exec). */
  url: string;
  /** Must match SECRET in the script. */
  secret: string;
  /** Send by itself when an admin opens the Overview (at most once an hour per browser). */
  auto: boolean;
}

export const sheetsUrlOk = (url: string) => /^https:\/\/script\.google\.com\/macros\/s\/[\w-]+\/exec$/.test(url.trim());

type Cell = string | number;
interface Tab {
  headers: string[];
  rows: Cell[][];
}

const LAST_KEY = 'farmtap.sheets.lastSent';

/** Builds every list the signed-in admin may read. A list they may not read is left out, not an error. */
export async function buildTabs(can: (p: Permission) => boolean): Promise<Record<string, Tab>> {
  const tabs: Record<string, Tab> = {};
  const now = new Date();
  const seeFarms = can('farms') || can('finance') || can('support') || can('users');
  const [farms, plans] = await Promise.all([seeFarms ? loadAllFarms().catch(() => []) : Promise.resolve([]), loadPlans().catch(() => [])]);
  if (seeFarms)
    tabs.Farms = {
      headers: ['Farm', 'Sector', 'Type', 'District', 'Owner', 'Email', 'WhatsApp', 'Status', 'Plan', 'Trial ends', 'Paid until', 'Created', 'Last seen', 'ID'],
      rows: farms.map((f) => [
        f.name,
        sectorName[f.sector] ?? f.sector,
        f.type,
        f.district,
        f.owner.name,
        f.owner.email,
        f.whatsapp,
        farmStatus(f, now).text,
        planOf(f, plans).name,
        date(f.trialEndsAt),
        date(f.paidUntil),
        date(f.createdAt),
        date(f.lastSeenAt),
        f.id,
      ]),
    };
  if (can('finance')) {
    const pays = await loadPayments().catch(() => null);
    if (pays)
      tabs.Payments = {
        headers: ['Paid on', 'Farm', 'For', 'Amount UGX', 'Method', 'Transaction ID', 'Months', 'SMS credits', 'Paid until', 'Status', 'Recorded by', 'Note'],
        rows: pays.map((p) => [date(p.paidAt), p.farmName, p.kind, p.amountUgx, paymentMethods[p.method] ?? p.method, p.reference, p.months, p.smsCredits, date(p.newPaidUntil), p.status, p.recordedByName, p.note]),
      };
  }
  if (can('users')) {
    const users = await getDocs(collection(firebase().db, 'users')).catch(() => null);
    if (users) {
      const farmName = new Map(farms.map((f) => [f.id, f.name]));
      const owners = new Map(farms.map((f) => [f.owner.uid, f.owner]));
      tabs.Users = {
        headers: ['Name', 'Email', 'Phone', 'Farms', 'Worker login', 'Disabled', 'ID'],
        rows: users.docs.map((d) => {
          const u = d.data();
          const owner = owners.get(d.id);
          const ms = ((u.memberships as { tenantId: string; role?: string }[] | undefined) ?? []).map((m) => `${farmName.get(m.tenantId) ?? m.tenantId}${m.role ? ` (${m.role})` : ''}`);
          return [String(u.name || owner?.name || ''), String(owner?.email || u.email || ''), String(u.phone ?? ''), ms.join(', '), u.staffLogin ? 'Yes' : 'No', u.disabled === true ? 'Yes' : 'No', d.id];
        }),
      };
    }
  }
  if (can('audit')) {
    const audit = await loadAudit(2000).catch(() => null);
    if (audit)
      tabs['Audit log'] = {
        headers: ['Time', 'Who', 'Action', 'Target', 'Details'],
        rows: audit.map((e) => [date(e.at), e.byName, e.action, e.target, Object.keys(e.details).length ? JSON.stringify(e.details).slice(0, 2000) : '']),
      };
  }
  return tabs;
}

/** Posts the lists to the sheet. Throws a plain-words Error when it did not work. */
export async function sendToSheets(s: SheetsSettings, can: (p: Permission) => boolean, by: string): Promise<string[]> {
  if (!sheetsUrlOk(s.url)) throw new Error('The Google Sheets link is not set, or it is not a web app link ending in /exec.');
  if (!s.secret) throw new Error('The secret word is missing.');
  const tabs = await buildTabs(can);
  let res: Response;
  try {
    // text/plain keeps this a simple request, which Apps Script accepts from a browser.
    res = await fetch(s.url.trim(), { method: 'POST', headers: { 'Content-Type': 'text/plain;charset=utf-8' }, body: JSON.stringify({ secret: s.secret, by, tabs }) });
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

/** True when this browser has not sent in the last hour (for the automatic send). */
export function sheetsDue(): boolean {
  try {
    const last = Number(localStorage.getItem(LAST_KEY) ?? 0);
    return Date.now() - last > 3600_000;
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
