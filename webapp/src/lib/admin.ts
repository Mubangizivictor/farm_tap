'use client';

// Control panel data (decision 0020). Every change goes through
// adminChange(), which writes the change and its adminAudit entry in one
// batch; firestore.rules refuse an admin write without that entry.

import {
  collection,
  doc,
  getDoc,
  getDocs,
  limit,
  orderBy,
  query,
  serverTimestamp,
  writeBatch,
  type DocumentReference,
  type WriteBatch,
} from 'firebase/firestore';
import { localIso, parseDate } from './dates.ts';
import { firebase } from './firebase.ts';
import { configFromDoc, planFromDoc, smsPackageFromDoc, type FeatureMap, type Permission } from './platform.ts';

export interface AuditInfo {
  action: string;
  target: string;
  tenantId?: string | null;
  details?: Record<string, unknown>;
}

export type Op = (b: WriteBatch, auditId: string) => void;

/** Runs [ops] and the audit entry they need, all or nothing. */
export async function adminChange(me: { uid: string; name: string }, info: AuditInfo, ops: Op[]): Promise<string> {
  const { db } = firebase();
  const b = writeBatch(db);
  const audit = doc(collection(db, 'adminAudit'));
  b.set(audit, {
    by: me.uid,
    byName: me.name,
    at: serverTimestamp(),
    action: info.action,
    target: info.target,
    tenantId: info.tenantId ?? null,
    details: clean(info.details ?? {}),
  });
  for (const op of ops) op(b, audit.id);
  await b.commit();
  return audit.id;
}

/** Firestore refuses `undefined`; drop those keys. */
function clean(o: Record<string, unknown>): Record<string, unknown> {
  return Object.fromEntries(Object.entries(o).filter(([, v]) => v !== undefined));
}

export const setOp =
  (ref: DocumentReference, data: Record<string, unknown>, merge = true): Op =>
  (b, id) =>
    b.set(ref, { ...clean(data), lastAudit: id }, { merge });

export const updateOp =
  (ref: DocumentReference, data: Record<string, unknown>): Op =>
  (b, id) =>
    b.update(ref, { ...clean(data), lastAudit: id });

// ---------------------------------------------------------------- Reads

export async function loadConfig() {
  const snap = await getDoc(doc(firebase().db, 'platform', 'config'));
  return { config: configFromDoc(snap.data()), exists: snap.exists() };
}

export interface SecretInfo {
  last4: string;
  setAt: Date | null;
  setByName: string;
}

export interface Integrations {
  sms: { provider: 'none' | 'africastalking' | 'twilio'; username: string; senderId: string };
  payments: { mode: 'sandbox' | 'live'; callbackUrl: string; mtnEnvironment: string; airtelCountry: string };
  maps: { provider: string };
  secrets: Record<string, SecretInfo>;
}

export async function loadIntegrations(): Promise<Integrations> {
  const d = (await getDoc(doc(firebase().db, 'platform', 'integrations'))).data() ?? {};
  const sms = (d.sms ?? {}) as Record<string, string>;
  const pay = (d.payments ?? {}) as Record<string, string>;
  const secrets: Record<string, SecretInfo> = {};
  for (const [k, v] of Object.entries((d.secrets ?? {}) as Record<string, Record<string, unknown>>)) {
    secrets[k] = { last4: String(v.last4 ?? ''), setAt: parseDate(v.setAt), setByName: String(v.setByName ?? '') };
  }
  return {
    sms: {
      provider: (['africastalking', 'twilio'].includes(sms.provider) ? sms.provider : 'none') as Integrations['sms']['provider'],
      username: sms.username ?? '',
      senderId: sms.senderId ?? '',
    },
    payments: {
      mode: pay.mode === 'live' ? 'live' : 'sandbox',
      callbackUrl: pay.callbackUrl ?? '',
      mtnEnvironment: pay.mtnEnvironment ?? 'sandbox',
      airtelCountry: pay.airtelCountry ?? 'UG',
    },
    maps: { provider: ((d.maps ?? {}) as Record<string, string>).provider ?? 'none' },
    secrets,
  };
}

export async function loadPlans() {
  const snap = await getDocs(collection(firebase().db, 'plans'));
  return snap.docs.map((d) => planFromDoc(d.id, d.data())).sort((a, b) => a.sort - b.sort || a.priceUgx - b.priceUgx);
}

export async function loadSmsPackages() {
  const snap = await getDocs(collection(firebase().db, 'smsPackages'));
  return snap.docs.map((d) => smsPackageFromDoc(d.id, d.data())).sort((a, b) => a.credits - b.credits);
}

// ---------------------------------------------------------------- Farms

export interface AdminFarm {
  id: string;
  name: string;
  sector: string;
  type: string;
  district: string;
  village: string;
  cows: number | null;
  owner: { uid: string; name: string; email: string };
  whatsapp: string;
  sms: string;
  trialStartedAt: Date | null;
  trialEndsAt: Date | null;
  paidUntil: Date | null;
  review: string;
  reviewNote: string;
  status: 'active' | 'suspended';
  suspendedReason: string;
  planId: string;
  features: FeatureMap;
  smsCredits: number;
  autoSend: boolean;
  createdAt: Date | null;
  lastSeenAt: Date | null;
}

export function adminFarmFromDoc(id: string, t: Record<string, unknown>): AdminFarm {
  const sub = (t.subscription ?? {}) as Record<string, unknown>;
  const owner = (t.owner ?? {}) as Record<string, string>;
  const contacts = (t.contacts ?? {}) as Record<string, string>;
  const review = (t.review ?? {}) as Record<string, string>;
  const messaging = (t.messaging ?? {}) as Record<string, unknown>;
  return {
    id,
    name: (t.name as string) || 'No name',
    sector: (t.sector as string) ?? 'dairy',
    type: (t.type as string) ?? 'farm',
    district: (t.district as string) ?? (t.place as string) ?? '',
    village: (t.village as string) ?? '',
    cows: typeof t.cows === 'number' ? t.cows : null,
    owner: { uid: owner.uid ?? (t.ownerUid as string) ?? '', name: owner.name ?? '', email: owner.email ?? '' },
    whatsapp: contacts.whatsapp ?? '',
    sms: contacts.sms ?? '',
    trialStartedAt: parseDate(sub.trialStartedAt),
    trialEndsAt: parseDate(sub.trialEndsAt),
    paidUntil: parseDate(sub.paidUntil),
    review: review.status ?? '',
    reviewNote: review.note ?? '',
    status: t.status === 'suspended' ? 'suspended' : 'active',
    suspendedReason: (t.suspendedReason as string) ?? '',
    planId: (t.planId as string) ?? '',
    features: (t.features ?? {}) as FeatureMap,
    smsCredits: typeof t.smsCredits === 'number' ? t.smsCredits : 0,
    autoSend: messaging.autoSend === true,
    createdAt: parseDate(t.createdAt),
    lastSeenAt: parseDate(t.lastSeenAt),
  };
}

export async function loadAllFarms(): Promise<AdminFarm[]> {
  const snap = await getDocs(collection(firebase().db, 'tenants'));
  return snap.docs.map((d) => adminFarmFromDoc(d.id, d.data())).sort((a, b) => (b.createdAt?.getTime() ?? 0) - (a.createdAt?.getTime() ?? 0));
}

export async function loadFarm(id: string): Promise<AdminFarm | null> {
  const snap = await getDoc(doc(firebase().db, 'tenants', id));
  return snap.exists() ? adminFarmFromDoc(id, snap.data()) : null;
}

/** Counts and the last record in a farm collection (read-only look). */
export async function farmCollection(tenantId: string, name: string, n = 50) {
  const { db } = firebase();
  const snap = await getDocs(query(collection(db, 'tenants', tenantId, name), orderBy('serverUpdatedAt', 'desc'), limit(n)));
  return snap.docs.map((d) => d.data() as { id: string; body: Record<string, unknown>; createdAt: string; isDeleted: boolean; version: number; createdBy: string; serverUpdatedAt?: unknown });
}

export async function farmMembers(tenantId: string) {
  const snap = await getDocs(collection(firebase().db, 'tenants', tenantId, 'members'));
  return snap.docs.map((d) => ({ uid: d.id, ...(d.data() as { role?: string; title?: string; name?: string; staffId?: string }) }));
}

/** Writes one farm record's next version (support: PIN reset, card revoke). */
export function recordNextVersion(tenantId: string, c: string, rec: { id: string; version: number; createdBy: string; createdAt: string; body: Record<string, unknown>; deviceId?: string; isDeleted?: boolean }, body: Record<string, unknown>, uid: string): Op {
  const { db } = firebase();
  return (b, auditId) =>
    b.set(doc(db, 'tenants', tenantId, c, rec.id), {
      id: rec.id,
      tenantId,
      collection: c,
      body: { ...rec.body, ...body },
      createdAt: rec.createdAt,
      updatedAt: localIso(new Date()),
      createdBy: rec.createdBy,
      updatedBy: `admin:${uid}`,
      deviceId: 'web-admin',
      version: rec.version + 1,
      isDeleted: rec.isDeleted ?? false,
      serverUpdatedAt: serverTimestamp(),
      lastAudit: auditId,
    });
}

// ---------------------------------------------------------------- PIN hash

/**
 * Same as the phone's PinHasher (lib/core/people/data/pin_security.dart):
 * PBKDF2-HMAC-SHA256, 16-byte salt, 32-byte key, 2000 rounds,
 * stored as pbkdf2-sha256$<rounds>$<salt b64>$<key b64>.
 */
export async function hashPin(pin: string, rounds = 2000): Promise<string> {
  const salt = crypto.getRandomValues(new Uint8Array(16));
  const key = await crypto.subtle.importKey('raw', new TextEncoder().encode(pin), 'PBKDF2', false, ['deriveBits']);
  const bits = await crypto.subtle.deriveBits({ name: 'PBKDF2', hash: 'SHA-256', salt, iterations: rounds }, key, 256);
  const b64 = (u: Uint8Array) => btoa(String.fromCharCode(...u));
  return `pbkdf2-sha256$${rounds}$${b64(salt)}$${b64(new Uint8Array(bits))}`;
}

export const randomPin = () => String(crypto.getRandomValues(new Uint32Array(1))[0] % 10000).padStart(4, '0');

// ---------------------------------------------------------------- Payments

export interface PlatformPayment {
  id: string;
  tenantId: string;
  farmName: string;
  kind: 'subscription' | 'sms';
  amountUgx: number;
  method: string;
  reference: string;
  planId: string;
  months: number;
  smsCredits: number;
  paidAt: Date | null;
  newPaidUntil: Date | null;
  status: 'received' | 'void';
  voidReason: string;
  recordedByName: string;
  note: string;
}

export async function loadPayments(): Promise<PlatformPayment[]> {
  const snap = await getDocs(collection(firebase().db, 'platformPayments'));
  return snap.docs
    .map((d) => {
      const p = d.data();
      return {
        id: d.id,
        tenantId: p.tenantId ?? '',
        farmName: p.farmName ?? '',
        kind: p.kind === 'sms' ? 'sms' : 'subscription',
        amountUgx: Number(p.amountUgx) || 0,
        method: p.method ?? '',
        reference: p.reference ?? '',
        planId: p.planId ?? '',
        months: Number(p.months) || 0,
        smsCredits: Number(p.smsCredits) || 0,
        paidAt: parseDate(p.paidAt),
        newPaidUntil: parseDate(p.newPaidUntil),
        status: p.status === 'void' ? 'void' : 'received',
        voidReason: p.voidReason ?? '',
        recordedByName: p.recordedByName ?? '',
        note: p.note ?? '',
      } satisfies PlatformPayment;
    })
    .sort((a, b) => (b.paidAt?.getTime() ?? 0) - (a.paidAt?.getTime() ?? 0));
}

export const paymentMethods: Record<string, string> = {
  mtn: 'MTN MoMo',
  airtel: 'Airtel Money',
  card: 'Card',
  bank: 'Bank',
  cash: 'Cash',
};

/** New paid-until: from today, or from the current paid-until if still in the future. */
export function extendPaidUntil(current: Date | null, months: number, now: Date): Date {
  const base = current && current > now ? new Date(current) : new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const out = new Date(base);
  out.setMonth(out.getMonth() + months);
  return out;
}

// ---------------------------------------------------------------- Staff

export interface AdminStaff {
  uid: string;
  role: string;
  perms: Permission[];
  active: boolean;
  name: string;
  email: string;
}

export async function loadStaff(): Promise<AdminStaff[]> {
  const snap = await getDocs(collection(firebase().db, 'platformAdmins'));
  return snap.docs.map((d) => {
    const s = d.data();
    return { uid: d.id, role: s.role ?? 'custom', perms: s.perms ?? [], active: s.active === true, name: s.name ?? '', email: s.email ?? '' };
  });
}

export async function loadInvites() {
  const snap = await getDocs(collection(firebase().db, 'adminInvites'));
  return snap.docs.map((d) => ({ email: d.id, ...(d.data() as { role: string; perms: Permission[]; active: boolean; name?: string }) }));
}

// ---------------------------------------------------------------- Audit

export interface AuditEntry {
  id: string;
  by: string;
  byName: string;
  at: Date | null;
  action: string;
  target: string;
  tenantId: string | null;
  details: Record<string, unknown>;
}

export async function loadAudit(n = 300): Promise<AuditEntry[]> {
  const snap = await getDocs(query(collection(firebase().db, 'adminAudit'), orderBy('at', 'desc'), limit(n)));
  return snap.docs.map((d) => {
    const a = d.data();
    return { id: d.id, by: a.by, byName: a.byName ?? '', at: parseDate(a.at), action: a.action, target: a.target ?? '', tenantId: a.tenantId ?? null, details: a.details ?? {} };
  });
}

export { downloadCsv } from './csv.ts';
