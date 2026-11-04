'use client';

import { useState } from 'react';
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
import { dayKey, localIso, parseDate, sameDay, startOfMonth } from '@/lib/dates';
import { addRecord, mergeBody, putRecord, upsertRecord, useRecords } from '@/lib/data';
import {
  isClockIn,
  manages,
  recordDate,
  staffRoles,
  type AttendanceBody,
  type FarmRecord,
  type FarmerBody,
  type NfcCardBody,
  type StaffBody,
  type WageBody,
} from '@/lib/domain';
import { count, date, initials, shortDate, time, ugx, words } from '@/lib/format';
import { firebase } from '@/lib/firebase';
import { hashPin, pinProblem } from '@/lib/pin';
import { useFarm, useSession } from '@/lib/session';
import { expensesOf, removeWithExpenses, saveWithExpense } from '@/lib/linked';
import { monthlyCost, payMethodName, payMethods, payTerms, payTypeUnit, payTypes, type ExpenseBody, type PayMethod, type PayType } from '@/lib/domain';

/** "UGX 15,000 a day · MTN MoMo" */
const payText = (b: StaffBody) => {
  const t = payTerms(b);
  return t.rate ? `${ugx(t.rate)} ${payTypeUnit[t.type].per}` : '';
};
import { useOpenFromUrl } from '@/lib/useOpen';

const inTime = (a: FarmRecord<AttendanceBody>) => parseDate(a.body.inAt ?? a.body.at) ?? recordDate(a);
const phoneOk = (p: string) => !p.trim() || /^\+?[\d\s-]{9,16}$/.test(p.trim());

/** Add a worker (with a starting PIN) or edit one. Same fields as the phone (I05). */
function WorkerForm({ s, cards = [], onClose }: { s?: FarmRecord<StaffBody>; cards?: FarmRecord<NfcCardBody>[]; onClose: () => void }) {
  const farm = useFarm();
  const { user, canSave, online } = useSession();
  const toast = useToast();
  const b = s?.body;
  const [f, setF] = useState({
    name: b?.name ?? '',
    role: b?.role ?? 'worker',
    title: b?.title ?? '',
    phone: b?.phone ?? '',
    payType: payTerms(b ?? ({} as StaffBody)).type as string,
    payRate: b ? (payTerms(b).rate ? String(payTerms(b).rate) : '') : '',
    payMethod: payTerms(b ?? ({} as StaffBody)).method as string,
    payAccount: b?.payAccount ?? '',
    department: b?.department ?? '',
    village: b?.village ?? '',
    nationalId: b?.nationalId ?? '',
    emergencyName: b?.emergencyName ?? '',
    emergencyPhone: b?.emergencyPhone ?? '',
    pin: '',
  });
  const { busy, error, setError, run } = useSave();
  const set = (k: keyof typeof f) => (e: { target: { value: string } }) => setF({ ...f, [k]: e.target.value });
  const roles = staffRoles.filter((r) => r !== 'manager' || farm.role === 'owner' || b?.role === 'manager');

  async function save() {
    if (!user) return;
    if (!f.name.trim()) return setError('Type the worker’s name.');
    if (!phoneOk(f.phone)) return setError('The phone number does not look right. Example: 0772 123 456.');
    if (!phoneOk(f.emergencyPhone)) return setError('The emergency phone number does not look right.');
    const rate = f.payRate.trim() ? Number(f.payRate) : null;
    if (rate != null && (!Number.isInteger(rate) || rate < 0)) return setError('Type the pay in whole shillings, e.g. 250000.');
    if ((f.payMethod === 'mtn' || f.payMethod === 'airtel') && f.payAccount.trim() && !phoneOk(f.payAccount)) return setError('The Mobile Money number does not look right.');
    if (!s) {
      const p = pinProblem(f.pin);
      if (p) return setError(`Starting PIN: ${p}`);
    }
    const fields = {
      name: f.name.trim(),
      role: f.role,
      title: f.title.trim() || null,
      phone: f.phone.trim() || null,
      // The phone reads monthlyWage; it stays the monthly pay (null for other pay types).
      monthlyWage: f.payType === 'monthly' ? rate : null,
      payType: f.payType,
      payRate: rate,
      payMethod: f.payMethod,
      payAccount: f.payAccount.trim() || null,
      department: f.department.trim() || null,
      village: f.village.trim() || null,
      nationalId: f.nationalId.trim() || null,
      emergencyName: f.emergencyName.trim() || null,
      emergencyPhone: f.emergencyPhone.trim() || null,
    };
    const { db } = firebase();
    const ok = await run(async () => {
      if (s) {
        await putRecord(db, farm.id, s, user.uid, mergeBody(s, fields));
        // The card register shows the holder's name too (phone: renameHolder).
        const card = activeCardOf(cards, s.id);
        if (card && card.body.personName !== fields.name) await upsertRecord(db, farm.id, 'nfcCards', card.id, user.uid, { ...card.body, personName: fields.name });
        return;
      }
      const pinHash = await hashPin(f.pin);
      const id = crypto.randomUUID();
      // Same as the phone's addStaff: the staff record carries the hash, and
      // staffPins says the worker must choose their own PIN at first use.
      await addRecord(db, farm.id, 'staff', user.uid, {
        ...fields,
        cardNumber: null,
        since: localIso(new Date(new Date().setHours(0, 0, 0, 0))),
        photo: null,
        photoUrl: null,
        login: 'none',
        active: true,
        pinHash,
      }, id);
      await addRecord(db, farm.id, 'staffPins', user.uid, { pinHash, mustChange: true }, id);
    });
    if (ok) {
      toast(s ? `${fields.name} saved` : `${fields.name} added. Give them their card on the farm phone or below.`);
      onClose();
    }
  }

  return (
    <FormDialog
      title={s ? `Edit ${s.body.name}` : 'Add worker'}
      subtitle={s ? undefined : 'The worker unlocks the farm phone with their card and this PIN, then chooses their own.'}
      onClose={onClose}
      onSubmit={save}
      busy={busy}
      error={error}
      canSave={canSave}
      online={online}
      submit={s ? 'Save changes' : 'Add worker'}
      size="lg"
    >
      <Fit kind="fields" cols={[1, 2, 2, 2]}>
        <Field label="Full name">
          <input className="input" required value={f.name} onChange={set('name')} autoFocus maxLength={80} />
        </Field>
        <Field label="Role">
          <select className="input" value={f.role} onChange={set('role')}>
            {roles.map((r) => (
              <option key={r} value={r}>
                {words(r)}
              </option>
            ))}
          </select>
        </Field>
        <Field label="Job title (optional)">
          <input className="input" value={f.title} onChange={set('title')} placeholder="e.g. Milker" />
        </Field>
        <Field label="Phone (optional)">
          <input className="input" type="tel" value={f.phone} onChange={set('phone')} placeholder="0772 123 456" />
        </Field>
        <Field label="Paid">
          <select className="input" value={f.payType} onChange={set('payType')}>
            {payTypes.map((t) => (
              <option key={t} value={t}>
                {t === 'contract' ? 'By contract (fixed amount)' : `By the ${payTypeUnit[t].unit}`}
              </option>
            ))}
          </select>
        </Field>
        <Field label={f.payType === 'contract' ? 'Contract amount, UGX (optional)' : `Pay ${payTypeUnit[f.payType as PayType].per}, UGX (optional)`}>
          <input className="input" type="number" min={0} step={500} inputMode="numeric" value={f.payRate} onChange={set('payRate')} />
        </Field>
        <Field label="Pay them by">
          <select className="input" value={f.payMethod} onChange={set('payMethod')}>
            {payMethods.map((m) => (
              <option key={m} value={m}>
                {payMethodName[m]}
              </option>
            ))}
          </select>
        </Field>
        {f.payMethod !== 'cash' && (
          <Field label={f.payMethod === 'bank' ? 'Bank and account number' : 'Mobile Money number'}>
            <input className="input" value={f.payAccount} onChange={set('payAccount')} placeholder={f.payMethod === 'bank' ? 'e.g. Stanbic 9030012345678' : '0772 123 456'} />
          </Field>
        )}
        <Field label="Department (optional)">
          <input className="input" value={f.department} onChange={set('department')} placeholder="e.g. Milking" />
        </Field>
        <Field label="Village (optional)">
          <input className="input" value={f.village} onChange={set('village')} />
        </Field>
        <Field label="National ID (optional)">
          <input className="input" value={f.nationalId} onChange={set('nationalId')} />
        </Field>
        <Field label="Emergency contact (optional)">
          <input className="input" value={f.emergencyName} onChange={set('emergencyName')} />
        </Field>
        <Field label="Emergency phone (optional)">
          <input className="input" type="tel" value={f.emergencyPhone} onChange={set('emergencyPhone')} />
        </Field>
      </Fit>
      {!s && (
        <Field label="Starting PIN (4 numbers)" hint="Tell the worker this PIN. The phone asks them to choose their own the first time.">
          <input
            className="input"
            style={{ maxWidth: 'var(--z-stat-min)' }}
            inputMode="numeric"
            autoComplete="off"
            maxLength={4}
            required
            value={f.pin}
            onChange={(e) => setF({ ...f, pin: e.target.value.replace(/\D/g, '') })}
          />
        </Field>
      )}
    </FormDialog>
  );
}

function PayForm({ s, onClose }: { s: FarmRecord<StaffBody>; onClose: () => void }) {
  const farm = useFarm();
  const { user, canSave, online } = useSession();
  const toast = useToast();
  const terms = payTerms(s.body);
  const perUnit = terms.type !== 'contract' && terms.type !== 'monthly' && terms.type !== 'yearly';
  const [kind, setKind] = useState<'wage' | 'advance'>('wage');
  const [units, setUnits] = useState(perUnit ? '' : '1');
  const [amount, setAmount] = useState(!perUnit && terms.rate ? String(terms.rate) : '');
  const [method, setMethod] = useState<PayMethod>(terms.method);
  const [reference, setReference] = useState('');
  const { busy, error, setError, run } = useSave();
  const unitWord = payTypeUnit[terms.type];

  async function save() {
    if (!user) return;
    const n = Number(amount);
    if (!Number.isInteger(n) || n <= 0) return setError('Type the amount in whole shillings, more than 0.');
    const u = Number(units) || null;
    const { db } = firebase();
    const at = localIso(new Date());
    // Like the phone's pay(): a wages record plus a wage expense in Money, saved together.
    const ok = await run(() =>
      saveWithExpense(
        db,
        farm.id,
        user.uid,
        {
          collection: 'wages',
          body: { staffId: s.id, kind, amount: n, at, payMethod: method, units: kind === 'wage' ? u : null, payType: terms.type, reference: reference.trim() || null, note: null },
        },
        'wage',
        { category: 'wages', amount: n, at, note: `${s.body.name} · ${kind === 'wage' ? (u && perUnit ? `${u} ${u === 1 ? unitWord.unit : unitWord.units}` : 'wage') : 'advance'}`, payMethod: method },
      ),
    );
    if (ok) {
      toast(`${ugx(n)} ${kind === 'wage' ? 'pay' : 'advance'} to ${s.body.name}, saved in Money`);
      onClose();
    }
  }

  return (
    <FormDialog
      title={`Pay ${s.body.name}`}
      subtitle={terms.rate ? `${ugx(terms.rate)} ${unitWord.per}. Saved as worker pay in Money too.` : 'Saved as worker pay in Money too.'}
      onClose={onClose}
      onSubmit={save}
      busy={busy}
      error={error}
      canSave={canSave}
      online={online}
      submit={Number(amount) > 0 ? `Pay ${ugx(Number(amount))}` : 'Pay'}
    >
      <Seg label="Kind" value={kind} onChange={setKind} items={[['wage', 'Pay'], ['advance', 'Advance']]} />
      <Fit kind="fields" cols={[1, 2, 2, 2]}>
        {kind === 'wage' && perUnit && (
          <Field label={`How many ${unitWord.units}`}>
            <input
              className="input"
              type="number"
              min={0.5}
              step={0.5}
              inputMode="decimal"
              value={units}
              onChange={(e) => {
                setUnits(e.target.value);
                if (terms.rate && Number(e.target.value) > 0) setAmount(String(Math.round(terms.rate * Number(e.target.value))));
              }}
              autoFocus
            />
          </Field>
        )}
        <Field label="Amount (UGX)">
          <input className="input" type="number" min={1} step={1} inputMode="numeric" required value={amount} onChange={(e) => setAmount(e.target.value)} autoFocus={!perUnit} />
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
        {method !== 'cash' && (
          <Field label="Transaction ID (optional)" hint={terms.account ? `Their account: ${terms.account}` : undefined}>
            <input className="input" value={reference} onChange={(e) => setReference(e.target.value)} />
          </Field>
        )}
      </Fit>
    </FormDialog>
  );
}

function PinReset({ s, onClose }: { s: FarmRecord<StaffBody>; onClose: () => void }) {
  const farm = useFarm();
  const { user, canSave, online } = useSession();
  const toast = useToast();
  const [pin, setPin] = useState('');
  const { busy, error, setError, run } = useSave();
  async function save() {
    if (!user) return;
    const p = pinProblem(pin);
    if (p) return setError(p);
    const ok = await run(async () => upsertRecord(firebase().db, farm.id, 'staffPins', s.id, user.uid, { pinHash: await hashPin(pin), mustChange: true }));
    if (ok) {
      toast(`New starting PIN set for ${s.body.name}`);
      onClose();
    }
  }
  return (
    <FormDialog title={`New PIN for ${s.body.name}`} subtitle="For a forgotten PIN. The worker chooses their own again at next unlock." onClose={onClose} onSubmit={save} busy={busy} error={error} canSave={canSave} online={online} submit="Set PIN">
      <Field label="Temporary PIN (4 numbers)">
        <input className="input" inputMode="numeric" autoComplete="off" maxLength={4} required value={pin} onChange={(e) => setPin(e.target.value.replace(/\D/g, ''))} autoFocus />
      </Field>
    </FormDialog>
  );
}

function CardForm({ s, cards, taken, onClose }: { s: FarmRecord<StaffBody>; cards: FarmRecord<NfcCardBody>[]; taken: Set<string>; onClose: () => void }) {
  const farm = useFarm();
  const { user, canSave, online } = useSession();
  const toast = useToast();
  const current = activeCardOf(cards, s.id);
  const [typed, setTyped] = useState(nextFreeCard(taken));
  const [why, setWhy] = useState<'returned' | 'lost'>('returned');
  const { busy, error, setError, run } = useSave();
  const n = cardNumber(typed);

  async function save() {
    if (!user) return;
    const { db } = firebase();
    if (current) {
      const ok = await run(async () => {
        await endCard(upsertRecord, db, farm.id, user.uid, current, why);
        await putRecord(db, farm.id, s, user.uid, mergeBody(s, { cardNumber: null }));
      });
      if (ok) {
        toast(`Card ${current.id} ${why === 'lost' ? 'blocked' : 'taken back'}`);
        onClose();
      }
      return;
    }
    if (!n) return setError('Type the 4-digit number printed on the card.');
    const p = cardProblem(cards, n, s.id);
    if (p) return setError(p);
    const ok = await run(async () => {
      await giveCard(upsertRecord, db, farm.id, user.uid, cards, n, { id: s.id, kind: 'staff', name: s.body.name });
      await putRecord(db, farm.id, s, user.uid, mergeBody(s, { cardNumber: n }));
    });
    if (ok) {
      toast(`Card ${n} given to ${s.body.name}`);
      onClose();
    }
  }

  return (
    <FormDialog
      title={current ? `Card ${current.id}` : `Give ${s.body.name} a card`}
      subtitle={current ? 'Take the card back before it goes to someone else.' : 'Type the number printed on the card. The chip is linked the first time it is tapped on the farm phone.'}
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
        <Field label="Card number" error={n && cardProblem(cards, n, s.id)} hint={`Next free number: ${nextFreeCard(taken)}`}>
          <input className="input" style={{ maxWidth: 'var(--z-stat-min)' }} inputMode="numeric" maxLength={7} required value={typed} onChange={(e) => setTyped(e.target.value)} autoFocus />
        </Field>
      )}
    </FormDialog>
  );
}

function Profile({
  s,
  card,
  attendance,
  wages,
  boss,
  onEdit,
  onPay,
  onPin,
  onCard,
  onClose,
  onUndo,
}: {
  s: FarmRecord<StaffBody>;
  card: string | null;
  attendance: FarmRecord<AttendanceBody>[];
  wages: FarmRecord<WageBody>[];
  boss: boolean;
  onEdit: () => void;
  onPay: () => void;
  onPin: () => void;
  onCard: () => void;
  onClose: () => void;
  onUndo?: (w: FarmRecord<WageBody>) => void;
}) {
  const { canSave } = useSession();
  const ins = attendance.filter((a) => isClockIn(a) && a.body.staffId === s.id).sort((a, b) => inTime(b).getTime() - inTime(a).getTime());
  const outs = attendance.filter((a) => a.body.event === 'out' && a.body.staffId === s.id);
  const days = new Set(ins.map((a) => dayKey(inTime(a))));
  const paid = wages.filter((w) => w.body.staffId === s.id).sort((a, b) => recordDate(b, 'at').getTime() - recordDate(a, 'at').getTime());
  const paidTotal = paid.reduce((t, w) => t + (Number(w.body.amount) || 0), 0);
  const wage = monthlyCost(payTerms(s.body));
  return (
    <Dialog title={s.body.name} subtitle={s.body.title || words(s.body.role)} onClose={onClose} size="lg">
      <div className="row wrap">
        <span className="avatar lg">{s.body.photoUrl ? <img src={s.body.photoUrl} alt="" /> : initials(s.body.name)}</span>
        <div className="stack grow" style={{ gap: 'var(--s-xxs)' }}>
          <span className="small muted">
            {s.body.phone || 'No phone'}
            {s.body.department ? ` · ${s.body.department}` : ''}
            {s.body.village ? ` · ${s.body.village}` : ''}
          </span>
          <div className="chips">
            {card ? <span className="chip brand">Card {card}</span> : <span className="chip warn">No card</span>}
            {s.body.since && <span className="chip">Since {date(parseDate(s.body.since))}</span>}
            {s.body.login === 'active' && <span className="chip ok">Phone sign-in on</span>}
          </div>
        </div>
      </div>
      {boss && canSave && (
        <div className="btn-row">
          <button className="btn sm" onClick={onEdit}>
            <Icon name="edit" /> Edit
          </button>
          <button className="btn sm outline" onClick={onPay}>
            <Icon name="money" /> Pay
          </button>
          <button className="btn sm outline" onClick={onCard}>
            <Icon name="card" /> {card ? 'Card' : 'Give card'}
          </button>
          <button className="btn sm outline" onClick={onPin}>
            <Icon name="key" /> New PIN
          </button>
        </div>
      )}
      <Fit kind="stats" cols={[2, 3, 3, 3]}>
        <div className="card flat stat">
          <span className="label">Days in, this month</span>
          <span className="value">{days.size}</span>
        </div>
        {boss && (
          <div className="card flat stat">
            <span className="label">Paid this month</span>
            <span className="value money">{ugx(paidTotal)}</span>
            <span className="hint">{wage ? (paidTotal >= wage ? 'Fully paid' : `About ${ugx(wage - paidTotal)} still to pay`) : 'No pay set'}</span>
          </div>
        )}
        {boss && (
          <div className="card flat stat">
            <span className="label">Pay</span>
            <span className="value money">{payText(s.body) || '–'}</span>
            <span className="hint">
              {payMethodName[payTerms(s.body).method]}
              {s.body.payAccount ? ` · ${s.body.payAccount}` : ''}
            </span>
          </div>
        )}
      </Fit>
      <Fit kind="cards" cols={[1, 2, 2, 2]}>
        <div className="stack">
          <h3>Clock-ins this month</h3>
          {ins.length === 0 ? (
            <p className="small muted">None yet this month.</p>
          ) : (
            <div className="list">
              {ins.slice(0, 8).map((a) => {
                const out = outs.find((o) => o.body.inId === a.id);
                return (
                  <div key={a.id} className="list-row small">
                    <span className="grow">{shortDate(inTime(a))}</span>
                    <span className="num">
                      {time(inTime(a))}
                      {out ? ` – ${time(parseDate(out.body.at) ?? recordDate(out))}` : ''}
                    </span>
                  </div>
                );
              })}
            </div>
          )}
        </div>
        {boss && (
          <div className="stack">
            <h3>Payments this month</h3>
            {paid.length === 0 ? (
              <p className="small muted">No payments yet this month.</p>
            ) : (
              <div className="list">
                {paid.map((w) => (
                  <div key={w.id} className="list-row small">
                    <span className="grow">
                      {shortDate(recordDate(w, 'at'))} · {w.body.kind === 'advance' ? 'Advance' : 'Pay'}
                      {w.body.units ? ` · ${w.body.units} ${w.body.payType ? payTypeUnit[w.body.payType as PayType]?.units ?? '' : ''}` : ''}
                      {w.body.payMethod ? ` · ${payMethodName[w.body.payMethod as PayMethod] ?? w.body.payMethod}` : ''}
                    </span>
                    <span className="num">{ugx(w.body.amount)}</span>
                    {canSave && onUndo && (
                      <button className="icon-btn" aria-label="Remove this payment" title="Remove a mistake (removes it from Money too)" onClick={() => onUndo(w)}>
                        <Icon name="close" />
                      </button>
                    )}
                  </div>
                ))}
              </div>
            )}
          </div>
        )}
      </Fit>
    </Dialog>
  );
}

type Modal = 'edit' | 'pay' | 'pin' | 'card' | null;

/** Workers, attendance and payroll (Section I). */
export default function Workers() {
  const farm = useFarm();
  const { canSave } = useSession();
  const now = new Date();
  const monthFrom = startOfMonth(now);
  const boss = manages(farm);
  const staff = useRecords<StaffBody>(farm.id, 'staff');
  const attendance = useRecords<AttendanceBody>(farm.id, 'attendance', localIso(monthFrom));
  const wages = useRecords<WageBody>(boss ? farm.id : null, 'wages', localIso(monthFrom));
  const expenses = useRecords<ExpenseBody>(boss ? farm.id : null, 'expenses', localIso(monthFrom));
  const [undo, setUndo] = useState<FarmRecord<WageBody> | null>(null);
  const undoSave = useSave();
  const toast = useToast();
  const { user } = useSession();
  const cards = useRecords<NfcCardBody>(farm.id, 'nfcCards');
  const farmers = useRecords<FarmerBody>(farm.id, 'farmers');
  const [q, setQ] = useState('');
  const [adding, setAdding] = useOpenFromUrl();
  const [openId, setOpenId] = useState<string | null>(null);
  const [modal, setModal] = useState<Modal>(null);

  const active = staff.data.filter((s) => s.body.active !== false).sort((a, b) => a.body.name.localeCompare(b.body.name));
  const open = staff.data.find((s) => s.id === openId) ?? null;
  const cardOf = (s: FarmRecord<StaffBody>) => activeCardOf(cards.data, s.id)?.id ?? s.body.cardNumber ?? null;
  const shown = active.filter((s) => !q || `${s.body.name} ${s.body.role} ${s.body.title ?? ''} ${s.body.phone ?? ''} ${cardOf(s) ?? ''}`.toLowerCase().includes(q.toLowerCase()));
  const ins = attendance.data.filter(isClockIn);
  const todayIn = (id: string) => ins.find((a) => a.body.staffId === id && sameDay(inTime(a), now));
  const daysIn = (id: string) => new Set(ins.filter((a) => a.body.staffId === id).map((a) => dayKey(inTime(a)))).size;
  const paidTo = (id: string) => wages.data.filter((w) => w.body.staffId === id).reduce((t, w) => t + (Number(w.body.amount) || 0), 0);
  const payroll = active.reduce((t, s) => t + (monthlyCost(payTerms(s.body))), 0);
  const paidAll = active.reduce((t, s) => t + paidTo(s.id), 0);
  const presentToday = active.filter((s) => todayIn(s.id)).length;
  const taken = takenNumbers(cards.data, [...staff.data.map((s) => s.body.cardNumber), ...farmers.data.map((f) => f.body.card)]);

  const csv = () =>
    downloadCsv(
      `${farm.name}-workers-${dayKey(now)}`,
      ['Name', 'Role', 'Phone', 'Card', 'Since', 'In today', 'Days in this month', ...(boss ? ['Pay', 'Pay type', 'Paid by', 'About a month', 'Paid this month', 'Still to pay'] : [])],
      shown.map((s) => {
        const wage = monthlyCost(payTerms(s.body));
        const t = todayIn(s.id);
        return [
          s.body.name,
          s.body.title || words(s.body.role),
          s.body.phone ?? '',
          cardOf(s) ?? '',
          s.body.since ? dayKey(parseDate(s.body.since) ?? now) : '',
          t ? time(inTime(t)) : 'No',
          daysIn(s.id),
          ...(boss ? [payTerms(s.body).rate, payTerms(s.body).type, payMethodName[payTerms(s.body).method], wage, paidTo(s.id), Math.max(0, wage - paidTo(s.id))] : []),
        ];
      }),
    );

  const closeModal = () => setModal(null);

  return (
    <>
      <PageHead title="Workers" subtitle="Workers clock in and record on the farm phone with their card and PIN.">
        <SearchBox value={q} onChange={setQ} placeholder="Search name, role, card" />
        <ExportButtons onCsv={csv} />
        {boss && (
          <button className="btn sm" onClick={() => setAdding(true)} disabled={!canSave}>
            <Icon name="plus" /> Add worker
          </button>
        )}
      </PageHead>
      <LoadError code={staff.error ?? attendance.error} />

      <Fit kind="stats" cols={[2, 3, 3, 3]}>
        <Stat loading={staff.loading} icon="workers" label="Workers" value={count(active.length)} hint={`${active.filter((s) => !cardOf(s)).length} without a card`} tone="gold" />
        <Stat
          loading={staff.loading || attendance.loading}
          icon="clock"
          label="In today"
          value={`${presentToday} / ${active.length}`}
          hint={active.length ? (active.length - presentToday ? `${active.length - presentToday} not in yet` : 'Everyone is in') : 'No workers yet'}
        />
        {boss && (
          <Stat
            loading={staff.loading || wages.loading}
            icon="money"
            label="Payroll this month"
            value={ugx(payroll)}
            hint={payroll ? `${ugx(paidAll)} paid · about ${ugx(Math.max(0, payroll - paidAll))} to pay` : 'Set each worker’s pay (by the day, month, hour...)'}
            tone="warn"
          />
        )}
      </Fit>

      <div className="table-wrap">
        <table className="table rt">
          <thead>
            <tr>
              <th>Name</th>
              <th>Role</th>
              <th>Phone</th>
              <th>Card</th>
              <th>Today</th>
              <th className="r">Days this month</th>
              {boss && <th className="r">Pay</th>}
              {boss && <th>Pay status</th>}
            </tr>
          </thead>
          <tbody>
            {shown.map((s) => {
              const t = todayIn(s.id);
              const wage = monthlyCost(payTerms(s.body));
              const paid = paidTo(s.id);
              const card = cardOf(s);
              return (
                <tr key={s.id} className="clickable" tabIndex={0} onClick={() => setOpenId(s.id)} onKeyDown={(e) => e.key === 'Enter' && setOpenId(s.id)}>
                  <td data-label="Name" className="lead">
                    <span className="row">
                      <span className="avatar">{s.body.photoUrl ? <img src={s.body.photoUrl} alt="" /> : initials(s.body.name)}</span>
                      <strong>{s.body.name}</strong>
                    </span>
                  </td>
                  <td data-label="Role">{s.body.title || words(s.body.role)}</td>
                  <td data-label="Phone">{s.body.phone || '–'}</td>
                  <td data-label="Card">{card || <span className="chip warn">No card</span>}</td>
                  <td data-label="Today">{t ? <span className="chip ok">In {time(inTime(t))}</span> : <span className="chip">Not in</span>}</td>
                  <td data-label="Days this month" className="r">
                    {daysIn(s.id)}
                  </td>
                  {boss && (
                    <td data-label="Pay" className="r">
                      {payText(s.body) || '–'}
                    </td>
                  )}
                  {boss && (
                    <td data-label="Pay status">
                      {!wage ? (
                        <span className="chip">{payTerms(s.body).type === 'contract' ? 'Contract' : 'No pay set'}</span>
                      ) : paid >= wage ? (
                        <span className="chip ok">Paid</span>
                      ) : paid > 0 ? (
                        <span className="chip warn">{ugx(wage - paid)} left</span>
                      ) : (
                        <span className="chip bad">Not paid</span>
                      )}
                    </td>
                  )}
                </tr>
              );
            })}
          </tbody>
        </table>
        {staff.loading && <SkelRows rows={5} cols={6} />}
        {!staff.loading && shown.length === 0 && (
          <Empty
            icon="workers"
            action={
              !q &&
              boss &&
              canSave && (
                <button className="btn sm" onClick={() => setAdding(true)}>
                  <Icon name="plus" /> Add worker
                </button>
              )
            }
          >
            {active.length ? 'No worker matches.' : 'No workers yet. Add them here or on the farm phone.'}
          </Empty>
        )}
      </div>

      {adding && <WorkerForm onClose={() => setAdding(false)} />}
      {open && modal === 'edit' && <WorkerForm s={open} cards={cards.data} onClose={closeModal} />}
      {open && modal === 'pay' && <PayForm s={open} onClose={closeModal} />}
      {open && modal === 'pin' && <PinReset s={open} onClose={closeModal} />}
      {open && modal === 'card' && <CardForm s={open} cards={cards.data} taken={taken} onClose={closeModal} />}
      {open && !modal && (
        <Profile
          s={open}
          card={cardOf(open)}
          attendance={attendance.data}
          wages={wages.data}
          boss={boss}
          onEdit={() => setModal('edit')}
          onPay={() => setModal('pay')}
          onPin={() => setModal('pin')}
          onCard={() => setModal('card')}
          onClose={() => setOpenId(null)}
          onUndo={setUndo}
        />
      )}
      {undo && (
        <ConfirmDialog
          title="Remove this payment?"
          confirm="Remove"
          danger
          busy={undoSave.busy}
          error={undoSave.error}
          onClose={() => setUndo(null)}
          onConfirm={async () => {
            if (!user) return;
            if (await undoSave.run(() => removeWithExpenses(firebase().db, farm.id, user.uid, undo, expensesOf(undo.id, expenses.data)))) {
              toast('Payment removed, and from Money too');
              setUndo(null);
            }
          }}
        >
          {ugx(undo.body.amount)} on {shortDate(recordDate(undo, 'at'))}. Use this only for a mistake. Its expense in Money is removed with it.
        </ConfirmDialog>
      )}
    </>
  );
}
