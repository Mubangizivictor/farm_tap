'use client';

// Control panel data for the launch pack (decision 0024): receipts and their
// numbers, refunds, account deletions (90-day hold and restore), legal
// documents, branding pictures, company details and the website words.
// Every write goes with its adminAudit entry, like adminChange().

import {
  collection,
  doc,
  getDoc,
  getDocs,
  runTransaction,
  serverTimestamp,
  type DocumentData,
  type Transaction,
} from 'firebase/firestore';
import { billingDocForPayment, billingFromDoc, refundDoc, type BillingDoc } from '../shared/billing.ts';
import { DEFAULT_LEGAL, legalFromDoc, type LegalDoc, type LegalKind } from '../shared/legal.ts';
import { adminChange, setOp, updateOp } from './admin.ts';
import { firebase } from './firebase.ts';
import { HOLD_DAYS, restoreDeadline } from './account.ts';

type Actor = { uid: string; name: string };

/** Writes the audit entry inside a transaction and returns its id. */
function auditIn(tx: Transaction, me: Actor, action: string, target: string, tenantId: string | null, details: Record<string, unknown>): string {
  const { db } = firebase();
  const a = doc(collection(db, 'adminAudit'));
  tx.set(a, { by: me.uid, byName: me.name, at: serverTimestamp(), action, target, tenantId, details });
  return a.id;
}

const COUNTER = 'counters/billing';
const nextSeq = (c: DocumentData | undefined) => (typeof c?.next === 'number' && c.next >= 1 ? (c.next as number) : 1);

// ---------------------------------------------------------------- Receipts

/**
 * Gives a payment its receipt and invoice numbers (billingDocs/{paymentId}).
 * The server does the same when it is switched on; whichever runs first
 * wins and the other finds the document already there.
 */
export async function issueBillingDoc(me: Actor, paymentId: string): Promise<BillingDoc | null> {
  const { db } = firebase();
  const pay = (await getDoc(doc(db, 'platformPayments', paymentId))).data();
  if (!pay || pay.status !== 'received') return null;
  const tenant = (await getDoc(doc(db, 'tenants', String(pay.tenantId))).catch(() => null))?.data() ?? {};
  let owner: DocumentData = {};
  try {
    if (tenant.ownerUid) owner = (await getDoc(doc(db, 'users', String(tenant.ownerUid)))).data() ?? {};
  } catch {
    /* no Users access: the farm name is enough */
  }
  return runTransaction(db, async (tx) => {
    const ref = doc(db, 'billingDocs', paymentId);
    const [existing, counter] = await Promise.all([tx.get(ref), tx.get(doc(db, COUNTER))]);
    if (existing.exists()) return billingFromDoc(existing.id, existing.data());
    const seq = nextSeq(counter.data());
    const d = billingDocForPayment(paymentId, pay, tenant, owner, seq, new Date());
    const audit = auditIn(tx, me, 'billing.issue', `billingDocs/${paymentId}`, d.tenantId, { receiptNo: d.receiptNo, seq });
    tx.set(ref, { ...d, id: paymentId, createdAt: serverTimestamp(), createdBy: me.uid, lastAudit: audit });
    tx.set(doc(db, COUNTER), { next: seq + 1, lastDoc: paymentId, lastAudit: audit }, { merge: true });
    return { id: paymentId, ...d };
  });
}

export async function loadAllBillingDocs(): Promise<BillingDoc[]> {
  const s = await getDocs(collection(firebase().db, 'billingDocs'));
  return s.docs.map((d) => billingFromDoc(d.id, d.data())).sort((a, b) => b.seq - a.seq);
}

// ---------------------------------------------------------------- Refunds

export type RefundStatus = 'requested' | 'approved' | 'rejected' | 'sending' | 'sent' | 'failed' | 'done';

export interface Refund {
  id: string;
  paymentId: string;
  tenantId: string;
  farmName: string;
  amountUgx: number;
  method: string;
  /** Number or card the money goes back to. */
  destination: string;
  reason: string;
  status: RefundStatus;
  byHand: boolean;
  reference: string;
  providerRef: string;
  failReason: string;
  refundNo: string;
  refundDocId: string;
  requestedByName: string;
  approvedByName: string;
  createdAt: Date | null;
}

const date = (v: unknown): Date | null => {
  const o = v as { toDate?: () => Date } | null;
  return o && typeof o.toDate === 'function' ? o.toDate() : null;
};

export function refundFromDoc(id: string, d: DocumentData): Refund {
  return {
    id,
    paymentId: String(d.paymentId ?? ''),
    tenantId: String(d.tenantId ?? ''),
    farmName: String(d.farmName ?? ''),
    amountUgx: Number(d.amountUgx) || 0,
    method: String(d.method ?? ''),
    destination: String(d.destination ?? ''),
    reason: String(d.reason ?? ''),
    status: (d.status ?? 'requested') as RefundStatus,
    byHand: d.byHand === true,
    reference: String(d.reference ?? ''),
    providerRef: String(d.providerRef ?? ''),
    failReason: String(d.failReason ?? ''),
    refundNo: String(d.refundNo ?? ''),
    refundDocId: String(d.refundDocId ?? ''),
    requestedByName: String(d.requestedByName ?? ''),
    approvedByName: String(d.approvedByName ?? ''),
    createdAt: date(d.createdAt),
  };
}

export async function loadRefunds(): Promise<Refund[]> {
  const s = await getDocs(collection(firebase().db, 'refunds'));
  return s.docs.map((d) => refundFromDoc(d.id, d.data())).sort((a, b) => (b.createdAt?.getTime() ?? 0) - (a.createdAt?.getTime() ?? 0));
}

export async function requestRefund(
  me: Actor,
  r: { paymentId: string; tenantId: string; farmName: string; amountUgx: number; method: string; destination: string; reason: string; byHand: boolean },
) {
  const ref = doc(collection(firebase().db, 'refunds'));
  await adminChange(me, { action: 'refund.request', target: `refunds/${ref.id}`, tenantId: r.tenantId, details: { amountUgx: r.amountUgx, paymentId: r.paymentId } }, [
    setOp(ref, { ...r, amountUgx: Math.round(r.amountUgx), status: 'requested', requestedBy: me.uid, requestedByName: me.name, createdAt: serverTimestamp() }, false),
  ]);
}

export async function decideRefund(me: Actor, r: Refund, status: 'approved' | 'rejected', note = '') {
  await adminChange(me, { action: `refund.${status}`, target: `refunds/${r.id}`, tenantId: r.tenantId, details: { amountUgx: r.amountUgx, note } }, [
    updateOp(doc(firebase().db, 'refunds', r.id), { status, approvedBy: me.uid, approvedByName: me.name, decidedAt: serverTimestamp(), decisionNote: note }),
  ]);
}

/**
 * Marks a refund paid (by hand, or after the provider sent it) and gives it
 * a numbered refund note in the same step.
 */
export async function completeRefund(me: Actor, r: Refund, reference: string) {
  const { db } = firebase();
  await runTransaction(db, async (tx) => {
    const ref = doc(db, 'refunds', r.id);
    const [cur, of, counter] = await Promise.all([tx.get(ref), tx.get(doc(db, 'billingDocs', r.paymentId)), tx.get(doc(db, COUNTER))]);
    const d = cur.data() ?? {};
    if (!['approved', 'failed', 'sent'].includes(String(d.status))) throw Object.assign(new Error('changed'), { code: 'failed-precondition' });
    const audit = auditIn(tx, me, 'refund.done', `refunds/${r.id}`, r.tenantId, { amountUgx: r.amountUgx, reference });
    const patch: Record<string, unknown> = { status: 'done', reference: reference.trim(), doneAt: serverTimestamp(), doneByName: me.name, lastAudit: audit };
    if (of.exists() && !d.refundDocId) {
      const seq = nextSeq(counter.data());
      const noteId = `refund-${r.id}`;
      const note = refundDoc(billingFromDoc(of.id, of.data()), r.id, r.amountUgx, seq, r.method, reference.trim() || r.providerRef, r.reason, new Date());
      tx.set(doc(db, 'billingDocs', noteId), { ...note, id: noteId, createdAt: serverTimestamp(), createdBy: me.uid, lastAudit: audit });
      tx.set(doc(db, COUNTER), { next: seq + 1, lastDoc: noteId, lastAudit: audit }, { merge: true });
      patch.refundDocId = noteId;
      patch.refundNo = note.refundNo;
    }
    tx.update(ref, patch);
  });
}

// ---------------------------------------------------------------- Deletions

export type DeletionStatus = 'closed' | 'requested' | 'verified' | 'restored' | 'rejected' | 'erased';

export interface Deletion {
  id: string;
  uid: string | null;
  name: string;
  email: string;
  phone: string;
  farmName: string;
  reason: string;
  status: DeletionStatus;
  source: string;
  farms: string[];
  closedAt: Date | null;
  createdAt: Date | null;
  /** Last day it can be restored (closed accounts). */
  restoreBy: Date | null;
  daysLeft: number | null;
  handledByName: string;
  note: string;
}

export function deletionFromDoc(id: string, d: DocumentData, now = new Date()): Deletion {
  const closedAt = date(d.closedAt);
  const by = restoreDeadline(closedAt);
  return {
    id,
    uid: typeof d.uid === 'string' ? d.uid : null,
    name: String(d.name ?? ''),
    email: String(d.email ?? ''),
    phone: String(d.phone ?? ''),
    farmName: String(d.farmName ?? ''),
    reason: String(d.reason ?? ''),
    status: (d.status ?? 'requested') as DeletionStatus,
    source: String(d.source ?? ''),
    farms: Array.isArray(d.farms) ? d.farms.map(String) : [],
    closedAt,
    createdAt: date(d.createdAt) ?? closedAt,
    restoreBy: by,
    daysLeft: by ? Math.max(0, Math.ceil((by.getTime() - now.getTime()) / 86_400_000)) : null,
    handledByName: String(d.handledByName ?? ''),
    note: String(d.note ?? ''),
  };
}

export async function loadDeletions(): Promise<Deletion[]> {
  const s = await getDocs(collection(firebase().db, 'deletionRequests'));
  const now = new Date();
  return s.docs.map((d) => deletionFromDoc(d.id, d.data(), now)).sort((a, b) => (b.createdAt?.getTime() ?? 0) - (a.createdAt?.getTime() ?? 0));
}

/**
 * Brings a closed account back within the 90 days: the account mark and the
 * farm closures are removed, all in one audited write. With the server on,
 * the sign-in is switched back on at the same time (functions/accounts.ts).
 */
export async function restoreAccount(me: Actor, d: Deletion, note: string) {
  if (!d.uid) throw new Error('This request has no account linked.');
  const { db } = firebase();
  const { deleteField } = await import('firebase/firestore');
  await adminChange(me, { action: 'account.restore', target: `users/${d.uid}`, details: { farms: d.farms, note } }, [
    updateOp(doc(db, 'deletionRequests', d.id), { status: 'restored', restoredAt: serverTimestamp(), handledBy: me.uid, handledByName: me.name, note }),
    updateOp(doc(db, 'users', d.uid), { deletion: deleteField() }),
    ...d.farms.map((t) => updateOp(doc(db, 'tenants', t), { closure: deleteField() })),
  ]);
}

/** A form request: mark it checked, or turn it down. */
export async function markDeletion(me: Actor, d: Deletion, status: 'verified' | 'rejected', note: string) {
  await adminChange(me, { action: `deletion.${status}`, target: `deletionRequests/${d.id}`, details: { note } }, [
    updateOp(doc(firebase().db, 'deletionRequests', d.id), { status, handledBy: me.uid, handledByName: me.name, note, handledAt: serverTimestamp() }),
  ]);
}

export { HOLD_DAYS };

// ---------------------------------------------------------------- Legal

export interface LegalAdmin {
  published: LegalDoc;
  /** Whether a version was ever published here (else the built-in text shows). */
  isPublished: boolean;
  draft: LegalDoc | null;
  versions: (LegalDoc & { publishedByName: string; publishedAt: Date | null })[];
}

export async function loadLegalAdmin(kind: LegalKind): Promise<LegalAdmin> {
  const { db } = firebase();
  const [pub, draft, versions] = await Promise.all([
    getDoc(doc(db, 'legalDocs', kind)),
    getDoc(doc(db, 'legalDrafts', kind)).catch(() => null),
    getDocs(collection(db, 'legalDocs', kind, 'versions')),
  ]);
  return {
    published: pub.exists() ? legalFromDoc(kind, pub.data()) : DEFAULT_LEGAL[kind],
    isPublished: pub.exists(),
    draft: draft?.exists() ? legalFromDoc(kind, draft.data()) : null,
    versions: versions.docs
      .map((v) => ({ ...legalFromDoc(kind, v.data()), publishedByName: String(v.data().publishedByName ?? ''), publishedAt: date(v.data().publishedAt) }))
      .sort((a, b) => b.version - a.version),
  };
}

const legalBody = (d: LegalDoc) => ({
  kind: d.kind,
  title: d.title.trim(),
  version: d.version,
  effectiveDate: d.effectiveDate,
  body: d.body,
  signatory: { name: d.signatory.name.trim(), title: d.signatory.title.trim() },
  summary: d.summary.trim(),
});

export async function saveLegalDraft(me: Actor, d: LegalDoc) {
  const { setDoc } = await import('firebase/firestore');
  await setDoc(doc(firebase().db, 'legalDrafts', d.kind), { ...legalBody(d), savedAt: serverTimestamp(), savedByName: me.name });
}

/** Publishes [d] as the next version; the earlier ones stay readable. */
export async function publishLegal(me: Actor, d: LegalDoc, current: LegalAdmin) {
  const { db } = firebase();
  const version = current.isPublished ? current.published.version + 1 : Math.max(1, (current.versions[0]?.version ?? 0) + 1);
  const body = { ...legalBody(d), version };
  const { deleteDoc } = await import('firebase/firestore');
  await adminChange(me, { action: 'legal.publish', target: `legalDocs/${d.kind}`, details: { version, effectiveDate: d.effectiveDate, summary: d.summary } }, [
    setOp(doc(db, 'legalDocs', d.kind, 'versions', String(version)), { ...body, publishedBy: me.uid, publishedByName: me.name, publishedAt: serverTimestamp() }, false),
    setOp(doc(db, 'legalDocs', d.kind), { ...body, publishedByName: me.name, publishedAt: serverTimestamp() }, false),
  ]);
  await deleteDoc(doc(db, 'legalDrafts', d.kind)).catch(() => undefined);
  return version;
}

// ---------------------------------------------------------------- Branding

export type AssetName = 'logo' | 'stamp' | 'signature';

export async function loadAssets(): Promise<Record<AssetName, string | null>> {
  const { db } = firebase();
  const get = async (n: AssetName) => {
    const d = (await getDoc(doc(db, 'platformAssets', n))).data();
    return (d?.dataUrl as string | undefined) || (d?.url as string | undefined) || null;
  };
  const [logo, stamp, signature] = await Promise.all([get('logo'), get('stamp'), get('signature')]);
  return { logo, stamp, signature };
}

export async function saveAsset(me: Actor, name: AssetName, img: { dataUrl: string; width: number; height: number }, url: string | null) {
  await adminChange(me, { action: 'branding.upload', target: `platformAssets/${name}`, details: { width: img.width, height: img.height, stored: url != null } }, [
    setOp(
      doc(firebase().db, 'platformAssets', name),
      { dataUrl: img.dataUrl, url, path: url ? `platform/branding/${name}.png` : null, width: img.width, height: img.height, updatedAt: serverTimestamp(), updatedByName: me.name },
      false,
    ),
  ]);
}

export async function removeAsset(me: Actor, name: AssetName) {
  await adminChange(me, { action: 'branding.remove', target: `platformAssets/${name}` }, [
    setOp(doc(firebase().db, 'platformAssets', name), { url: null, path: null, updatedAt: serverTimestamp(), updatedByName: me.name }, false),
  ]);
}

export const HOLD_NOTE = `Closed accounts are kept ${HOLD_DAYS} days, then erased for good.`;
