// Dates in the same text form the phone writes (Dart's DateTime.toIso8601String
// on local time: "2026-11-03T14:40:19.123", no zone). JavaScript reads that
// form as local time, so phone and web agree on which day a record is.

const pad = (n: number, w = 2) => String(n).padStart(w, '0');

export function localIso(d: Date): string {
  return (
    `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}` +
    `T${pad(d.getHours())}:${pad(d.getMinutes())}:${pad(d.getSeconds())}.${pad(d.getMilliseconds(), 3)}`
  );
}

/** Reads a stored date: ISO text (with or without zone) or a Firestore Timestamp. */
export function parseDate(v: unknown): Date | null {
  if (v == null) return null;
  if (typeof v === 'string') {
    // Dart may write microseconds (6 digits); JS only reads 3.
    const d = new Date(v.replace(/(\.\d{3})\d+/, '$1'));
    return Number.isNaN(d.getTime()) ? null : d;
  }
  if (typeof v === 'object' && v !== null && 'toDate' in v && typeof (v as { toDate: unknown }).toDate === 'function') {
    return (v as { toDate: () => Date }).toDate();
  }
  if (v instanceof Date) return v;
  return null;
}

export function startOfDay(d: Date): Date {
  return new Date(d.getFullYear(), d.getMonth(), d.getDate());
}

export function addDays(d: Date, days: number): Date {
  return new Date(d.getFullYear(), d.getMonth(), d.getDate() + days);
}

export function startOfMonth(d: Date): Date {
  return new Date(d.getFullYear(), d.getMonth(), 1);
}

export function sameDay(a: Date, b: Date): boolean {
  return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();
}

/** Whole days from a to b (b later is positive), by calendar day. */
export function daysBetween(a: Date, b: Date): number {
  return Math.round((startOfDay(b).getTime() - startOfDay(a).getTime()) / 86_400_000);
}

/** "2026-11-03" for date inputs. */
export function dayKey(d: Date): string {
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
}
