'use client';

// Brand and documents (decision 0024): the logo, company stamp and
// signature used on receipts, invoices, refund notes and the legal pages,
// and the company details printed on them.

import { doc, serverTimestamp } from 'firebase/firestore';
import { useEffect, useState, type FormEvent } from 'react';
import Link from 'next/link';
import { Fit, MsgBanner, Need, useAction, useLoad } from '@/components/admin';
import { Icon } from '@/components/Icon';
import { AssetPicker } from '@/components/upload';
import { Field, PageHead, SkelCard } from '@/components/ui';
import { adminChange, setOp } from '@/lib/admin';
import { loadAssets, removeAsset, saveAsset, type AssetName } from '@/lib/adminLaunch';
import { useAdmin } from '@/lib/adminSession';
import { downloadBillingPdf, resetBrandCache } from '@/lib/billing';
import { firebase } from '@/lib/firebase';
import { storeImage } from '@/lib/images';
import { defaultCompany, loadCompany } from '@/lib/publicData';
import type { Company } from '@/lib/site';
import type { BillingDoc } from '@/shared/billing';

const ASSETS: [AssetName, string, string, number][] = [
  ['logo', 'Logo', 'Shown on receipts, invoices, legal pages and the website. A wide PNG with a clear background looks best.', 900],
  ['stamp', 'Company stamp', 'A round or square stamp, scanned or photographed on white. PNG with a clear background is best.', 600],
  ['signature', 'Signature', 'Sign on white paper with a dark pen, photograph it flat, then upload. It is placed above the signer’s name.', 800],
];

/** A made-up payment, to see how a receipt looks. */
function sample(): BillingDoc {
  const now = new Date().toISOString();
  return {
    id: 'sample',
    seq: 1,
    receiptNo: 'RCT-SAMPLE-000001',
    invoiceNo: 'INV-SAMPLE-000001',
    refundNo: null,
    kind: 'payment',
    tenantId: 'sample',
    farmName: 'Sample Dairy Farm',
    farmPlace: 'Rwanyamahembe, Mbarara',
    billedTo: 'Sample Farmer',
    billedEmail: 'farmer@example.com',
    items: [{ description: 'FarmTap Standard plan, 1 month', qty: 1, unitUgx: 50000, amountUgx: 50000 }],
    totalUgx: 50000,
    method: 'mtn',
    reference: 'SAMPLE123456',
    issuedAt: now,
    paidAt: now,
    periodFrom: now,
    periodTo: new Date(Date.now() + 30 * 86_400_000).toISOString(),
    paymentId: 'sample',
    refundOf: null,
    note: 'Sample only. Not a real payment.',
    pdfPath: null,
  };
}

export default function Branding() {
  const { actor } = useAdmin();
  const assets = useLoad(loadAssets);
  const company = useLoad(loadCompany);
  const act = useAction();
  const [c, setC] = useState<Company>(defaultCompany);
  useEffect(() => {
    if (company.data) setC(company.data);
  }, [company.data]);

  const upload = (name: AssetName) => async (img: { dataUrl: string; width: number; height: number }) => {
    const url = await storeImage(`platform/branding/${name}.png`, img.dataUrl);
    const ok = await act.run(() => saveAsset(actor, name, img, url), url ? 'Saved.' : 'Saved. (File storage is off, so a small copy is kept; it works the same.)');
    if (ok) {
      resetBrandCache();
      assets.reload();
    }
  };

  const remove = (name: AssetName) => async () => {
    if (await act.run(() => removeAsset(actor, name), 'Removed.')) {
      resetBrandCache();
      assets.reload();
    }
  };

  const saveCompany = (e: FormEvent) => {
    e.preventDefault();
    void act
      .run(
        () =>
          adminChange(actor, { action: 'company.update', target: 'platform/company', details: { company: c.company, tin: c.tin } }, [
            setOp(doc(firebase().db, 'platform', 'company'), { ...c, updatedAt: serverTimestamp(), updatedByName: actor.name }),
          ]),
        'Company details saved. New receipts and the legal pages use them.',
      )
      .then((ok) => ok && resetBrandCache());
  };

  return (
    <Need perm="settings">
      <PageHead title="Brand and documents" subtitle="Logo, stamp and signature on receipts, invoices and the legal pages">
        <button className="btn outline sm" onClick={() => void downloadBillingPdf(sample(), 'receipt')}>
          <Icon name="download" /> Sample receipt
        </button>
        <button className="btn outline sm" onClick={() => void downloadBillingPdf(sample(), 'invoice')}>
          <Icon name="download" /> Sample invoice
        </button>
      </PageHead>
      <MsgBanner msg={act.msg} />

      {assets.data ? (
        <Fit kind="cards" cols={[1, 3, 3, 3]}>
          {ASSETS.map(([name, label, hint, max]) => (
            <section key={name} className="card">
              <AssetPicker label={label} hint={hint} value={assets.data![name]} max={max} onPick={upload(name)} onRemove={remove(name)} />
            </section>
          ))}
        </Fit>
      ) : (
        <Fit kind="cards" cols={[1, 3, 3, 3]}>
          <SkelCard lines={4} />
          <SkelCard lines={4} />
          <SkelCard lines={4} />
        </Fit>
      )}

      <section className="card">
        <form className="stack" onSubmit={saveCompany}>
          <div className="card-head">
            <h2>Company details</h2>
          </div>
          <p className="small muted">
            Printed on every receipt, invoice and refund note, and filled into the legal documents. The support phone and email come from{' '}
            <Link href="/admin/settings/">App settings</Link>.
          </p>
          <Fit kind="fields" cols={[1, 2, 3, 3]}>
            <Field label="Company name">
              <input className="input" value={c.company} onChange={(e) => setC({ ...c, company: e.target.value })} required />
            </Field>
            <Field label="Address">
              <input className="input" value={c.address} onChange={(e) => setC({ ...c, address: e.target.value })} />
            </Field>
            <Field label="Website">
              <input className="input" value={c.website} onChange={(e) => setC({ ...c, website: e.target.value })} />
            </Field>
            <Field label="TIN (tax number)" hint="Leave empty until you are registered; the line is then hidden.">
              <input className="input" value={c.tin} onChange={(e) => setC({ ...c, tin: e.target.value })} />
            </Field>
            <Field label="Signed by">
              <input className="input" value={c.signatoryName} onChange={(e) => setC({ ...c, signatoryName: e.target.value })} />
            </Field>
            <Field label="Title of signer">
              <input className="input" value={c.signatoryTitle} onChange={(e) => setC({ ...c, signatoryTitle: e.target.value })} />
            </Field>
          </Fit>
          <div className="row">
            <button className="btn" disabled={act.busy}>
              Save company details
            </button>
          </div>
        </form>
      </section>
    </Need>
  );
}
