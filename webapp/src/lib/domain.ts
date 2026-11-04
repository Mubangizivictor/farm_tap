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
  | { kind: 'readOnly'; since: Date | null };

/**
 * Same rule as the phone and firestore.rules (decision 0023): the farm can
 * record while the free trial runs or until the paid-until date, and not a
 * minute after. There is no grace: support extends paid-until by hand when
 * a farm needs more time.
 */
export function planState(s: Subscription, now: Date): PlanState {
  if (s.paidUntil && now < s.paidUntil) return { kind: 'paid', until: s.paidUntil, daysLeft: daysBetween(now, s.paidUntil) };
  if (s.trialEndsAt && now < s.trialEndsAt) {
    return { kind: 'trial', daysLeft: Math.max(0, daysBetween(now, s.trialEndsAt)), endsAt: s.trialEndsAt };
  }
  const ends = [s.paidUntil, s.trialEndsAt].filter((d): d is Date => d != null);
  const since = ends.length ? new Date(Math.max(...ends.map((d) => d.getTime()))) : null;
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
  /** Herd total only: how many cows were milked (not every cow is milked every day). */
  cowsMilked?: number | null;
  /** Herd total only: which cows were milked, when the recorder named them. */
  cowIds?: string[] | null;
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
  /** What the treatment cost (drugs + vet), UGX. Goes to Money as a vet expense. */
  cost?: number | null;
  /** The vet or doctor (contacts id) who treated. */
  vetId?: string | null;
}

export interface ExpenseBody {
  category: string;
  amount: number;
  at: string;
  note?: string | null;
  /** The record that made this expense (feed purchase, wage, treatment...). */
  sourceId?: string | null;
  /** Which kind of record [sourceId] is, so Money can link back to it. */
  sourceType?: SpendSource | null;
  /** The supplier or vet paid (contacts id), for "spent per supplier". */
  supplierId?: string | null;
  /** How it was paid: cash, MTN, Airtel, bank. */
  payMethod?: PayMethod | null;
  photo?: string | null;
}

/** Where an automatic expense comes from (decision 0023). */
export type SpendSource = 'feedPurchase' | 'wage' | 'treatment' | 'supplierPayment' | 'drugPurchase' | 'service' | 'vaccination';

export const sourcePage: Record<SpendSource, { label: string; href: string }> = {
  feedPurchase: { label: 'Feed purchase', href: '/feeds/' },
  wage: { label: 'Worker pay', href: '/workers/' },
  treatment: { label: 'Treatment', href: '/health/' },
  vaccination: { label: 'Vaccination', href: '/health/' },
  supplierPayment: { label: 'Supplier payment', href: '/contacts/' },
  drugPurchase: { label: 'Drug purchase', href: '/health/' },
  service: { label: 'Breeding service', href: '/breeding/' },
};

/** Phone wages and feed purchases have a sourceId but no sourceType yet. */
export function sourceOf(e: ExpenseBody): SpendSource | null {
  if (e.sourceType) return e.sourceType;
  if (!e.sourceId) return null;
  if (e.category === 'wages') return 'wage';
  if (e.category === 'feed') return 'feedPurchase';
  if (e.category === 'breeding') return 'service';
  if (e.category === 'vet') return 'drugPurchase';
  return null;
}

// ---------------------------------------------------------------- Pay

export const payMethods = ['cash', 'mtn', 'airtel', 'bank'] as const;
export type PayMethod = (typeof payMethods)[number];
export const payMethodName: Record<PayMethod, string> = { cash: 'Cash', mtn: 'MTN MoMo', airtel: 'Airtel Money', bank: 'Bank' };

/** How a worker is paid (decision 0023). The phone keeps monthlyWage for monthly pay. */
export const payTypes = ['monthly', 'daily', 'hourly', 'weekly', 'yearly', 'contract'] as const;
export type PayType = (typeof payTypes)[number];
export const payTypeUnit: Record<PayType, { per: string; unit: string; units: string }> = {
  monthly: { per: 'a month', unit: 'month', units: 'months' },
  weekly: { per: 'a week', unit: 'week', units: 'weeks' },
  daily: { per: 'a day', unit: 'day', units: 'days' },
  hourly: { per: 'an hour', unit: 'hour', units: 'hours' },
  yearly: { per: 'a year', unit: 'year', units: 'years' },
  contract: { per: 'for the contract', unit: 'contract', units: 'contracts' },
};

/** A worker's pay terms, reading older records that only had monthlyWage. */
export function payTerms(b: StaffBody): { type: PayType; rate: number; method: PayMethod; account: string } {
  const type = (payTypes as readonly string[]).includes(b.payType ?? '') ? (b.payType as PayType) : 'monthly';
  const rate = Number(b.payRate ?? (type === 'monthly' ? b.monthlyWage : 0)) || 0;
  const method = (payMethods as readonly string[]).includes(b.payMethod ?? '') ? (b.payMethod as PayMethod) : 'cash';
  return { type, rate, method, account: b.payAccount ?? '' };
}

/** What a worker's pay comes to for a month, for the payroll estimate. */
export function monthlyCost(t: { type: PayType; rate: number }, workDays = 26, hoursPerDay = 8): number {
  switch (t.type) {
    case 'monthly':
      return t.rate;
    case 'weekly':
      return Math.round((t.rate * 52) / 12);
    case 'daily':
      return t.rate * workDays;
    case 'hourly':
      return t.rate * workDays * hoursPerDay;
    case 'yearly':
      return Math.round(t.rate / 12);
    case 'contract':
      return 0;
  }
}

// ---------------------------------------------------------------- Contacts

/** People and businesses the farm deals with: vets, suppliers, buyers... */
export const contactKinds = ['vet', 'feedSupplier', 'drugSupplier', 'aiTechnician', 'milkBuyer', 'transport', 'mechanic', 'extension', 'other'] as const;
export type ContactKind = (typeof contactKinds)[number];
export const contactKindName: Record<ContactKind, string> = {
  vet: 'Vet or animal doctor',
  feedSupplier: 'Feed supplier',
  drugSupplier: 'Drugs and agro-vet shop',
  aiTechnician: 'AI technician',
  milkBuyer: 'Milk buyer',
  transport: 'Transport',
  mechanic: 'Mechanic or repairs',
  extension: 'Extension officer',
  other: 'Other',
};
export const isSupplier = (k: string) => ['feedSupplier', 'drugSupplier', 'aiTechnician', 'vet', 'transport', 'mechanic', 'other'].includes(k);

export interface ContactBody {
  name: string;
  kind: ContactKind | string;
  phone: string;
  phone2?: string | null;
  /** Clinic, shop or company. */
  org?: string | null;
  place?: string | null;
  note?: string | null;
  /** Workers see this contact (on duty boards and their phone). */
  showWorkers?: boolean;
}

export const telLink = (p: string) => `tel:${p.replace(/[^\d+]/g, '')}`;
export const waLink = (p: string) => {
  let d = p.replace(/\D/g, '');
  if (d.startsWith('0')) d = `256${d.slice(1)}`;
  return `https://wa.me/${d}`;
};

// ---------------------------------------------------------------- Duty roster

/** Farm jobs someone is on duty for. 'manager' = who is in charge. */
export const dutyActivities = ['milking', 'feeding', 'health', 'cleaning', 'grazing', 'security', 'collection', 'manager'] as const;
export const dutyName: Record<string, string> = {
  milking: 'Milking',
  feeding: 'Feeding',
  health: 'Animal health',
  cleaning: 'Cleaning the shed',
  grazing: 'Grazing and water',
  security: 'Night watch',
  collection: 'Taking milk to the centre',
  manager: 'In charge of the farm',
};
export const weekDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'] as const;

export interface DutyBody {
  activity: string;
  /** Free text when the activity is not in the list. */
  label?: string | null;
  staffId: string;
  /** Who covers when [staffId] is away. */
  standInId?: string | null;
  /** 0 = Sunday ... 6 = Saturday. Empty = every day. */
  days: number[];
  shift: 'morning' | 'afternoon' | 'evening' | 'night' | 'allDay';
  note?: string | null;
  /** Contact to call for this job (the vet for health, the supplier for feeding). */
  contactId?: string | null;
}

export const shiftName: Record<DutyBody['shift'], string> = {
  morning: 'Morning',
  afternoon: 'Afternoon',
  evening: 'Evening',
  night: 'Night',
  allDay: 'All day',
};

export const dutyLabel = (d: DutyBody) => (d.activity === 'other' ? d.label?.trim() || 'Other' : dutyName[d.activity] ?? words2(d.activity));
const words2 = (k: string) => k.replace(/([A-Z])/g, ' $1').replace(/^./, (c) => c.toUpperCase());

/** Someone away (leave, sick, off) for whole days, both ends included. */
export interface AbsenceBody {
  staffId: string;
  from: string;
  to: string;
  reason?: string | null;
}

/** Staff ids away on [day]. */
export function awayOn(absences: FarmRecord<AbsenceBody>[], day: Date): Set<string> {
  const k = startOfDay(day).getTime();
  const out = new Set<string>();
  for (const a of absences) {
    if (a.isDeleted) continue;
    const from = parseDate(a.body.from);
    const to = parseDate(a.body.to) ?? from;
    if (from && to && startOfDay(from).getTime() <= k && k <= startOfDay(to).getTime()) out.add(a.body.staffId);
  }
  return out;
}

export const onDay = (d: DutyBody, day: Date) => !d.days?.length || d.days.includes(day.getDay());

/**
 * Who does a duty on [day]: the person on it, or their stand-in when the
 * person is away (on leave, or has not clocked in by the time it matters).
 */
export function whoIsOn(d: DutyBody, away: Set<string>): { staffId: string | null; covering: boolean } {
  if (!away.has(d.staffId)) return { staffId: d.staffId, covering: false };
  if (d.standInId && !away.has(d.standInId)) return { staffId: d.standInId, covering: true };
  return { staffId: null, covering: false };
}

// ---------------------------------------------------------------- Feeds

/** The phone's feeds (feeding_models.dart FeedKind) and their units. */
export const phoneFeeds = ['dairyMeal', 'maizeBran', 'mineralLick', 'silage', 'napierGrass', 'hay', 'cottonSeedCake', 'brewersWaste'] as const;
export const feedName: Record<string, string> = {
  dairyMeal: 'Dairy meal',
  maizeBran: 'Maize bran',
  mineralLick: 'Mineral lick',
  silage: 'Silage',
  napierGrass: 'Napier grass',
  hay: 'Hay',
  cottonSeedCake: 'Cotton seed cake',
  brewersWaste: "Brewers' waste",
};
export const feedUnit = (feed: string, custom?: { unit?: string }) =>
  custom?.unit || (feed === 'mineralLick' ? 'blocks' : ['silage', 'napierGrass', 'brewersWaste'].includes(feed) ? 'kg' : 'bags');
export const feedGroups = ['milkingCows', 'dryCows', 'heifers', 'calves'] as const;

/** A feed the farm added itself (feedTypes). Its id is used as the feed key. */
export interface FeedTypeBody {
  name: string;
  unit: string;
  /** Warn when stock falls to this or below. */
  lowAt?: number | null;
}

/** stockMovements as the phone writes them: a purchase or a hand count. */
export interface StockMoveBody {
  kind: 'purchase' | 'count' | string;
  feed?: string;
  amount: number;
  pricePerUnit?: number;
  supplier?: string | null;
  supplierId?: string | null;
  payMethod?: PayMethod | null;
  at: string;
}

export interface FeedUseBody {
  feed: string;
  group: string;
  amount: number;
  at: string;
  /** Staff id of who fed. */
  fedBy?: string | null;
}

/** Stock of one feed: the last count, plus purchases after it, minus feedings after it. */
export function feedStock(feed: string, moves: FarmRecord<StockMoveBody>[], uses: FarmRecord<FeedUseBody>[], now: Date) {
  const mine = alive(moves).filter((m) => m.body.feed === feed);
  const counts = mine.filter((m) => m.body.kind === 'count').sort((a, b) => recordDate(b, 'at').getTime() - recordDate(a, 'at').getTime());
  const last = counts[0];
  const from = last ? recordDate(last, 'at') : new Date(0);
  let left = last ? Number(last.body.amount) || 0 : 0;
  for (const m of mine) if (m.body.kind === 'purchase' && recordDate(m, 'at') > from) left += Number(m.body.amount) || 0;
  const fed = alive(uses).filter((u) => u.body.feed === feed);
  for (const u of fed) if (recordDate(u, 'at') > from) left -= Number(u.body.amount) || 0;
  const weekAgo = addDays(now, -7);
  const perDay = fed.filter((u) => recordDate(u, 'at') >= weekAgo).reduce((t, u) => t + (Number(u.body.amount) || 0), 0) / 7;
  return { left: Math.round(left * 100) / 100, perDay: Math.round(perDay * 100) / 100, daysLeft: perDay > 0 ? Math.floor(Math.max(0, left) / perDay) : null };
}

// ---------------------------------------------------------------- Breeding

/**
 * breedingEvents exactly as the phone writes them (fake_breeding_repository):
 * a service or heat (type 'ai' | 'service', kind 'heat' | 'natural' | 'ai'),
 * a pregnancy check (type 'pregnancyCheck', serviceId, pregnant) or a
 * calving (type 'calving'). cost is whole UGX (the phone reads it as int).
 */
export interface BreedingBody {
  type: 'ai' | 'service' | 'pregnancyCheck' | 'calving';
  kind?: 'heat' | 'natural' | 'ai';
  animalId?: string;
  at: string;
  straw?: string | null;
  bull?: string | null;
  technician?: string | null;
  cost?: number | null;
  serviceId?: string;
  pregnant?: boolean;
  by?: string | null;
}

/** Cattle carry a calf about 283 days; heat comes back about every 21 days. */
export const GESTATION_DAYS = 283;
export const HEAT_CYCLE_DAYS = 21;

const isService = (b: BreedingBody) => (b.type === 'ai' || b.type === 'service') && b.kind !== 'heat';
const isHeat = (b: BreedingBody) => b.type === 'service' && b.kind === 'heat';

/** An animal's breeding state from its events: served, in calf, due, next heat. */
export function breedingView(animalId: string, events: FarmRecord<BreedingBody>[], now: Date) {
  const all = alive(events).sort((a, b) => recordDate(b, 'at').getTime() - recordDate(a, 'at').getTime());
  const mine = all.filter((e) => e.body.animalId === animalId);
  const served = mine.find((e) => isService(e.body));
  const calved = mine.find((e) => e.body.type === 'calving');
  const heat = mine.find((e) => isHeat(e.body));
  const servedAt = served ? recordDate(served, 'at') : null;
  const open = served && servedAt && (!calved || recordDate(calved, 'at') < servedAt) ? served : null;
  const check = open ? all.find((e) => e.body.type === 'pregnancyCheck' && e.body.serviceId === open.id) : undefined;
  const result = check ? check.body.pregnant === true : null;
  const pregnant = open != null && result !== false;
  const due = pregnant && servedAt ? addDays(servedAt, GESTATION_DAYS) : null;
  const lastSign = [heat ? recordDate(heat, 'at') : null, result === false && servedAt ? servedAt : null, calved ? recordDate(calved, 'at') : null]
    .filter((d): d is Date => d != null)
    .sort((a, b) => b.getTime() - a.getTime())[0];
  let nextHeat: Date | null = null;
  if (!pregnant && lastSign) {
    nextHeat = addDays(lastSign, HEAT_CYCLE_DAYS);
    while (nextHeat < startOfDay(now)) nextHeat = addDays(nextHeat, HEAT_CYCLE_DAYS);
  }
  return {
    service: open,
    servedAt: open ? servedAt : null,
    confirmed: result === true,
    pregnant,
    due,
    checkDue: open && result == null && servedAt ? addDays(servedAt, 60) : null,
    lastHeat: heat ? recordDate(heat, 'at') : null,
    nextHeat,
    calvedAt: calved ? recordDate(calved, 'at') : null,
  };
}

// ---------------------------------------------------------------- Vaccination

/** vaccinations (append-only): one dose given, with when the next is due. */
export interface VaccinationBody {
  vaccine: string;
  /** Whole herd when empty. */
  animalIds: string[];
  given: string;
  nextDue?: string | null;
  cost?: number | null;
  vetId?: string | null;
  note?: string | null;
}

export const commonVaccines = ['Foot and mouth (FMD)', 'Lumpy skin', 'Anthrax', 'Blackquarter', 'Brucellosis (S19)', 'East Coast Fever (ITM)', 'Rabies'] as const;


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
  /** Decision 0023: how the worker is paid. Older records only had monthlyWage. */
  payType?: string | null;
  payRate?: number | null;
  payMethod?: string | null;
  /** MoMo number or bank account for paying them. */
  payAccount?: string | null;
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
  payMethod?: PayMethod | null;
  /** Hours, days or months paid for (hourly and daily pay). */
  units?: number | null;
  /** Pay type at the time, e.g. 'daily'. */
  payType?: string | null;
  reference?: string | null;
  note?: string | null;
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

/** The phone's ExpenseCategory names. Keep to these: an older phone cannot read others. */
export const expenseCategories = ['feed', 'vet', 'breeding', 'wages', 'transport', 'fuel', 'equipment', 'other'] as const;
export const categoryName: Record<string, string> = {
  feed: 'Feed',
  vet: 'Health and vet',
  breeding: 'Breeding',
  wages: 'Worker pay',
  transport: 'Transport',
  fuel: 'Fuel',
  equipment: 'Equipment and repairs',
  other: 'Other',
};
/** The expense category a supplier's bills usually go under. */
export const categoryForContact = (k: string) =>
  k === 'feedSupplier' ? 'feed' : k === 'vet' || k === 'drugSupplier' ? 'vet' : k === 'aiTechnician' ? 'breeding' : k === 'transport' ? 'transport' : k === 'mechanic' ? 'equipment' : 'other';
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
