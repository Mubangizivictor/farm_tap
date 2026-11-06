'use client';

import { useState } from 'react';
import { MilkAi } from '@/components/aiPage';
import { Fit } from '@/components/fit';
import { Icon } from '@/components/Icon';
import { MilkChart } from '@/components/MilkChart';
import {
  CardHead,
  ConfirmDialog,
  Dialog,
  Empty,
  ExportButtons,
  Field,
  FormDialog,
  LoadError,
  PageHead,
  Seg,
  SkelRows,
  Stat,
  Tabs,
  useSave,
  useToast,
} from '@/components/ui';
import { downloadCsv } from '@/lib/csv';
import { addDays, dayKey, localIso, sameDay, startOfDay, startOfMonth } from '@/lib/dates';
import { addRecord, removeRecord, upsertRecord, useRecords } from '@/lib/data';
import {
  alive,
  animalLabel,
  buyerKinds,
  dailyLitres,
  inWithdrawal,
  isMilker,
  manages,
  recordDate,
  salePaid,
  saleValue,
  type AnimalBody,
  type FarmRecord,
  type MilkBody,
  type MilkSaleBody,
  type MilkSalePaymentBody,
  type TreatmentBody,
} from '@/lib/domain';
import { count, date, litres, num1, shortDate, time, ugx, weekday, words, plural } from '@/lib/format';
import { firebase } from '@/lib/firebase';
import { useFarm, useSession } from '@/lib/session';
import { useOpenFromUrl } from '@/lib/useOpen';

type Range = '7' | '30' | 'month';
type Tab = 'days' | 'entries' | 'sales';

/** Most a herd total or one animal can give in one milking; above it is a typing mistake. */
const MAX_HERD_L = 5000;
const MAX_ANIMAL_L = 60;

const recorder = (u: { displayName: string | null; email: string | null; uid: string }) => u.displayName || u.email || u.uid;

function RecordMilk({ onClose, cows, blocked }: { onClose: () => void; cows: { id: string; label: string }[]; blocked: Set<string> }) {
  const farm = useFarm();
  const { user, canSave, online } = useSession();
  const toast = useToast();
  const [session, setSession] = useState<'morning' | 'evening'>(new Date().getHours() < 12 ? 'morning' : 'evening');
  const [mode, setMode] = useState<'total' | 'cow'>('total');
  const [total, setTotal] = useState('');
  const [perCow, setPerCow] = useState<Record<string, string>>({});
  // Not every cow is milked every day: the recorder ticks the ones milked now.
  const [milked, setMilked] = useState<Set<string>>(() => new Set(cows.map((c) => c.id)));
  const [count, setCount] = useState(String(cows.length || ''));
  const [naming, setNaming] = useState(false);
  const { busy, error, setError, run } = useSave();
  const toggle = (id: string) =>
    setMilked((m) => {
      const n = new Set(m);
      if (n.has(id)) n.delete(id);
      else n.add(id);
      if (naming) setCount(String(n.size));
      return n;
    });

  const entered = Object.entries(perCow).filter(([id, v]) => milked.has(id) && Number(v) > 0);
  const sum = entered.reduce((t, [, v]) => t + Number(v), 0);

  async function save() {
    if (!user) return;
    const howMany = naming ? milked.size : Number(count) || null;
    if (mode === 'total') {
      const l = Number(total);
      if (!(l > 0)) return setError('Type the litres, more than 0.');
      if (l > MAX_HERD_L) return setError(`${num1(l)} L looks too much for one milking. Check the number.`);
      if (howMany != null && (!Number.isInteger(howMany) || howMany < 1)) return setError('Type how many cows were milked, or leave it empty.');
      if (howMany && l / howMany > MAX_ANIMAL_L) return setError(`${num1(l / howMany)} L a cow looks too much. Check the litres or the number of cows.`);
    } else {
      if (!entered.length) return setError('Type the litres for at least one animal.');
      const big = entered.find(([, v]) => Number(v) > MAX_ANIMAL_L);
      if (big) return setError(`${cows.find((c) => c.id === big[0])?.label}: ${big[1]} L is too much for one milking. Check the number.`);
    }
    const { db } = firebase();
    const by = recorder(user);
    const ok = await run(async () => {
      if (mode === 'total') {
        await addRecord(db, farm.id, 'milkRecords', user.uid, {
          animalId: null,
          session,
          litres: Number(total),
          recordedBy: by,
          cowsMilked: howMany,
          cowIds: naming ? [...milked] : null,
        });
      } else {
        await Promise.all(
          entered.map(([cowId, v]) =>
            addRecord(db, farm.id, 'milkRecords', user.uid, {
              animalId: cowId,
              session,
              litres: Number(v),
              notForSale: blocked.has(cowId),
              recordedBy: by,
            }),
          ),
        );
      }
    });
    if (ok) {
      toast(`Milk saved: ${litres(mode === 'total' ? Number(total) : sum)} ${session}`);
      onClose();
    }
  }

  return (
    <FormDialog
      title="Record milk"
      subtitle="Saved for today, now. The farm phones get it on their next sync."
      onClose={onClose}
      onSubmit={save}
      busy={busy}
      error={error}
      canSave={canSave}
      online={online}
      submit={mode === 'cow' && sum ? `Save ${litres(sum)}` : 'Save'}
      size={mode === 'cow' ? 'lg' : 'md'}
    >
      <Fit kind="fields" cols={[1, 2, 2, 2]}>
        <Seg label="Session" value={session} onChange={setSession} items={[['morning', 'Morning'], ['evening', 'Evening']]} />
        <Seg
          label="How"
          value={mode}
          onChange={(m) => {
            setMode(m);
            setError('');
          }}
          items={cows.length ? [['total', 'Total litres'], ['cow', 'Each cow']] : [['total', 'Total litres']]}
        />
      </Fit>
      {mode === 'total' ? (
        <>
          <Fit kind="fields" cols={[1, 2, 2, 2]}>
            <Field label="Litres from the cows milked" hint="Use a dot for parts of a litre, e.g. 42.5">
              <input
                className="input"
                type="number"
                min={0.1}
                max={MAX_HERD_L}
                step={0.1}
                inputMode="decimal"
                required
                value={total}
                onChange={(e) => setTotal(e.target.value)}
                autoFocus
              />
            </Field>
            <Field label="How many cows were milked" hint={cows.length ? `${cows.length} cows are milking in the herd list.` : undefined}>
              <input className="input" type="number" min={1} step={1} inputMode="numeric" value={count} disabled={naming} onChange={(e) => setCount(e.target.value)} />
            </Field>
          </Fit>
          {cows.length > 0 && (
            <label className="check-row">
              <input type="checkbox" checked={naming} onChange={(e) => (setNaming(e.target.checked), e.target.checked && setCount(String(milked.size)))} />
              <span>Name the cows that were milked</span>
            </label>
          )}
          {naming && <CowPicker cows={cows} milked={milked} toggle={toggle} setAll={(all) => (setMilked(new Set(all ? cows.map((c) => c.id) : [])), setCount(String(all ? cows.length : 0)))} blocked={blocked} />}
          {Number(total) > 0 && (naming ? milked.size : Number(count)) > 0 && (
            <p className="small muted">About {num1(Number(total) / (naming ? milked.size : Number(count)))} L a cow.</p>
          )}
        </>
      ) : (
        <>
          <p className="small muted">Untick the cows not milked this time (dry, sick, away, calving). Only ticked cows are saved.</p>
          <div className="row wrap">
            <button type="button" className="btn sm ghost" onClick={() => setMilked(new Set(cows.map((c) => c.id)))}>
              Tick all
            </button>
            <button type="button" className="btn sm ghost" onClick={() => setMilked(new Set())}>
              Untick all
            </button>
            <span className="small muted">
              {milked.size} of {cows.length} cows milked
            </span>
          </div>
          <div className="list">
            {cows.map((c) => {
              const on = milked.has(c.id);
              return (
                <div key={c.id} className={`list-row ${on ? '' : 'dim'}`}>
                  <input type="checkbox" checked={on} onChange={() => toggle(c.id)} aria-label={`${c.label} milked`} />
                  <span className="grow">
                    {c.label}
                    {blocked.has(c.id) && <span className="chip bad">Not for sale</span>}
                  </span>
                  <input
                    className="input"
                    style={{ maxWidth: 'var(--z-stat-min)' }}
                    type="number"
                    min={0}
                    max={MAX_ANIMAL_L}
                    step={0.1}
                    inputMode="decimal"
                    placeholder={on ? 'Litres' : 'Not milked'}
                    disabled={!on}
                    aria-label={`Litres from ${c.label}`}
                    value={perCow[c.id] ?? ''}
                    onChange={(e) => setPerCow({ ...perCow, [c.id]: e.target.value })}
                  />
                </div>
              );
            })}
          </div>
        </>
      )}
    </FormDialog>
  );
}

function CowPicker({
  cows,
  milked,
  toggle,
  setAll,
  blocked,
}: {
  cows: { id: string; label: string }[];
  milked: Set<string>;
  toggle: (id: string) => void;
  setAll: (all: boolean) => void;
  blocked: Set<string>;
}) {
  return (
    <div className="stack">
      <div className="row wrap">
        <button type="button" className="btn sm ghost" onClick={() => setAll(true)}>
          All
        </button>
        <button type="button" className="btn sm ghost" onClick={() => setAll(false)}>
          None
        </button>
        <span className="small muted">
          {milked.size} of {cows.length} ticked
        </span>
      </div>
      <div className="pick-grid">
        {cows.map((c) => (
          <label key={c.id} className={`pick ${milked.has(c.id) ? 'on' : ''}`}>
            <input type="checkbox" checked={milked.has(c.id)} onChange={() => toggle(c.id)} />
            {c.label}
            {blocked.has(c.id) ? ' ⚠' : ''}
          </label>
        ))}
      </div>
    </div>
  );
}

function RecordSale({ onClose, buyers }: { onClose: () => void; buyers: string[] }) {
  const farm = useFarm();
  const { user, canSave, online } = useSession();
  const toast = useToast();
  const [f, setF] = useState({ buyer: '', kind: 'centre', litres: '', price: '', paid: false });
  const { busy, error, setError, run } = useSave();
  const value = (Number(f.litres) || 0) * (Number(f.price) || 0);

  async function save() {
    if (!user) return;
    if (!f.buyer.trim()) return setError('Type who bought the milk.');
    if (!(Number(f.litres) > 0)) return setError('Type the litres sold, more than 0.');
    if (!(Number(f.price) > 0) || !Number.isInteger(Number(f.price))) return setError('Type the price for one litre in shillings, e.g. 1200.');
    const ok = await run(() =>
      addRecord(firebase().db, farm.id, 'milkSales', user.uid, {
        buyer: f.buyer.trim(),
        kind: f.kind,
        litres: Number(f.litres),
        pricePerLitre: Number(f.price),
        paid: f.paid,
      }),
    );
    if (ok) {
      toast(`Sale saved: ${ugx(value)}`);
      onClose();
    }
  }

  return (
    <FormDialog
      title="Record milk sale"
      onClose={onClose}
      onSubmit={save}
      busy={busy}
      error={error}
      canSave={canSave}
      online={online}
      submit={value ? `Save ${ugx(value)}` : 'Save'}
    >
      <Fit kind="fields" cols={[1, 2, 2, 2]}>
        <Field label="Buyer">
          <input className="input" list="buyers" required value={f.buyer} onChange={(e) => setF({ ...f, buyer: e.target.value })} autoFocus />
          <datalist id="buyers">
            {buyers.map((b) => (
              <option key={b} value={b} />
            ))}
          </datalist>
        </Field>
        <Field label="Buyer type">
          <select className="input" value={f.kind} onChange={(e) => setF({ ...f, kind: e.target.value })}>
            {buyerKinds.map((k) => (
              <option key={k} value={k}>
                {k === 'centre' ? 'Collection centre' : words(k)}
              </option>
            ))}
          </select>
        </Field>
        <Field label="Litres">
          <input className="input" type="number" min={0.1} step={0.1} inputMode="decimal" required value={f.litres} onChange={(e) => setF({ ...f, litres: e.target.value })} />
        </Field>
        <Field label="Price per litre (UGX)">
          <input className="input" type="number" min={1} step={1} inputMode="numeric" required value={f.price} onChange={(e) => setF({ ...f, price: e.target.value })} />
        </Field>
      </Fit>
      <label className="check-row">
        <input type="checkbox" checked={f.paid} onChange={(e) => setF({ ...f, paid: e.target.checked })} />
        <span>Already paid</span>
      </label>
    </FormDialog>
  );
}

function DayDialog({
  day,
  records,
  name,
  onClose,
}: {
  day: Date;
  records: FarmRecord<MilkBody>[];
  name: (id: string | null) => string;
  onClose: () => void;
}) {
  const farm = useFarm();
  const { user, canSave } = useSession();
  const toast = useToast();
  const [removing, setRemoving] = useState<FarmRecord<MilkBody> | null>(null);
  const { busy, error, run } = useSave();
  const rows = [...records].sort((a, b) => recordDate(a).getTime() - recordDate(b).getTime());

  if (removing) {
    return (
      <ConfirmDialog
        title="Remove this milk record?"
        confirm="Remove"
        danger
        busy={busy}
        error={error}
        onClose={() => setRemoving(null)}
        onConfirm={async () => {
          if (!user) return;
          if (await run(() => removeRecord(firebase().db, farm.id, removing, user.uid))) {
            toast('Milk record removed');
            setRemoving(null);
          }
        }}
      >
        {litres(removing.body.litres)} · {words(removing.body.session)} · {name(removing.body.animalId)} at {time(recordDate(removing))}. Use this only for a mistake. It is removed on every phone too.
      </ConfirmDialog>
    );
  }

  return (
    <Dialog title={`${weekday(day)} ${date(day)}`} subtitle={`${rows.length} records · ${litres(rows.reduce((t, r) => t + (Number(r.body.litres) || 0), 0))}`} onClose={onClose}>
      {rows.length === 0 ? (
        <Empty icon="drop">No milk recorded on this day.</Empty>
      ) : (
        <div className="list">
          {rows.map((r) => (
            <div key={r.id} className="list-row small">
              <span className="num muted">{time(recordDate(r))}</span>
              <span className="grow">
                {words(r.body.session)} · {name(r.body.animalId)}
                {r.body.recordedBy ? <span className="muted"> · {r.body.recordedBy}</span> : null}
              </span>
              {r.body.notForSale && <span className="chip bad">Not for sale</span>}
              <strong className="num">{litres(r.body.litres)}</strong>
              {canSave && (
                <button className="icon-btn" aria-label="Remove" title="Remove a mistake" onClick={() => setRemoving(r)}>
                  <Icon name="close" />
                </button>
              )}
            </div>
          ))}
        </div>
      )}
    </Dialog>
  );
}

function Sales({
  sales,
  marks,
  loading,
  onAdd,
}: {
  sales: FarmRecord<MilkSaleBody>[];
  marks: FarmRecord<MilkSalePaymentBody>[];
  loading: boolean;
  onAdd: () => void;
}) {
  const farm = useFarm();
  const { user, canSave } = useSession();
  const toast = useToast();
  const { run } = useSave();
  const rows = alive(sales).sort((a, b) => recordDate(b).getTime() - recordDate(a).getTime());

  async function toggle(s: FarmRecord<MilkSaleBody>) {
    if (!user) return;
    const paid = !salePaid(s, marks);
    if (await run(() => upsertRecord(firebase().db, farm.id, 'milkSalePayments', `pay-${s.id}`, user.uid, { saleId: s.id, paid })))
      toast(paid ? `${s.body.buyer} marked paid` : `${s.body.buyer} marked not paid`);
  }

  return (
    <div className="table-wrap">
      <table className="table rt">
        <thead>
          <tr>
            <th>Date</th>
            <th>Buyer</th>
            <th className="r">Litres</th>
            <th className="r">Price</th>
            <th className="r">Value</th>
            <th>Paid</th>
          </tr>
        </thead>
        <tbody>
          {rows.map((s) => {
            const paid = salePaid(s, marks);
            return (
              <tr key={s.id}>
                <td data-label="Date">
                  {shortDate(recordDate(s))} {time(recordDate(s))}
                </td>
                <td data-label="Buyer" className="lead">
                  <strong>{s.body.buyer}</strong> <span className="small muted">{s.body.kind === 'centre' ? 'Centre' : words(s.body.kind)}</span>
                </td>
                <td data-label="Litres" className="r">
                  {litres(s.body.litres)}
                </td>
                <td data-label="Price" className="r">
                  {ugx(s.body.pricePerLitre)}
                </td>
                <td data-label="Value" className="r">
                  <strong>{ugx(saleValue(s.body))}</strong>
                </td>
                <td data-label="Paid">
                  <button className={`chip ${paid ? 'ok' : 'warn'}`} disabled={!canSave} onClick={() => void toggle(s)} title={canSave ? 'Change' : undefined}>
                    {paid ? 'Paid' : 'Not paid'}
                  </button>
                </td>
              </tr>
            );
          })}
        </tbody>
      </table>
      {loading && <SkelRows rows={4} cols={6} />}
      {!loading && rows.length === 0 && (
        <Empty icon="money" action={canSave && <button className="btn sm" onClick={onAdd}><Icon name="plus" /> Record sale</button>}>
          No milk sales in this period.
        </Empty>
      )}
    </div>
  );
}

export default function Milk() {
  const farm = useFarm();
  const { canSave } = useSession();
  const boss = manages(farm);
  const [range, setRange] = useState<Range>('7');
  const [tab, setTab] = useState<Tab>('days');
  const [adding, setAdding] = useOpenFromUrl();
  const [selling, setSelling] = useOpenFromUrl('sale');
  const [openDay, setOpenDay] = useState<Date | null>(null);
  const now = new Date();
  const today = startOfDay(now);
  const from = range === 'month' ? startOfMonth(now) : addDays(today, -(Number(range) - 1));
  const since = localIso(addDays(today, -40));
  const milk = useRecords<MilkBody>(farm.id, 'milkRecords', since);
  const animals = useRecords<AnimalBody>(farm.id, 'animals');
  const treatments = useRecords<TreatmentBody>(farm.id, 'treatments', localIso(addDays(today, -90)));
  const sales = useRecords<MilkSaleBody>(boss ? farm.id : null, 'milkSales', since);
  const marks = useRecords<MilkSalePaymentBody>(boss ? farm.id : null, 'milkSalePayments');

  const inRange = alive(milk.data).filter((r) => recordDate(r) >= from);
  const salesInRange = alive(sales.data).filter((r) => recordDate(r) >= from);
  const nDays = Math.max(1, Math.round((today.getTime() - from.getTime()) / 86_400_000) + 1);
  const days = dailyLitres(milk.data, now, nDays);
  const total = inRange.reduce((t, r) => t + (Number(r.body.litres) || 0), 0);
  const notForSale = inRange.filter((r) => r.body.notForSale).reduce((t, r) => t + (Number(r.body.litres) || 0), 0);
  const recordedDays = days.filter((d) => d.litres > 0).length;
  const best = days.reduce((b, d) => (d.litres > b.litres ? d : b), { day: today, litres: 0 });
  const soldValue = salesInRange.reduce((t, s) => t + saleValue(s.body), 0);
  const unpaid = salesInRange.filter((s) => !salePaid(s, marks.data)).reduce((t, s) => t + saleValue(s.body), 0);

  const name = (id: string | null) => {
    if (!id) return 'Herd total';
    const a = animals.data.find((x) => x.id === id);
    return a ? animalLabel(a) : 'An animal';
  };

  // Top animals in the range.
  const perCow = new Map<string, number>();
  for (const r of inRange) if (r.body.animalId) perCow.set(r.body.animalId, (perCow.get(r.body.animalId) ?? 0) + (Number(r.body.litres) || 0));
  const top = [...perCow.entries()].sort((a, b) => b[1] - a[1]).slice(0, 8);

  const byDay = [...days].reverse().map((d) => {
    const rs = inRange.filter((r) => sameDay(recordDate(r), d.day));
    const m = rs.filter((r) => r.body.session !== 'evening').reduce((t, r) => t + (Number(r.body.litres) || 0), 0);
    const e = rs.filter((r) => r.body.session === 'evening').reduce((t, r) => t + (Number(r.body.litres) || 0), 0);
    return { day: d.day, m, e, total: m + e, n: rs.length, rs };
  });
  const entries = [...inRange].sort((a, b) => recordDate(b).getTime() - recordDate(a).getTime());

  const blocked = new Set(treatments.data.filter((t) => inWithdrawal(t.body, now)).map((t) => t.body.animalId));
  const cows = animals.data
    .filter(isMilker)
    .sort((a, b) => a.body.tagNumber.localeCompare(b.body.tagNumber, undefined, { numeric: true }))
    .map((a) => ({ id: a.id, label: animalLabel(a) }));
  const buyers = [...new Set(alive(sales.data).map((s) => s.body.buyer))];

  const csv = () =>
    tab === 'sales'
      ? downloadCsv(
          `${farm.name}-milk-sales-${dayKey(from)}-to-${dayKey(today)}`,
          ['Date', 'Buyer', 'Type', 'Litres', 'Price per litre', 'Value', 'Paid'],
          salesInRange.map((s) => [dayKey(recordDate(s)), s.body.buyer, words(s.body.kind), s.body.litres, s.body.pricePerLitre, saleValue(s.body), salePaid(s, marks.data) ? 'Yes' : 'No']),
        )
      : downloadCsv(
          `${farm.name}-milk-${dayKey(from)}-to-${dayKey(today)}`,
          ['Date', 'Time', 'Session', 'Animal', 'Litres', 'Not for sale', 'Recorded by'],
          [...inRange]
            .sort((a, b) => recordDate(a).getTime() - recordDate(b).getTime())
            .map((r) => [dayKey(recordDate(r)), time(recordDate(r)), words(r.body.session), name(r.body.animalId), r.body.litres, r.body.notForSale ? 'Yes' : '', r.body.recordedBy ?? '']),
        );

  const tabs: (readonly [Tab, string, number?])[] = [
    ['days', 'By day'],
    ['entries', 'Every record', inRange.length],
    ...(boss ? [['sales', 'Sales', salesInRange.length] as const] : []),
  ];

  return (
    <>
      <PageHead title="Milk" subtitle={`${shortDate(from)} to ${shortDate(today)}`}>
        <Seg label="Period" value={range} onChange={setRange} items={[['7', '7 days'], ['30', '30 days'], ['month', 'This month']]} />
        <ExportButtons onCsv={csv} />
        {boss && (
          <button className="btn sm outline" onClick={() => setSelling(true)} disabled={!canSave}>
            <Icon name="money" /> Record sale
          </button>
        )}
        <button className="btn sm" onClick={() => setAdding(true)} disabled={!canSave}>
          <Icon name="plus" /> Record milk
        </button>
      </PageHead>
      <MilkAi />
      <LoadError code={milk.error ?? sales.error} />

      <Fit kind="stats">
        <Stat loading={milk.loading} icon="drop" label="Total" value={litres(total)} hint={plural(inRange.length, 'record', 'records')} />
        <Stat
          loading={milk.loading}
          icon="calendar"
          label="Average a day"
          value={litres(recordedDays ? total / recordedDays : 0)}
          hint={`${recordedDays} of ${days.length} days recorded`}
        />
        <Stat
          loading={milk.loading}
          icon="check"
          label="Best day"
          value={litres(best.litres)}
          hint={best.litres ? `${weekday(best.day)} ${date(best.day)}` : 'None yet'}
          tone="gold"
        />
        <Stat
          loading={milk.loading}
          icon="health"
          label="Not for sale"
          value={litres(notForSale)}
          hint="From animals on drug withdrawal"
          tone={notForSale ? 'bad' : undefined}
        />
        {boss && (
          <Stat
            loading={sales.loading}
            icon="money"
            label="Sold"
            value={ugx(soldValue)}
            hint={unpaid ? `${ugx(unpaid)} not paid yet` : salesInRange.length ? 'All paid' : 'No sales recorded'}
            tone={unpaid ? 'warn' : undefined}
          />
        )}
      </Fit>

      <Fit kind="cards" cols={[1, 2, 2, 2]}>
        <section className="card">
          <CardHead title="Litres per day" />
          {milk.loading ? <SkelRows rows={4} cols={3} /> : <MilkChart days={days.slice(-31)} />}
        </section>
        <section className="card">
          <CardHead title="Top animals">
            <span className="small muted">this period</span>
          </CardHead>
          {milk.loading ? (
            <SkelRows rows={4} cols={3} />
          ) : top.length === 0 ? (
            <Empty icon="tag">Milk is recorded as a herd total. Choose “Each animal” when recording to see who gives the most.</Empty>
          ) : (
            <div className="list">
              {top.map(([id, l], i) => (
                <div key={id} className="list-row">
                  <span className="avatar">{i + 1}</span>
                  <span className="grow">{name(id)}</span>
                  <span className="num">{litres(l)}</span>
                  <span className="small muted num">{num1(l / Math.max(1, recordedDays))} L/day</span>
                </div>
              ))}
            </div>
          )}
        </section>
      </Fit>

      <Tabs label="Milk records" value={tab} onChange={setTab} items={tabs} />

      {tab === 'days' && (
        <div className="table-wrap">
          <table className="table rt">
            <thead>
              <tr>
                <th>Day</th>
                <th className="r">Morning</th>
                <th className="r">Evening</th>
                <th className="r">Total</th>
                <th className="r">Records</th>
              </tr>
            </thead>
            <tbody>
              {!milk.loading &&
                byDay.map((d) => (
                  <tr key={d.day.toISOString()} className="clickable" tabIndex={0} onClick={() => setOpenDay(d.day)} onKeyDown={(e) => e.key === 'Enter' && setOpenDay(d.day)}>
                    <td data-label="Day" className="lead">
                      <strong>
                        {weekday(d.day)} {date(d.day)}
                      </strong>
                    </td>
                    <td data-label="Morning" className="r">
                      {d.m ? litres(d.m) : '–'}
                    </td>
                    <td data-label="Evening" className="r">
                      {d.e ? litres(d.e) : '–'}
                    </td>
                    <td data-label="Total" className="r">
                      <strong>{d.total ? litres(d.total) : '–'}</strong>
                    </td>
                    <td data-label="Records" className="r">
                      {d.n || '–'}
                    </td>
                  </tr>
                ))}
            </tbody>
          </table>
          {milk.loading && <SkelRows rows={7} cols={5} />}
          {!milk.loading && inRange.length === 0 && (
            <Empty icon="drop" action={canSave && <button className="btn sm" onClick={() => setAdding(true)}><Icon name="plus" /> Record milk</button>}>
              No milk recorded in this period.
            </Empty>
          )}
        </div>
      )}

      {tab === 'entries' && (
        <div className="table-wrap">
          <table className="table rt">
            <thead>
              <tr>
                <th>When</th>
                <th>Session</th>
                <th>Animal</th>
                <th>Recorded by</th>
                <th className="r">Litres</th>
              </tr>
            </thead>
            <tbody>
              {entries.slice(0, 300).map((r) => (
                <tr key={r.id} className="clickable" onClick={() => setOpenDay(startOfDay(recordDate(r)))}>
                  <td data-label="When" className="lead">
                    {shortDate(recordDate(r))} {time(recordDate(r))}
                  </td>
                  <td data-label="Session">{words(r.body.session)}</td>
                  <td data-label="Animal">
                    {name(r.body.animalId)}
                    {!r.body.animalId && r.body.cowsMilked ? <span className="small muted"> · {r.body.cowsMilked} cows milked</span> : null}{' '}
                    {r.body.notForSale && <span className="chip bad">Not for sale</span>}
                  </td>
                  <td data-label="Recorded by">{r.body.recordedBy || '–'}</td>
                  <td data-label="Litres" className="r">
                    <strong>{litres(r.body.litres)}</strong>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
          {milk.loading && <SkelRows rows={6} cols={5} />}
          {!milk.loading && entries.length === 0 && <Empty icon="drop">No milk recorded in this period.</Empty>}
        </div>
      )}

      {tab === 'sales' && boss && <Sales sales={salesInRange} marks={marks.data} loading={sales.loading} onAdd={() => setSelling(true)} />}

      {adding && <RecordMilk onClose={() => setAdding(false)} cows={cows} blocked={blocked} />}
      {selling && <RecordSale onClose={() => setSelling(false)} buyers={buyers} />}
      {openDay && (
        <DayDialog day={openDay} records={inRange.filter((r) => sameDay(recordDate(r), openDay))} name={name} onClose={() => setOpenDay(null)} />
      )}
    </>
  );
}
