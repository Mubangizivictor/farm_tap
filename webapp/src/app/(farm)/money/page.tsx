'use client';

import { useState, type FormEvent } from 'react';
import { Icon } from '@/components/Icon';
import { Dialog, Empty, ExportButtons, LoadError, PageHead, SaveHint, Stat } from '@/components/ui';
import { downloadCsv } from '@/lib/csv';
import { dayKey, localIso, parseDate } from '@/lib/dates';
import { addRecord, saveError, useRecords } from '@/lib/data';
import { alive, expenseCategories, manages, recordDate, type ExpenseBody, type MilkSaleBody } from '@/lib/domain';
import { date, litres, ugx, words } from '@/lib/format';
import { firebase } from '@/lib/firebase';
import { useFarm, useSession } from '@/lib/session';

const monthName = new Intl.DateTimeFormat('en-GB', { month: 'long', year: 'numeric' });

function AddExpense({ onClose }: { onClose: () => void }) {
  const farm = useFarm();
  const { user, canSave, online } = useSession();
  const [category, setCategory] = useState<string>('feed');
  const [amount, setAmount] = useState('');
  const [day, setDay] = useState(dayKey(new Date()));
  const [note, setNote] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');

  async function save(ev: FormEvent) {
    ev.preventDefault();
    if (!user) return;
    setBusy(true);
    try {
      const picked = parseDate(day) ?? new Date();
      const now = new Date();
      // Keep the time of day so today's entries sort in order.
      const at = new Date(picked.getFullYear(), picked.getMonth(), picked.getDate(), now.getHours(), now.getMinutes());
      await addRecord(firebase().db, farm.id, 'expenses', user.uid, {
        category,
        amount: Math.round(Number(amount)),
        at: localIso(at),
        note: note.trim() || null,
        sourceId: null,
      });
      onClose();
    } catch (e) {
      setError(saveError((e as { code?: string }).code));
      setBusy(false);
    }
  }

  return (
    <Dialog title="Add expense" onClose={onClose}>
      <form className="stack" onSubmit={save}>
        <div className="field">
          <span>What for?</span>
          <div className="row wrap">
            {expenseCategories.map((c) => (
              <button type="button" key={c} className={`chip ${category === c ? 'brand' : ''}`} style={{ border: 0, cursor: 'pointer' }} onClick={() => setCategory(c)}>
                {words(c)}
              </button>
            ))}
          </div>
        </div>
        <label className="field">
          <span>Amount (UGX)</span>
          <input className="input" type="number" min={1} step={1} inputMode="numeric" required value={amount} onChange={(e) => setAmount(e.target.value)} autoFocus />
        </label>
        <label className="field">
          <span>Date</span>
          <input className="input" type="date" max={dayKey(new Date())} required value={day} onChange={(e) => setDay(e.target.value)} />
        </label>
        <label className="field">
          <span>Note (optional)</span>
          <input className="input" value={note} onChange={(e) => setNote(e.target.value)} placeholder="e.g. 10 bags of dairy meal" />
        </label>
        {error && <p className="error-text">{error}</p>}
        <SaveHint canSave={canSave} online={online} />
        <div className="actions">
          <button type="button" className="btn outline" onClick={onClose}>
            Cancel
          </button>
          <button className="btn" disabled={busy || !canSave}>
            {busy ? 'Saving…' : 'Save expense'}
          </button>
        </div>
      </form>
    </Dialog>
  );
}

/** Farm money only (binding rule 8: household money is never mixed in). */
export default function Money() {
  const farm = useFarm();
  const { canSave } = useSession();
  const [offset, setOffset] = useState(0);
  const [adding, setAdding] = useState(false);
  const now = new Date();
  const from = new Date(now.getFullYear(), now.getMonth() + offset, 1);
  const to = new Date(from.getFullYear(), from.getMonth() + 1, 1);
  const expenses = useRecords<ExpenseBody>(farm.id, 'expenses', localIso(new Date(from.getFullYear(), from.getMonth() - 1, 1)));
  const sales = useRecords<MilkSaleBody>(farm.id, 'milkSales', localIso(new Date(from.getFullYear(), from.getMonth() - 1, 1)));

  if (!manages(farm)) return <Empty>Only the owner or manager can see money.</Empty>;

  const inMonth = alive(expenses.data)
    .filter((e) => {
      const at = recordDate(e, 'at');
      return at >= from && at < to;
    })
    .sort((a, b) => recordDate(b, 'at').getTime() - recordDate(a, 'at').getTime());
  const spent = inMonth.reduce((t, e) => t + (Number(e.body.amount) || 0), 0);
  const salesIn = alive(sales.data).filter((s) => {
    const at = recordDate(s);
    return at >= from && at < to;
  });
  const income = salesIn.reduce((t, s) => t + (Number(s.body.litres) || 0) * (Number(s.body.pricePerLitre) || 0), 0);
  const unpaid = salesIn.filter((s) => !s.body.paid).reduce((t, s) => t + (Number(s.body.litres) || 0) * (Number(s.body.pricePerLitre) || 0), 0);
  const soldLitres = salesIn.reduce((t, s) => t + (Number(s.body.litres) || 0), 0);
  const byCat = new Map<string, number>();
  for (const e of inMonth) byCat.set(e.body.category, (byCat.get(e.body.category) ?? 0) + (Number(e.body.amount) || 0));
  const cats = [...byCat.entries()].sort((a, b) => b[1] - a[1]);
  const biggest = Math.max(...cats.map((c) => c[1]), 1);

  const csv = () =>
    downloadCsv(
      `${farm.name}-money-${dayKey(from).slice(0, 7)}`,
      ['Date', 'Type', 'Category / buyer', 'Amount (UGX)', 'Note'],
      [
        ...inMonth.map((e) => [dayKey(recordDate(e, 'at')), 'Expense', words(e.body.category), -Number(e.body.amount), e.body.note ?? '']),
        ...salesIn.map((s) => [
          dayKey(recordDate(s)),
          'Milk sale',
          s.body.buyer,
          Math.round(Number(s.body.litres) * Number(s.body.pricePerLitre)),
          `${s.body.litres} L at ${s.body.pricePerLitre}${s.body.paid ? '' : ' (not paid yet)'}`,
        ]),
      ],
    );

  return (
    <>
      <PageHead title="Money" subtitle="Farm money only. Household money stays out of FarmTap.">
        <div className="row">
          <button className="icon-btn" aria-label="Previous month" onClick={() => setOffset(offset - 1)} style={{ transform: 'scaleX(-1)' }}>
            <Icon name="chevron" />
          </button>
          <strong>{monthName.format(from)}</strong>
          <button className="icon-btn" aria-label="Next month" onClick={() => setOffset(offset + 1)} disabled={offset >= 0}>
            <Icon name="chevron" />
          </button>
        </div>
        <ExportButtons onCsv={csv} />
        <button className="btn sm" onClick={() => setAdding(true)} disabled={!canSave}>
          <Icon name="plus" /> Add expense
        </button>
      </PageHead>
      <LoadError code={expenses.error} />

      <div className="grid">
        <Stat icon="drop" label="Milk sales" value={ugx(income)} hint={`${litres(soldLitres)} sold${unpaid ? ` · ${ugx(unpaid)} not paid yet` : ''}`} />
        <Stat icon="money" label="Spent" value={ugx(spent)} hint={`${inMonth.length} expenses`} tone="warn" />
        <Stat
          icon="check"
          label="Left over"
          value={ugx(income - spent)}
          hint={income - spent >= 0 ? 'Milk sales minus spending' : 'Spending is more than milk sales'}
          tone={income - spent >= 0 ? 'gold' : 'bad'}
        />
      </div>

      <div className="grid cols">
        <section className="card">
          <div className="card-head">
            <h2>Where the money went</h2>
          </div>
          {cats.length === 0 ? (
            <p className="muted">No spending recorded this month.</p>
          ) : (
            <div className="stack">
              {cats.map(([c, v]) => (
                <div key={c} className="stack" style={{ gap: 'var(--s-xxs)' }}>
                  <div className="row between small">
                    <span>{words(c)}</span>
                    <span className="num">
                      {ugx(v)} · {Math.round((v / spent) * 100)}%
                    </span>
                  </div>
                  <div className="split">
                    <span className="a" style={{ width: `${(v / biggest) * 100}%` }} />
                  </div>
                </div>
              ))}
            </div>
          )}
        </section>
        <section className="card">
          <div className="card-head">
            <h2>Milk buyers</h2>
          </div>
          {salesIn.length === 0 ? (
            <p className="muted">No milk sales recorded this month. They are recorded on the phone (Milk → Sales).</p>
          ) : (
            <div className="list">
              {[...new Set(salesIn.map((s) => s.body.buyer))].map((b) => {
                const mine = salesIn.filter((s) => s.body.buyer === b);
                const amt = mine.reduce((t, s) => t + s.body.litres * s.body.pricePerLitre, 0);
                const owed = mine.filter((s) => !s.body.paid).reduce((t, s) => t + s.body.litres * s.body.pricePerLitre, 0);
                return (
                  <div key={b} className="list-row">
                    <span className="grow">{b}</span>
                    <span className="num">{ugx(amt)}</span>
                    {owed > 0 ? <span className="chip warn">Owes {ugx(owed)}</span> : <span className="chip ok">Paid</span>}
                  </div>
                );
              })}
            </div>
          )}
        </section>
      </div>

      <div className="table-wrap">
        <table className="table">
          <thead>
            <tr>
              <th>Date</th>
              <th>Category</th>
              <th>Note</th>
              <th className="r">Amount</th>
            </tr>
          </thead>
          <tbody>
            {inMonth.map((e) => (
              <tr key={e.id}>
                <td>{date(recordDate(e, 'at'))}</td>
                <td>
                  <span className="chip">{words(e.body.category)}</span>
                </td>
                <td>{e.body.note || '–'}</td>
                <td className="r">{ugx(e.body.amount)}</td>
              </tr>
            ))}
          </tbody>
        </table>
        {!expenses.loading && inMonth.length === 0 && <Empty>No expenses in {monthName.format(from)}.</Empty>}
      </div>

      {adding && <AddExpense onClose={() => setAdding(false)} />}
    </>
  );
}
