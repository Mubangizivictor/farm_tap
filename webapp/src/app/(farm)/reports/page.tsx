'use client';

import { useState } from 'react';
import { Fit } from '@/components/fit';
import { Icon } from '@/components/Icon';
import { CardHead, Empty, ExportButtons, PageHead, SkelCard } from '@/components/ui';
import { downloadCsv } from '@/lib/csv';
import { localIso } from '@/lib/dates';
import { useRecords } from '@/lib/data';
import {
  alive,
  categoryName,
  litresBetween,
  manages,
  recordDate,
  saleValue,
  type ContactBody,
  type ExpenseBody,
  type IncomeBody,
  type MilkBody,
  type MilkSaleBody,
  type StaffBody,
  type TreatmentBody,
  type WageBody,
} from '@/lib/domain';
import { litres, num1, ugx } from '@/lib/format';
import { useFarm } from '@/lib/session';

const monthName = new Intl.DateTimeFormat('en-GB', { month: 'long', year: 'numeric' });

/**
 * Monthly farm report (decision 0023): milk, money in and out, cost of a
 * litre, where the money went, who was paid. Prints to one page and exports.
 */
export default function Reports() {
  const farm = useFarm();
  const boss = manages(farm);
  const [offset, setOffset] = useState(0);
  const now = new Date();
  const from = new Date(now.getFullYear(), now.getMonth() + offset, 1);
  const to = new Date(from.getFullYear(), from.getMonth() + 1, 1);
  const since = localIso(new Date(from.getFullYear(), from.getMonth() - 1, 1));
  const id = boss ? farm.id : null;
  const milk = useRecords<MilkBody>(id, 'milkRecords', since);
  const sales = useRecords<MilkSaleBody>(id, 'milkSales', since);
  const expenses = useRecords<ExpenseBody>(id, 'expenses', since);
  const income = useRecords<IncomeBody>(id, 'income', since);
  const wages = useRecords<WageBody>(id, 'wages', since);
  const staff = useRecords<StaffBody>(id, 'staff');
  const contacts = useRecords<ContactBody>(id, 'contacts');
  const treatments = useRecords<TreatmentBody>(id, 'treatments', since);

  if (!boss) return <Empty icon="lock">Only the owner or manager can see reports.</Empty>;
  const loading = milk.loading || sales.loading || expenses.loading || income.loading;

  const within = (d: Date) => d >= from && d < to;
  const produced = litresBetween(milk.data, from, to);
  const days = Math.max(1, Math.round((Math.min(to.getTime(), now.getTime()) - from.getTime()) / 86400000));
  const salesIn = alive(sales.data).filter((s) => within(recordDate(s)));
  const sold = salesIn.reduce((t, s) => t + (Number(s.body.litres) || 0), 0);
  const milkMoney = salesIn.reduce((t, s) => t + saleValue(s.body), 0);
  const otherMoney = alive(income.data)
    .filter((e) => within(recordDate(e, 'at')))
    .reduce((t, e) => t + (Number(e.body.amount) || 0), 0);
  const spentList = alive(expenses.data).filter((e) => within(recordDate(e, 'at')));
  const spent = spentList.reduce((t, e) => t + (Number(e.body.amount) || 0), 0);
  const byCat = new Map<string, number>();
  for (const e of spentList) byCat.set(e.body.category, (byCat.get(e.body.category) ?? 0) + (Number(e.body.amount) || 0));
  const cats = [...byCat.entries()].sort((a, b) => b[1] - a[1]);
  const feedCost = byCat.get('feed') ?? 0;
  const profit = milkMoney + otherMoney - spent;
  const perLitre = produced > 0 ? spent / produced : null;
  const feedPerLitre = produced > 0 ? feedCost / produced : null;
  const avgPrice = sold > 0 ? milkMoney / sold : null;
  const bySup = new Map<string, number>();
  for (const e of spentList) if (e.body.supplierId) bySup.set(e.body.supplierId, (bySup.get(e.body.supplierId) ?? 0) + (Number(e.body.amount) || 0));
  const supName = (sid: string) => alive(contacts.data).find((c) => c.id === sid)?.body.name ?? 'Removed contact';
  const paid = new Map<string, number>();
  for (const w of alive(wages.data).filter((w) => within(recordDate(w, 'at')))) paid.set(w.body.staffId, (paid.get(w.body.staffId) ?? 0) + (Number(w.body.amount) || 0));
  const staffName = (sid: string) => alive(staff.data).find((s) => s.id === sid)?.body.name ?? 'Former worker';
  const treated = alive(treatments.data).filter((t) => within(recordDate(t, 'given'))).length;

  const csv = () =>
    downloadCsv(`${farm.name}-report-${localIso(from).slice(0, 7)}`, ['Item', 'Value'], [
      ['Month', monthName.format(from)],
      ['Milk produced (L)', Math.round(produced * 10) / 10],
      ['Milk a day (L)', Math.round((produced / days) * 10) / 10],
      ['Milk sold (L)', sold],
      ['Milk sales (UGX)', Math.round(milkMoney)],
      ['Other income (UGX)', otherMoney],
      ['Spent (UGX)', spent],
      ['Profit (UGX)', Math.round(profit)],
      ['Cost of a litre (UGX)', perLitre != null ? Math.round(perLitre) : ''],
      ['Feed cost of a litre (UGX)', feedPerLitre != null ? Math.round(feedPerLitre) : ''],
      ...cats.map(([c, v]) => [`Spent on ${categoryName[c] ?? c}`, v] as [string, number]),
      ...[...bySup.entries()].map(([sid, v]) => [`Paid to ${supName(sid)}`, v] as [string, number]),
      ...[...paid.entries()].map(([sid, v]) => [`Pay to ${staffName(sid)}`, v] as [string, number]),
    ]);

  return (
    <>
      <PageHead title="Monthly report" subtitle={`${farm.name} · ${monthName.format(from)}`}>
        <div className="row month-nav no-print">
          <button className="icon-btn" aria-label="Previous month" onClick={() => setOffset(offset - 1)} style={{ transform: 'scaleX(-1)' }}>
            <Icon name="chevron" />
          </button>
          <strong>{monthName.format(from)}</strong>
          <button className="icon-btn" aria-label="Next month" onClick={() => setOffset(offset + 1)} disabled={offset >= 0}>
            <Icon name="chevron" />
          </button>
        </div>
        <ExportButtons onCsv={csv} />
      </PageHead>

      {loading ? (
        <Fit kind="cards" cols={[1, 2, 2, 2]}>
          <SkelCard lines={5} />
          <SkelCard lines={5} />
        </Fit>
      ) : (
        <>
          <section className={`card report-hero ${profit < 0 ? 'bad' : ''}`}>
            <span className="small muted">{profit < 0 ? 'Loss' : 'Profit'} this month</span>
            <strong className="big-num">
              {profit < 0 ? '−' : ''}
              {ugx(Math.abs(profit))}
            </strong>
            <span className="small">
              {ugx(milkMoney + otherMoney)} in · {ugx(spent)} out
            </span>
          </section>
          <Fit kind="cards" cols={[1, 2, 2, 2]}>
            <section className="card">
              <CardHead title="Milk" />
              <div className="list">
                <Row k="Produced" v={litres(produced)} />
                <Row k="A day on average" v={litres(produced / days)} />
                <Row k="Sold" v={litres(sold)} />
                <Row k="Average price" v={avgPrice != null ? `${ugx(avgPrice)} a litre` : '–'} />
                <Row k="Cost to produce a litre" v={perLitre != null ? ugx(perLitre) : '–'} strong />
                <Row k="Feed cost of a litre" v={feedPerLitre != null ? ugx(feedPerLitre) : '–'} />
              </div>
              {avgPrice != null && perLitre != null && (
                <p className={`small ${avgPrice < perLitre ? 'down' : 'up'}`}>
                  {avgPrice < perLitre ? `Each litre sold loses about ${ugx(perLitre - avgPrice)}.` : `Each litre sold earns about ${ugx(avgPrice - perLitre)} after costs.`}
                </p>
              )}
            </section>
            <section className="card">
              <CardHead title="Where the money went" />
              {cats.length === 0 ? (
                <Empty icon="receipt">No spending this month.</Empty>
              ) : (
                <div className="list">
                  {cats.map(([c, v]) => (
                    <Row key={c} k={categoryName[c] ?? c} v={`${ugx(v)} · ${Math.round((v / Math.max(1, spent)) * 100)}%`} />
                  ))}
                </div>
              )}
            </section>
            <section className="card">
              <CardHead title="Paid to suppliers" />
              {bySup.size === 0 ? (
                <Empty icon="truck">No supplier payments this month.</Empty>
              ) : (
                <div className="list">
                  {[...bySup.entries()]
                    .sort((a, b) => b[1] - a[1])
                    .map(([sid, v]) => (
                      <Row key={sid} k={supName(sid)} v={ugx(v)} />
                    ))}
                </div>
              )}
            </section>
            <section className="card">
              <CardHead title="Workers paid" />
              {paid.size === 0 ? (
                <Empty icon="workers">No pay recorded this month.</Empty>
              ) : (
                <div className="list">
                  {[...paid.entries()]
                    .sort((a, b) => b[1] - a[1])
                    .map(([sid, v]) => (
                      <Row key={sid} k={staffName(sid)} v={ugx(v)} />
                    ))}
                </div>
              )}
              <p className="small muted">
                {treated} treatment{treated === 1 ? '' : 's'} this month. Milk a day: {num1(produced / days)} L.
              </p>
            </section>
          </Fit>
        </>
      )}
    </>
  );
}

function Row({ k, v, strong }: { k: string; v: string; strong?: boolean }) {
  return (
    <div className="list-row">
      <span className="grow">{k}</span>
      {strong ? <strong className="num">{v}</strong> : <span className="num">{v}</span>}
    </div>
  );
}
