'use client';

// Settings > Plan and payment: the farm's receipts, invoices and refund notes.

import { useEffect, useState } from 'react';
import { Icon } from '@/components/Icon';
import { Empty, SkelRows } from '@/components/ui';
import { downloadBillingPdf, farmBillingDocs } from '@/lib/billing';
import type { Farm } from '@/lib/domain';
import { methodLabel, shortDay, ugxText, type BillingDoc, type DocView } from '@/shared/billing';

export function BillingDocsSection({ farm }: { farm: Farm }) {
  const [docs, setDocs] = useState<BillingDoc[] | null>(null);
  const [error, setError] = useState('');
  const [busy, setBusy] = useState('');
  useEffect(() => {
    let live = true;
    farmBillingDocs(farm.id).then(
      (d) => live && setDocs(d),
      () => {
        if (!live) return;
        setDocs([]);
        setError('We could not load your receipts just now.');
      },
    );
    return () => {
      live = false;
    };
  }, [farm.id]);

  const get = async (d: BillingDoc, view: DocView) => {
    setBusy(`${d.id}-${view}`);
    try {
      await downloadBillingPdf(d, view);
    } catch {
      setError('We could not make that PDF. Try again.');
    } finally {
      setBusy('');
    }
  };

  const btn = (d: BillingDoc, view: DocView, label: string) => (
    <button key={view} type="button" className="btn outline sm" disabled={busy !== ''} onClick={() => void get(d, view)}>
      {busy === `${d.id}-${view}` ? <span className="spinner sm" aria-hidden /> : <Icon name="download" />} {label}
    </button>
  );

  return (
    <section className="card stack">
      <div className="card-head">
        <h2>Receipts and invoices</h2>
      </div>
      <p className="small muted">A numbered receipt and invoice is made for every payment. Download them as PDF for your records.</p>
      {error && <p className="banner bad small">{error}</p>}
      {docs === null ? (
        <SkelRows rows={3} cols={3} />
      ) : docs.length === 0 ? (
        <Empty icon="receipt">No payments yet. Your receipts will show here after your first payment.</Empty>
      ) : (
        <div className="list">
          {docs.map((d) => (
            <div key={d.id} className="list-row wrap">
              <span className="grow stack tight">
                <strong>{d.kind === 'refund' ? `Refund ${d.refundNo ?? ''}` : d.receiptNo}</strong>
                <small className="muted">
                  {shortDay(d.paidAt || d.issuedAt)} · {ugxText(d.totalUgx)} · {methodLabel[d.method] ?? d.method}
                </small>
              </span>
              <span className="row wrap">
                {d.kind === 'refund' ? btn(d, 'refund', 'Refund note') : [btn(d, 'receipt', 'Receipt'), btn(d, 'invoice', 'Invoice')]}
              </span>
            </div>
          ))}
        </div>
      )}
    </section>
  );
}
