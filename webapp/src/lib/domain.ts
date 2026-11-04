// FarmTap data shapes as the phone writes them (lib/core/sync, lib/sectors/cattle).
// Pure functions only, so they can be tested without Firebase.

import { addDays, daysBetween, parseDate, sameDay, startOfDay, startOfMonth } from './dates.ts';

/** One stored record: base fields (ROADMAP 5.1) + the feature's body. */
export interface FarmRecord<B = object> {
  id: string;
  tenantId: string;
  collection: string;
  body: B;
  createdAt: string;
  updatedAt: string;
  createdBy: string;
  updatedBy: string;
  deviceId: string;
  version: number;
  isDeleted: boolean;
}

export type Sector = 'dairy' | 'poultry' | 'piggery' | 'goats' | 'crops' | 'fish';
export type FarmType = 'farm' | 'centre' | 'both';
export type Role = 'owner' | 'manager' | 'worker' | string;

export interface Subscription {
  trialStartedAt: Date | null;
  trialEndsAt: Date | null;
  paidUntil: Date | null;
}

export interface Farm {
  id: string;
  name: string;
  place: string;
  district: string;
  village: string;
  type: FarmType;
  sector: Sector;
  cows: number | null;
  role: Role;
  roleTitle: string;
  subscription: Subscription;
  whatsapp: string;
  sms: string;
  reviewStatus: string;
  /** Admin-set: 'active' (default) | 'suspended' */
  farmStatus: string;
  /** Plan id from admin (empty = default plan). */
  planId: string;
  /** Feature overrides: undefined means use plan/config default. */
  features: Record<string, boolean | undefined>;
}

export function farmFromDoc(id: string, t: Record<string, unknown>, member: Record<string, unknown>): Farm {
  const sub = (t.subscription as Record<string, unknown> | undefined) ?? {};
  const contacts = (t.contacts as Record<string, unknown> | undefined) ?? {};
  const review = (t.review as Record<string, unknown> | undefined) ?? {};
  return {
    id,
    name: (t.name as string) ?? '',
    place: (t.place as string) ?? '',
    district: (t.district as string) ?? '',
    village: (t.village as string) ?? '',
    type: (['farm', 'centre', 'both'].includes(t.type as string) ? t.type : 'farm') as FarmType,
    sector: ((t.sector as string) ?? 'dairy') as Sector,
    cows: typeof t.cows === 'number' ? t.cows : null,
    role: (member.role as string) ?? 'worker',
    roleTitle: (member.title as string) ?? '',
    subscription: {
      trialStartedAt: parseDate(sub.trialStartedAt),
      trialEndsAt: parseDate(sub.trialEndsAt),
      paidUntil: parseDate(sub.paidUntil),
    },
    whatsapp: (contacts.whatsapp as string) ?? '',
    sms: (contacts.sms as string) ?? '',
    reviewStatus: (review.status as string) ?? '',
    farmStatus: (t.status as string) ?? 'active',
    planId: (t.planId as string) ?? '',
    features: (t.features as Record<string, boolean | undefined>) ?? {},
  };
}

export const isCentre = (f: Farm) => f.type === 'centre' || f.type === 'both';
export const hasHerd = (f: Farm) => f.type === 'farm' || f.type === 'both';
export const manages = (f: Farm) => f.role === 'owner' || f.role === 'manager';

export type PlanState =
  | { kind: 'trial'; daysLeft: number; endsAt: Date }
  | { kind: 'paid'; until: Date; daysLeft: number }
  | { kind: 'grace'; until: Date; daysLeft: number }
  | { kind: 'readOnly'; since: Date | null };

/**
 * Same rule as the phone and firestore.rules (binding rule 3): writes while
 * the trial runs, or until paid-until + 7 days' grace; read-only after.
 */
export function planState(s: Subscription, now: Date): PlanState {
  if (s.paidUntil) {
    const left = daysBetween(now, s.paidUntil);
    if (now < s.paidUntil) return { kind: 'paid', until: s.paidUntil, daysLeft: left };
    const graceEnd = addDays(s.paidUntil, 7);
    if (now < graceEnd) return { kind: 'grace', until: graceEnd, daysLeft: daysBetween(now, graceEnd) };
  }
  if (s.trialEndsAt && now < s.trialEndsAt) {
    return { kind: 'trial', daysLeft: Math.max(0, daysBetween(now, s.trialEndsAt)), endsAt: s.trialEndsAt };
  }
  const since = s.paidUntil ? addDays(s.paidUntil, 7) : s.trialEndsAt;
  return { kind: 'readOnly', since };
}

export const canWrite = (s: Subscription, now: Date) => planState(s, now).kind !== 'readOnly';

// ---------------------------------------------------------------- Records

export const alive = <B>(rs: FarmRecord<B>[]) => rs.filter((r) => !r.isDeleted);
export const recordDate = (r: FarmRecord<object>, field?: string): Date =>
  (field ? parseDate((r.body as Record<string, unknown>)[field]) : null) ?? parseDate(r.createdAt) ?? new Date(0);

export interface AnimalBody {
  tagNumber: string;
  name: string;
  sex: 'female' | 'male';
  breed: string;
  dateOfBirth: string;
  status: 'active' | 'sold' | 'deceased' | 'transferred';
  govIdTag?: string | null;
  dairyStatus: 'milking' | 'dry' | 'treated' | 'pregnant' | 'heifer' | 'calf' | 'bull';
  avatarIndex?: number;
  group?: string | null;
  motherTag?: string | null;
  photo?: string | null;
}

export interface MilkBody {
  animalId: string | null;
  session: 'morning' | 'evening';
  litres: number;
  notForSale?: boolean;
  recordedBy?: string;
}

export interface TreatmentBody {
  animalId: string;
  animalName?: string;
  tag?: string;
  condition: string;
  drugId: string;
  withdrawalDays: number;
  given: string;
  dose?: string | null;
  route?: string;
  givenBy?: string | null;
  courseDays?: number;
  animalDry?: boolean;
  avatarIndex?: number;
  note?: string | null;
  photo?: string | null;
}

export interface ExpenseBody {
  category: string;
  amount: number;
  at: string;
  note?: string | null;
  sourceId?: string | null;
}

export interface StaffBody {
  name: string;
  role: string;
  title?: string | null;
  phone?: string | null;
  monthlyWage?: number | null;
  cardNumber?: string | null;
  since?: string | null;
  active?: boolean;
  photoUrl?: string | null;
  department?: string | null;
  nationalId?: string | null;
  village?: string | null;
  emergencyName?: string | null;
  emergencyPhone?: string | null;
  login?: string;
  pinHash?: string;
}

export interface FarmerBody {
  name: string;
  phone: string;
  village?: string;
  card?: string | null;
  photo?: string | null;
  photoUrl?: string | null;
  since?: string | null;
  smsReceipts?: boolean;
}

export interface DeliveryBody {
  farmerId: string;
  litres: number;
  session: 'morning' | 'evening';
  test: 'passed' | 'failed' | 'notDone';
  rejectReason?: string | null;
  at: string;
  note?: string | null;
}

/** Clock-in and clock-out events (phone: event 'in' | 'out', at; 'out' points at its 'in'). */
export interface AttendanceBody {
  staffId: string;
  event?: 'in' | 'out';
  inId?: string;
  method?: string;
  inAt?: string;
  outAt?: string | null;
  at?: string;
}

/** Clock-ins only: an 'out' event is not a second arrival. */
export const isClockIn = (a: FarmRecord<AttendanceBody>) => !a.isDeleted && a.body.event !== 'out';

export interface WageBody {
  staffId: string;
  kind: string;
  amount: number;
  at: string;
}

/**
 * A task as the phone saves it (sectors/cattle/workers, FarmTask): who does
 * it (staffId), the day it is due, a worded time ("before 10:00") and when
 * it was done. `note` and `priority` are web extras the phone keeps.
 * Older web tasks used assignedTo/dueDate/status; [taskView] reads both.
 */
export interface TaskBody {
  title: string;
  staffId: string;
  due: string;
  when: string;
  doneAt: string | null;
  note?: string | null;
  priority?: 'normal' | 'high' | null;
  // Older web shape (read only).
  assignedTo?: string;
  dueDate?: string;
  status?: 'open' | 'done' | 'cancelled';
  description?: string;
  completedAt?: string | null;
}

export interface TaskView {
  title: string;
  staffId: string;
  due: Date | null;
  when: string;
  doneAt: Date | null;
  done: boolean;
  note: string;
  priority: 'normal' | 'high';
}

export function taskView(b: TaskBody): TaskView {
  const doneAt = parseDate(b.doneAt ?? b.completedAt ?? null);
  return {
    title: b.title ?? '',
    staffId: b.staffId ?? b.assignedTo ?? '',
    due: parseDate(b.due ?? b.dueDate ?? null),
    when: b.when ?? '',
    doneAt,
    done: doneAt != null || b.status === 'done' || b.status === 'cancelled',
    note: b.note ?? b.description ?? '',
    priority: b.priority === 'high' ? 'high' : 'normal',
  };
}

/** Body for a task in the phone's shape, keeping fields it does not know. */
export function taskBody(v: { title: string; staffId: string; due: Date; when: string; doneAt: Date | null; note?: string; priority?: 'normal' | 'high' }, iso: (d: Date) => string) {
  return {
    title: v.title,
    staffId: v.staffId,
    due: iso(v.due),
    when: v.when,
    doneAt: v.doneAt ? iso(v.doneAt) : null,
    note: v.note?.trim() || null,
    priority: v.priority ?? 'normal',
  };
}

export interface MilkSaleBody {
  buyer: string;
  litres: number;
  pricePerLitre: number;
  paid?: boolean;
  kind?: 'centre' | 'shop' | 'neighbours' | string;
}

/** A later "paid" or "not paid" mark on a milk sale (id `pay-<saleId>`). */
export interface MilkSalePaymentBody {
  saleId: string;
  paid: boolean;
}

export const buyerKinds = ['centre', 'shop', 'neighbours'] as const;

/** Paid, with a later mark from milkSalePayments winning (local_milk_repository). */
export function salePaid(sale: FarmRecord<MilkSaleBody>, marks: FarmRecord<MilkSalePaymentBody>[]): boolean {
  const m = marks.find((x) => !x.isDeleted && x.body.saleId === sale.id);
  return m ? m.body.paid !== false : sale.body.paid === true;
}

export const saleValue = (s: MilkSaleBody) => (Number(s.litres) || 0) * (Number(s.pricePerLitre) || 0);

/** Farm income that is not a milk sale (core/money IncomeSource). */
export interface IncomeBody {
  source: 'animalSale' | 'manure' | 'calfSale' | 'hire' | 'other' | string;
  amount: number;
  at: string;
  note?: string | null;
  sourceId?: string | null;
}

export const incomeSources = ['animalSale', 'calfSale', 'manure', 'hire', 'other'] as const;

/** One card in the farm's register, id = 4-digit number (core/people LocalCardRegistry). */
export interface NfcCardBody {
  personId: string;
  personType: 'staff' | 'farmer';
  personName: string;
  status: 'active' | 'returned' | 'lost';
  chipId?: string | null;
  issuedAt?: string | null;
  endedAt?: string | null;
}

/** Staff roles on the phone (core/people StaffRole). */
export const staffRoles = ['worker', 'herdsman', 'clerk', 'vet', 'manager'] as const;

// ---------------------------------------------------------------- Health

/** Conditions and routes the phone knows (health_models.dart). */
export const conditions = ['mastitis', 'lame', 'fever', 'wound', 'eye', 'diarrhoea', 'other'] as const;
export const drugRoutes = ['injection', 'oral', 'spray', 'pourOn'] as const;

export interface Drug {
  id: string;
  name: string;
  withdrawalDays: number;
}

/** The phone's starter drugs (LocalTreatmentRepository.starterDrugs). Same ids, so records match. */
export const starterDrugs: Drug[] = [
  { id: 'drug-penstrep', name: 'Penicillin-Streptomycin', withdrawalDays: 4 },
  { id: 'drug-oxy', name: 'Oxytetracycline 20%', withdrawalDays: 8 },
  { id: 'drug-albendazole', name: 'Albendazole dewormer', withdrawalDays: 3 },
  { id: 'drug-acaricide', name: 'Acaricide (dip)', withdrawalDays: 0 },
];

export interface StockItemBody {
  kind: string;
  name?: string;
  withdrawalDays?: number;
  stock?: number;
  unit?: string;
}

/** The farm's drugs: the ones saved in stock, then the starter ones not replaced. */
export function drugsFrom(stock: FarmRecord<StockItemBody>[]): Drug[] {
  const saved = stock
    .filter((r) => !r.isDeleted && r.body.kind === 'drug')
    .map((r) => ({ id: r.id, name: r.body.name ?? '', withdrawalDays: Number(r.body.withdrawalDays) || 0 }));
  const ids = new Set(saved.map((d) => d.id));
  return [...saved, ...starterDrugs.filter((d) => !ids.has(d.id))];
}

/** Next free tag in the phone's form, FT-001 (LocalHerdRepository.nextTag). */
export function nextTag(animals: FarmRecord<AnimalBody>[]): string {
  let max = 0;
  for (const a of animals) {
    const n = Number.parseInt((a.body.tagNumber ?? '').replace(/\D/g, ''), 10);
    if (Number.isFinite(n) && n > max) max = n;
  }
  return `FT-${String(max + 1).padStart(3, '0')}`;
}

/** Another living animal already has this tag (the phone refuses it too). */
export function tagTaken(animals: FarmRecord<AnimalBody>[], tag: string, exceptId?: string): boolean {
  const t = tag.trim().toLowerCase();
  return animals.some((a) => a.id !== exceptId && isActiveAnimal(a) && (a.body.tagNumber ?? '').toLowerCase() === t);
}

export const expenseCategories = ['feed', 'vet', 'breeding', 'wages', 'transport', 'fuel', 'equipment', 'other'] as const;
export const dairyStatuses = ['milking', 'dry', 'pregnant', 'heifer', 'calf', 'bull'] as const;

export const animalLabel = (a: FarmRecord<AnimalBody>) => a.body.name?.trim() || a.body.tagNumber || 'No tag';
export const isActiveAnimal = (a: FarmRecord<AnimalBody>) =>
  !a.isDeleted && (a.body.status ?? 'active') === 'active';
export const isMilker = (a: FarmRecord<AnimalBody>) =>
  isActiveAnimal(a) && a.body.sex === 'female' && !['dry', 'calf', 'heifer', 'bull'].includes(a.body.dairyStatus);

export function ageText(dob: string | null | undefined, now: Date): string {
  const d = parseDate(dob);
  if (!d) return '';
  const months = (now.getFullYear() - d.getFullYear()) * 12 + (now.getMonth() - d.getMonth());
  if (months < 1) return `${Math.max(0, daysBetween(d, now))} days`;
  if (months < 24) return `${months} mo`;
  return `${Math.floor(months / 12)} yrs`;
}

/** Safe-from day of a treatment: given day + withdrawal days (health_models.dart). */
export function safeFrom(t: TreatmentBody): Date | null {
  const given = parseDate(t.given);
  if (!given) return null;
  return addDays(startOfDay(given), t.withdrawalDays ?? 0);
}

export function inWithdrawal(t: TreatmentBody, now: Date): boolean {
  const s = safeFrom(t);
  return (t.withdrawalDays ?? 0) > 0 && s != null && now < s;
}

/** Litres per day for the last [days] days, oldest first. */
export function dailyLitres(milk: FarmRecord<MilkBody>[], now: Date, days: number) {
  const out: { day: Date; litres: number }[] = [];
  for (let i = days - 1; i >= 0; i--) out.push({ day: addDays(startOfDay(now), -i), litres: 0 });
  for (const r of alive(milk)) {
    const at = recordDate(r);
    const slot = out.find((o) => sameDay(o.day, at));
    if (slot) slot.litres += Number(r.body.litres) || 0;
  }
  return out;
}

export function litresBetween(milk: FarmRecord<MilkBody>[], from: Date, to: Date) {
  return alive(milk)
    .filter((r) => {
      const at = recordDate(r);
      return at >= from && at < to;
    })
    .reduce((t, r) => t + (Number(r.body.litres) || 0), 0);
}

export function sessionLitres(milk: FarmRecord<MilkBody>[], day: Date) {
  let morning = 0;
  let evening = 0;
  for (const r of alive(milk)) {
    if (!sameDay(recordDate(r), day)) continue;
    if (r.body.session === 'evening') evening += Number(r.body.litres) || 0;
    else morning += Number(r.body.litres) || 0;
  }
  return { morning, evening };
}

export function sumAmount<B extends { amount: number }>(rs: FarmRecord<B>[], from: Date, to: Date, field = 'at') {
  return alive(rs)
    .filter((r) => {
      const at = recordDate(r, field);
      return at >= from && at < to;
    })
    .reduce((t, r) => t + (Number(r.body.amount) || 0), 0);
}

export function monthRange(now: Date) {
  const from = startOfMonth(now);
  const to = new Date(from.getFullYear(), from.getMonth() + 1, 1);
  const prevFrom = new Date(from.getFullYear(), from.getMonth() - 1, 1);
  return { from, to, prevFrom };
}

/** Percent change, or null when there is nothing to compare with. */
export function change(now: number, before: number): number | null {
  if (before <= 0) return null;
  return Math.round(((now - before) / before) * 100);
}
