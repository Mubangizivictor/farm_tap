'use client';

import { doc, setDoc } from 'firebase/firestore';
import { useEffect, useState } from 'react';
import { Fit } from '@/components/fit';
import { Icon } from '@/components/Icon';
import {
  ConfirmDialog,
  Dialog,
  Empty,
  ExportButtons,
  Field,
  FormDialog,
  LoadError,
  PageHead,
  SearchBox,
  Seg,
  SkelRows,
  Stat,
  useSave,
  useToast,
} from '@/components/ui';
import { activeCardOf, cardNumber, cardProblem, endCard, giveCard, nextFreeCard, takenNumbers } from '@/lib/cards';
import { downloadCsv } from '@/lib/csv';
import { dayKey, localIso, sameDay, startOfMonth } from '@/lib/dates';
import { addRecord, mergeBody, putRecord, removeRecord, upsertRecord, useRecords } from '@/lib/data';
import { manages, recordDate, type DeliveryBody, type FarmRecord, type FarmerBody, type NfcCardBody, type StaffBody } from '@/lib/domain';
import { count, date, initials, litres, num1, shortDate, time, words } from '@/lib/format';
import { firebase } from '@/lib/firebase';
import { useFarm, useSession } from '@/lib/session';
import { useOpenFromUrl } from '@/lib/useOpen';

const rejectReasons = ['sour', 'addedWater', 'dirty', 'treatedCow', 'other'] as const;
const reasonText = (r: string | null | undefined) => (r === 'treatedCow' ? 'From a treated animal' : words(r) || 'Rejected');
const phoneOk = (p: string) => /^\+?[\d\s-]{9,16}$/.test(p.trim());
const MAX_DELIVERY_L = 2000;

function SupplierForm({ f: rec, cards, taken, onClose }: { f?: FarmRecord<FarmerBody>; cards: FarmRecord<NfcCardBody>[]; taken: Set<string>; onClose: () => void }) {
  const farm = useFarm();
  const { user, canSave, online } = useSession();
  const toast = useToast();
  const [name, setName] = useState(rec?.body.name ?? '');
  const [phone, setPhone] = useState(rec?.body.phone ?? '');
  const [village, setVillage] = useState(rec?.body.village ?? '');
  const [sms, setSms] = useState(rec?.body.smsReceipts !== false);
  const [card, setCard] = useState(rec ? '' : nextFreeCard(taken));
  const [cardTouched, setCardTouched] = useState(false);
  // Opened before the card register loaded: keep the suggestion free until they type one.
  const freeCard = nextFreeCard(taken);
  useEffect(() => {
    if (!rec && !cardTouched) setCard(freeCard);
  }, [rec, cardTouched, freeCard]);
  const { busy, error, setError, run } = useSave();
  const n = card.trim() ? cardNumber(card) : null;

  async function save() {
    if (!user) return;
    if (!name.trim()) return setError('Type the farmer’s name.');
    if (!phoneOk(phone)) return setError('Type a phone number for SMS receipts, e.g. 0772 123 456.');
    if (card.trim() && !n) return setError('A card number is up to 4 numbers, e.g. 0012.');
    const id = rec?.id ?? crypto.randomUUID();
    if (n) {
      const p = cardProblem(cards, n, id);
      if (p) return setError(`${p} Use ${nextFreeCard(taken)}.`);
    }
    const { db } = firebase();
    const ok = await run(async () => {
      if (rec) {
        await putRecord(db, farm.id, rec, user.uid, mergeBody(rec, { name: name.trim(), phone: phone.trim(), village: village.trim(), smsReceipts: sms }));
        const c = activeCardOf(cards, rec.id);
        if (c && c.body.personName !== name.trim()) await upsertRecord(db, farm.id, 'nfcCards', c.id, user.uid, { ...c.body, personName: name.trim() });
        return;
      }
      // The card goes in the farm's register first, so every phone knows its holder.
      if (n) await giveCard(upsertRecord, db, farm.id, user.uid, cards, n, { id, kind: 'farmer', name: name.trim() });
      await addRecord(
        db,
        farm.id,
        'farmers',
        user.uid,
        { name: name.trim(), phone: phone.trim(), village: village.trim(), card: n, photo: null, photoUrl: null, since: localIso(new Date(new Date().setHours(0, 0, 0, 0))), smsReceipts: sms },
        id,
      );
    });
    if (ok) {
      toast(rec ? `${name.trim()} saved` : `${name.trim()} added${n ? ` with card ${n}` : ''}`);
      onClose();
    }
  }

  return (
    <FormDialog
      title={rec ? `Edit ${rec.body.name}` : 'Add supplier'}
      onClose={onClose}
      onSubmit={save}
      busy={busy}
      error={error}
      canSave={canSave}
      online={online}
      submit={rec ? 'Save changes' : 'Add supplier'}
    >
      <Fit kind="fields" cols={[1, 2, 2, 2]}>
        <Field label="Farmer’s name">
          <input className="input" required value={name} onChange={(e) => setName(e.target.value)} autoFocus maxLength={80} />
        </Field>
        <Field label="Phone (for SMS receipts)">
          <input className="input" type="tel" required value={phone} onChange={(e) => setPhone(e.target.value)} placeholder="0772 123 456" />
        </Field>
        <Field label="Village (optional)">
          <input className="input" value={village} onChange={(e) => setVillage(e.target.value)} />
        </Field>
        {!rec && (
          <Field label="Card number (optional)" hint="The number printed on the card. Each card belongs to one person." error={n ? cardProblem(cards, n, '') : null}>
            <input className="input" inputMode="numeric" maxLength={7} value={card} onChange={(e) => (setCardTouched(true), setCard(e.target.value))} />
          </Field>
        )}
      </Fit>
      <label className="check-row">
        <input type="checkbox" checked={sms} onChange={(e) => setSms(e.target.checked)} />
        <span>Send an SMS receipt for each delivery</span>
      </label>
    </FormDialog>
  );
}

function CardForm({ f, cards, taken, onClose }: { f: FarmRecord<FarmerBody>; cards: FarmRecord<NfcCardBody>[]; taken: Set<string>; onClose: () => void }) {
  const farm = useFarm();
  const { user, canSave, online } = useSession();
  const toast = useToast();
  const current = activeCardOf(cards, f.id);
  const [typed, setTyped] = useState(nextFreeCard(taken));
  const [why, setWhy] = useState<'returned' | 'lost'>('returned');
  const { busy, error, setError, run } = useSave();
  const n = cardNumber(typed);

  async function save() {
    if (!user) return;
    const { db } = firebase();
    if (current) {
      if (
        await run(async () => {
          await endCard(upsertRecord, db, farm.id, user.uid, current, why);
          await putRecord(db, farm.id, f, user.uid, mergeBody(f, { card: null }));
        })
      ) {
        toast(`Card ${current.id} ${why === 'lost' ? 'blocked' : 'taken back'}`);
        onClose();
      }
      return;
    }
    if (!n) return setError('Type the 4-digit number printed on the card.');
    const p = cardProblem(cards, n, f.id);
    if (p) return setError(p);
    if (
      await run(async () => {
        await giveCard(upsertRecord, db, farm.id, user.uid, cards, n, { id: f.id, kind: 'farmer', name: f.body.name });
        await putRecord(db, farm.id, f, user.uid, mergeBody(f, { card: n }));
      })
    ) {
      toast(`Card ${n} given to ${f.body.name}`);
      onClose();
    }
  }

  return (
    <FormDialog
      title={current ? `Card ${current.id}` : `Give ${f.body.name} a card`}
      subtitle={current ? 'Take the card back before it goes to someone else.' : 'Type the number printed on the card.'}
      onClose={onClose}
      onSubmit={save}
      busy={busy}
      error={error}
      canSave={canSave}
      online={online}
      submit={current ? (why === 'lost' ? 'Block card' : 'Take card back') : 'Give card'}
      danger={!!current && why === 'lost'}
    >
      {current ? (
        <Seg label="Why" value={why} onChange={setWhy} items={[['returned', 'Given back'], ['lost', 'Lost or stolen']]} />
      ) : (
        <Field label="Card number" error={n && cardProblem(cards, n, f.id)} hint={`Next free number: ${nextFreeCard(taken)}`}>
          <input className="input" style={{ maxWidth: 'var(--z-stat-min)' }} inputMode="numeric" maxLength={7} required value={typed} onChange={(e) => setTyped(e.target.value)} autoFocus />
        </Field>
      )}
    </FormDialog>
  );
}

/** A delivery typed at the centre desk (phone: recordDelivery / rejectDelivery). */
function DeliveryForm({ farmers, start, onClose }: { farmers: FarmRecord<FarmerBody>[]; start?: string; onClose: () => void }) {
  const farm = useFarm();
  const { user, canSave, online } = useSession();
  const toast = useToast();
  const [farmerId, setFarmerId] = useState(start ?? '');
  const [l, setL] = useState('');
  const [test, setTest] = useState<'passed' | 'failed' | 'notDone'>('passed');
  const [reason, setReason] = useState<(typeof rejectReasons)[number]>('sour');
  const [note, setNote] = useState('');
  const { busy, error, setError, run } = useSave();

  async function save() {
    if (!user) return;
    const f = farmers.find((x) => x.id === farmerId);
    if (!f) return setError('Choose the farmer who brought the milk.');
    const n = Number(l);
    if (!(n > 0)) return setError('Type the litres, more than 0.');
    if (n > MAX_DELIVERY_L) return setError(`${num1(n)} L looks too much for one delivery. Check the number.`);
    const now = new Date();
    const id = crypto.randomUUID();
    const { db } = firebase();
    const ok = await run(async () => {
      await addRecord(
        db,
        farm.id,
        'deliveries',
        user.uid,
        {
          farmerId: f.id,
          litres: n,
          session: now.getHours() < 12 ? 'morning' : 'evening',
          test,
          rejectReason: test === 'failed' ? reason : null,
          at: localIso(now),
          ...(test === 'failed' ? { note: note.trim() || null } : {}),
        },
        id,
      );
      if (test !== 'failed' && f.body.smsReceipts !== false && f.body.phone) {
        const hm = `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`;
        await addRecord(
          db,
          farm.id,
          'smsOutbox',
          user.uid,
          { to: f.body.phone.replace(/\s/g, ''), text: `FarmTap: received ${n.toFixed(1)} L of milk from ${f.body.name} at ${hm}. Thank you.`, kind: 'deliveryReceipt', status: 'queued' },
          `receipt-${id}`,
        );
      }
    });
    if (ok) {
      toast(test === 'failed' ? `Rejected ${litres(n)} from ${f.body.name}` : `${litres(n)} received from ${f.body.name}`);
      onClose();
    }
  }

  return (
    <FormDialog title="Record delivery" subtitle="Saved now, for this session." onClose={onClose} onSubmit={save} busy={busy} error={error} canSave={canSave} online={online} submit={test === 'failed' ? 'Save rejection' : 'Save delivery'} danger={test === 'failed'}>
      <Fit kind="fields" cols={[1, 2, 2, 2]}>
        <Field label="Farmer">
          <select className="input" required value={farmerId} onChange={(e) => setFarmerId(e.target.value)} autoFocus={!start}>
            <option value="">Choose…</option>
            {farmers.map((f) => (
              <option key={f.id} value={f.id}>
                {f.body.name}
                {f.body.card ? ` · ${f.body.card}` : ''}
              </option>
            ))}
          </select>
        </Field>
        <Field label="Litres">
          <input className="input" type="number" min={0.1} max={MAX_DELIVERY_L} step={0.1} inputMode="decimal" required value={l} onChange={(e) => setL(e.target.value)} autoFocus={!!start} />
        </Field>
      </Fit>
      <Field label="Quality test">
        <Seg label="Quality test" value={test} onChange={setTest} items={[['passed', 'Passed'], ['notDone', 'Not tested'], ['failed', 'Rejected']]} />
      </Field>
      {test === 'failed' && (
        <Fit kind="fields" cols={[1, 2, 2, 2]}>
          <Field label="Why rejected">
            <select className="input" value={reason} onChange={(e) => setReason(e.target.value as (typeof rejectReasons)[number])}>
              {rejectReasons.map((r) => (
                <option key={r} value={r}>
                  {reasonText(r)}
                </option>
              ))}
            </select>
          </Field>
          <Field label="Note (optional)">
            <input className="input" value={note} onChange={(e) => setNote(e.target.value)} />
          </Field>
        </Fit>
      )}
    </FormDialog>
  );
}

function InviteDialog({ f, farmName, onClose }: { f: FarmRecord<FarmerBody>; farmName: string; onClose: () => void }) {
  const farm = useFarm();
  const { user } = useSession();
  const [link, setLink] = useState('');
  const [copied, setCopied] = useState(false);
  const { busy, error, run } = useSave();

  async function generate() {
    if (!user) return;
    const code = crypto.randomUUID().replace(/-/g, '').slice(0, 16);
    const ok = await run(() =>
      setDoc(doc(firebase().db, 'farmerInvites', code), {
        tenantId: farm.id,
        farmerId: f.id,
        farmerName: f.body.name,
        farmName,
        createdAt: new Date().toISOString(),
        expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(),
        createdBy: user.uid,
        used: false,
      }),
    );
    if (ok) setLink(`${window.location.origin}/supplier-invite/?code=${code}`);
  }

  async function copy() {
    try {
      await navigator.clipboard.writeText(link);
      setCopied(true);
    } catch {
      /* the link is selectable */
    }
  }

  return (
    <Dialog title={`Invite ${f.body.name}`} onClose={onClose}>
      <p className="muted">
        Send this link to <strong>{f.body.name}</strong> so they can see their deliveries online. The link works once and for 7 days.
      </p>
      {error && <div className="banner bad small">{error}</div>}
      {!link ? (
        <div className="actions">
          <button type="button" className="btn outline" onClick={onClose}>
            Cancel
          </button>
          <button className="btn" onClick={() => void generate()} disabled={busy}>
            {busy ? 'Making link…' : 'Make invite link'}
          </button>
        </div>
      ) : (
        <>
          <Field label="Invite link">
            <div className="row" style={{ gap: 'var(--s-xs)' }}>
              <input className="input grow" readOnly value={link} onFocus={(e) => e.target.select()} />
              <button className="btn sm outline" onClick={() => void copy()} title="Copy">
                <Icon name={copied ? 'check' : 'copy'} />
              </button>
            </div>
          </Field>
          <div className="actions">
            <button type="button" className="btn outline" onClick={onClose}>
              Close
            </button>
            <a
              className="btn"
              href={`https://wa.me/${f.body.phone.replace(/\D/g, '').replace(/^0/, '256')}?text=${encodeURIComponent(`Hello ${f.body.name}, here is your FarmTap link to see your milk deliveries: ${link}`)}`}
              target="_blank"
              rel="noreferrer"
            >
              <Icon name="whatsapp" /> Send on WhatsApp
            </a>
          </div>
        </>
      )}
    </Dialog>
  );
}

function SupplierDetail({
  f,
  card,
  deliveries,
  boss,
  onEdit,
  onCard,
  onInvite,
  onDeliver,
  onClose,
}: {
  f: FarmRecord<FarmerBody>;
  card: string | null;
  deliveries: FarmRecord<DeliveryBody>[];
  boss: boolean;
  onEdit: () => void;
  onCard: () => void;
  onInvite: () => void;
  onDeliver: () => void;
  onClose: () => void;
}) {
  const farm = useFarm();
  const { user, canSave } = useSession();
  const toast = useToast();
  const [undo, setUndo] = useState<FarmRecord<DeliveryBody> | null>(null);
  const undoSave = useSave();
  const now = new Date();
  const mine = deliveries.filter((d) => d.body.farmerId === f.id).sort((a, b) => recordDate(b, 'at').getTime() - recordDate(a, 'at').getTime());
  const ok = mine.filter((d) => d.body.test !== 'failed');
  const total = ok.reduce((t, d) => t + (Number(d.body.litres) || 0), 0);

  if (undo) {
    return (
      <ConfirmDialog
        title="Undo this delivery?"
        confirm="Undo delivery"
        danger
        busy={undoSave.busy}
        error={undoSave.error}
        onClose={() => setUndo(null)}
        onConfirm={async () => {
          if (!user) return;
          const { db } = firebase();
          const done = await undoSave.run(async () => {
            await removeRecord(db, farm.id, undo, user.uid);
            // The SMS receipt, if still waiting, is withdrawn too (phone: sms.cancel).
            try {
              await removeRecord(db, farm.id, { id: `receipt-${undo.id}`, collection: 'smsOutbox', version: 1 } as FarmRecord<object>, user.uid);
            } catch {
              /* no receipt queued for this one */
            }
          });
          if (done) {
            toast('Delivery undone');
            setUndo(null);
          }
        }}
      >
        {litres(undo.body.litres)} at {time(recordDate(undo, 'at'))}. Use this only for a mistake.
      </ConfirmDialog>
    );
  }

  return (
    <Dialog title={f.body.name} subtitle={f.body.village || 'Village not set'} onClose={onClose} size="lg">
      <div className="row wrap">
        <span className="avatar lg">{f.body.photoUrl ? <img src={f.body.photoUrl} alt="" /> : initials(f.body.name)}</span>
        <div className="stack grow" style={{ gap: 'var(--s-xxs)' }}>
          <span>{f.body.phone}</span>
          <div className="chips">
            {card ? <span className="chip brand">Card {card}</span> : <span className="chip warn">No card</span>}
            {f.body.smsReceipts === false ? <span className="chip">No SMS receipts</span> : <span className="chip ok">SMS receipts</span>}
          </div>
        </div>
      </div>
      {canSave && (
        <div className="btn-row">
          <button className="btn sm" onClick={onDeliver}>
            <Icon name="truck" /> Record delivery
          </button>
          {boss && (
            <>
              <button className="btn sm outline" onClick={onEdit}>
                <Icon name="edit" /> Edit
              </button>
              <button className="btn sm outline" onClick={onCard}>
                <Icon name="card" /> {card ? 'Card' : 'Give card'}
              </button>
              <button className="btn sm outline" onClick={onInvite}>
                <Icon name="globe" /> Invite to see records
              </button>
            </>
          )}
        </div>
      )}
      <Fit kind="stats" cols={[2, 2, 2, 2]}>
        <div className="card flat stat">
          <span className="label">Brought this month</span>
          <span className="value">{litres(total)}</span>
          <span className="hint">{ok.length} deliveries</span>
        </div>
        <div className="card flat stat">
          <span className="label">Rejected</span>
          <span className="value">{mine.length - ok.length}</span>
        </div>
      </Fit>
      <h3>Deliveries this month</h3>
      {mine.length === 0 ? (
        <p className="small muted">No deliveries this month.</p>
      ) : (
        <div className="list">
          {mine.slice(0, 30).map((d) => (
            <div key={d.id} className="list-row small">
              <span className="grow">
                {shortDate(recordDate(d, 'at'))} {time(recordDate(d, 'at'))} · {words(d.body.session)}
              </span>
              <span className="num">{litres(d.body.litres)}</span>
              {d.body.test === 'failed' && <span className="chip bad">{reasonText(d.body.rejectReason)}</span>}
              {canSave && sameDay(recordDate(d, 'at'), now) && (
                <button className="icon-btn" aria-label="Undo" title="Undo a mistake" onClick={() => setUndo(d)}>
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

type Modal = 'edit' | 'card' | 'invite' | 'deliver' | null;

/** Milk suppliers of a collection centre (Section E). */
export default function Farmers() {
  const farm = useFarm();
  const { canSave } = useSession();
  const boss = manages(farm);
  const now = new Date();
  const monthFrom = startOfMonth(now);
  const farmers = useRecords<FarmerBody>(farm.id, 'farmers');
  const staff = useRecords<StaffBody>(farm.id, 'staff');
  const cards = useRecords<NfcCardBody>(farm.id, 'nfcCards');
  const deliveries = useRecords<DeliveryBody>(farm.id, 'deliveries', localIso(monthFrom));
  const [q, setQ] = useState('');
  const [adding, setAdding] = useOpenFromUrl();
  const [delivering, setDelivering] = useOpenFromUrl('delivery');
  const [openId, setOpenId] = useState<string | null>(null);
  const [modal, setModal] = useState<Modal>(null);

  const open = farmers.data.find((f) => f.id === openId) ?? null;
  const taken = takenNumbers(cards.data, [...farmers.data.map((f) => f.body.card), ...staff.data.map((s) => s.body.cardNumber)]);
  const cardOf = (f: FarmRecord<FarmerBody>) => activeCardOf(cards.data, f.id)?.id ?? f.body.card ?? null;
  const accepted = (id: string) => deliveries.data.filter((d) => d.body.farmerId === id && d.body.test !== 'failed');
  const monthL = (id: string) => accepted(id).reduce((t, d) => t + (Number(d.body.litres) || 0), 0);
  const todayL = (id: string) => accepted(id).filter((d) => sameDay(recordDate(d, 'at'), now)).reduce((t, d) => t + (Number(d.body.litres) || 0), 0);
  const rejected = (id: string) => deliveries.data.filter((d) => d.body.farmerId === id && d.body.test === 'failed').length;
  const list = [...farmers.data].sort((a, b) => monthL(b.id) - monthL(a.id) || a.body.name.localeCompare(b.body.name));
  const shown = list.filter((f) => !q || `${f.body.name} ${f.body.phone} ${f.body.village ?? ''} ${cardOf(f) ?? ''}`.toLowerCase().includes(q.toLowerCase()));
  const totalToday = farmers.data.reduce((t, f) => t + todayL(f.id), 0);
  const totalMonth = farmers.data.reduce((t, f) => t + monthL(f.id), 0);
  const broughtToday = farmers.data.filter((f) => todayL(f.id) > 0).length;
  const rejectedMonth = deliveries.data.filter((d) => d.body.test === 'failed').length;
  const byName = [...farmers.data].sort((a, b) => a.body.name.localeCompare(b.body.name));

  const csv = () =>
    downloadCsv(
      `${farm.name}-suppliers-${dayKey(now)}`,
      ['Name', 'Phone', 'Village', 'Card', 'Litres today', 'Litres this month', 'Rejected this month'],
      shown.map((f) => [f.body.name, f.body.phone, f.body.village ?? '', cardOf(f) ?? '', todayL(f.id), monthL(f.id), rejected(f.id)]),
    );
  const closeModal = () => setModal(null);

  return (
    <>
      <PageHead title="Suppliers" subtitle={`Farmers who bring milk · ${date(monthFrom)} to today`}>
        <SearchBox value={q} onChange={setQ} placeholder="Search name, phone, card" />
        <ExportButtons onCsv={csv} />
        <button className="btn sm outline" onClick={() => setDelivering(true)} disabled={!canSave || farmers.data.length === 0}>
          <Icon name="truck" /> Record delivery
        </button>
        {boss && (
          <button className="btn sm" onClick={() => setAdding(true)} disabled={!canSave}>
            <Icon name="plus" /> Add supplier
          </button>
        )}
      </PageHead>
      <LoadError code={farmers.error ?? deliveries.error} />

      <Fit kind="stats">
        <Stat loading={deliveries.loading} icon="truck" label="Collected today" value={litres(totalToday)} hint={`${broughtToday} of ${farmers.data.length} suppliers`} tone="info" />
        <Stat loading={deliveries.loading} icon="calendar" label="This month" value={litres(totalMonth)} hint={`${rejectedMonth} rejected`} />
        <Stat loading={farmers.loading} icon="farmers" label="Suppliers" value={count(farmers.data.length)} hint={`${farmers.data.filter((f) => !cardOf(f)).length} without a card`} tone="gold" />
      </Fit>

      <div className="table-wrap">
        <table className="table rt">
          <thead>
            <tr>
              <th>Name</th>
              <th>Phone</th>
              <th>Village</th>
              <th>Card</th>
              <th className="r">Today</th>
              <th className="r">This month</th>
              <th className="r">Rejected</th>
            </tr>
          </thead>
          <tbody>
            {shown.map((f) => (
              <tr key={f.id} className="clickable" tabIndex={0} onClick={() => setOpenId(f.id)} onKeyDown={(e) => e.key === 'Enter' && setOpenId(f.id)}>
                <td data-label="Name" className="lead">
                  <strong>{f.body.name}</strong>
                </td>
                <td data-label="Phone">{f.body.phone}</td>
                <td data-label="Village">{f.body.village || '–'}</td>
                <td data-label="Card">{cardOf(f) || <span className="chip warn">No card</span>}</td>
                <td data-label="Today" className="r">
                  {todayL(f.id) ? litres(todayL(f.id)) : '–'}
                </td>
                <td data-label="This month" className="r">
                  {litres(monthL(f.id))}
                </td>
                <td data-label="Rejected" className="r">
                  {rejected(f.id) || '–'}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        {farmers.loading && <SkelRows rows={5} cols={6} />}
        {!farmers.loading && shown.length === 0 && (
          <Empty
            icon="truck"
            action={
              !q &&
              boss &&
              canSave && (
                <button className="btn sm" onClick={() => setAdding(true)}>
                  <Icon name="plus" /> Add supplier
                </button>
              )
            }
          >
            {farmers.data.length ? 'No supplier matches.' : 'No suppliers yet. Add the farmers who bring you milk.'}
          </Empty>
        )}
      </div>

      {adding && <SupplierForm cards={cards.data} taken={taken} onClose={() => setAdding(false)} />}
      {delivering && <DeliveryForm farmers={byName} onClose={() => setDelivering(false)} />}
      {open && modal === 'edit' && <SupplierForm f={open} cards={cards.data} taken={taken} onClose={closeModal} />}
      {open && modal === 'card' && <CardForm f={open} cards={cards.data} taken={taken} onClose={closeModal} />}
      {open && modal === 'invite' && <InviteDialog f={open} farmName={farm.name} onClose={closeModal} />}
      {open && modal === 'deliver' && <DeliveryForm farmers={byName} start={open.id} onClose={closeModal} />}
      {open && !modal && (
        <SupplierDetail
          f={open}
          card={cardOf(open)}
          deliveries={deliveries.data}
          boss={boss}
          onEdit={() => setModal('edit')}
          onCard={() => setModal('card')}
          onInvite={() => setModal('invite')}
          onDeliver={() => setModal('deliver')}
          onClose={() => setOpenId(null)}
        />
      )}
    </>
  );
}
