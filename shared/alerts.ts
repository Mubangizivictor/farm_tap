// Farm reminders (decision 0024): what is due today, worked out from the
// farm's records. The server's daily job (functions/src/alerts.ts) sends
// them as phone notifications and queues WhatsApp/SMS; the phone works out
// the same list itself (lib/core/alerts/alert_rules.dart) for its own
// notifications and for "Messages to send", so reminders work before the
// server job is switched on. Both use the same ids, so nothing is sent twice.

export type AlertKind = 'duty' | 'vaccination' | 'calving' | 'pregnancyCheck' | 'heat' | 'trial' | 'plan';

export interface FarmAlert {
  /** Same on every device and the server: kind-yyyy-mm-dd-subject. */
  id: string;
  kind: AlertKind;
  title: string;
  body: string;
  /** Staff ids it is for; empty = the owner and managers. */
  staffIds: string[];
}

export interface AlertSettings {
  duties: boolean;
  vaccinations: boolean;
  calving: boolean;
  trial: boolean;
  /** Phone notifications. */
  push: boolean;
  /** Queue an SMS / WhatsApp for the person (sent from the phone, or automatically when paid SMS is on). */
  sms: boolean;
  whatsapp: boolean;
  /** Hour of the day (Kampala) the morning reminders go out. */
  hour: number;
}

export const defaultAlertSettings: AlertSettings = {
  duties: true,
  vaccinations: true,
  calving: true,
  trial: true,
  push: true,
  sms: false,
  whatsapp: true,
  hour: 6,
};

const obj = (v: unknown): Record<string, unknown> => (v && typeof v === 'object' && !Array.isArray(v) ? (v as Record<string, unknown>) : {});
const b = (v: unknown, d: boolean) => (typeof v === 'boolean' ? v : d);

/** settings/alerts record body -> settings. */
export function alertSettingsFrom(body: unknown): AlertSettings {
  const d = obj(body);
  const D = defaultAlertSettings;
  const hour = typeof d.hour === 'number' && d.hour >= 0 && d.hour <= 23 ? Math.round(d.hour) : D.hour;
  return {
    duties: b(d.duties, D.duties),
    vaccinations: b(d.vaccinations, D.vaccinations),
    calving: b(d.calving, D.calving),
    trial: b(d.trial, D.trial),
    push: b(d.push, D.push),
    sms: b(d.sms, D.sms),
    whatsapp: b(d.whatsapp, D.whatsapp),
    hour,
  };
}

/** Minimal record shapes (the same bodies the phone and web write). */
export interface Rec<B> {
  id: string;
  isDeleted?: boolean;
  body: B;
}
export interface DutyIn {
  activity: string;
  label?: string | null;
  staffId: string;
  standInId?: string | null;
  days?: number[];
  shift?: string;
}
export interface AbsenceIn {
  staffId: string;
  from: string;
  to: string;
}
export interface VaccinationIn {
  vaccine: string;
  animalIds?: string[];
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
export interface AnimalIn {
  tagNumber?: string;
  name?: string;
  status?: string;
}

export interface AlertInput {
  /** Today in Kampala, yyyy-mm-dd. */
  today: string;
  duties: Rec<DutyIn>[];
  absences: Rec<AbsenceIn>[];
  vaccinations: Rec<VaccinationIn>[];
  breeding: Rec<BreedingIn>[];
  animals: Rec<AnimalIn>[];
  /** Staff id -> name. */
  staffNames: Record<string, string>;
  trialEndsAt: string | null;
  paidUntil: string | null;
  settings: AlertSettings;
}

export const GESTATION_DAYS = 283;
export const HEAT_CYCLE_DAYS = 21;
export const PREGNANCY_CHECK_DAYS = 60;

const DAY = 86400000;
/** yyyy-mm-dd (any ISO date or date-time; local date part). */
export const dayOf = (iso: string | null | undefined): string | null => (iso && /^\d{4}-\d{2}-\d{2}/.test(iso) ? iso.slice(0, 10) : null);
const ms = (day: string) => Date.UTC(Number(day.slice(0, 4)), Number(day.slice(5, 7)) - 1, Number(day.slice(8, 10)));
export const addDays = (day: string, n: number) => new Date(ms(day) + n * DAY).toISOString().slice(0, 10);
export const daysBetween = (from: string, to: string) => Math.round((ms(to) - ms(from)) / DAY);
const weekday = (day: string) => new Date(ms(day)).getUTCDay();

/** Today in Kampala (UTC+3, no daylight saving). */
export const kampalaToday = (now: Date) => new Date(now.getTime() + 3 * 3600 * 1000).toISOString().slice(0, 10);

export const dutyNames: Record<string, string> = {
  milking: 'Milking',
  feeding: 'Feeding',
  health: 'Animal health',
  cleaning: 'Cleaning the shed',
  grazing: 'Grazing and water',
  security: 'Night watch',
  collection: 'Taking milk to the centre',
  manager: 'In charge of the farm',
};
const shiftNames: Record<string, string> = { morning: 'morning', afternoon: 'afternoon', evening: 'evening', night: 'night', allDay: 'all day' };

const alive = <B>(rs: Rec<B>[]) => rs.filter((r) => !r.isDeleted);

function animalName(animals: Rec<AnimalIn>[], id: string | undefined): string {
  const a = animals.find((x) => x.id === id);
  if (!a) return 'A cow';
  const name = a.body.name?.trim();
  const tag = a.body.tagNumber?.trim();
  return name && tag ? `${name} (${tag})` : name || (tag ? `Tag ${tag}` : 'A cow');
}

/** Everything due today, in a stable order. */
export function alertsFor(input: AlertInput): FarmAlert[] {
  const { today, settings: s } = input;
  const out: FarmAlert[] = [];

  // Duties: who is on today, or their stand-in when they are away.
  if (s.duties) {
    const away = new Set(
      alive(input.absences)
        .filter((a) => {
          const from = dayOf(a.body.from);
          const to = dayOf(a.body.to) ?? from;
          return from && to && from <= today && today <= to;
        })
        .map((a) => a.body.staffId),
    );
    for (const d of alive(input.duties)) {
      const days = d.body.days ?? [];
      if (days.length && !days.includes(weekday(today))) continue;
      let who: string | null = d.body.staffId;
      let covering = false;
      if (away.has(d.body.staffId)) {
        who = d.body.standInId && !away.has(d.body.standInId) ? d.body.standInId : null;
        covering = who != null;
      }
      const job = d.body.activity === 'other' ? d.body.label?.trim() || 'Farm duty' : (dutyNames[d.body.activity] ?? d.body.activity);
      const shift = shiftNames[d.body.shift ?? 'allDay'] ?? '';
      if (!who) {
        out.push({
          id: `duty-${today}-${d.id}-nobody`,
          kind: 'duty',
          title: `Nobody on ${job.toLowerCase()} today`,
          body: `${input.staffNames[d.body.staffId] ?? 'The person on duty'} is away and there is no stand-in. Choose someone in the duty roster.`,
          staffIds: [],
        });
        continue;
      }
      const name = input.staffNames[who] ?? '';
      out.push({
        id: `duty-${today}-${d.id}`,
        kind: 'duty',
        title: `${job} today${shift ? `, ${shift}` : ''}`,
        body: covering
          ? `${name || 'You'}: you stand in for ${input.staffNames[d.body.staffId] ?? 'a colleague'} today (${job.toLowerCase()}).`
          : `${name || 'You'}: you are on ${job.toLowerCase()} today${shift ? ` (${shift})` : ''}.`,
        staffIds: [who],
      });
    }
  }

  // Vaccinations: the next dose is due today, tomorrow, or overdue by up to a week.
  if (s.vaccinations) {
    for (const v of alive(input.vaccinations)) {
      const due = dayOf(v.body.nextDue);
      if (!due) continue;
      const gap = daysBetween(today, due);
      if (gap > 1 || gap < -7) continue;
      // A later dose of the same vaccine already given replaces this one.
      const later = alive(input.vaccinations).some((o) => o.id !== v.id && o.body.vaccine === v.body.vaccine && (dayOf(o.body.nextDue) ?? '') > due);
      if (later) continue;
      const who = v.body.animalIds?.length ? `${v.body.animalIds.length} animal${v.body.animalIds.length === 1 ? '' : 's'}` : 'the whole herd';
      out.push({
        id: `vaccination-${today}-${v.id}`,
        kind: 'vaccination',
        title: gap < 0 ? `${v.body.vaccine} is overdue` : gap === 0 ? `${v.body.vaccine} is due today` : `${v.body.vaccine} is due tomorrow`,
        body: `Vaccinate ${who}${gap < 0 ? ` (due ${-gap} day${gap === -1 ? '' : 's'} ago)` : ''}. Call the vet if you need one.`,
        staffIds: [],
      });
    }
  }

  // Breeding: calving due, pregnancy check due, heat expected.
  if (s.calving) {
    const events = alive(input.breeding).sort((a, c) => (dayOf(c.body.at) ?? '').localeCompare(dayOf(a.body.at) ?? ''));
    const ids = Array.from(new Set(events.map((e) => e.body.animalId).filter((x): x is string => !!x)));
    for (const id of ids) {
      const a = input.animals.find((x) => x.id === id);
      if (a && (a.isDeleted || (a.body.status && a.body.status !== 'active'))) continue;
      const mine = events.filter((e) => e.body.animalId === id);
      const served = mine.find((e) => (e.body.type === 'ai' || e.body.type === 'service') && e.body.kind !== 'heat');
      const calved = mine.find((e) => e.body.type === 'calving');
      const heat = mine.find((e) => e.body.type === 'service' && e.body.kind === 'heat');
      const servedDay = served ? dayOf(served.body.at) : null;
      const open = served && servedDay && (!calved || (dayOf(calved.body.at) ?? '') < servedDay) ? served : null;
      const check = open ? events.find((e) => e.body.type === 'pregnancyCheck' && e.body.serviceId === open.id) : undefined;
      const result = check ? check.body.pregnant === true : null;
      const name = animalName(input.animals, id);
      if (open && servedDay && result !== false) {
        const due = addDays(servedDay, GESTATION_DAYS);
        const gap = daysBetween(today, due);
        if (gap === 7 || gap === 1 || gap === 0 || (gap < 0 && gap >= -3)) {
          out.push({
            id: `calving-${today}-${id}`,
            kind: 'calving',
            title: gap > 0 ? `${name} calves in ${gap} day${gap === 1 ? '' : 's'}` : gap === 0 ? `${name} is due to calve today` : `${name} was due to calve ${-gap} day${gap === -1 ? '' : 's'} ago`,
            body: gap > 1 ? 'Move her to the calving place and prepare clean bedding.' : 'Check on her often today. Call the vet if calving is difficult.',
            staffIds: [],
          });
        }
        if (result == null && daysBetween(servedDay, today) === PREGNANCY_CHECK_DAYS) {
          out.push({
            id: `pregnancyCheck-${today}-${id}`,
            kind: 'pregnancyCheck',
            title: `Pregnancy check for ${name}`,
            body: `It is ${PREGNANCY_CHECK_DAYS} days since she was served. Ask the vet to check her.`,
            staffIds: [],
          });
        }
        continue;
      }
      const last = [heat ? dayOf(heat.body.at) : null, result === false ? servedDay : null, calved ? dayOf(calved.body.at) : null]
        .filter((d): d is string => !!d)
        .sort()
        .pop();
      if (last && daysBetween(last, today) > 0 && daysBetween(last, today) % HEAT_CYCLE_DAYS === 0) {
        out.push({
          id: `heat-${today}-${id}`,
          kind: 'heat',
          title: `${name} may come on heat today`,
          body: 'Watch her this morning and evening. Record the heat and call the AI technician.',
          staffIds: [],
        });
      }
    }
  }

  // Trial or plan ending: 3 days, 1 day and the last day.
  if (s.trial) {
    const paid = dayOf(input.paidUntil);
    const trial = dayOf(input.trialEndsAt);
    const ends = paid && paid > today ? paid : trial && trial > today && !paid ? trial : null;
    if (ends) {
      const left = daysBetween(today, ends);
      if (left === 3 || left === 1) {
        const isTrial = ends === trial && !(paid && paid > today);
        out.push({
          id: `${isTrial ? 'trial' : 'plan'}-${today}`,
          kind: isTrial ? 'trial' : 'plan',
          title: isTrial ? `Free trial ends in ${left} day${left === 1 ? '' : 's'}` : `FarmTap plan ends in ${left} day${left === 1 ? '' : 's'}`,
          body: 'Choose a plan and pay to keep recording. Your records stay safe.',
          staffIds: [],
        });
      }
    }
  }
  return out;
}

/** The SMS / WhatsApp text for an alert (short: one SMS is 160 letters). */
export const alertText = (a: FarmAlert, farmName: string) => `FarmTap ${farmName}: ${a.title}. ${a.body}`.slice(0, 300);
