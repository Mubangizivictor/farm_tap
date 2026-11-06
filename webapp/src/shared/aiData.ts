// GENERATED from shared/ by `node shared/sync.mjs`. Edit the file in shared/, not this copy.
// FarmTap AI engine — the farm's records as the engine reads them
// (decision 0025). The same bodies the phone and web write; only the fields
// the engine uses are listed. Everything is optional so older records and
// half-filled ones never break an analysis.

import { addDays, alive, daysBetween, dayOf, num, recDay, type Rec } from './aiCore.ts';

export interface AnimalIn {
  tagNumber?: string;
  name?: string;
  sex?: string;
  status?: string;
  dairyStatus?: string;
  dateOfBirth?: string;
  group?: string | null;
}
export interface MilkIn {
  /** Null for a herd total. */
  animalId?: string | null;
  session?: string;
  litres: number;
  notForSale?: boolean;
  cowsMilked?: number | null;
}
export interface TreatmentIn {
  animalId: string;
  condition?: string;
  given?: string;
  withdrawalDays?: number;
  courseDays?: number;
  cost?: number | null;
  drugId?: string;
  note?: string | null;
}
export interface VaccinationIn {
  vaccine: string;
  animalIds?: string[];
  given?: string;
  nextDue?: string | null;
}
export interface BreedingIn {
  type: string;
  kind?: string;
  animalId?: string;
  at: string;
  serviceId?: string;
  pregnant?: boolean;
}
export interface ExpenseIn {
  category: string;
  amount: number;
  at?: string;
  sourceType?: string | null;
}
export interface IncomeIn {
  source: string;
  amount: number;
  at?: string;
}
export interface MilkSaleIn {
  buyer?: string;
  litres: number;
  pricePerLitre: number;
}
export interface FeedUseIn {
  feed: string;
  group?: string;
  amount: number;
  at?: string;
}
export interface StockMoveIn {
  kind: string;
  feed?: string;
  amount: number;
  pricePerUnit?: number;
  at?: string;
}
export interface FeedTypeIn {
  name: string;
  unit?: string;
  lowAt?: number | null;
}
export interface StockItemIn {
  kind: string;
  name?: string;
  stock?: number;
  unit?: string;
  /** Reorder level (the phone's "warn at"). */
  lowAt?: number | null;
  reorderAt?: number | null;
}
export interface DeliveryIn {
  farmerId: string;
  litres: number;
  session?: string;
  test?: 'passed' | 'failed' | 'notDone' | string;
  rejectReason?: string | null;
  at?: string;
}

/** milkBatches (decision 0025): milk kept on the farm before it leaves. */
export interface MilkBatchIn {
  litres: number;
  /** When the milk was collected (milked), local ISO. */
  collectedAt: string;
  /** Product rule to use; only raw milk today. */
  product?: string;
  /** Put in a cooler or cooling tank. */
  cooled?: boolean;
  /** Where it is kept: "Cooler 1", "Can A". */
  place?: string | null;
  status?: 'stored' | 'sold' | 'discarded' | 'used' | string;
  /** When it left (sold, used or thrown away). */
  closedAt?: string | null;
  note?: string | null;
}

/** storageReadings (decision 0025): one temperature reading. */
export interface StorageReadingIn {
  batchId?: string | null;
  place?: string | null;
  tempC: number;
  at: string;
}

/** Shelf-life rule for a product, set by the farm (settings/aiMilk). */
export interface ShelfRule {
  product: string;
  label: string;
  /** Hours the milk keeps when cooled and every reading is at or below maxTempC. */
  cooledHours: number;
  /** Hours it keeps when not cooled, or after a reading above maxTempC. */
  warmHours: number;
  maxTempC: number;
}

/**
 * Starting rules, to be checked and changed by each farm (settings): raw
 * milk keeps about 2 days at 4 °C or colder and must be cooled or sold
 * within a few hours when warm. These are FarmTap defaults, not a safety
 * certificate; the farm's buyer or the Dairy Development Authority decides.
 */
export const defaultShelfRules: ShelfRule[] = [{ product: 'rawMilk', label: 'Raw milk', cooledHours: 48, warmHours: 3, maxTempC: 4 }];

export interface FarmData {
  /** Kampala local now, ISO without zone (kampalaNow(new Date()).iso). */
  now: string;
  animals?: Rec<AnimalIn>[];
  milk?: Rec<MilkIn>[];
  treatments?: Rec<TreatmentIn>[];
  vaccinations?: Rec<VaccinationIn>[];
  breeding?: Rec<BreedingIn>[];
  expenses?: Rec<ExpenseIn>[];
  income?: Rec<IncomeIn>[];
  milkSales?: Rec<MilkSaleIn>[];
  feedUses?: Rec<FeedUseIn>[];
  stockMoves?: Rec<StockMoveIn>[];
  feedTypes?: Rec<FeedTypeIn>[];
  stockItems?: Rec<StockItemIn>[];
  deliveries?: Rec<DeliveryIn>[];
  milkBatches?: Rec<MilkBatchIn>[];
  storageReadings?: Rec<StorageReadingIn>[];
  shelfRules?: ShelfRule[];
}

export const today = (d: FarmData) => d.now.slice(0, 10);

// ---------------------------------------------------------------- Animals

export const isActive = (a: Rec<AnimalIn>) => !a.body.status || a.body.status === 'active';
export const animalName = (a: Rec<AnimalIn> | undefined) => (a ? a.body.name?.trim() || a.body.tagNumber || 'No tag' : 'Unknown animal');
export const animalHref = (id: string) => `/herd/?animal=${encodeURIComponent(id)}`;

export function animalMap(d: FarmData): Map<string, Rec<AnimalIn>> {
  return new Map(alive(d.animals).map((a) => [a.id, a]));
}

export const isMilkingCow = (a: Rec<AnimalIn>) => isActive(a) && (a.body.dairyStatus === 'milking' || a.body.dairyStatus === 'treated');

// ---------------------------------------------------------------- Milk days

/**
 * Litres per day for the [days] days ending today (oldest first), plus
 * which days have any record at all. A day with no record is "not
 * recorded", never "zero milk": the forecasts skip such days.
 */
export function milkDays(d: FarmData, days: number): { day: string; litres: number; recorded: boolean }[] {
  const end = today(d);
  const out = new Map<string, { day: string; litres: number; recorded: boolean }>();
  for (let i = days - 1; i >= 0; i--) {
    const day = addDays(end, -i);
    out.set(day, { day, litres: 0, recorded: false });
  }
  for (const r of alive(d.milk)) {
    const day = recDay(r);
    const slot = day ? out.get(day) : undefined;
    if (!slot) continue;
    slot.litres += num(r.body.litres);
    slot.recorded = true;
  }
  return [...out.values()];
}

/** Litres per cow per day for the last [days] days (only cows with per-cow records). */
export function cowDays(d: FarmData, days: number): Map<string, Map<string, number>> {
  const from = addDays(today(d), -(days - 1));
  const out = new Map<string, Map<string, number>>();
  for (const r of alive(d.milk)) {
    const id = r.body.animalId;
    const day = recDay(r);
    if (!id || !day || day < from || day > today(d)) continue;
    const m = out.get(id) ?? new Map<string, number>();
    m.set(day, (m.get(day) ?? 0) + num(r.body.litres));
    out.set(id, m);
  }
  return out;
}

// ---------------------------------------------------------------- Breeding

export const GESTATION_DAYS = 283;
export const HEAT_CYCLE_DAYS = 21;
export const PREGNANCY_CHECK_DAYS = 60;

const isService = (b: BreedingIn) => (b.type === 'ai' || b.type === 'service') && b.kind !== 'heat';
const isHeat = (b: BreedingIn) => b.type === 'service' && b.kind === 'heat';

/** The same reading of breeding events as the phone and web (domain.breedingView). */
export function breedingState(animalId: string, events: Rec<BreedingIn>[], day: string) {
  const all = alive(events)
    .filter((e) => dayOf(e.body.at))
    .sort((a, b) => (b.body.at > a.body.at ? 1 : b.body.at < a.body.at ? -1 : 0));
  const mine = all.filter((e) => e.body.animalId === animalId);
  const services = mine.filter((e) => isService(e.body));
  const served = services[0];
  const calved = mine.find((e) => e.body.type === 'calving');
  const heat = mine.find((e) => isHeat(e.body));
  const servedDay = served ? (dayOf(served.body.at) as string) : null;
  const calvedDay = calved ? (dayOf(calved.body.at) as string) : null;
  const open = served && servedDay && (!calvedDay || calvedDay < servedDay) ? served : null;
  const check = open ? all.find((e) => e.body.type === 'pregnancyCheck' && e.body.serviceId === open.id) : undefined;
  const result = check ? check.body.pregnant === true : null;
  const pregnant = open != null && result !== false;
  const due = pregnant && servedDay ? addDays(servedDay, GESTATION_DAYS) : null;
  const lastSign = [heat ? dayOf(heat.body.at) : null, result === false ? servedDay : null, calvedDay].filter((x): x is string => !!x).sort().reverse()[0];
  let nextHeat: string | null = null;
  if (!pregnant && lastSign) {
    nextHeat = addDays(lastSign, HEAT_CYCLE_DAYS);
    while (nextHeat < day) nextHeat = addDays(nextHeat, HEAT_CYCLE_DAYS);
  }
  // Services since the last calving with no confirmed pregnancy (repeat breeder sign).
  const sinceCalving = services.filter((s) => !calvedDay || (dayOf(s.body.at) as string) > calvedDay);
  const failedServices = sinceCalving.filter((s) => {
    const c = all.find((e) => e.body.type === 'pregnancyCheck' && e.body.serviceId === s.id);
    return c ? c.body.pregnant === false : s !== open;
  }).length;
  return {
    servedDay: open ? servedDay : null,
    confirmed: result === true,
    pregnant,
    due,
    checkDue: open && result == null && servedDay ? addDays(servedDay, PREGNANCY_CHECK_DAYS) : null,
    lastHeat: heat ? dayOf(heat.body.at) : null,
    nextHeat,
    calvedDay,
    daysInMilk: calvedDay ? daysBetween(calvedDay, day) : null,
    servicesSinceCalving: sinceCalving.length,
    failedServices,
  };
}
