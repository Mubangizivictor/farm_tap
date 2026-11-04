// Shared server helpers: the database, the switches in platform/config.server
// and the keys in platformSecrets (decision 0024).
//
// Every job that costs money or needs the Blaze plan checks its switch first,
// so deploying the code changes nothing until it is switched on
// (tool/activate-blaze.sh switches them all on at once).

import { getFirestore, type Firestore } from 'firebase-admin/firestore';

export const db = (): Firestore => getFirestore();

export type ServerSwitch = 'alerts' | 'autoSms' | 'whatsappApi' | 'billingPdf' | 'refundsApi' | 'accountErase';

export const serverSwitches: { key: ServerSwitch; label: string }[] = [
  { key: 'alerts', label: 'Daily reminders (phone notifications, SMS and WhatsApp queue)' },
  { key: 'autoSms', label: 'Automatic SMS through the SMS company' },
  { key: 'whatsappApi', label: 'Automatic WhatsApp through the WhatsApp Business API' },
  { key: 'billingPdf', label: 'Receipt and invoice PDF files stored on the server' },
  { key: 'refundsApi', label: 'Refunds sent through MTN, Airtel or Flutterwave' },
  { key: 'accountErase', label: 'Deleted accounts erased after 90 days' },
];

/** platform/config.server.<key> == true. */
export async function switchOn(key: ServerSwitch): Promise<boolean> {
  const v = (await db().doc('platform/config').get()).get(`server.${key}`);
  return v === true;
}

export async function secret(name: string): Promise<string> {
  const v = (await db().doc(`platformSecrets/${name}`).get()).get('value');
  return typeof v === 'string' ? v.trim() : '';
}

/** platform/integrations (provider names, usernames: not secret). */
export async function integrations(): Promise<Record<string, Record<string, unknown>>> {
  return ((await db().doc('platform/integrations').get()).data() ?? {}) as Record<string, Record<string, unknown>>;
}
