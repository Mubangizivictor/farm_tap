// Daily reminders (decision 0024): duties, vaccinations, calving, heat,
// pregnancy checks and the trial or plan ending. Every hour, farms whose
// reminder hour (Kampala) has come get:
//   - a phone notification to the people it is for (owner and managers, or
//     the worker on duty when they sign in on their own phone), and
//   - a WhatsApp or SMS in the farm's "Messages to send" (smsOutbox, queued),
//     sent from the phone for free or automatically when paid SMS is on.
// The phone works out the same reminders with the same ids, so a reminder is
// never sent twice. Off until platform/config.server.alerts is true.

import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';
import { logger } from 'firebase-functions';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { alertSettingsFrom, alertText, alertsFor, kampalaToday, type FarmAlert, type Rec } from './shared/alerts';
import { db, switchOn } from './server';

const iso = (v: unknown): string | null => (v instanceof Timestamp ? v.toDate().toISOString() : typeof v === 'string' ? v : null);

async function records<B>(t: string, c: string): Promise<Rec<B>[]> {
  const s = await db().collection(`tenants/${t}/${c}`).where('isDeleted', '==', false).get();
  return s.docs.map((d) => ({ id: d.id, isDeleted: false, body: (d.get('body') ?? {}) as B }));
}

/** International number for an outbox record: "0772 451908" -> "+256772451908". */
export function intl(phone: string): string {
  const d = phone.replace(/\D/g, '');
  if (!d) return '';
  if (phone.trim().startsWith('+') || d.startsWith('256')) return `+${d}`;
  if (d.startsWith('0') && d.length === 10) return `+256${d.slice(1)}`;
  if (d.length === 9) return `+256${d}`;
  return `+${d}`;
}

/** Works out and delivers one farm's reminders for [today]. Returns how many were new. */
export async function runFarmAlerts(t: string, today: string, opts: { push?: boolean } = {}): Promise<number> {
  const tenantSnap = await db().doc(`tenants/${t}`).get();
  const tenant = tenantSnap.data() ?? {};
  if (tenant.status === 'suspended' || tenant.closure) return 0;
  const [settingsDoc, duties, absences, vaccinations, breeding, animals, staff, members] = await Promise.all([
    db().doc(`tenants/${t}/settings/alerts`).get(),
    records<never>(t, 'duties'),
    records<never>(t, 'absences'),
    records<never>(t, 'vaccinations'),
    records<never>(t, 'breedingEvents'),
    records<never>(t, 'animals'),
    records<{ name?: string; phone?: string; role?: string }>(t, 'staff'),
    db().collection(`tenants/${t}/members`).get(),
  ]);
  const settings = alertSettingsFrom(settingsDoc.get('body'));
  const sub = (tenant.subscription ?? {}) as Record<string, unknown>;
  const alerts = alertsFor({
    today,
    duties,
    absences,
    vaccinations,
    breeding,
    animals,
    staffNames: Object.fromEntries(staff.map((s) => [s.id, s.body.name ?? ''])),
    trialEndsAt: iso(sub.trialEndsAt),
    paidUntil: iso(sub.paidUntil),
    settings,
  });
  if (!alerts.length) return 0;

  const managers = members.docs.filter((m) => ['owner', 'manager'].includes(String(m.get('role'))) && !m.get('staffId')).map((m) => m.id);
  const staffUid = new Map(members.docs.filter((m) => m.get('staffId')).map((m) => [String(m.get('staffId')), m.id]));
  const farmPhone = String((tenant.contacts as Record<string, unknown> | undefined)?.whatsapp ?? (tenant.contacts as Record<string, unknown> | undefined)?.sms ?? '');
  let fresh = 0;
  for (const a of alerts) {
    // One delivery per reminder, whoever (server or phone) gets there first.
    try {
      await db().doc(`tenants/${t}/alertLog/${a.id}`).create({ kind: a.kind, title: a.title, at: FieldValue.serverTimestamp() });
    } catch {
      continue;
    }
    fresh++;
    if (settings.push && opts.push !== false) await pushAlert(t, a, a.staffIds.map((s) => staffUid.get(s)).filter((u): u is string => !!u), managers);
    if (settings.whatsapp || settings.sms) {
      const to = a.staffIds.length ? (staff.find((s) => s.id === a.staffIds[0])?.body.phone ?? '') : farmPhone;
      if (intl(to)) await queueMessage(t, a, String(tenant.name ?? ''), intl(to), settings.whatsapp ? 'whatsapp' : 'sms', a.staffIds.length ? (staff.find((s) => s.id === a.staffIds[0])?.body.name ?? '') : '');
    }
  }
  return fresh;
}

async function queueMessage(t: string, a: FarmAlert, farmName: string, to: string, via: 'whatsapp' | 'sms', name: string) {
  const id = `alert-${a.id}`;
  const now = new Date().toISOString();
  try {
    await db().doc(`tenants/${t}/smsOutbox/${id}`).create({
      id,
      tenantId: t,
      collection: 'smsOutbox',
      body: { to, text: alertText(a, farmName), kind: `alert.${a.kind}`, status: 'queued', via, ...(name ? { name } : {}) },
      createdAt: now,
      updatedAt: now,
      createdBy: 'server',
      updatedBy: 'server',
      deviceId: 'server',
      version: 1,
      isDeleted: false,
      serverUpdatedAt: FieldValue.serverTimestamp(),
    });
  } catch {
    // The phone queued it already.
  }
}

/** Phone notification to the worker's own phone, else the owner and managers. */
async function pushAlert(t: string, a: FarmAlert, staffUids: string[], managers: string[]) {
  const uids = staffUids.length ? [...staffUids, ...(a.kind === 'duty' ? [] : managers)] : managers;
  const tokens: string[] = [];
  for (const uid of new Set(uids)) {
    const devices = await db().collection(`users/${uid}/devices`).get();
    for (const d of devices.docs) if (typeof d.get('token') === 'string') tokens.push(d.get('token'));
  }
  if (!tokens.length) return;
  try {
    const r = await getMessaging().sendEachForMulticast({
      tokens,
      notification: { title: a.title, body: a.body },
      data: { tenantId: t, kind: a.kind, alertId: a.id },
      android: { priority: 'high', notification: { channelId: 'farm_reminders' } },
      apns: { payload: { aps: { sound: 'default' } } },
    });
    // Forget phones that uninstalled the app.
    r.responses.forEach((res, i) => {
      const code = res.error?.code ?? '';
      if (code.includes('registration-token-not-registered') || code.includes('invalid-registration-token')) {
        void db().collectionGroup('devices').where('token', '==', tokens[i]).get().then((s) => s.docs.forEach((d) => void d.ref.delete()));
      }
    });
  } catch (e) {
    logger.warn('push failed', { t, alert: a.id, error: String(e) });
  }
}

export const farmAlerts = onSchedule({ schedule: '0 * * * *', timeZone: 'Africa/Kampala', timeoutSeconds: 540 }, async () => {
  if (!(await switchOn('alerts'))) return;
  const now = new Date();
  const today = kampalaToday(now);
  const hour = (now.getUTCHours() + 3) % 24;
  const farms = await db().collection('tenants').get();
  for (const f of farms.docs) {
    const want = (await db().doc(`tenants/${f.id}/settings/alerts`).get()).get('body.hour');
    if ((typeof want === 'number' ? want : 6) !== hour) continue;
    try {
      await runFarmAlerts(f.id, today);
    } catch (e) {
      logger.warn('farm alerts failed', { t: f.id, error: String(e) });
    }
  }
});
