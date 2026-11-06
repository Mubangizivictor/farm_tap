// FarmTap receipts, invoices and refund notes (decision 0024): numbering and
// the PDF layout. The same layout is drawn on the server (functions/, stored
// as a file once cloud storage is on) and in the browser (download from the
// web app and the control panel). The phone draws the same page with the
// Dart `pdf` package (lib/core/billing/presentation/billing_pdf.dart).
//
// pdf-lib is passed in, so this file has no imports and both packages can use it.

import type * as PdfLib from 'pdf-lib';

export type BillingKind = 'receipt' | 'invoice' | 'refund';

export const kindPrefix: Record<BillingKind, string> = { receipt: 'RCT', invoice: 'INV', refund: 'RFD' };
export const kindTitle: Record<BillingKind, string> = { receipt: 'RECEIPT', invoice: 'INVOICE', refund: 'REFUND NOTE' };

/** RCT-2026-000012. One sequence for all kinds keeps the numbers unique. */
export function docNumber(kind: BillingKind, year: number, seq: number): string {
  return `${kindPrefix[kind]}-${year}-${String(Math.max(1, Math.floor(seq))).padStart(6, '0')}`;
}

export interface BillingLine {
  description: string;
  qty: number;
  unitUgx: number;
  amountUgx: number;
}

/** billingDocs/{id}: one payment's numbered documents. */
export interface BillingDoc {
  id: string;
  /** Sequence number from counters/billing. */
  seq: number;
  /** The receipt number (paid), e.g. RCT-2026-000012. */
  receiptNo: string;
  /** The invoice number for the same payment, e.g. INV-2026-000012. */
  invoiceNo: string;
  /** Refund notes only: RFD-2026-000013. */
  refundNo?: string | null;
  kind: 'payment' | 'refund';
  tenantId: string;
  farmName: string;
  farmPlace: string;
  billedTo: string;
  billedEmail: string;
  items: BillingLine[];
  totalUgx: number;
  method: string;
  reference: string;
  /** ISO dates. */
  issuedAt: string;
  paidAt: string;
  periodFrom: string | null;
  periodTo: string | null;
  /** platformPayments id this belongs to. */
  paymentId: string;
  /** For a refund note: the receipt it refunds. */
  refundOf?: string | null;
  note: string;
  /** Path of the stored PDF, once the server has made it. */
  pdfPath?: string | null;
}

const obj = (v: unknown): Record<string, unknown> => (v && typeof v === 'object' && !Array.isArray(v) ? (v as Record<string, unknown>) : {});
const s = (v: unknown, d = '') => (typeof v === 'string' ? v : d);
const n = (v: unknown, d = 0) => (typeof v === 'number' && Number.isFinite(v) ? v : d);
const iso = (v: unknown): string | null => {
  if (typeof v === 'string') return v;
  const o = obj(v);
  if (typeof o.toDate === 'function') return (o.toDate as () => Date)().toISOString();
  if (typeof o.seconds === 'number') return new Date(o.seconds * 1000).toISOString();
  if (v instanceof Date) return v.toISOString();
  return null;
};

export function billingFromDoc(id: string, data: unknown): BillingDoc {
  const d = obj(data);
  return {
    id,
    seq: n(d.seq),
    receiptNo: s(d.receiptNo),
    invoiceNo: s(d.invoiceNo),
    refundNo: s(d.refundNo) || null,
    kind: d.kind === 'refund' ? 'refund' : 'payment',
    tenantId: s(d.tenantId),
    farmName: s(d.farmName),
    farmPlace: s(d.farmPlace),
    billedTo: s(d.billedTo),
    billedEmail: s(d.billedEmail),
    items: Array.isArray(d.items)
      ? d.items.map(obj).map((i) => ({ description: s(i.description), qty: n(i.qty, 1), unitUgx: n(i.unitUgx), amountUgx: n(i.amountUgx) }))
      : [],
    totalUgx: n(d.totalUgx),
    method: s(d.method),
    reference: s(d.reference),
    issuedAt: iso(d.issuedAt) ?? new Date(0).toISOString(),
    paidAt: iso(d.paidAt) ?? iso(d.issuedAt) ?? new Date(0).toISOString(),
    periodFrom: iso(d.periodFrom),
    periodTo: iso(d.periodTo),
    paymentId: s(d.paymentId),
    refundOf: s(d.refundOf) || null,
    note: s(d.note),
    pdfPath: s(d.pdfPath) || null,
  };
}

/** Builds the billing record for a platformPayments document (server and control panel). */
export function billingDocForPayment(
  id: string,
  p: Record<string, unknown>,
  tenant: Record<string, unknown>,
  owner: Record<string, unknown>,
  seq: number,
  now: Date,
): Omit<BillingDoc, 'id'> {
  const paidAt = iso(p.paidAt) ?? now.toISOString();
  const year = new Date(new Date(paidAt).getTime() + 3 * 3600 * 1000).getUTCFullYear();
  const amount = Number(p.amountUgx) || 0;
  const months = Number(p.months) || 0;
  const until = iso(p.newPaidUntil);
  let periodFrom: string | null = null;
  if (until && months) {
    const d = new Date(until);
    d.setUTCMonth(d.getUTCMonth() - months);
    periodFrom = d.toISOString();
  }
  const planName = s(p.planName) || s(p.note).split(',')[0] || 'Standard';
  const items: BillingLine[] =
    p.kind === 'sms'
      ? [{ description: `SMS credits (${n(p.smsCredits)})`, qty: 1, unitUgx: amount, amountUgx: amount }]
      : subscriptionLines(planName.replace(/^FarmTap\s+/i, ''), months || 1, n(p.periods, 1) || 1, amount);
  return {
    seq,
    receiptNo: docNumber('receipt', year, seq),
    invoiceNo: docNumber('invoice', year, seq),
    refundNo: null,
    kind: 'payment',
    tenantId: s(p.tenantId),
    farmName: s(p.farmName) || s(tenant.name),
    farmPlace: [tenant.village, tenant.district].filter((x) => typeof x === 'string' && x).join(', '),
    billedTo: s(owner.name) || s(owner.displayName) || s(tenant.ownerName),
    billedEmail: s(owner.email),
    items,
    totalUgx: amount,
    method: s(p.method),
    reference: s(p.reference),
    issuedAt: now.toISOString(),
    paidAt,
    periodFrom,
    periodTo: until,
    paymentId: id,
    refundOf: null,
    note: '',
    pdfPath: null,
  };
}

/** The refund note record for a refund of [of]. */
export function refundDoc(of: BillingDoc, refundId: string, amountUgx: number, seq: number, method: string, reference: string, reason: string, now: Date): Omit<BillingDoc, 'id'> {
  const year = new Date(now.getTime() + 3 * 3600 * 1000).getUTCFullYear();
  return {
    ...of,
    seq,
    kind: 'refund',
    refundNo: docNumber('refund', year, seq),
    receiptNo: of.receiptNo,
    invoiceNo: of.invoiceNo,
    items: [{ description: `Refund of ${of.receiptNo}${reason ? ` (${reason.slice(0, 40)})` : ''}`, qty: 1, unitUgx: amountUgx, amountUgx }],
    totalUgx: amountUgx,
    method,
    reference,
    issuedAt: now.toISOString(),
    paidAt: now.toISOString(),
    paymentId: refundId,
    refundOf: of.receiptNo,
    note: reason,
    pdfPath: null,
  };
}

export const methodLabel: Record<string, string> = {
  mtn: 'MTN Mobile Money',
  airtel: 'Airtel Money',
  card: 'Card',
  bank: 'Bank transfer',
  cash: 'Cash',
  other: 'Other',
};

/** The lines of a subscription payment: "FarmTap Monthly plan, 2 x 1 month". */
export function subscriptionLines(planName: string, months: number, periods: number, amountUgx: number): BillingLine[] {
  const p = Math.max(1, periods || 1);
  const each = Math.round(amountUgx / p);
  const span = months / p === 1 ? '1 month' : `${months / p} months`;
  return [{ description: `FarmTap ${planName} plan (${span})`, qty: p, unitUgx: each, amountUgx }];
}

// ---------------------------------------------------------------- PDF

export interface BrandImage {
  bytes: Uint8Array;
  type: 'png' | 'jpg';
}

export interface BillingBranding {
  company: string;
  address: string;
  phone: string;
  email: string;
  website: string;
  /** Tax ID (TIN) when registered; empty hides the line. */
  tin: string;
  signatoryName: string;
  signatoryTitle: string;
  logo?: BrandImage | null;
  stamp?: BrandImage | null;
  signature?: BrandImage | null;
}

/** "data:image/png;base64,..." -> bytes, or null when it is not a PNG/JPEG. */
export function imageFromDataUrl(url: string | null | undefined): BrandImage | null {
  if (!url) return null;
  const m = /^data:image\/(png|jpe?g);base64,([A-Za-z0-9+/=]+)$/.exec(url.trim());
  if (!m) return null;
  const bin = atob(m[2]);
  const bytes = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
  return { bytes, type: m[1] === 'png' ? 'png' : 'jpg' };
}

/** "UGX 70,000". */
export const ugxText = (v: number) => `UGX ${Math.round(v).toLocaleString('en-US')}`;

/** "4 Nov 2026". */
export function shortDay(isoText: string | null | undefined): string {
  if (!isoText) return '';
  const d = new Date(isoText);
  if (Number.isNaN(d.getTime())) return '';
  const mon = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][d.getUTCMonth()];
  // Kampala is UTC+3 all year.
  const k = new Date(d.getTime() + 3 * 3600 * 1000);
  return `${k.getUTCDate()} ${mon} ${k.getUTCFullYear()}`;
}

/** Characters the standard PDF fonts cannot draw are replaced. */
const safe = (t: string) =>
  t
    .replace(/[‘’]/g, "'")
    .replace(/[“”]/g, '"')
    .replace(/[–—]/g, '-')
    .replace(/…/g, '...')
    .replace(/[^\x20-\x7E -ÿ]/g, '');

export type DocView = 'receipt' | 'invoice' | 'refund';

/** Which numbered page to draw for a billing doc. */
export function viewNumber(doc: BillingDoc, view: DocView): string {
  if (view === 'refund') return doc.refundNo || doc.receiptNo;
  return view === 'invoice' ? doc.invoiceNo : doc.receiptNo;
}

/**
 * One A4 page: logo and company, title and number, billed to, the lines,
 * the total, PAID (or REFUNDED) with the stamp, and the signature.
 */
export async function renderBillingPdf(lib: typeof PdfLib, doc: BillingDoc, view: DocView, brand: BillingBranding): Promise<Uint8Array> {
  const { PDFDocument, StandardFonts, rgb, degrees } = lib;
  const pdf = await PDFDocument.create();
  pdf.setTitle(`${kindTitle[view]} ${viewNumber(doc, view)}`);
  pdf.setAuthor(brand.company);
  pdf.setCreator('FarmTap');
  const page = pdf.addPage([595.28, 841.89]);
  const font = await pdf.embedFont(StandardFonts.Helvetica);
  const bold = await pdf.embedFont(StandardFonts.HelveticaBold);
  const green = rgb(0.122, 0.369, 0.29);
  const gold = rgb(0.933, 0.725, 0.231);
  const ink = rgb(0.13, 0.15, 0.14);
  const muted = rgb(0.42, 0.45, 0.43);
  const line = rgb(0.86, 0.88, 0.86);
  const W = 595.28;
  const M = 48;

  const text = (t: string, x: number, y: number, size = 10, f = font, color = ink) => page.drawText(safe(t), { x, y, size, font: f, color });
  const right = (t: string, xr: number, y: number, size = 10, f = font, color = ink) => {
    const v = safe(t);
    page.drawText(v, { x: xr - f.widthOfTextAtSize(v, size), y, size, font: f, color });
  };
  const embed = async (img: BrandImage | null | undefined) => {
    if (!img) return null;
    try {
      return img.type === 'png' ? await pdf.embedPng(img.bytes) : await pdf.embedJpg(img.bytes);
    } catch {
      return null;
    }
  };

  // Top band.
  page.drawRectangle({ x: 0, y: 841.89 - 8, width: W, height: 8, color: green });

  // Logo (or the FarmTap mark drawn) and company details.
  let y = 841.89 - 56;
  const logo = await embed(brand.logo);
  if (logo) {
    const h = 44;
    const w = Math.min(160, (logo.width / logo.height) * h);
    page.drawImage(logo, { x: M, y: y - h + 20, width: w, height: (w / logo.width) * logo.height });
  } else {
    page.drawCircle({ x: M + 16, y: y + 2, size: 16, color: green });
    page.drawCircle({ x: M + 16, y: y + 2, size: 9, borderColor: gold, borderWidth: 2.4 });
    page.drawCircle({ x: M + 16, y: y + 2, size: 4.5, color: gold });
    text('Farm', M + 40, y - 6, 22, bold, green);
    text('Tap', M + 40 + bold.widthOfTextAtSize('Farm', 22), y - 6, 22, bold, gold);
  }
  right(brand.company, W - M, y + 8, 12, bold);
  right(brand.address, W - M, y - 6, 9, font, muted);
  right(`${brand.phone}  |  ${brand.email}`, W - M, y - 18, 9, font, muted);
  right(brand.website.replace(/^https?:\/\//, ''), W - M, y - 30, 9, font, muted);
  if (brand.tin) right(`TIN ${brand.tin}`, W - M, y - 42, 9, font, muted);

  // Title.
  y -= 92;
  text(kindTitle[view], M, y, 26, bold, green);
  const number = viewNumber(doc, view);
  right(`No. ${number}`, W - M, y + 10, 11, bold);
  right(`Date: ${shortDay(view === 'invoice' ? doc.issuedAt : doc.paidAt)}`, W - M, y - 4, 10, font, muted);
  if (view === 'receipt') right(`Invoice: ${doc.invoiceNo}`, W - M, y - 18, 9, font, muted);
  if (view === 'invoice') right(`Receipt: ${doc.receiptNo}`, W - M, y - 18, 9, font, muted);
  if (view === 'refund' && doc.refundOf) right(`Refund of: ${doc.refundOf}`, W - M, y - 18, 9, font, muted);

  // Billed to.
  y -= 44;
  page.drawRectangle({ x: M, y: y - 62, width: W - 2 * M, height: 72, color: rgb(0.965, 0.973, 0.965), borderColor: line, borderWidth: 0.8 });
  text(view === 'refund' ? 'REFUNDED TO' : 'BILLED TO', M + 14, y - 8, 8, bold, muted);
  text(doc.farmName || doc.billedTo, M + 14, y - 24, 12, bold);
  text([doc.billedTo !== doc.farmName ? doc.billedTo : '', doc.farmPlace].filter(Boolean).join(', '), M + 14, y - 38, 9, font, muted);
  if (doc.billedEmail) text(doc.billedEmail, M + 14, y - 51, 9, font, muted);
  const px = W / 2 + 20;
  text('PAYMENT', px, y - 8, 8, bold, muted);
  text(`Method: ${methodLabel[doc.method] ?? doc.method}`, px, y - 24, 9);
  text(`Reference: ${doc.reference || '-'}`, px, y - 37, 9);
  if (doc.periodFrom && doc.periodTo) text(`Period: ${shortDay(doc.periodFrom)} to ${shortDay(doc.periodTo)}`, px, y - 50, 9);

  // Lines.
  y -= 96;
  const cols = { desc: M + 10, qty: W - M - 210, unit: W - M - 110, amount: W - M - 10 };
  page.drawRectangle({ x: M, y: y - 6, width: W - 2 * M, height: 22, color: green });
  text('DESCRIPTION', cols.desc, y + 1, 8.5, bold, rgb(1, 1, 1));
  right('QTY', cols.qty + 20, y + 1, 8.5, bold, rgb(1, 1, 1));
  right('UNIT PRICE', cols.unit + 40, y + 1, 8.5, bold, rgb(1, 1, 1));
  right('AMOUNT', cols.amount, y + 1, 8.5, bold, rgb(1, 1, 1));
  y -= 26;
  const items = doc.items.length ? doc.items : [{ description: 'FarmTap subscription', qty: 1, unitUgx: doc.totalUgx, amountUgx: doc.totalUgx }];
  for (const it of items) {
    text(it.description.slice(0, 64), cols.desc, y, 10);
    right(String(it.qty), cols.qty + 20, y, 10);
    right(ugxText(it.unitUgx), cols.unit + 40, y, 10);
    right(ugxText(it.amountUgx), cols.amount, y, 10);
    y -= 8;
    page.drawLine({ start: { x: M, y }, end: { x: W - M, y }, thickness: 0.6, color: line });
    y -= 16;
  }

  // Totals.
  y -= 6;
  right('Total', cols.unit + 40, y, 11, bold);
  right(ugxText(doc.totalUgx), cols.amount, y, 12, bold);
  y -= 18;
  const paidLabel = view === 'refund' ? 'Refunded' : view === 'invoice' ? 'Paid' : 'Amount received';
  right(paidLabel, cols.unit + 40, y, 10, font, muted);
  right(ugxText(doc.totalUgx), cols.amount, y, 10, font, muted);
  y -= 16;
  right('Balance due', cols.unit + 40, y, 10, font, muted);
  right(ugxText(0), cols.amount, y, 10, font, muted);

  // Stamp: the uploaded company stamp, or a drawn PAID / REFUNDED mark.
  const stampY = y - 120;
  const stamp = await embed(brand.stamp);
  if (stamp) {
    const sw = 120;
    page.drawImage(stamp, { x: M + 10, y: stampY, width: sw, height: (sw / stamp.width) * stamp.height, rotate: degrees(-8), opacity: 0.9 });
  }
  const mark = view === 'refund' ? 'REFUNDED' : 'PAID';
  const mx = stamp ? M + 150 : M + 20;
  page.drawRectangle({ x: mx, y: stampY + 30, width: bold.widthOfTextAtSize(mark, 26) + 24, height: 40, borderColor: view === 'refund' ? rgb(0.75, 0.2, 0.2) : green, borderWidth: 2.5, rotate: degrees(-8), opacity: 0 });
  page.drawText(mark, { x: mx + 12, y: stampY + 40, size: 26, font: bold, color: view === 'refund' ? rgb(0.75, 0.2, 0.2) : green, rotate: degrees(-8) });

  // Signature.
  const sx = W - M - 190;
  const sig = await embed(brand.signature);
  if (sig) {
    const sw = 150;
    const sh = Math.min(60, (sw / sig.width) * sig.height);
    page.drawImage(sig, { x: sx + 10, y: stampY + 26, width: (sh / sig.height) * sig.width, height: sh });
  }
  page.drawLine({ start: { x: sx, y: stampY + 22 }, end: { x: W - M, y: stampY + 22 }, thickness: 0.8, color: ink });
  text(brand.signatoryName, sx, stampY + 8, 10, bold);
  text(brand.signatoryTitle.slice(0, 48), sx, stampY - 5, 8, font, muted);
  text(`For ${brand.company}`, sx, stampY - 17, 8, font, muted);

  if (doc.note) text(`Note: ${doc.note.slice(0, 110)}`, M, stampY - 46, 9, font, muted);

  // Footer.
  page.drawLine({ start: { x: M, y: 70 }, end: { x: W - M, y: 70 }, thickness: 0.6, color: line });
  text(view === 'refund' ? 'This note confirms the refund above.' : 'Thank you for farming with FarmTap.', M, 54, 10, bold, green);
  text(`Questions about this document? WhatsApp or call ${brand.phone}. This document was made by computer and is valid without a handwritten signature.`.slice(0, 140), M, 40, 7.5, font, muted);
  right(number, W - M, 54, 9, font, muted);
  page.drawRectangle({ x: 0, y: 0, width: W, height: 6, color: gold });

  return pdf.save();
}
