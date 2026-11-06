'use client';

import Link from 'next/link';
import { FeedAi } from '@/components/aiPage';
import { useMemo, useState } from 'react';
import { CallButtons } from '@/components/farm';
import { Fit } from '@/components/fit';
import { Icon } from '@/components/Icon';
import { CardHead, ConfirmDialog, Empty, ExportButtons, Field, FormDialog, LoadError, PageHead, SkelRows, Stat, Tabs, useSave, useToast } from '@/components/ui';
import { downloadCsv } from '@/lib/csv';
import { addDays, dayKey, localIso, parseDate, startOfDay, startOfMonth } from '@/lib/dates';
import { addRecord, useRecords } from '@/lib/data';
import {
  alive,
  dutyLabel,
  feedGroups,
  feedName,
  feedStock,
  feedUnit,
  manages,
  onDay,
  payMethodName,
  payMethods,
  phoneFeeds,
  recordDate,
  whoIsOn,
  awayOn,
  type AbsenceBody,
  type ContactBody,
  type DutyBody,
  type ExpenseBody,
  type FarmRecord,
  type FeedTypeBody,
  type FeedUseBody,
  type PayMethod,
  type StaffBody,
  type StockMoveBody,
} from '@/lib/domain';
import { firebase } from '@/lib/firebase';
import { num1, shortDate, ugx, words } from '@/lib/format';
import { expensesOf, removeWithExpenses, saveWithExpense } from '@/lib/linked';
import { useFarm, useSession } from '@/lib/session';
import { useOpenFromUrl } from '@/lib/useOpen';

interface FeedOpt {
  key: string;
  name: string;
  unit: string;
  lowAt: number | null;
}

const groupName: Record<string, string> = { milkingCows: 'Milking cows', dryCows: 'Dry cows', heifers: 'Heifers', calves: 'Calves' };

function atFor(day: string): string {
  const d = parseDate(day) ?? new Date();
  const now = new Date();
  return localIso(new Date(d.getFullYear(), d.getMonth(), d.getDate(), now.getHours(), now.getMinutes(), now.getSeconds()));
}

function BuyFeed({
  feeds,
  suppliers,
  edit,
  editExpenses,
  onClose,
}: {
  feeds: FeedOpt[];
  suppliers: FarmRecord<ContactBody>[];
  edit?: FarmRecord<StockMoveBody>;
  editExpenses?: FarmRecord<ExpenseBody>[];
  onClose: () => void;
}) {
  const farm = useFarm();
  const { user, canSave, online } = useSession();
  const toast = useToast();
  const b = edit?.body;
  const [f, setF] = useState({
    feed: b?.feed ?? feeds[0]?.key ?? 'dairyMeal',
    amount: b ? String(b.amount) : '',
    price: b?.pricePerUnit ? String(b.pricePerUnit) : '',
    supplierId: b?.supplierId ?? '',
    supplierName: b?.supplierId ? '' : (b?.supplier ?? ''),
    method: (b?.payMethod ?? 'cash') as PayMethod,
    day: b ? dayKey(recordDate(edit!, 'at')) : dayKey(new Date()),
  });
  const { busy, error, setError, run } = useSave();
  const feed = feeds.find((x) => x.key === f.feed);
  const total = Math.round((Number(f.amount) || 0) * (Number(f.price) || 0));

  async function save() {
    if (!user) return;
    const amount = Number(f.amount);
    const price = Number(f.price);
    if (!(amount > 0)) return setError(`Type how many ${feed?.unit ?? 'bags'} you bought.`);
    if (!Number.isInteger(price) || price <= 0) return setError(`Type the price of one ${feed?.unit.replace(/s$/, '') ?? 'bag'} in shillings.`);
    if (total > 100_000_000) return setError(`${ugx(total)} looks too big. Check the numbers.`);
    const sup = suppliers.find((s) => s.id === f.supplierId);
    const supplier = sup?.body.name ?? (f.supplierName.trim() || null);
    const at = atFor(f.day);
    const ok = await run(() =>
      saveWithExpense(
        firebase().db,
        farm.id,
        user.uid,
        // The phone's purchase shape (fake_feed_repository addPurchase), plus who and how it was paid.
        { collection: 'stockMovements', body: { kind: 'purchase', feed: f.feed, amount, pricePerUnit: price, supplier, supplierId: sup?.id ?? null, payMethod: f.method, at } },
        'feedPurchase',
        { category: 'feed', amount: total, at, note: `${num1(amount)} ${feed?.unit ?? ''} ${feed?.name ?? ''}${supplier ? ` · ${supplier}` : ''}`, supplierId: sup?.id ?? null, payMethod: f.method },
        edit ? { record: edit, expenses: editExpenses ?? [] } : undefined,
      ),
    );
    if (ok) {
      toast(`${edit ? 'Changed' : 'Saved'}: ${ugx(total)} of ${feed?.name}. Money and stock are updated.`);
      onClose();
    }
  }

  return (
    <FormDialog
      title={edit ? 'Change feed purchase' : 'Buy feed'}
      subtitle="Adds to the stock and saves the cost in Money, linked together."
      onClose={onClose}
      onSubmit={save}
      busy={busy}
      error={error}
      canSave={canSave}
      online={online}
      submit={total ? `Save ${ugx(total)}` : 'Save'}
    >
      <Fit kind="fields" cols={[1, 2, 2, 2]}>
        <Field label="Feed">
          <select className="input" value={f.feed} onChange={(e) => setF({ ...f, feed: e.target.value })}>
            {feeds.map((x) => (
              <option key={x.key} value={x.key}>
                {x.name}
              </option>
            ))}
          </select>
        </Field>
        <Field label="Date">
          <input className="input" type="date" max={dayKey(new Date())} value={f.day} onChange={(e) => setF({ ...f, day: e.target.value })} />
        </Field>
        <Field label={`How many ${feed?.unit ?? 'bags'}`}>
          <input className="input" type="number" min={0.5} step={0.5} inputMode="decimal" required value={f.amount} onChange={(e) => setF({ ...f, amount: e.target.value })} autoFocus />
        </Field>
        <Field label={`Price for one ${feed?.unit.replace(/s$/, '') ?? 'bag'} (UGX)`}>
          <input className="input" type="number" min={1} step={1} inputMode="numeric" required value={f.price} onChange={(e) => setF({ ...f, price: e.target.value })} />
        </Field>
        <Field label="Supplier" hint={suppliers.length ? undefined : 'Add feed suppliers under Contacts to see what you spend with each.'}>
          <select className="input" value={f.supplierId} onChange={(e) => setF({ ...f, supplierId: e.target.value })}>
            <option value="">{suppliers.length ? 'Other (type below)' : 'Type below'}</option>
            {suppliers.map((s) => (
              <option key={s.id} value={s.id}>
                {s.body.name}
              </option>
            ))}
          </select>
        </Field>
        {!f.supplierId && (
          <Field label="Supplier name (optional)">
            <input className="input" value={f.supplierName} onChange={(e) => setF({ ...f, supplierName: e.target.value })} placeholder="e.g. Kakoba Agro-vet" />
          </Field>
        )}
        <Field label="Paid by">
          <select className="input" value={f.method} onChange={(e) => setF({ ...f, method: e.target.value as PayMethod })}>
            {payMethods.map((m) => (
              <option key={m} value={m}>
                {payMethodName[m]}
              </option>
            ))}
          </select>
        </Field>
      </Fit>
    </FormDialog>
  );
}

function FeedNow({ feeds, staff, me, onClose }: { feeds: FeedOpt[]; staff: FarmRecord<StaffBody>[]; me: string; onClose: () => void }) {
  const farm = useFarm();
  const { user, canSave, online } = useSession();
  const toast = useToast();
  const [f, setF] = useState({ feed: feeds[0]?.key ?? 'dairyMeal', group: 'milkingCows', amount: '', fedBy: me });
  const { busy, error, setError, run } = useSave();
  const feed = feeds.find((x) => x.key === f.feed);

  async function save() {
    if (!user) return;
    const amount = Number(f.amount);
    if (!(amount > 0)) return setError(`Type how many ${feed?.unit ?? 'bags'} were fed.`);
    const ok = await run(() =>
      addRecord(firebase().db, farm.id, 'feedUsage', user.uid, { feed: f.feed, group: f.group, amount, at: localIso(new Date()), fedBy: f.fedBy || null }),
    );
    if (ok) {
      toast(`Feeding saved: ${num1(amount)} ${feed?.unit} ${feed?.name}`);
      onClose();
    }
  }

  return (
    <FormDialog title="Record feeding" subtitle="Takes it off the stock." onClose={onClose} onSubmit={save} busy={busy} error={error} canSave={canSave} online={online} submit="Save feeding">
      <Fit kind="fields" cols={[1, 2, 2, 2]}>
        <Field label="Feed">
          <select className="input" value={f.feed} onChange={(e) => setF({ ...f, feed: e.target.value })}>
            {feeds.map((x) => (
              <option key={x.key} value={x.key}>
                {x.name}
              </option>
            ))}
          </select>
        </Field>
        <Field label={`How many ${feed?.unit ?? 'bags'}`}>
          <input className="input" type="number" min={0.1} step={0.1} inputMode="decimal" required value={f.amount} onChange={(e) => setF({ ...f, amount: e.target.value })} autoFocus />
        </Field>
        <Field label="Fed to">
          <select className="input" value={f.group} onChange={(e) => setF({ ...f, group: e.target.value })}>
            {feedGroups.map((g) => (
              <option key={g} value={g}>
                {groupName[g]}
              </option>
            ))}
          </select>
        </Field>
        <Field label="Who fed">
          <select className="input" value={f.fedBy} onChange={(e) => setF({ ...f, fedBy: e.target.value })}>
            <option value="">Not said</option>
            {staff.map((s) => (
              <option key={s.id} value={s.id}>
                {s.body.name}
              </option>
            ))}
          </select>
        </Field>
      </Fit>
    </FormDialog>
  );
}

function CountStock({ feeds, onClose }: { feeds: FeedOpt[]; onClose: () => void }) {
  const farm = useFarm();
  const { user, canSave, online } = useSession();
  const toast = useToast();
  const [feed, setFeed] = useState(feeds[0]?.key ?? 'dairyMeal');
  const [amount, setAmount] = useState('');
  const { busy, error, setError, run } = useSave();
  const unit = feeds.find((x) => x.key === feed)?.unit ?? 'bags';
  async function save() {
    if (!user) return;
    const n = Number(amount);
    if (!(n >= 0) || amount.trim() === '') return setError(`Type how many ${unit} are in the store now.`);
    if (await run(() => addRecord(firebase().db, farm.id, 'stockMovements', user.uid, { kind: 'count', feed, amount: n, at: localIso(new Date()) }))) {
      toast('Stock count saved');
      onClose();
    }
  }
  return (
    <FormDialog title="Count the store" subtitle="What is really there now. Stock starts again from this number." onClose={onClose} onSubmit={save} busy={busy} error={error} canSave={canSave} online={online} submit="Save count">
      <Fit kind="fields" cols={[1, 2, 2, 2]}>
        <Field label="Feed">
          <select className="input" value={feed} onChange={(e) => setFeed(e.target.value)}>
            {feeds.map((x) => (
              <option key={x.key} value={x.key}>
                {x.name}
              </option>
            ))}
          </select>
        </Field>
        <Field label={`${words(unit)} in the store`}>
          <input className="input" type="number" min={0} step={0.5} inputMode="decimal" value={amount} onChange={(e) => setAmount(e.target.value)} autoFocus />
        </Field>
      </Fit>
    </FormDialog>
  );
}

function NewFeedType({ onClose }: { onClose: () => void }) {
  const farm = useFarm();
  const { user, canSave, online } = useSession();
  const toast = useToast();
  const [f, setF] = useState({ name: '', unit: 'bags', lowAt: '' });
  const { busy, error, setError, run } = useSave();
  async function save() {
    if (!user) return;
    if (!f.name.trim()) return setError('Type the feed’s name.');
    const lowAt = f.lowAt.trim() ? Number(f.lowAt) : null;
    if (await run(() => addRecord(firebase().db, farm.id, 'feedTypes', user.uid, { name: f.name.trim(), unit: f.unit, lowAt }))) {
      toast(`${f.name.trim()} added`);
      onClose();
    }
  }
  return (
    <FormDialog title="Add a feed" subtitle="For feeds not in the list, like molasses or sweet potato vines." onClose={onClose} onSubmit={save} busy={busy} error={error} canSave={canSave} online={online} submit="Add feed">
      <Fit kind="fields" cols={[1, 3, 3, 3]}>
        <Field label="Name">
          <input className="input" value={f.name} onChange={(e) => setF({ ...f, name: e.target.value })} autoFocus maxLength={40} />
        </Field>
        <Field label="Counted in">
          <select className="input" value={f.unit} onChange={(e) => setF({ ...f, unit: e.target.value })}>
            {['bags', 'kg', 'litres', 'bales', 'blocks', 'tins'].map((u) => (
              <option key={u} value={u}>
                {u}
              </option>
            ))}
          </select>
        </Field>
        <Field label="Warn when this or less is left (optional)">
          <input className="input" type="number" min={0} value={f.lowAt} onChange={(e) => setF({ ...f, lowAt: e.target.value })} />
        </Field>
      </Fit>
    </FormDialog>
  );
}

type Tab = 'purchases' | 'feedings';

export default function Feeds() {
  const farm = useFarm();
  const { user, canSave } = useSession();
  const toast = useToast();
  const boss = manages(farm);
  const now = new Date();
  const monthFrom = startOfMonth(now);
  const moves = useRecords<StockMoveBody>(farm.id, 'stockMovements');
  const uses = useRecords<FeedUseBody>(farm.id, 'feedUsage');
  const types = useRecords<FeedTypeBody>(farm.id, 'feedTypes');
  const contacts = useRecords<ContactBody>(farm.id, 'contacts');
  const duties = useRecords<DutyBody>(farm.id, 'duties');
  const staff = useRecords<StaffBody>(farm.id, 'staff');
  const absences = useRecords<AbsenceBody>(farm.id, 'absences');
  const expenses = useRecords<ExpenseBody>(boss ? farm.id : null, 'expenses', localIso(addDays(monthFrom, -62)));
  const [tab, setTab] = useState<Tab>('purchases');
  const [buying, setBuying] = useOpenFromUrl();
  const [feeding, setFeeding] = useOpenFromUrl('feed');
  const [counting, setCounting] = useState(false);
  const [newType, setNewType] = useState(false);
  const [editing, setEditing] = useState<FarmRecord<StockMoveBody> | null>(null);
  const [removing, setRemoving] = useState<FarmRecord<StockMoveBody> | null>(null);
  const del = useSave();

  const feeds: FeedOpt[] = useMemo(() => {
    const custom = alive(types.data).map((t) => ({ key: t.id, name: t.body.name, unit: t.body.unit || 'bags', lowAt: t.body.lowAt ?? null }));
    return [...phoneFeeds.map((k) => ({ key: k, name: feedName[k], unit: feedUnit(k), lowAt: null })), ...custom];
  }, [types.data]);
  const feedOf = (k: string | undefined) => feeds.find((x) => x.key === k) ?? { key: k ?? '', name: feedName[k ?? ''] ?? words(k ?? 'feed'), unit: feedUnit(k ?? ''), lowAt: null };
  const live = alive(moves.data).filter((m) => m.body.feed);
  const usesAlive = alive(uses.data);
  const used = new Set([...live.map((m) => m.body.feed!), ...usesAlive.map((u) => u.body.feed)]);
  const shownFeeds = feeds.filter((x) => used.has(x.key) || ['dairyMeal', 'maizeBran', 'mineralLick', 'silage'].includes(x.key) || !phoneFeeds.includes(x.key as (typeof phoneFeeds)[number]));
  const stock = shownFeeds.map((x) => ({ ...x, ...feedStock(x.key, live, usesAlive, now) }));
  const purchases = live.filter((m) => m.body.kind === 'purchase').sort((a, b) => recordDate(b, 'at').getTime() - recordDate(a, 'at').getTime());
  const monthBuys = purchases.filter((p) => recordDate(p, 'at') >= monthFrom);
  const monthCost = monthBuys.reduce((t, p) => t + Math.round((Number(p.body.amount) || 0) * (Number(p.body.pricePerUnit) || 0)), 0);
  const low = stock.filter((x) => (x.daysLeft != null && x.daysLeft <= 7) || (x.lowAt != null && x.left <= x.lowAt));
  const suppliers = alive(contacts.data).filter((c) => c.body.kind === 'feedSupplier' && (boss || c.body.showWorkers !== false));
  const people = alive(staff.data).filter((s) => s.body.active !== false);
  const nameOf = (id: string | null | undefined) => people.find((s) => s.id === id)?.body.name ?? '';
  const away = awayOn(absences.data, now);
  const feedingDuty = alive(duties.data).filter((d) => d.body.activity === 'feeding' && onDay(d.body, now));
  const me = people.find((s) => s.body.phone && user?.phoneNumber && s.body.phone.replace(/\D/g, '').endsWith(user.phoneNumber.replace(/\D/g, '').slice(-9)))?.id ?? '';

  const csv = () =>
    downloadCsv(
      `${farm.name}-feed-purchases`,
      ['Date', 'Feed', 'Amount', 'Unit', 'Price each (UGX)', 'Total (UGX)', 'Supplier', 'Paid by'],
      purchases.map((p) => {
        const x = feedOf(p.body.feed);
        return [dayKey(recordDate(p, 'at')), x.name, p.body.amount, x.unit, p.body.pricePerUnit ?? 0, Math.round(p.body.amount * (p.body.pricePerUnit ?? 0)), p.body.supplier ?? '', p.body.payMethod ? payMethodName[p.body.payMethod] : ''];
      }),
    );

  return (
    <>
      <PageHead title="Feeds" subtitle="What is in the store, who feeds, who supplies, and what it costs.">
        <ExportButtons onCsv={csv} />
        {boss && (
          <button className="btn sm ghost" onClick={() => setNewType(true)} disabled={!canSave}>
            <Icon name="plus" /> Feed type
          </button>
        )}
        <button className="btn sm outline" onClick={() => setCounting(true)} disabled={!canSave}>
          <Icon name="list" /> Count store
        </button>
        <button className="btn sm outline" onClick={() => setFeeding(true)} disabled={!canSave}>
          <Icon name="feed" /> Record feeding
        </button>
        {boss && (
          <button className="btn sm" onClick={() => setBuying(true)} disabled={!canSave}>
            <Icon name="plus" /> Buy feed
          </button>
        )}
      </PageHead>
      <FeedAi />
      <LoadError code={moves.error ?? uses.error} />

      {low.length > 0 && (
        <div className="banner warn">
          <Icon name="alert" />
          <span className="grow">
            Running low: {low.map((x) => `${x.name} (${x.daysLeft != null ? `${x.daysLeft} days left` : `${num1(x.left)} ${x.unit}`})`).join(', ')}.
            {suppliers[0] ? ` Call ${suppliers[0].body.name}.` : ''}
          </span>
          {suppliers[0] && <CallButtons phone={suppliers[0].body.phone} compact />}
        </div>
      )}

      <Fit kind="stats" cols={[2, 2, 4, 4]}>
        {boss && <Stat loading={moves.loading} icon="receipt" label="Feed bought this month" value={ugx(monthCost)} hint={`${monthBuys.length} purchase${monthBuys.length === 1 ? '' : 's'} · in Money`} tone="warn" />}
        <Stat loading={moves.loading} icon="feed" label="Feeds in stock" value={String(stock.filter((x) => x.left > 0).length)} hint={low.length ? `${low.length} running low` : 'None running low'} tone={low.length ? 'bad' : undefined} />
        <Stat
          loading={duties.loading}
          icon="workers"
          label="Feeding today"
          value={feedingDuty.length ? nameOf(whoIsOn(feedingDuty[0].body, away).staffId) || 'Nobody' : 'Not set'}
          hint={feedingDuty.length ? (whoIsOn(feedingDuty[0].body, away).covering ? `Covering for ${nameOf(feedingDuty[0].body.staffId)}` : feedingDuty[0].body.standInId ? `Stand-in: ${nameOf(feedingDuty[0].body.standInId)}` : 'No stand-in set') : 'Set it on the duty roster'}
          href="/roster/"
        />
        <Stat loading={contacts.loading} icon="truck" label="Feed suppliers" value={String(suppliers.length)} hint={suppliers[0]?.body.name ?? 'Add them under Contacts'} href="/contacts/" tone="info" />
      </Fit>

      <section className="card">
        <CardHead title="In the store" />
        {moves.loading || uses.loading ? (
          <SkelRows rows={4} cols={4} />
        ) : (
          <div className="feed-grid">
            {stock.map((x) => {
              const bad = (x.daysLeft != null && x.daysLeft <= 7) || (x.lowAt != null && x.left <= x.lowAt);
              return (
                <div key={x.key} className={`card flat stack feed-tile ${bad ? 'low' : ''}`}>
                  <span className="small muted">{x.name}</span>
                  <strong className="big-num">
                    {num1(Math.max(0, x.left))} <small>{x.unit}</small>
                  </strong>
                  <span className="small">{x.perDay > 0 ? `${num1(x.perDay)} a day · ${x.daysLeft ?? 0} days left` : 'No feeding recorded this week'}</span>
                </div>
              );
            })}
          </div>
        )}
      </section>

      {(suppliers.length > 0 || feedingDuty.length > 0) && (
        <Fit kind="cards" cols={[1, 2, 2, 2]}>
          <section className="card">
            <CardHead title="Who feeds">
              <Link className="small" href="/roster/">
                Duty roster
              </Link>
            </CardHead>
            {feedingDuty.length === 0 ? (
              <Empty icon="calendar">Nobody is on feeding duty today. Set it on the duty roster.</Empty>
            ) : (
              <div className="list">
                {feedingDuty.map((d) => {
                  const on = whoIsOn(d.body, away);
                  const p = people.find((s) => s.id === on.staffId);
                  return (
                    <div key={d.id} className="list-row wrap">
                      <span className="grow">
                        <strong>{p?.body.name ?? 'Nobody (all away)'}</strong>
                        <span className="small muted">
                          {' '}
                          · {dutyLabel(d.body)} {on.covering ? `(covering for ${nameOf(d.body.staffId)})` : d.body.standInId ? `· stand-in ${nameOf(d.body.standInId)}` : ''}
                        </span>
                      </span>
                      {p?.body.phone && <CallButtons phone={p.body.phone} compact />}
                    </div>
                  );
                })}
              </div>
            )}
          </section>
          <section className="card">
            <CardHead title="Feed suppliers">
              <Link className="small" href="/contacts/">
                Contacts
              </Link>
            </CardHead>
            {suppliers.length === 0 ? (
              <Empty icon="truck">No feed suppliers yet.</Empty>
            ) : (
              <div className="list">
                {suppliers.map((s) => (
                  <div key={s.id} className="list-row wrap">
                    <span className="grow">
                      <strong>{s.body.name}</strong>
                      <span className="small muted">{s.body.org ? ` · ${s.body.org}` : ''} · {s.body.phone}</span>
                    </span>
                    <CallButtons phone={s.body.phone} compact />
                  </div>
                ))}
              </div>
            )}
          </section>
        </Fit>
      )}

      <Tabs
        label="Feed records"
        value={tab}
        onChange={setTab}
        items={[
          ['purchases', 'Purchases', purchases.length],
          ['feedings', 'Feedings', usesAlive.length],
        ]}
      />
      <div className="table-wrap">
        <table className="table rt">
          <thead>
            {tab === 'purchases' ? (
              <tr>
                <th>Date</th>
                <th>Feed</th>
                <th>Amount</th>
                <th>Supplier</th>
                <th className="r">Cost</th>
                <th />
              </tr>
            ) : (
              <tr>
                <th>When</th>
                <th>Feed</th>
                <th>Amount</th>
                <th>Fed to</th>
                <th>Who fed</th>
              </tr>
            )}
          </thead>
          <tbody>
            {tab === 'purchases' &&
              purchases.slice(0, 200).map((p) => {
                const x = feedOf(p.body.feed);
                return (
                  <tr key={p.id}>
                    <td data-label="Date">{shortDate(recordDate(p, 'at'))}</td>
                    <td data-label="Feed" className="lead">
                      <strong>{x.name}</strong>
                    </td>
                    <td data-label="Amount">
                      {num1(p.body.amount)} {x.unit} × {ugx(p.body.pricePerUnit ?? 0)}
                    </td>
                    <td data-label="Supplier">
                      {p.body.supplier || '–'}
                      {p.body.payMethod ? <span className="small muted"> · {payMethodName[p.body.payMethod]}</span> : null}
                    </td>
                    <td data-label="Cost" className="r">
                      <strong>{ugx(Math.round(p.body.amount * (p.body.pricePerUnit ?? 0)))}</strong>
                    </td>
                    <td className="acts r">
                      {boss && canSave && (
                        <>
                          <button className="icon-btn" aria-label="Change purchase" onClick={() => setEditing(p)}>
                            <Icon name="edit" />
                          </button>
                          <button className="icon-btn" aria-label="Remove purchase" onClick={() => setRemoving(p)}>
                            <Icon name="close" />
                          </button>
                        </>
                      )}
                    </td>
                  </tr>
                );
              })}
            {tab === 'feedings' &&
              [...usesAlive]
                .sort((a, b) => recordDate(b, 'at').getTime() - recordDate(a, 'at').getTime())
                .slice(0, 200)
                .map((u) => {
                  const x = feedOf(u.body.feed);
                  return (
                    <tr key={u.id}>
                      <td data-label="When">{shortDate(recordDate(u, 'at'))}</td>
                      <td data-label="Feed" className="lead">
                        <strong>{x.name}</strong>
                      </td>
                      <td data-label="Amount">
                        {num1(u.body.amount)} {x.unit}
                      </td>
                      <td data-label="Fed to">{groupName[u.body.group] ?? words(u.body.group)}</td>
                      <td data-label="Who fed">{nameOf(u.body.fedBy) || '–'}</td>
                    </tr>
                  );
                })}
          </tbody>
        </table>
        {(moves.loading || uses.loading) && <SkelRows rows={4} cols={5} />}
        {!moves.loading && tab === 'purchases' && purchases.length === 0 && <Empty icon="feed">No feed bought yet. Buying feed here adds it to the store and to Money.</Empty>}
        {!uses.loading && tab === 'feedings' && usesAlive.length === 0 && <Empty icon="feed">No feedings recorded yet.</Empty>}
      </div>

      {buying && <BuyFeed feeds={feeds} suppliers={suppliers} onClose={() => setBuying(false)} />}
      {editing && <BuyFeed feeds={feeds} suppliers={suppliers} edit={editing} editExpenses={expensesOf(editing.id, expenses.data)} onClose={() => setEditing(null)} />}
      {feeding && <FeedNow feeds={feeds} staff={people} me={me} onClose={() => setFeeding(false)} />}
      {counting && <CountStock feeds={feeds} onClose={() => setCounting(false)} />}
      {newType && <NewFeedType onClose={() => setNewType(false)} />}
      {removing && (
        <ConfirmDialog
          title="Remove this purchase?"
          confirm="Remove"
          danger
          busy={del.busy}
          error={del.error}
          onClose={() => setRemoving(null)}
          onConfirm={async () => {
            if (!user) return;
            if (await del.run(() => removeWithExpenses(firebase().db, farm.id, user.uid, removing, expensesOf(removing.id, expenses.data)))) {
              toast('Purchase removed from the store and from Money');
              setRemoving(null);
            }
          }}
        >
          It comes off the stock, and its expense in Money is removed with it.
        </ConfirmDialog>
      )}
    </>
  );
}

