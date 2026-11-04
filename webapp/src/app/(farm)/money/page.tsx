'use client';

import Link from 'next/link';
import { doc, getDoc } from 'firebase/firestore';
import { useState } from 'react';
import { Fit } from '@/components/fit';
import { Icon } from '@/components/Icon';
import { CardHead, ConfirmDialog, Empty, ExportButtons, Field, FormDialog, LoadError, PageHead, SkelRows, Stat, Tabs, useSave, useToast } from '@/components/ui';
import { downloadCsv } from '@/lib/csv';
import { dayKey, localIso, parseDate } from '@/lib/dates';
import { addRecord, removeRecord, useRecords } from '@/lib/data';
import {
  alive,
  categoryName,
  contactKindName,
  payMethodName,
  payMethods,
  sourceOf,
  sourcePage,
  type ContactBody,
  type PayMethod,
  type SpendSource,
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
import { expensesOf, removeWithExpenses, saveWithExpense } from '@/lib/linked';

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

/** Where each kind of automatic expense's record lives, to remove both together. */
const sourceCollection: Record<SpendSource, string | null> = {
  feedPurchase: 'stockMovements',
  drugPurchase: 'stockMovements',
  wage: 'wages',
  treatment: 'treatments',
  vaccination: 'vaccinations',
  service: 'breedingEvents',
  supplierPayment: null,
};

function MoneyForm({
  kind,
  onClose,
  edit,
  contacts,
}: {
  kind: 'expense' | 'income';
  onClose: () => void;
  edit?: FarmRecord<ExpenseBody> | FarmRecord<IncomeBody>;
  contacts: FarmRecord<ContactBody>[];
}) {
  const farm = useFarm();
  const { user, canSave, online } = useSession();
  const toast = useToast();
  const eb = kind === 'expense' ? (edit as FarmRecord<ExpenseBody> | undefined)?.body : undefined;
  const ib = kind === 'income' ? (edit as FarmRecord<IncomeBody> | undefined)?.body : undefined;
  const [category, setCategory] = useState<string>(eb?.category ?? ib?.source ?? (kind === 'expense' ? 'feed' : 'manure'));
  const [amount, setAmount] = useState(edit ? String(edit.body.amount) : '');
  const [day, setDay] = useState(edit ? dayKey(recordDate(edit, 'at')) : dayKey(new Date()));
  const [note, setNote] = useState(edit?.body.note ?? '');
  const [supplierId, setSupplierId] = useState(eb?.supplierId ?? '');
  const [method, setMethod] = useState<PayMethod>((eb?.payMethod as PayMethod) ?? 'cash');
  const { busy, error, setError, run } = useSave();
  const options = kind === 'expense' ? expenseCategories.filter((c) => c !== 'wages') : incomeSources;

  async function save() {
    if (!user) return;
    const n = Number(amount);
    if (!Number.isInteger(n) || n <= 0) return setError('Type the amount in whole shillings, more than 0.');
    if (n > MAX_UGX) return setError(`${ugx(n)} looks too big. Check the number.`);
    if (!parseDate(day)) return setError('Choose the date.');
    const at = localIso(atFor(day));
    const { db } = firebase();
    const body =
      kind === 'expense'
        ? { category, amount: n, at, note: note.trim() || null, sourceId: null, sourceType: supplierId ? 'supplierPayment' : null, supplierId: supplierId || null, payMethod: method, photo: null }
        : { source: category, amount: n, at, note: note.trim() || null, sourceId: null };
    const col = kind === 'expense' ? 'expenses' : 'income';
    const ok = await run(() =>
      edit
        ? // Money records cannot change in place: the old one goes and the new one is saved in the same write.
          saveWithExpense(db, farm.id, user.uid, { collection: col, body }, 'supplierPayment', null, { record: edit, expenses: [] })
        : addRecord(db, farm.id, col, user.uid, body),
    );
    if (ok) {
      toast(`${kind === 'expense' ? 'Expense' : 'Income'} ${edit ? 'changed' : 'saved'}: ${ugx(n)}`);
      onClose();
    }
  }

  return (
    <FormDialog
      title={edit ? (kind === 'expense' ? 'Change expense' : 'Change income') : kind === 'expense' ? 'Add expense' : 'Add income'}
      subtitle={
        kind === 'income'
          ? 'Money the farm earned that is not a milk sale. Record milk sales on the Milk page.'
          : 'Farm spending only. Feed bought, worker pay, treatments and supplier payments come in here by themselves.'
      }
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
              {kind === 'expense' ? categoryName[c] ?? words(c) : sourceText(c)}
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
        {kind === 'expense' && (
          <Field label="Paid to (optional)" hint={contacts.length ? undefined : 'Add suppliers under Contacts to count what you spend with each.'}>
            <select className="input" value={supplierId} onChange={(e) => setSupplierId(e.target.value)}>
              <option value="">Nobody in particular</option>
              {contacts.map((c) => (
                <option key={c.id} value={c.id}>
                  {c.body.name} · {contactKindName[c.body.kind as keyof typeof contactKindName] ?? c.body.kind}
                </option>
              ))}
            </select>
          </Field>
        )}
        {kind === 'expense' && (
          <Field label="Paid by">
            <select className="input" value={method} onChange={(e) => setMethod(e.target.value as PayMethod)}>
              {payMethods.map((m) => (
                <option key={m} value={m}>
                  {payMethodName[m]}
                </option>
              ))}
            </select>
          </Field>
        )}
      </Fit>
      <Field label="Note (optional)">
        <input className="input" value={note} onChange={(e) => setNote(e.target.value)} placeholder={kind === 'expense' ? 'e.g. Fuel for the milk run' : 'e.g. 3 trips of manure'} maxLength={200} />
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
  const [editing, setEditing] = useState<{ kind: 'expense' | 'income'; rec: FarmRecord<ExpenseBody> | FarmRecord<IncomeBody> } | null>(null);

  const removeSave = useSave();
  const boss = manages(farm);
  const contacts = useRecords<ContactBody>(boss ? farm.id : null, 'contacts');
  const allExpenses = useRecords<ExpenseBody>(boss ? farm.id : null, 'expenses');
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
  const people = alive(contacts.data);
  const nameOf = (id: string | null | undefined) => (id ? people.find((c) => c.id === id)?.body.name ?? '' : '');
  const bySupplier = new Map<string, number>();
  for (const e of inMonth) if (e.body.supplierId) bySupplier.set(e.body.supplierId, (bySupplier.get(e.body.supplierId) ?? 0) + (Number(e.body.amount) || 0));
  const autoShare = inMonth.filter((e) => sourceOf(e.body)).reduce((t, e) => t + (Number(e.body.amount) || 0), 0);
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
                    <span>{categoryName[c] ?? words(c)}</span>
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

      {bySupplier.size > 0 && (
        <section className="card">
          <CardHead title="Paid to suppliers this month">
            <Link className="small no-print" href="/contacts/">
              All contacts
            </Link>
          </CardHead>
          <div className="list">
            {[...bySupplier.entries()]
              .sort((a, b) => b[1] - a[1])
              .slice(0, 8)
              .map(([id, v]) => (
                <div key={id} className="list-row">
                  <span className="grow">{nameOf(id) || 'Removed contact'}</span>
                  <span className="num">{ugx(v)}</span>
                </div>
              ))}
          </div>
          <p className="small muted">{Math.round((autoShare / Math.max(spent, 1)) * 100)}% of this month&apos;s spending came in by itself from feeds, workers, health and breeding.</p>
        </section>
      )}

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
              inMonth.map((e) => {
                const src = sourceOf(e.body);
                const auto = src && src !== 'supplierPayment' && e.body.sourceId;
                const who = nameOf(e.body.supplierId);
                return (
                  <tr key={e.id}>
                    <td data-label="Date">{shortDate(recordDate(e, 'at'))}</td>
                    <td data-label="Category" className="lead">
                      <strong>{categoryName[e.body.category] ?? words(e.body.category)}</strong>
                      {src && (
                        <div className="small">
                          <Link href={sourcePage[src].href} className="muted">
                            {sourcePage[src].label}
                          </Link>
                        </div>
                      )}
                    </td>
                    <td data-label="Note" className="wide">
                      {[who, e.body.note, e.body.payMethod ? payMethodName[e.body.payMethod as PayMethod] : null].filter(Boolean).join(' · ') || '–'}
                    </td>
                    <td data-label="Amount" className="r">
                      <strong>{ugx(e.body.amount)}</strong>
                    </td>
                    <td className="acts r">
                      {canSave && !auto && (
                        <button className="icon-btn" aria-label="Change expense" title="Change" onClick={() => setEditing({ kind: 'expense', rec: e })}>
                          <Icon name="edit" />
                        </button>
                      )}
                      {canSave && (
                        <button
                          className="icon-btn"
                          aria-label="Remove expense"
                          title={auto ? `Removes the ${sourcePage[src!].label.toLowerCase()} too` : 'Remove a mistake'}
                          onClick={() => setRemoving(e)}
                        >
                          <Icon name="close" />
                        </button>
                      )}
                    </td>
                  </tr>
                );
              })}
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
                      <>
                        <button className="icon-btn" aria-label="Change income" title="Change" onClick={() => setEditing({ kind: 'income', rec: e })}>
                          <Icon name="edit" />
                        </button>
                        <button className="icon-btn" aria-label="Remove income" title="Remove a mistake" onClick={() => setRemoving(e)}>
                          <Icon name="close" />
                        </button>
                      </>
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

      {adding && <MoneyForm kind="expense" contacts={people} onClose={() => setAdding(false)} />}
      {addingIncome && <MoneyForm kind="income" contacts={people} onClose={() => setAddingIncome(false)} />}
      {editing && <MoneyForm kind={editing.kind} edit={editing.rec} contacts={people} onClose={() => setEditing(null)} />}
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
            const { db } = firebase();
            const ok = await removeSave.run(async () => {
              const body = removing.body as ExpenseBody;
              const src = removing.collection === 'expenses' ? sourceOf(body) : null;
              const col = src ? sourceCollection[src] : null;
              if (col && body.sourceId) {
                // An automatic expense goes together with what made it (and any other expense it made).
                const snap = await getDoc(doc(db, 'tenants', farm.id, col, body.sourceId));
                const source = snap.exists() && !snap.data().isDeleted ? (snap.data() as FarmRecord<object>) : null;
                const others = expensesOf(body.sourceId, allExpenses.data).filter((x) => x.id !== removing.id);
                await removeWithExpenses(db, farm.id, user.uid, source, [removing as FarmRecord<ExpenseBody>, ...others]);
              } else await removeRecord(db, farm.id, removing, user.uid);
            });
            if (ok) {
              toast('Entry removed');
              setRemoving(null);
            }
          }}
        >
          {ugx(removing.body.amount)} on {shortDate(recordDate(removing, 'at'))}. Use this only for a mistake. It is removed on the farm phones too.
          {removing.collection === 'expenses' && sourceOf(removing.body as ExpenseBody) && sourceOf(removing.body as ExpenseBody) !== 'supplierPayment' && (
            <> The {sourcePage[sourceOf(removing.body as ExpenseBody)!].label.toLowerCase()} that made it is removed too, so both stay the same.</>
          )}
        </ConfirmDialog>
      )}
    </>
  );
}
