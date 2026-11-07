'use client';

import { collection, getDocs } from 'firebase/firestore';
import Link from 'next/link';
import { Fit, useLoad } from '@/components/admin';
import { Icon } from '@/components/Icon';
import { Empty, PageHead, PrintButton, Stat } from '@/components/ui';
import { loadAllFarms, loadIntegrations, loadPayments, loadPlans, type AdminFarm } from '@/lib/admin';
import { SheetsSendButton } from '@/components/SheetsSend';
import { sheetsUrlOk } from '@/lib/sheets';
import { useAdmin } from '@/lib/adminSession';
import { addDays } from '@/lib/dates';
import { firebase } from '@/lib/firebase';
import { count, date, shortDate, ugx } from '@/lib/format';
import { sectorName } from '@/lib/labels';
import { farmPlan, planOf } from '@/lib/adminView';
import { monthlyValue } from '@/lib/platform';

export default function Overview() {
  const { can, me } = useAdmin();
  const seeFarms = can('farms') || can('finance') || can('support') || can('users');
  const farms = useLoad(() => (seeFarms ? loadAllFarms() : Promise.resolve([])), [seeFarms]);
  const pays = useLoad(() => (can('finance') ? loadPayments() : Promise.resolve([])), [me?.role]);
  const plans = useLoad(loadPlans);
  const sheets = useLoad(loadIntegrations);
  const waitlist = useLoad(async () => {
    if (!can('farms')) return [];
    const s = await getDocs(collection(firebase().db, 'waitlist'));
    return s.docs.map((d) => d.data() as { sector?: string; name?: string; whatsapp?: string });
  }, [me?.role]);

  const now = new Date();
  const list = farms.data ?? [];
  const allPlans = plans.data ?? [];
  const states = list.map((f) => ({ f, s: farmPlan(f, now) }));
  const live = list.filter((f) => f.status !== 'suspended');
  const paid = states.filter((x) => x.f.status !== 'suspended' && (x.s.kind === 'paid' || x.s.kind === 'grace'));
  const trials = states.filter((x) => x.f.status !== 'suspended' && x.s.kind === 'trial');
  const endingSoon = trials.filter((x) => x.s.kind === 'trial' && x.s.daysLeft <= 3);
  const overdue = states.filter((x) => x.s.kind === 'grace');
  const pending = list.filter((f) => f.review === 'pending');
  const mrr = paid.reduce((t, x) => t + monthlyValue(planOf(x.f, allPlans)), 0);
  const payments = (pays.data ?? []).filter((p) => p.status === 'received');
  const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);
  const thisMonth = payments.filter((p) => p.paidAt && p.paidAt >= monthStart).reduce((t, p) => t + p.amountUgx, 0);
  const smsSold = payments.filter((p) => p.kind === 'sms').reduce((t, p) => t + p.smsCredits, 0);
  const weekAgo = addDays(now, -7);
  const newThisWeek = list.filter((f) => f.createdAt && f.createdAt >= weekAgo).length;
  const activeWeek = list.filter((f) => f.lastSeenAt && f.lastSeenAt >= weekAgo).length;

  // Revenue for the last 6 months.
  const months = Array.from({ length: 6 }, (_, i) => new Date(now.getFullYear(), now.getMonth() - 5 + i, 1));
  const revenue = months.map((m) => {
    const end = new Date(m.getFullYear(), m.getMonth() + 1, 1);
    return payments.filter((p) => p.paidAt && p.paidAt >= m && p.paidAt < end).reduce((t, p) => t + p.amountUgx, 0);
  });
  const maxRev = Math.max(1, ...revenue);

  const bySector = Object.entries(
    live.reduce<Record<string, number>>((acc, f) => {
      acc[f.sector] = (acc[f.sector] ?? 0) + 1;
      return acc;
    }, {}),
  ).sort((a, b) => b[1] - a[1]);
  const waitBySector = Object.entries(
    (waitlist.data ?? []).reduce<Record<string, number>>((acc, w) => {
      const s = w.sector ?? 'other';
      acc[s] = (acc[s] ?? 0) + 1;
      return acc;
    }, {}),
  ).sort((a, b) => b[1] - a[1]);

  return (
    <>
      <PageHead title={`Hello${me?.name ? `, ${me.name.split(' ')[0]}` : ''}`} subtitle="How FarmTap is doing today.">
        <PrintButton />
      </PageHead>
      {sheets.data && sheetsUrlOk(sheets.data.sheets.url) && <SheetsSendButton settings={sheets.data.sheets} auto />}

      {seeFarms && (
        <Fit kind="stats">
          <Stat href="/admin/farms/" icon="home" label="Farms" value={count(live.length)} hint={`${newThisWeek} new this week · ${activeWeek} active`} />
          <Stat href={overdue.length ? "/admin/farms/?filter=grace" : "/admin/farms/?filter=paid"} icon="check" label="Paying" value={count(paid.length)} hint={overdue.length ? `${overdue.length} overdue` : 'None overdue'} tone={overdue.length ? 'warn' : undefined} />
          <Stat href="/admin/farms/?filter=trial" icon="clock" label="On trial" value={count(trials.length)} hint={`${endingSoon.length} end in 3 days`} tone="info" />
          {can('finance') && <Stat href="/admin/money/" icon="money" label="MRR" value={ugx(mrr)} hint="Monthly value of paying farms" tone="gold" />}
          {can('finance') && <Stat href="/admin/money/" icon="receipt" label="This month" value={ugx(thisMonth)} hint={`${count(smsSold)} SMS credits sold in total`} tone="gold" />}
          <Stat href="/admin/farms/?filter=pending" icon="shield" label="To review" value={count(pending.length)} hint="New farms waiting" tone={pending.length ? 'warn' : undefined} />
        </Fit>
      )}

      <Fit>
        {can('finance') && (
          <section className="card">
            <div className="card-head">
              <h2>Revenue, last 6 months</h2>
              <Link href="/admin/money/" className="small">
                Payments
              </Link>
            </div>
            <div className="bars money">
              {months.map((m, i) => (
                <div key={m.toISOString()} className="bar-col" title={`${m.toLocaleString('en-GB', { month: 'long' })}: ${ugx(revenue[i])}`}>
                  <div className={`bar ${revenue[i] ? '' : 'zero'}`} style={{ height: `${(revenue[i] / maxRev) * 100}%` }} />
                  <span className="bar-label">{m.toLocaleString('en-GB', { month: 'short' })}</span>
                </div>
              ))}
            </div>
          </section>
        )}

        {seeFarms && (
          <section className="card">
            <div className="card-head">
              <h2>Needs you</h2>
              <Link href="/admin/farms/" className="small">
                All farms
              </Link>
            </div>
            <div className="list">
              {pending.slice(0, 4).map((f) => (
                <Link key={f.id} href={`/admin/farm/?id=${f.id}`} className="list-row" style={{ color: 'inherit', textDecoration: 'none' }}>
                  <span className="chip warn">Review</span>
                  <span className="grow">{f.name}</span>
                  <span className="small muted">{shortDate(f.createdAt)}</span>
                </Link>
              ))}
              {endingSoon.slice(0, 4).map(({ f, s }) => (
                <Link key={f.id} href={`/admin/farm/?id=${f.id}`} className="list-row" style={{ color: 'inherit', textDecoration: 'none' }}>
                  <span className="chip brand">Trial</span>
                  <span className="grow">{f.name}</span>
                  <span className="small muted">{s.kind === 'trial' ? `ends ${date(s.endsAt)}` : ''}</span>
                </Link>
              ))}
              {overdue.slice(0, 4).map(({ f }) => (
                <Link key={f.id} href={`/admin/farm/?id=${f.id}`} className="list-row" style={{ color: 'inherit', textDecoration: 'none' }}>
                  <span className="chip warn">Overdue</span>
                  <span className="grow">{f.name}</span>
                  <span className="small muted">{f.owner.name}</span>
                </Link>
              ))}
              {!pending.length && !endingSoon.length && !overdue.length && <Empty>Nothing waiting. Go and sell.</Empty>}
            </div>
          </section>
        )}

        {seeFarms && (
          <section className="card">
            <div className="card-head">
              <h2>Farms by sector</h2>
            </div>
            <div className="list">
              {bySector.map(([s, n]) => (
                <Link key={s} href={`/admin/farms/?sector=${encodeURIComponent(s)}`} className="list-row" style={{ color: 'inherit', textDecoration: 'none' }}>
                  <span className="grow">{sectorName[s] ?? s}</span>
                  <strong className="num">{n}</strong>
                  <Icon name="chevron" className="icon muted" />
                </Link>
              ))}
              {!bySector.length && <Empty>No farms yet.</Empty>}
            </div>
          </section>
        )}

        {can('farms') && (
          <section className="card">
            <div className="card-head">
              <h2>Waiting list</h2>
              <span className="small muted">Sectors not open yet</span>
            </div>
            <div className="list">
              {waitBySector.map(([s, n]) => (
                <div key={s} className="list-row">
                  <span className="grow">{sectorName[s] ?? s}</span>
                  <strong className="num">{n}</strong>
                </div>
              ))}
              {!waitBySector.length && <Empty>Nobody on the waiting list yet.</Empty>}
            </div>
            {waitBySector.length > 0 && (
              <Link href="/admin/users/?tab=waitlist" className="small">
                See names and numbers <Icon name="chevron" className="icon" />
              </Link>
            )}
          </section>
        )}
      </Fit>

      {!seeFarms && !can('finance') && <Empty>Use the menu to open the areas your role covers.</Empty>}
    </>
  );
}
