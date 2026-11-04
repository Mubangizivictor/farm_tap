'use client';

// Receipts and refunds (decision 0024). Every payment gets a numbered
// receipt and invoice. A refund is recorded, approved by someone with Money
// access, then sent: automatically through MTN, Airtel or card when that
// server switch is on, otherwise by hand and marked paid here. Paying a
// refund makes a numbered refund note.

import { useMemo, useState } from 'react';
import { MsgBanner, Need, useAction, useLoad, Fit } from '@/components/admin';
import { Icon } from '@/components/Icon';
import { Dialog, Empty, Field, LoadError, PageHead, SearchBox, SkelRows, Stat, Tabs } from '@/components/ui';
import { loadPayments, paymentMethods, type PlatformPayment } from '@/lib/admin';
import { completeRefund, decideRefund, issueBillingDoc, loadAllBillingDocs, loadRefunds, requestRefund, type Refund } from '@/lib/adminLaunch';
import { useAdmin } from '@/lib/adminSession';
import { downloadBillingPdf } from '@/lib/billing';
import { date, ugx } from '@/lib/format';
import type { BillingDoc } from '@/shared/billing';

type View = 'refunds' | 'receipts';

const refundStatus: Record<string, [string, string]> = {
  requested: ['Waiting for approval', 'warn'],
  approved: ['Approved, to send', 'info'],
  sending: ['Sending', 'info'],
  sent: ['Sent by provider', 'ok'],
  failed: ['Failed', 'bad'],
  done: ['Paid', 'ok'],
  rejected: ['Turned down', ''],
};

export default function Refunds() {
  const { actor, can } = useAdmin();
  const refunds = useLoad(loadRefunds);
  const docs = useLoad(loadAllBillingDocs);
  const pays = useLoad(loadPayments);
  const act = useAction();
  const [view, setView] = useState<View>('refunds');
  const [q, setQ] = useState('');
  const [newFor, setNewFor] = useState<PlatformPayment | null>(null);
  const [picking, setPicking] = useState(false);
  const [paying, setPaying] = useState<Refund | null>(null);
  const [busyDoc, setBusyDoc] = useState('');

  const docOf = useMemo(() => new Map((docs.data ?? []).map((d) => [d.id, d])), [docs.data]);
  const t = q.trim().toLowerCase();
  const refundRows = (refunds.data ?? []).filter((r) => !t || [r.farmName, r.reason, r.refundNo, r.destination].some((v) => v.toLowerCase().includes(t)));
  const docRows = (docs.data ?? []).filter((d) => !t || [d.farmName, d.receiptNo, d.invoiceNo, d.refundNo ?? '', d.reference].some((v) => v.toLowerCase().includes(t)));
  const missing = (pays.data ?? []).filter((p) => p.status === 'received' && !docOf.has(p.id));
  const waiting = (refunds.data ?? []).filter((r) => ['requested', 'approved', 'failed'].includes(r.status));
  const refunded = (refunds.data ?? []).filter((r) => ['done', 'sent'].includes(r.status)).reduce((s, r) => s + r.amountUgx, 0);

  const reload = () => {
    refunds.reload();
    docs.reload();
  };

  const issueMissing = () =>
    act
      .run(async () => {
        for (const p of missing) await issueBillingDoc(actor, p.id);
      }, `Numbered ${missing.length} receipt${missing.length === 1 ? '' : 's'}.`)
      .then(reload);

  const get = async (d: BillingDoc, v: 'receipt' | 'invoice' | 'refund') => {
    setBusyDoc(`${d.id}${v}`);
    try {
      await downloadBillingPdf(d, v);
    } finally {
      setBusyDoc('');
    }
  };

  return (
    <Need perm="finance">
      <PageHead title="Receipts and refunds" subtitle="Numbered receipts, invoices and refund notes">
        <SearchBox value={q} onChange={setQ} placeholder="Farm, number, transaction ID" />
        <button className="btn sm" onClick={() => setPicking(true)}>
          <Icon name="plus" /> Record refund
        </button>
      </PageHead>
      <MsgBanner msg={act.msg} />
      <LoadError code={refunds.error || docs.error} />

      <Fit kind="stats" cols={[2, 3, 3, 3]}>
        <Stat icon="receipt" label="Documents" value={String(docs.data?.length ?? '–')} hint="Receipts and refund notes" />
        <Stat icon="alert" label="Refunds to act on" value={String(waiting.length)} hint="Waiting, approved or failed" tone={waiting.length ? 'warn' : undefined} />
        <Stat icon="money" label="Refunded" value={ugx(refunded)} hint="All time" />
      </Fit>

      {missing.length > 0 && (
        <div className="banner warn" role="status">
          <Icon name="receipt" />
          <span className="grow">
            {missing.length} payment{missing.length === 1 ? ' has' : 's have'} no receipt number yet.
          </span>
          <button className="btn sm" onClick={() => void issueMissing()} disabled={act.busy}>
            Number them now
          </button>
        </div>
      )}

      <Tabs
        label="Show"
        value={view}
        onChange={setView}
        items={[
          ['refunds', 'Refunds', waiting.length],
          ['receipts', 'Receipts and invoices'],
        ]}
      />

      {view === 'refunds' ? (
        <section className="card">
          {!refunds.data ? (
            <SkelRows rows={4} cols={4} />
          ) : refundRows.length === 0 ? (
            <Empty icon="receipt">No refunds yet.</Empty>
          ) : (
            <div className="list">
              {refundRows.map((r) => {
                const [label, tone] = refundStatus[r.status] ?? [r.status, ''];
                const note = r.refundDocId ? docOf.get(r.refundDocId) : undefined;
                return (
                  <div key={r.id} className="list-row wrap">
                    <span className="grow stack tight">
                      <strong>
                        {r.farmName} · {ugx(r.amountUgx)}
                      </strong>
                      <small className="muted">
                        {date(r.createdAt)} · {paymentMethods[r.method] ?? r.method}
                        {r.destination ? ` to ${r.destination}` : ''} · {r.byHand ? 'by hand' : 'through provider'} · asked by {r.requestedByName}
                      </small>
                      {r.reason && <small>{r.reason}</small>}
                      {r.failReason && <small className="error-text">{r.failReason}</small>}
                      {r.refundNo && <small className="muted">Refund note {r.refundNo}</small>}
                    </span>
                    <span className="acts">
                      <span className={`chip ${tone}`}>{label}</span>
                      {r.status === 'requested' && can('finance') && (
                        <>
                          <button className="btn sm" onClick={() => void act.run(() => decideRefund(actor, r, 'approved'), r.byHand ? 'Approved. Pay it, then mark it paid.' : 'Approved. It is sent automatically when refunds through providers are switched on; otherwise pay it by hand and mark it paid.').then(reload)} disabled={act.busy}>
                            Approve
                          </button>
                          <button className="btn ghost sm" onClick={() => void act.run(() => decideRefund(actor, r, 'rejected'), 'Turned down.').then(reload)} disabled={act.busy}>
                            Turn down
                          </button>
                        </>
                      )}
                      {['approved', 'failed', 'sent'].includes(r.status) && (
                        <button className="btn outline sm" onClick={() => setPaying(r)}>
                          Mark paid
                        </button>
                      )}
                      {note && (
                        <button className="btn ghost sm" onClick={() => void get(note, 'refund')} disabled={busyDoc !== ''}>
                          <Icon name="download" /> Note
                        </button>
                      )}
                    </span>
                  </div>
                );
              })}
            </div>
          )}
        </section>
      ) : (
        <section className="card">
          {!docs.data ? (
            <SkelRows rows={5} cols={4} />
          ) : docRows.length === 0 ? (
            <Empty icon="receipt">No receipts yet. Every payment you record gets one.</Empty>
          ) : (
            <div className="list">
              {docRows.map((d) => (
                <div key={d.id} className="list-row wrap">
                  <span className="grow stack tight">
                    <strong>{d.kind === 'refund' ? d.refundNo : d.receiptNo}</strong>
                    <small className="muted">
                      {d.farmName} · {ugx(d.totalUgx)} · {date(new Date(d.paidAt || d.issuedAt))} · {paymentMethods[d.method] ?? d.method}
                      {d.reference ? ` · ${d.reference}` : ''}
                    </small>
                  </span>
                  <span className="acts">
                    {d.kind === 'refund' ? (
                      <button className="btn ghost sm" onClick={() => void get(d, 'refund')} disabled={busyDoc !== ''}>
                        <Icon name="download" /> Refund note
                      </button>
                    ) : (
                      <>
                        <button className="btn ghost sm" onClick={() => void get(d, 'receipt')} disabled={busyDoc !== ''}>
                          <Icon name="download" /> Receipt
                        </button>
                        <button className="btn ghost sm" onClick={() => void get(d, 'invoice')} disabled={busyDoc !== ''}>
                          <Icon name="download" /> Invoice
                        </button>
                      </>
                    )}
                  </span>
                </div>
              ))}
            </div>
          )}
        </section>
      )}

      {picking && (
        <Dialog title="Which payment is refunded?" onClose={() => setPicking(false)} size="lg">
          <div className="dialog-body">
            {!pays.data ? (
              <SkelRows rows={4} cols={3} />
            ) : (
              <div className="list">
                {pays.data
                  .filter((p) => p.status === 'received')
                  .slice(0, 100)
                  .map((p) => (
                    <button
                      key={p.id}
                      className="list-row row-btn"
                      onClick={() => {
                        setPicking(false);
                        setNewFor(p);
                      }}
                    >
                      <span className="grow stack tight">
                        <strong>
                          {p.farmName} · {ugx(p.amountUgx)}
                        </strong>
                        <small className="muted">
                          {date(p.paidAt)} · {paymentMethods[p.method] ?? p.method} · {p.reference || 'no transaction ID'} · {docOf.get(p.id)?.receiptNo ?? 'no receipt yet'}
                        </small>
                      </span>
                      <Icon name="chevron" />
                    </button>
                  ))}
              </div>
            )}
          </div>
        </Dialog>
      )}
      {newFor && <NewRefund pay={newFor} onClose={() => setNewFor(null)} onSaved={reload} />}
      {paying && <MarkPaid refund={paying} onClose={() => setPaying(null)} onSaved={reload} />}
    </Need>
  );
}

function NewRefund({ pay, onClose, onSaved }: { pay: PlatformPayment; onClose: () => void; onSaved: () => void }) {
  const { actor } = useAdmin();
  const act = useAction();
  const [amount, setAmount] = useState(String(pay.amountUgx));
  const [method, setMethod] = useState(pay.method);
  const [destination, setDestination] = useState('');
  const [reason, setReason] = useState('');
  const [byHand, setByHand] = useState(!['mtn', 'airtel', 'card'].includes(pay.method));
  const n = Math.round(Number(amount));
  const ok = Number.isFinite(n) && n > 0 && n <= pay.amountUgx && reason.trim().length > 2;

  const save = () =>
    act
      .run(async () => {
        await issueBillingDoc(actor, pay.id);
        await requestRefund(actor, { paymentId: pay.id, tenantId: pay.tenantId, farmName: pay.farmName, amountUgx: n, method, destination: destination.trim(), reason: reason.trim(), byHand });
      }, 'Recorded. Someone with Money access approves it next.')
      .then((done) => {
        if (done) {
          onSaved();
          onClose();
        }
      });

  return (
    <Dialog title="Record a refund" subtitle={`${pay.farmName} · paid ${ugx(pay.amountUgx)} on ${date(pay.paidAt)}`} onClose={onClose}>
      <div className="dialog-body stack">
        <MsgBanner msg={act.msg} />
        <Field label="Amount to refund (UGX)" error={n > pay.amountUgx ? 'More than was paid.' : null}>
          <input className="input" type="number" min={1} max={pay.amountUgx} value={amount} onChange={(e) => setAmount(e.target.value)} />
        </Field>
        <Field label="Send it back by">
          <select className="input" value={method} onChange={(e) => setMethod(e.target.value)}>
            {Object.entries(paymentMethods).map(([k, v]) => (
              <option key={k} value={k}>
                {v}
              </option>
            ))}
          </select>
        </Field>
        <Field label="Number or account" hint="Mobile Money number like 0772 123456, or bank details. Card refunds go back to the card.">
          <input className="input" value={destination} onChange={(e) => setDestination(e.target.value)} />
        </Field>
        <Field label="Reason">
          <input className="input" value={reason} onChange={(e) => setReason(e.target.value)} maxLength={300} />
        </Field>
        <label className="check-row">
          <input type="checkbox" checked={byHand} onChange={(e) => setByHand(e.target.checked)} />
          <span>I will pay this by hand (not through the MTN, Airtel or card connection)</span>
        </label>
      </div>
      <div className="actions">
        <button className="btn outline" onClick={onClose}>
          Cancel
        </button>
        <button className="btn" onClick={() => void save()} disabled={!ok || act.busy}>
          {act.busy ? 'Saving…' : 'Record refund'}
        </button>
      </div>
    </Dialog>
  );
}

function MarkPaid({ refund, onClose, onSaved }: { refund: Refund; onClose: () => void; onSaved: () => void }) {
  const { actor } = useAdmin();
  const act = useAction();
  const [ref, setRef] = useState(refund.providerRef);
  const save = () =>
    act.run(() => completeRefund(actor, refund, ref), 'Marked paid. A numbered refund note was made.').then((done) => {
      if (done) {
        onSaved();
        onClose();
      }
    });
  return (
    <Dialog title="Mark refund paid" subtitle={`${refund.farmName} · ${ugx(refund.amountUgx)}`} onClose={onClose}>
      <div className="dialog-body stack">
        <MsgBanner msg={act.msg} />
        <Field label="Transaction ID of the refund" hint="From the Mobile Money message, bank slip or card dashboard.">
          <input className="input" value={ref} onChange={(e) => setRef(e.target.value)} />
        </Field>
      </div>
      <div className="actions">
        <button className="btn outline" onClick={onClose}>
          Cancel
        </button>
        <button className="btn" onClick={() => void save()} disabled={act.busy || !ref.trim()}>
          {act.busy ? 'Saving…' : 'Mark paid'}
        </button>
      </div>
    </Dialog>
  );
}
