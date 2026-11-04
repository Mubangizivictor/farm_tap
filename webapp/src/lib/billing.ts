'use client';

// Receipts, invoices and refund notes in the browser (decision 0024). The
// numbers come from billingDocs (one sequence, counters/billing). The PDF is
// drawn here with the same code the server uses (shared/billing.ts), so it
// downloads the same whether or not the server copy exists yet.

import { collection, doc, getDoc, getDocs, query, where } from 'firebase/firestore';
import * as PdfLib from 'pdf-lib';
import { billingFromDoc, imageFromDataUrl, renderBillingPdf, viewNumber, type BillingBranding, type BillingDoc, type DocView } from '../shared/billing.ts';
import { DEFAULT_SIGNATORY, OPERATOR } from '../shared/legal.ts';
import { firebase } from './firebase.ts';

export async function loadBranding(): Promise<BillingBranding> {
  const { db } = firebase();
  const read = async (path: string) => {
    try {
      return (await getDoc(doc(db, path))).data() ?? {};
    } catch {
      return {};
    }
  };
  const [cfg, logo, stamp, signature, c] = await Promise.all([
    read('platform/config'),
    read('platformAssets/logo'),
    read('platformAssets/stamp'),
    read('platformAssets/signature'),
    read('platform/company'),
  ]);
  const sup = (cfg.support ?? {}) as Record<string, string>;
  return {
    company: String(c.company ?? OPERATOR.company),
    address: String(c.address ?? OPERATOR.address),
    phone: String(sup.phone || OPERATOR.phone),
    email: String(sup.email || OPERATOR.email),
    website: String(c.website ?? OPERATOR.website),
    tin: String(c.tin ?? ''),
    signatoryName: String(c.signatoryName ?? DEFAULT_SIGNATORY.name),
    signatoryTitle: String(c.signatoryTitle ?? DEFAULT_SIGNATORY.title),
    logo: imageFromDataUrl(logo.dataUrl as string | undefined),
    stamp: imageFromDataUrl(stamp.dataUrl as string | undefined),
    signature: imageFromDataUrl(signature.dataUrl as string | undefined),
  };
}

/** A farm's documents, newest first. */
export async function farmBillingDocs(tenantId: string): Promise<BillingDoc[]> {
  const snap = await getDocs(query(collection(firebase().db, 'billingDocs'), where('tenantId', '==', tenantId)));
  return snap.docs.map((d) => billingFromDoc(d.id, d.data())).sort((a, b) => b.seq - a.seq);
}

let brandCache: Promise<BillingBranding> | null = null;

/** Draws the PDF and saves it as a file on this device. */
export async function downloadBillingPdf(d: BillingDoc, view: DocView, brand?: BillingBranding) {
  brandCache ??= loadBranding();
  const bytes = await renderBillingPdf(PdfLib, d, view, brand ?? (await brandCache));
  const blob = new Blob([bytes as BlobPart], { type: 'application/pdf' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = `FarmTap-${viewNumber(d, view)}.pdf`;
  document.body.appendChild(a);
  a.click();
  a.remove();
  setTimeout(() => URL.revokeObjectURL(url), 10_000);
}

/** Opens the PDF in a new tab (for printing). */
export async function openBillingPdf(d: BillingDoc, view: DocView) {
  const w = window.open('', '_blank');
  brandCache ??= loadBranding();
  const bytes = await renderBillingPdf(PdfLib, d, view, await brandCache);
  const url = URL.createObjectURL(new Blob([bytes as BlobPart], { type: 'application/pdf' }));
  if (w) w.location.href = url;
  else window.location.href = url;
}

export const resetBrandCache = () => {
  brandCache = null;
};
