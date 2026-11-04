'use client';

// Shared farm pieces (decision 0023): call buttons and paying a supplier.

import Link from 'next/link';
import { useState } from 'react';
import { Fit } from '@/components/fit';
import { Icon } from '@/components/Icon';
import { Field, FormDialog, useSave, useToast } from '@/components/ui';
import { addDays, dayKey, localIso, parseDate, sameDay, startOfDay } from '@/lib/dates';
import { addRecord, useRecords } from '@/lib/data';
import {
  alive,
  animalLabel,
  awayOn,
  breedingView,
  dutyLabel,
  feedName,
  feedStock,
  hasHerd,
  isActiveAnimal,
  manages,
  onDay,
  whoIsOn,
  type AbsenceBody,
  type AnimalBody,
  type BreedingBody,
  type DutyBody,
  type FeedUseBody,
  type StaffBody,
  type StockMoveBody,
  type VaccinationBody,
  categoryForContact,
  categoryName,
  contactKindName,
  expenseCategories,
  payMethodName,
  payMethods,
  recordDate,
  telLink,
  waLink,
  type ContactBody,
  type ExpenseBody,
  type FarmRecord,
  type PayMethod,
} from '@/lib/domain';
import { firebase } from '@/lib/firebase';
import { shortDate, ugx } from '@/lib/format';
import { saveWithExpense } from '@/lib/linked';
import { useFarm, useSession } from '@/lib/session';

const MAX_UGX = 100_000_000;

/** Call and WhatsApp buttons for a phone number. */
export function CallButtons({ phone, compact }: { phone: string; compact?: boolean }) {
  if (!phone) return null;
  return (
    <span className="row call-btns">
      <a className={`btn ${compact ? 'sm' : ''} outline`} href={telLink(phone)} aria-label={`Call ${phone}`}>
        <Icon name="phone" /> {compact ? '' : 'Call'}
      </a>
      <a className={`btn ${compact ? 'sm' : ''} ghost`} href={waLink(phone)} target="_blank" rel="noreferrer" aria-label={`WhatsApp ${phone}`}>
        <Icon name="whatsapp" />
      </a>
    </span>
  );
}

/** Pay a supplier, vet or anyone: an expense linked to them, shown in Money. */
export function PaySupplier({
  contacts,
  contact,
  onClose,
  edit,
}: {
  contacts: FarmRecord<ContactBody>[];
  contact?: FarmRecord<ContactBody>;
  onClose: () => void;
  edit?: FarmRecord<ExpenseBody>;
}) {
  const farm = useFarm();
  const { user, canSave, online } = useSession();
  const toast = useToast();
  const [supplierId, setSupplierId] = useState(edit?.body.supplierId ?? contact?.id ?? contacts[0]?.id ?? '');
  const sup = contacts.find((c) => c.id === supplierId);
  const [category, setCategory] = useState<string>(edit?.body.category ?? (sup ? categoryForContact(sup.body.kind) : 'other'));
  const [amount, setAmount] = useState(edit ? String(edit.body.amount) : '');
  const [day, setDay] = useState(edit ? dayKey(recordDate(edit, 'at')) : dayKey(new Date()));
  const [method, setMethod] = useState<PayMethod>((edit?.body.payMethod as PayMethod) ?? 'cash');
  const [note, setNote] = useState(edit?.body.note ?? '');
  const { busy, error, setError, run } = useSave();

  async function save() {
    if (!user) return;
    if (!sup) return setError('Choose who you paid.');
    const n = Number(amount);
    if (!Number.isInteger(n) || n <= 0) return setError('Type the amount in whole shillings.');
    if (n > MAX_UGX) return setError(`${ugx(n)} looks too big. Check the number.`);
    const picked = parseDate(day) ?? new Date();
    const at = localIso(new Date(picked.getFullYear(), picked.getMonth(), picked.getDate(), new Date().getHours(), new Date().getMinutes()));
    const { db } = firebase();
    const body = { category, amount: n, at, note: note.trim() || sup.body.name, sourceId: null, sourceType: 'supplierPayment', supplierId: sup.id, payMethod: method, photo: null };
    const ok = await run(async () => {
      if (edit) {
        // Expenses cannot change in place: remove the old one and save the new one together.
        await saveWithExpense(db, farm.id, user.uid, { collection: 'expenses', body: body }, 'supplierPayment', null, { record: edit, expenses: [] });
      } else await addRecord(db, farm.id, 'expenses', user.uid, body);
    });
    if (ok) {
      toast(`${ugx(n)} to ${sup.body.name} saved in Money`);
      onClose();
    }
  }

  return (
    <FormDialog
      title={edit ? 'Change payment' : 'Pay a supplier'}
      subtitle="Saved as an expense in Money and counted in what you spent with them."
      onClose={onClose}
      onSubmit={save}
      busy={busy}
      error={error}
      canSave={canSave}
      online={online}
      submit={Number(amount) > 0 ? `Save ${ugx(Number(amount))}` : 'Save'}
    >
      <Field label="Paid to">
        <select
          className="input"
          value={supplierId}
          onChange={(e) => {
            setSupplierId(e.target.value);
            const s = contacts.find((c) => c.id === e.target.value);
            if (s) setCategory(categoryForContact(s.body.kind));
          }}
        >
          {contacts.map((c) => (
            <option key={c.id} value={c.id}>
              {c.body.name} · {contactKindName[c.body.kind as keyof typeof contactKindName] ?? c.body.kind}
            </option>
          ))}
        </select>
      </Field>
      <Fit kind="fields" cols={[1, 2, 2, 2]}>
        <Field label="Amount (UGX)">
          <input className="input" type="number" min={1} step={1} inputMode="numeric" required value={amount} onChange={(e) => setAmount(e.target.value)} />
        </Field>
        <Field label="Date">
          <input className="input" type="date" max={dayKey(new Date())} value={day} onChange={(e) => setDay(e.target.value)} />
        </Field>
        <Field label="For">
          <select className="input" value={category} onChange={(e) => setCategory(e.target.value)}>
            {expenseCategories
              .filter((c) => c !== 'wages')
              .map((c) => (
                <option key={c} value={c}>
                  {categoryName[c]}
                </option>
              ))}
          </select>
        </Field>
        <Field label="Paid by">
          <select className="input" value={method} onChange={(e) => setMethod(e.target.value as PayMethod)}>
            {payMethods.map((m) => (
              <option key={m} value={m}>
                {payMethodName[m]}
              </option>
            ))}
          </select>
        </Field>
      </Fit>
      <Field label="What for (optional)">
        <input className="input" value={note} onChange={(e) => setNote(e.target.value)} placeholder="e.g. Vet visit, 2 cows; 10 bags dairy meal" maxLength={200} />
      </Field>
    </FormDialog>
  );
}


// ---------------------------------------------------------------- Home: today on the farm

/**
 * Home card for everyone, workers included (decision 0023): who is on duty
 * today and who covers, who to call, and what is coming up (vaccinations,
 * calvings, pregnancy checks, feed running low).
 */
export function TodayOnFarm() {
  const farm = useFarm();
  const now = new Date();
  const duties = useRecords<DutyBody>(farm.id, 'duties');
  const staff = useRecords<StaffBody>(farm.id, 'staff');
  const contacts = useRecords<ContactBody>(farm.id, 'contacts');
  const absences = useRecords<AbsenceBody>(farm.id, 'absences');
  const vax = useRecords<VaccinationBody>(hasHerd(farm) ? farm.id : null, 'vaccinations');
  const breeding = useRecords<BreedingBody>(hasHerd(farm) ? farm.id : null, 'breedingEvents');
  const animals = useRecords<AnimalBody>(hasHerd(farm) ? farm.id : null, 'animals');
  const moves = useRecords<StockMoveBody>(hasHerd(farm) ? farm.id : null, 'stockMovements');
  const uses = useRecords<FeedUseBody>(hasHerd(farm) ? farm.id : null, 'feedUsage', localIso(addDays(now, -30)));
  const boss = manages(farm);
  const people = alive(staff.data);
  const person = (id: string | null | undefined) => people.find((s) => s.id === id);
  const away = awayOn(absences.data, now);
  const today = alive(duties.data).filter((d) => onDay(d.body, now));
  const shared = alive(contacts.data).filter((c) => boss || c.body.showWorkers !== false);
  const vet = shared.find((c) => c.body.kind === 'vet');
  const feedSup = shared.find((c) => c.body.kind === 'feedSupplier');

  const reminders: { text: string; href: string; tone: 'warn' | 'bad' | 'info' }[] = [];
  const latest = new Map<string, Date>();
  for (const v of alive(vax.data).sort((a, b) => recordDate(b, 'given').getTime() - recordDate(a, 'given').getTime())) {
    const due = parseDate(v.body.nextDue);
    if (due && !latest.has(v.body.vaccine)) latest.set(v.body.vaccine, due);
  }
  for (const [name, due] of latest) {
    if (due <= addDays(now, 14)) reminders.push({ text: `${name} vaccination ${due < startOfDay(now) ? 'overdue since' : 'due'} ${shortDate(due)}`, href: '/health/', tone: due < now ? 'bad' : 'warn' });
  }
  const ev = alive(breeding.data);
  for (const a of animals.data.filter((x) => isActiveAnimal(x) && x.body.sex === 'female')) {
    const v = breedingView(a.id, ev, now);
    if (v.due && v.due <= addDays(now, 14)) reminders.push({ text: `${animalLabel(a)} due to calve ${shortDate(v.due)}`, href: '/breeding/', tone: 'info' });
    if (v.checkDue && v.checkDue <= now) reminders.push({ text: `${animalLabel(a)}: pregnancy check due`, href: '/breeding/', tone: 'info' });
    if (v.nextHeat && v.nextHeat <= addDays(now, 1) && v.nextHeat >= startOfDay(now)) reminders.push({ text: `${animalLabel(a)} may come on heat ${sameDay(v.nextHeat, now) ? 'today' : 'tomorrow'}`, href: '/breeding/', tone: 'info' });
  }
  const live = alive(moves.data).filter((m) => m.body.feed);
  for (const feed of new Set(live.map((m) => m.body.feed!))) {
    const s = feedStock(feed, live, alive(uses.data), now);
    if (s.daysLeft != null && s.daysLeft <= 5) reminders.push({ text: `${feedName[feed] ?? 'A feed'}: about ${s.daysLeft} days left`, href: '/feeds/', tone: 'warn' });
  }

  return (
    <section className="card today-farm">
      <div className="card-head">
        <h2>On duty today</h2>
        <Link href="/roster/" className="small no-print">
          Duty roster
        </Link>
      </div>
      {today.length === 0 ? (
        <p className="small muted">{boss ? 'Nobody is on the roster yet. Set who milks, feeds and treats, with stand-ins.' : 'The roster is empty. Ask the manager.'}</p>
      ) : (
        <div className="list">
          {today.slice(0, 6).map((d) => {
            const on = whoIsOn(d.body, away);
            const p = person(on.staffId);
            return (
              <div key={d.id} className="list-row wrap">
                <span className="grow">
                  <strong>{dutyLabel(d.body)}</strong>
                  <span className="small muted">
                    {' '}
                    · {p?.body.name ?? 'Nobody'}
                    {on.covering ? ` (for ${person(d.body.staffId)?.body.name ?? 'someone'})` : ''}
                  </span>
                </span>
                {p?.body.phone && <CallButtons phone={p.body.phone} compact />}
              </div>
            );
          })}
        </div>
      )}
      {(vet || feedSup) && (
        <div className="row wrap key-calls">
          {vet && (
            <a className="btn sm outline" href={telLink(vet.body.phone)}>
              <Icon name="phone" /> Vet: {vet.body.name}
            </a>
          )}
          {feedSup && (
            <a className="btn sm outline" href={telLink(feedSup.body.phone)}>
              <Icon name="phone" /> Feed: {feedSup.body.name}
            </a>
          )}
        </div>
      )}
      {reminders.length > 0 && (
        <div className="stack" style={{ gap: 'var(--s-xs)' }}>
          <h3 className="small muted">Coming up</h3>
          {reminders.slice(0, 6).map((r) => (
            <Link key={r.text} href={r.href} className={`reminder ${r.tone}`}>
              <Icon name={r.tone === 'info' ? 'calendar' : 'alert'} /> {r.text}
            </Link>
          ))}
        </div>
      )}
    </section>
  );
}
