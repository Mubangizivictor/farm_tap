'use client';

import { collectionGroup, doc, getDocs, query, where } from 'firebase/firestore';
import Link from 'next/link';
import { useMemo, useState } from 'react';
import { Confirm, MsgBanner, Need, useAction, useLoad } from '@/components/admin';
import { RecordPayment } from '@/components/adminPayment';
import { Icon } from '@/components/Icon';
import { Empty, LoadError, PageHead, SearchBox, Stat } from '@/components/ui';
import { adminChange, downloadCsv, loadAllFarms, loadPayments, loadPlans, loadSmsPackages, paymentMethods, updateOp, type PlatformPayment } from '@/lib/admin';
import { useAdmin } from '@/lib/adminSession';
import { farmPlan, planOf } from '@/lib/adminView';
import { parseDate } from '@/lib/dates';
import { firebase } from '@/lib/firebase';
import { date, shortDate, ugx } from '@/lib/format';
import { monthlyValue } from '@/lib/platform';

export default function Money() {
  const { actor } = useAdmin();
  const pays = useLoad(loadPayments);
  const farms = useLoad(loadAllFarms);
  const plans = useLoad(loadPlans);
  const packages = useLoad(loadSmsPackages);
  // Payment claims the farms sent from the app (status "submitted").
  const claims = useLoad(async () => {
    const s = await getDocs(query(collectionGroup(firebase().db, 'payments'), where('body.status', '==', 'submitted')));
    return s.docs.map((d) => ({ path: d.ref.path, ...(d.data() as { tenantId: string; createdAt: string; body: Record<string, unknown> }) }));
  });
  const act = useAction();
  const [open, setOpen] = useState(false);
  const [voiding, setVoiding] = useState<PlatformPayment | null>(null);
  const [reason, setReason] = useState('');
  const [q, setQ] = useState('');
  const now = new Date();

  const list = useMemo(() => {
    const t = q.trim().toLowerCase();
    return (pays.data ?? []).filter((p) => !t || [p.farmName, p.reference, p.method, p.recordedByName].some((v) => v.toLowerCase().includes(t)));
  }, [pays.data, q]);
  const ok = (pays.data ?? []).filter((p) => p.status === 'received');
  const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);
  const lastMonthStart = new Date(now.getFullYear(), now.getMonth() - 1, 1);
  const sum = (from: Date, to?: Date) => ok.filter((p) => p.paidAt && p.paidAt >= from && (!to || p.paidAt < to)).reduce((t, p) => t + p.amountUgx, 0);
  const paying = (farms.data ?? []).filter((f) => f.status !== 'suspended' && ['paid', 'grace'].includes(farmPlan(f, now).kind));
  const mrr = paying.reduce((t, f) => t + monthlyValue(planOf(f, plans.data ?? [])), 0);
  const overdue = (farms.data ?? []).filter((f) => farmPlan(f, now).kind === 'grace');
  const byMethod = Object.entries(ok.filter((p) => p.paidAt && p.paidAt >= monthStart).reduce<Record<string, number>>((a, p) => ({ ...a, [p.method]: (a[p.method] ?? 0) + p.amountUgx }), {}));

  return (
    <Need perm="finance">
      <PageHead title="Payments" subtitle="Money FarmTap received, and what farms owe">
        <SearchBox value={q} onChange={setQ} placeholder="Farm, transaction ID" />
        <button
          className="btn outline sm"
          onClick={() =>
            downloadCsv(
              `farmtap-payments-${now.toISOString().slice(0, 10)}`,
              ['Paid on', 'Farm', 'For', 'Amount UGX', 'Method', 'Transaction ID', 'Months', 'SMS credits', 'Paid until', 'Status', 'Recorded by', 'Note'],
              list.map((p) => [date(p.paidAt), p.farmName, p.kind, p.amountUgx, paymentMethods[p.method] ?? p.method, p.reference, p.months, p.smsCredits, date(p.newPaidUntil), p.status, p.recordedByName, p.note]),
            )
          }
        >
          <Icon name="download" /> CSV
        </button>
        <button className="btn sm" onClick={() => setOpen(true)}>
          <Icon name="plus" /> Record payment
        </button>
      </PageHead>

      <MsgBanner msg={act.msg} />
      <LoadError code={pays.error} />

      <div className="grid">
        <Stat icon="money" label="MRR" value={ugx(mrr)} hint={`${paying.length} paying farms`} tone="gold" />
        <Stat icon="receipt" label="This month" value={ugx(sum(monthStart))} hint={`Last month ${ugx(sum(lastMonthStart, monthStart))}`} tone="gold" />
        <Stat icon="alert" label="Overdue" value={String(overdue.length)} hint="In the 7 days of grace" tone={overdue.length ? 'warn' : undefined} />
        <Stat icon="chart" label="All time" value={ugx(sum(new Date(0)))} hint={`${ok.length} payments`} />
      </div>

      <div className="grid cols">
        <section className="card">
          <div className="card-head">
            <h2>This month by method</h2>
          </div>
          <div className="list">
            {byMethod.map(([m, v]) => (
              <div key={m} className="list-row">
                <span className="grow">{paymentMethods[m] ?? m}</span>
                <strong className="num">{ugx(v)}</strong>
              </div>
            ))}
            {!byMethod.length && <Empty>Nothing yet this month.</Empty>}
          </div>
        </section>
        <section className="card">
          <div className="card-head">
            <h2>Claims from farms</h2>
            <span className="small muted">Sent from the app, waiting for you</span>
          </div>
          <div className="list">
            {(claims.data ?? []).map((c) => {
              const f = (farms.data ?? []).find((x) => x.id === c.tenantId);
              return (
                <div key={c.path} className="list-row">
                  <div className="stack grow" style={{ gap: 0 }}>
                    <Link href={`/admin/farm/?id=${c.tenantId}`}>{f?.name ?? c.tenantId}</Link>
                    <span className="small muted">
                      {ugx(Number(c.body.amount ?? c.body.amountUgx ?? 0))} · {String(c.body.method ?? '')} {String(c.body.reference ?? c.body.transactionId ?? '')} · {shortDate(parseDate(c.createdAt))}
                    </span>
                  </div>
                </div>
              );
            })}
            {claims.data && !claims.data.length && <Empty>No claims waiting.</Empty>}
            {claims.error && <p className="small muted">Could not load claims. Deploy the Firestore indexes (see the setup steps).</p>}
          </div>
        </section>
        <section className="card">
          <div className="card-head">
            <h2>Overdue farms</h2>
          </div>
          <div className="list">
            {overdue.map((f) => (
              <Link key={f.id} href={`/admin/farm/?id=${f.id}`} className="list-row" style={{ color: 'inherit', textDecoration: 'none' }}>
                <span className="grow">{f.name}</span>
                <span className="small muted">was due {shortDate(f.paidUntil)}</span>
              </Link>
            ))}
            {!overdue.length && <Empty>Nobody is overdue.</Empty>}
          </div>
        </section>
      </div>

      <div className="table-wrap">
        <table className="table">
          <thead>
            <tr>
              <th>Paid on</th>
              <th>Farm</th>
              <th>For</th>
              <th className="r">Amount</th>
              <th>Method</th>
              <th>Transaction ID</th>
              <th>Recorded by</th>
              <th />
            </tr>
          </thead>
          <tbody>
            {list.map((p) => (
              <tr key={p.id} style={p.status === 'void' ? { opacity: 0.5 } : undefined}>
                <td>{shortDate(p.paidAt)}</td>
                <td>
                  <Link href={`/admin/farm/?id=${p.tenantId}`}>{p.farmName}</Link>
                </td>
                <td>{p.kind === 'sms' ? `${p.smsCredits} SMS` : `${p.months} month${p.months === 1 ? '' : 's'}, to ${shortDate(p.newPaidUntil)}`}</td>
                <td className="r">{ugx(p.amountUgx)}</td>
                <td>{paymentMethods[p.method] ?? p.method}</td>
                <td className="mono">{p.reference}</td>
                <td className="small muted">{p.recordedByName}</td>
                <td className="r">
                  {p.status === 'void' ? (
                    <span className="chip bad" title={p.voidReason}>
                      Void
                    </span>
                  ) : (
                    <button className="btn sm ghost" onClick={() => setVoiding(p)}>
                      Void
                    </button>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        {pays.data && !list.length && <Empty>No payments recorded yet.</Empty>}
      </div>

      {open && <RecordPayment farms={farms.data ?? []} plans={plans.data ?? []} packages={packages.data ?? []} onClose={() => setOpen(false)} onSaved={() => (pays.reload(), farms.reload())} />}
      {voiding && (
        <Confirm
          title={`Void ${ugx(voiding.amountUgx)} from ${voiding.farmName}?`}
          confirm="Void payment"
          danger
          busy={act.busy}
          onClose={() => setVoiding(null)}
          onConfirm={() =>
            void act
              .run(
                () =>
                  adminChange(actor, { action: 'payment.void', target: `platformPayments/${voiding.id}`, tenantId: voiding.tenantId, details: { reason } }, [
                    updateOp(doc(firebase().db, 'platformPayments', voiding.id), { status: 'void', voidReason: reason.trim(), voidedBy: actor.name }),
                  ]),
                'Payment voided. Change the farm’s paid-until on its page if it was extended by mistake.',
              )
              .then(() => {
                setVoiding(null);
                pays.reload();
              })
          }
        >
          <p className="muted">A voided payment stays in the list, crossed out, so the books always add up. It does not change the farm&apos;s paid-until date.</p>
          <label className="field">
            <span>Reason</span>
            <input className="input" value={reason} onChange={(e) => setReason(e.target.value)} />
          </label>
        </Confirm>
      )}
    </Need>
  );
}
