// Receipts and invoices (decision 0024). Every payment FarmTap receives
// (platformPayments/{id}, from an in-app payment or recorded in the control
// panel) gets numbered documents in billingDocs/{same id}:
//   receipt RCT-yyyy-nnnnnn and invoice INV-yyyy-nnnnnn (one sequence).
// The control panel makes the record itself when it records a payment, so
// numbering works before the Blaze plan. With billingPdf switched on, this
// code also draws the PDFs and keeps them in cloud storage, and makes the
// record for in-app payments. Apps can always draw the same PDF themselves.

import { FieldValue, type Transaction } from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';
import { logger } from 'firebase-functions';
import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import * as PdfLib from 'pdf-lib';
import { billingDocForPayment as docForPayment, imageFromDataUrl, renderBillingPdf, billingFromDoc, type BillingBranding, type BillingDoc, type DocView } from './shared/billing';
import { DEFAULT_SIGNATORY, OPERATOR } from './shared/legal';
import { db, switchOn } from './server';

const COUNTER = 'counters/billing';

/** Takes the next number in a transaction (reads must come first in the caller). */
export function nextSeq(counter: FirebaseFirestore.DocumentSnapshot): number {
  const n = counter.get('next');
  return typeof n === 'number' && n >= 1 ? n : 1;
}

/** Allocates the number and writes billingDocs/{id} once. Safe to repeat. */
export async function ensureBillingDoc(paymentId: string): Promise<BillingDoc | null> {
  const ref = db().doc(`billingDocs/${paymentId}`);
  return db().runTransaction(async (tx: Transaction) => {
    const [existing, pay, counter] = await Promise.all([tx.get(ref), tx.get(db().doc(`platformPayments/${paymentId}`)), tx.get(db().doc(COUNTER))]);
    if (existing.exists) return billingFromDoc(existing.id, existing.data());
    if (!pay.exists || pay.get('status') !== 'received') return null;
    const p = pay.data() ?? {};
    const tenant = (await tx.get(db().doc(`tenants/${String(p.tenantId)}`))).data() ?? {};
    const owner = tenant.ownerUid ? ((await tx.get(db().doc(`users/${String(tenant.ownerUid)}`))).data() ?? {}) : {};
    const seq = nextSeq(counter);
    const doc = docForPayment(paymentId, p, tenant, owner, seq, new Date());
    tx.set(ref, { ...doc, createdAt: FieldValue.serverTimestamp(), createdBy: 'system' });
    tx.set(db().doc(COUNTER), { next: seq + 1, lastDoc: paymentId }, { merge: true });
    return { id: paymentId, ...doc };
  });
}

/** Logo, stamp, signature and company details from the control panel. */
export async function loadBranding(): Promise<BillingBranding> {
  const [cfg, logo, stamp, signature, legal] = await Promise.all([
    db().doc('platform/config').get(),
    db().doc('platformAssets/logo').get(),
    db().doc('platformAssets/stamp').get(),
    db().doc('platformAssets/signature').get(),
    db().doc('platform/company').get(),
  ]);
  const sup = (cfg.get('support') ?? {}) as Record<string, string>;
  const c = legal.data() ?? {};
  return {
    company: String(c.company ?? OPERATOR.company),
    address: String(c.address ?? OPERATOR.address),
    phone: String(sup.phone || OPERATOR.phone),
    email: String(sup.email || OPERATOR.email),
    website: String(c.website ?? OPERATOR.website),
    tin: String(c.tin ?? ''),
    signatoryName: String(c.signatoryName ?? DEFAULT_SIGNATORY.name),
    signatoryTitle: String(c.signatoryTitle ?? DEFAULT_SIGNATORY.title),
    logo: imageFromDataUrl(logo.get('dataUrl')),
    stamp: imageFromDataUrl(stamp.get('dataUrl')),
    signature: imageFromDataUrl(signature.get('dataUrl')),
  };
}

/** Draws the PDFs and keeps them at billing/{tenantId}/{number}.pdf. */
export async function storePdfs(doc: BillingDoc): Promise<string[]> {
  const brand = await loadBranding();
  const views: DocView[] = doc.kind === 'refund' ? ['refund'] : ['receipt', 'invoice'];
  const bucket = getStorage().bucket();
  const paths: string[] = [];
  for (const v of views) {
    const bytes = await renderBillingPdf(PdfLib, doc, v, brand);
    const no = v === 'invoice' ? doc.invoiceNo : v === 'refund' ? (doc.refundNo ?? doc.receiptNo) : doc.receiptNo;
    const path = `billing/${doc.tenantId}/${no}.pdf`;
    await bucket.file(path).save(Buffer.from(bytes), { contentType: 'application/pdf', resumable: false, metadata: { cacheControl: 'private, max-age=3600' } });
    paths.push(path);
  }
  await db().doc(`billingDocs/${doc.id}`).update({ pdfPath: paths[0], pdfPaths: paths, pdfAt: FieldValue.serverTimestamp() });
  return paths;
}

export const issueBillingDocs = onDocumentWritten({ document: 'platformPayments/{id}', timeoutSeconds: 120, memory: '512MiB' }, async (event) => {
  const after = event.data?.after?.data();
  if (!after || after.status !== 'received') return;
  if (!(await switchOn('billingPdf'))) return;
  try {
    const doc = await ensureBillingDoc(event.params.id);
    if (doc && !doc.pdfPath) await storePdfs(doc);
  } catch (e) {
    logger.error('billing docs failed', { id: event.params.id, error: String(e) });
  }
});

export const issueRefundDocs = onDocumentWritten({ document: 'billingDocs/{id}', timeoutSeconds: 120, memory: '512MiB' }, async (event) => {
  const after = event.data?.after?.data();
  if (!after || after.kind !== 'refund' || after.pdfPath) return;
  if (!(await switchOn('billingPdf'))) return;
  await storePdfs(billingFromDoc(event.params.id, after));
});
