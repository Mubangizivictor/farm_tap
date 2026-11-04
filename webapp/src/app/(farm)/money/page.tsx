'use client';

import Link from 'next/link';
import { useState } from 'react';
import { Fit } from '@/components/fit';
import { Icon } from '@/components/Icon';
import { CardHead, ConfirmDialog, Empty, ExportButtons, Field, FormDialog, LoadError, PageHead, SkelRows, Stat, Tabs, useSave, useToast } from '@/components/ui';
import { downloadCsv } from '@/lib/csv';
import { dayKey, localIso, parseDate } from '@/lib/dates';
import { addRecord, removeRecord, useRecords } from '@/lib/data';
import {
  alive,
  expenseCategories,
  incomeSources,
  manages,
  recordDate,
  salePaid,
  saleValue,
  type ExpenseBody,
  type FarmRecord,
  type IncomeBody,
  type MilkSaleBody,
  type MilkSalePaymentBody,
} from '@/lib/domain';
import { litres, shortDate, ugx, words, plural } from '@/lib/format';
import { firebase } from '@/lib/firebase';
import { useFarm, useSession } from '@/lib/session';
import { useOpenFromUrl } from '@/lib/useOpen';

const monthName = new Intl.DateTimeFormat('en-GB', { month: 'long', year: 'numeric' });
const sourceText = (s: string) => (s === 'animalSale' ? 'Animal sold' : s === 'calfSale' ? 'Calf sold' : words(s));
/** Biggest single entry we accept without a typing mistake (UGX 100 million). */
const MAX_UGX = 100_000_000;

/** Keeps the time of day so today's entries sort in order. */
function atFor(day: string): Date {
  const picked = parseDate(day) ?? new Date();
  const now = new Date();
  return new Date(picked.getFullYear(), picked.getMonth(), picked.getDate(), now.getHours(), now.getMinutes(), now.getSeconds());
}

function MoneyForm({ kind, onClose }: { kind: 'expense' | 'income'; onClose: () => void }) {
  const farm = useFarm();
  const { user, canSave, online } = useSession();
  const toast = useToast();
  const [category, setCategory] = useState<string>(kind === 'expense' ? 'feed' : 'manure');
  const [amount, setAmount] = useState('');
  const [day, setDay] = useState(dayKey(new Date()));
  const [note, setNote] = useState('');
  const { busy, error, setError, run } = useSave();
  const options = kind === 'expense' ? expenseCategories.filter((c) => c !== 'wages') : incomeSources;

  async function save() {
    if (!user) return;
    const n = Number(amount);
    if (!Number.isInteger(n) || n <= 0) return setError('Type the amount in whole shillings, more than 0.');
    if (n > MAX_UGX) return setError(`${ugx(n)} looks too big. Check the number.`);
    if (!parseDate(day)) return setError('Choose the date.');
    const at = localIso(atFor(day));
    const ok = await run(() =>
      kind === 'expense'
        ? addRecord(firebase().db, farm.id, 'expenses', user.uid, { category, amount: n, at, note: note.trim() || null, sourceId: null, photo: null })
        : addRecord(firebase().db, farm.id, 'income', user.uid, { source: category, amount: n, at, note: note.trim() || null, sourceId: null }),
    );
    if (ok) {
      toast(`${kind === 'expense' ? 'Expense' : 'Income'} saved: ${ugx(n)}`);
      onClose();
    }
  }

  return (
    <FormDialog
      title={kind === 'expense' ? 'Add expense' : 'Add income'}
      subtitle={kind === 'income' ? 'Money the farm earned that is not a milk sale. Record milk sales on the Milk page.' : 'Farm spending only. Wages are paid from Workers.'}
      onClose={onClose}
      onSubmit={save}
      busy={busy}
      error={error}
      canSave={canSave}
      online={online}
      submit={Number(amount) > 0 ? `Save ${ugx(Number(amount))}` : 'Save'}
    >
      <Field label={kind === 'expense' ? 'What for?' : 'From what?'}>
        <div className="chips" role="group">
          {options.map((c) => (
            <button type="button" key={c} className={`chip ${category === c ? 'brand' : ''}`} aria-pressed={category === c} onClick={() => setCategory(c)}>
              {kind === 'expense' ? words(c) : sourceText(c)}
            </button>
          ))}
        </div>
      </Field>
      <Fit kind="fields" cols={[1, 2, 2, 2]}>
        <Field label="Amount (UGX)">
          <input className="input" type="number" min={1} step={1} inputMode="numeric" required value={amount} onChange={(e) => setAmount(e.target.value)} autoFocus />
        </Field>
        <Field label="Date">
          <input className="input" type="date" max={dayKey(new Date())} required value={day} onChange={(e) => setDay(e.target.value)} />
        </Field>
      </Fit>
      <Field label="Note (optional)">
        <input className="input" value={note} onChange={(e) => setNote(e.target.value)} placeholder={kind === 'expense' ? 'e.g. 10 bags of dairy meal' : 'e.g. 3 trips of manure'} maxLength={200} />
      </Field>
    </FormDialog>
  );
}

type Tab = 'expenses' | 'income' | 'sales';

/** Farm money only (binding rule 8: household money is never mixed in). */
export default function Money() {
  const farm = useFarm();
  const { user, canSave } = useSession();
  const toast = useToast();
  const [offset, setOffset] = useState(0);
  const [tab, setTab] = useState<Tab>('expenses');
  const [adding, setAdding] = useOpenFromUrl();
  const [addingIncome, setAddingIncome] = useOpenFromUrl('income');
  const [removing, setRemoving] = useState<FarmRecord<ExpenseBody | IncomeBody> | null>(null);
  const removeSave = useSave();
  const boss = manages(farm);
  const now = new Date();
  const from = new Date(now.getFullYear(), now.getMonth() + offset, 1);
  const to = new Date(from.getFullYear(), from.getMonth() + 1, 1);
  // Money dates are the `at` field (an entry can be for an earlier day), so read from a month earlier.
  const since = localIso(new Date(from.getFullYear(), from.getMonth() - 1, 1));
  const expenses = useRecords<ExpenseBody>(boss ? farm.id : null, 'expenses', since);
  const income = useRecords<IncomeBody>(boss ? farm.id : null, 'income', since);
  const sales = useRecords<MilkSaleBody>(boss ? farm.id : null, 'milkSales', since);
  const marks = useRecords<MilkSalePaymentBody>(boss ? farm.id : null, 'milkSalePayments');

  if (!boss) return <Empty icon="lock">Only the owner or manager can see money.</Empty>;

  const within = (d: Date) => d >= from && d < to;
  const inMonth = alive(expenses.data)
    .filter((e) => within(recordDate(e, 'at')))
    .sort((a, b) => recordDate(b, 'at').getTime() - recordDate(a, 'at').getTime());
  const incomeIn = alive(income.data)
    .filter((e) => within(recordDate(e, 'at')))
    .sort((a, b) => recordDate(b, 'at').getTime() - recordDate(a, 'at').getTime());
  const salesIn = alive(sales.data)
    .filter((s) => within(recordDate(s)))
    .sort((a, b) => recordDate(b).getTime() - recordDate(a).getTime());
  const spent = inMonth.reduce((t, e) => t + (Number(e.body.amount) || 0), 0);
  const milkIncome = salesIn.reduce((t, s) => t + saleValue(s.body), 0);
  const otherIncome = incomeIn.reduce((t, e) => t + (Number(e.body.amount) || 0), 0);
  const unpaid = salesIn.filter((s) => !salePaid(s, marks.data)).reduce((t, s) => t + saleValue(s.body), 0);
  const soldLitres = salesIn.reduce((t, s) => t + (Number(s.body.litres) || 0), 0);
  const left = milkIncome + otherIncome - spent;
  const byCat = new Map<string, number>();
  for (const e of inMonth) byCat.set(e.body.category, (byCat.get(e.body.category) ?? 0) + (Number(e.body.amount) || 0));
  const cats = [...byCat.entries()].sort((a, b) => b[1] - a[1]);
  const biggest = Math.max(...cats.map((c) => c[1]), 1);
  const buyers = new Map<string, { value: number; unpaid: number; litres: number }>();
  for (const s of salesIn) {
    const b = buyers.get(s.body.buyer) ?? { value: 0, unpaid: 0, litres: 0 };
    b.value += saleValue(s.body);
    b.litres += Number(s.body.litres) || 0;
    if (!salePaid(s, marks.data)) b.unpaid += saleValue(s.body);
    buyers.set(s.body.buyer, b);
  }
  const loading = expenses.loading || income.loading || sales.loading;

  const csv = () =>
    downloadCsv(
      `${farm.name}-money-${dayKey(from).slice(0, 7)}`,
      ['Date', 'Type', 'Category / buyer', 'Amount (UGX)', 'Note'],
      [
        ...inMonth.map((e) => [dayKey(recordDate(e, 'at')), 'Expense', words(e.body.category), -Number(e.body.amount), e.body.note ?? '']),
        ...incomeIn.map((e) => [dayKey(recordDate(e, 'at')), 'Income', sourceText(e.body.source), Number(e.body.amount), e.body.note ?? '']),
        ...salesIn.map((s) => [
          dayKey(recordDate(s)),
          'Milk sale',
          s.body.buyer,
          Math.round(saleValue(s.body)),
          `${s.body.litres} L at ${s.body.pricePerLitre}${salePaid(s, marks.data) ? '' : ' (not paid yet)'}`,
        ]),
      ],
    );

  return (
    <>
      <PageHead title="Money" subtitle="Farm money only. Household money stays out of FarmTap.">
        <div className="row month-nav">
          <button className="icon-btn" aria-label="Previous month" onClick={() => setOffset(offset - 1)} style={{ transform: 'scaleX(-1)' }}>
            <Icon name="chevron" />
          </button>
          <strong>{monthName.format(from)}</strong>
          <button className="icon-btn" aria-label="Next month" onClick={() => setOffset(offset + 1)} disabled={offset >= 0}>
            <Icon name="chevron" />
          </button>
        </div>
        <ExportButtons onCsv={csv} />
        <button className="btn sm outline" onClick={() => setAddingIncome(true)} disabled={!canSave}>
          <Icon name="plus" /> Add income
        </button>
        <button className="btn sm" onClick={() => setAdding(true)} disabled={!canSave}>
          <Icon name="plus" /> Add expense
        </button>
      </PageHead>
      <LoadError code={expenses.error ?? income.error ?? sales.error} />

      <Fit kind="stats" cols={[2, 2, 4, 4]}>
        <Stat loading={sales.loading} icon="drop" label="Milk sales" value={ugx(milkIncome)} hint={`${litres(soldLitres)} sold${unpaid ? ` · ${ugx(unpaid)} not paid yet` : ''}`} />
        <Stat loading={income.loading} icon="money" label="Other income" value={ugx(otherIncome)} hint={plural(incomeIn.length, 'entry', 'entries')} tone="info" />
        <Stat loading={expenses.loading} icon="receipt" label="Spent" value={ugx(spent)} hint={plural(inMonth.length, 'expense', 'expenses')} tone="warn" />
        <Stat
          loading={loading}
          icon="check"
          label="Left over"
          value={`${left < 0 ? '−' : ''}${ugx(Math.abs(left))}`}
          hint="Income minus spending"
          tone={left < 0 ? 'bad' : 'gold'}
        />
      </Fit>

      <Fit kind="cards" cols={[1, 2, 2, 2]}>
        <section className="card">
          <CardHead title="Where the money went" />
          {expenses.loading ? (
            <SkelRows rows={4} cols={2} />
          ) : cats.length === 0 ? (
            <Empty icon="receipt">No spending recorded this month.</Empty>
          ) : (
            <div className="stack">
              {cats.map(([c, v]) => (
                <div key={c} className="stack" style={{ gap: 'var(--s-xxs)' }}>
                  <div className="row between small">
                    <span>{words(c)}</span>
                    <span className="num">
                      {ugx(v)} · {Math.round((v / Math.max(spent, 1)) * 100)}%
                    </span>
                  </div>
                  <div className="split">
                    <span className="b" style={{ width: `${(v / biggest) * 100}%` }} />
                  </div>
                </div>
              ))}
            </div>
          )}
        </section>
        <section className="card">
          <CardHead title="Milk buyers">
            <Link className="small no-print" href="/milk/?sale=1">
              Record a sale
            </Link>
          </CardHead>
          {sales.loading ? (
            <SkelRows rows={3} cols={2} />
          ) : buyers.size === 0 ? (
            <Empty icon="drop">No milk sales recorded this month.</Empty>
          ) : (
            <div className="list">
              {[...buyers.entries()]
                .sort((a, b) => b[1].value - a[1].value)
                .map(([name, b]) => (
                  <div key={name} className="list-row">
                    <div className="grow">
                      <div>{name}</div>
                      <div className="small muted">{litres(b.litres)}</div>
                    </div>
                    <span className="num">{ugx(b.value)}</span>
                    {b.unpaid > 0 ? <span className="chip warn">{ugx(b.unpaid)} owed</span> : <span className="chip ok">Paid</span>}
                  </div>
                ))}
            </div>
          )}
        </section>
      </Fit>

      <Tabs
        label="Entries"
        value={tab}
        onChange={setTab}
        items={[
          ['expenses', 'Expenses', inMonth.length],
          ['income', 'Other income', incomeIn.length],
          ['sales', 'Milk sales', salesIn.length],
        ]}
      />

      <div className="table-wrap">
        <table className="table rt">
          <thead>
            <tr>
              <th>Date</th>
              <th>{tab === 'sales' ? 'Buyer' : tab === 'income' ? 'From' : 'Category'}</th>
              <th>{tab === 'sales' ? 'Litres' : 'Note'}</th>
              <th className="r">Amount</th>
              <th />
            </tr>
          </thead>
          <tbody>
            {tab === 'expenses' &&
              inMonth.map((e) => (
                <tr key={e.id}>
                  <td data-label="Date">{shortDate(recordDate(e, 'at'))}</td>
                  <td data-label="Category" className="lead">
                    <strong>{words(e.body.category)}</strong>
                  </td>
                  <td data-label="Note" className="wide">
                    {e.body.note || '–'}
                  </td>
                  <td data-label="Amount" className="r">
                    <strong>{ugx(e.body.amount)}</strong>
                  </td>
                  <td className="acts r">
                    {canSave &&
                      (e.body.sourceId ? (
                        <span className="small muted" title="Made by a wage payment or a feed purchase on the phone">
                          Automatic
                        </span>
                      ) : (
                        <button className="icon-btn" aria-label="Remove expense" title="Remove a mistake" onClick={() => setRemoving(e)}>
                          <Icon name="close" />
                        </button>
                      ))}
                  </td>
                </tr>
              ))}
            {tab === 'income' &&
              incomeIn.map((e) => (
                <tr key={e.id}>
                  <td data-label="Date">{shortDate(recordDate(e, 'at'))}</td>
                  <td data-label="From" className="lead">
                    <strong>{sourceText(e.body.source)}</strong>
                  </td>
                  <td data-label="Note" className="wide">
                    {e.body.note || '–'}
                  </td>
                  <td data-label="Amount" className="r">
                    <strong>{ugx(e.body.amount)}</strong>
                  </td>
                  <td className="acts r">
                    {canSave && !e.body.sourceId && (
                      <button className="icon-btn" aria-label="Remove income" title="Remove a mistake" onClick={() => setRemoving(e)}>
                        <Icon name="close" />
                      </button>
                    )}
                  </td>
                </tr>
              ))}
            {tab === 'sales' &&
              salesIn.map((s) => (
                <tr key={s.id}>
                  <td data-label="Date">{shortDate(recordDate(s))}</td>
                  <td data-label="Buyer" className="lead">
                    <strong>{s.body.buyer}</strong>
                  </td>
                  <td data-label="Litres">
                    {litres(s.body.litres)} at {ugx(s.body.pricePerLitre)}
                  </td>
                  <td data-label="Amount" className="r">
                    <strong>{ugx(saleValue(s.body))}</strong>
                  </td>
                  <td className="acts r">{salePaid(s, marks.data) ? <span className="chip ok">Paid</span> : <span className="chip warn">Not paid</span>}</td>
                </tr>
              ))}
          </tbody>
        </table>
        {loading && <SkelRows rows={4} cols={4} />}
        {!loading && (tab === 'expenses' ? inMonth : tab === 'income' ? incomeIn : salesIn).length === 0 && (
          <Empty
            icon="receipt"
            action={
              canSave &&
              tab !== 'sales' && (
                <button className="btn sm" onClick={() => (tab === 'income' ? setAddingIncome(true) : setAdding(true))}>
                  <Icon name="plus" /> {tab === 'income' ? 'Add income' : 'Add expense'}
                </button>
              )
            }
          >
            Nothing in {monthName.format(from)}.
          </Empty>
        )}
      </div>

      {adding && <MoneyForm kind="expense" onClose={() => setAdding(false)} />}
      {addingIncome && <MoneyForm kind="income" onClose={() => setAddingIncome(false)} />}
      {removing && (
        <ConfirmDialog
          title="Remove this entry?"
          confirm="Remove"
          danger
          busy={removeSave.busy}
          error={removeSave.error}
          onClose={() => setRemoving(null)}
          onConfirm={async () => {
            if (!user) return;
            if (await removeSave.run(() => removeRecord(firebase().db, farm.id, removing, user.uid))) {
              toast('Entry removed');
              setRemoving(null);
            }
          }}
        >
          {ugx(removing.body.amount)} on {shortDate(recordDate(removing, 'at'))}. Use this only for a mistake. It is removed on the farm phones too.
        </ConfirmDialog>
      )}
    </>
  );
}
