// FarmTap AI engine — core (decision 0025). Pure TypeScript, no Firebase,
// no network, so the same rules run in the web app, Cloud Functions and
// (ported) on the phone, and can be tested with plain data.
//
// Dates: the phone writes local Kampala time with no zone
// ("2026-11-03T14:40:19.123"). The engine never converts zones: it reads
// the day ("2026-11-03") and, where hours matter, the clock time, all in
// the same local frame. `now` is turned into that frame with kampalaNow().

/** One stored record, as both apps write it (base fields we need). */
export interface Rec<B> {
  id: string;
  isDeleted?: boolean;
  createdAt?: string;
  createdBy?: string;
  body: B;
}

/** How an answer was made. Shown on every card, so a sum is never called "AI". */
export type Method = 'calculated' | 'statistical' | 'rules' | 'model' | 'experimental';

export const methodLabel: Record<Method, string> = {
  calculated: 'Calculated from your records',
  statistical: 'Statistical estimate',
  rules: 'Rule-based guide',
  model: 'AI model',
  experimental: 'Experimental',
};

export type Severity = 'critical' | 'high' | 'medium' | 'low';
export const severityRank: Record<Severity, number> = { critical: 0, high: 1, medium: 2, low: 3 };

/** The AI modules, used for menus, role checks and admin switches. */
export const aiModules = [
  { key: 'assistant', label: 'Farm Assistant', hint: 'Ask questions about your farm records' },
  { key: 'vet', label: 'Veterinary Assistant', hint: 'Symptoms, warning signs and when to call the vet' },
  { key: 'screening', label: 'Photo Check', hint: 'Take a photo, get possible causes' },
  { key: 'milk', label: 'Milk Intelligence', hint: 'Daily milk, cows dropping, unusual days, losses' },
  { key: 'quality', label: 'Milk Quality and Expiry', hint: 'Batches, cooling, temperatures, rejections' },
  { key: 'predictions', label: 'Production Predictions', hint: 'Next 7 and 30 days of milk' },
  { key: 'feed', label: 'Feed Intelligence', hint: 'Feed left, run-out dates, cost per litre' },
  { key: 'breeding', label: 'Breeding Intelligence', hint: 'Heats, checks, calving, open cows' },
  { key: 'health', label: 'Animal Health Monitoring', hint: 'Repeat illness, vaccinations, follow-ups' },
  { key: 'finance', label: 'Financial Intelligence', hint: 'Cost per litre, unusual spending, cash estimate' },
  { key: 'inventory', label: 'Inventory Intelligence', hint: 'Feed and drug stock, reorder' },
  { key: 'reports', label: 'Smart Farm Reports', hint: 'Ask for a report in your own words' },
  { key: 'risks', label: 'Farm Risk Detection', hint: 'Every risk, by how serious it is' },
  { key: 'recommendations', label: 'AI Recommendations', hint: "Today's insights" },
  { key: 'alerts', label: 'AI Alerts Centre', hint: 'Acknowledge and resolve alerts' },
] as const;
export type AiModule = (typeof aiModules)[number]['key'];

// ---------------------------------------------------------------- Dates

const DAY_MS = 86_400_000;
const pad = (n: number) => String(n).padStart(2, '0');

/** yyyy-mm-dd of an ISO date or date-time (its own local day). */
export const dayOf = (iso: unknown): string | null => (typeof iso === 'string' && /^\d{4}-\d{2}-\d{2}/.test(iso) ? iso.slice(0, 10) : null);

/** Milliseconds of a local ISO date-time, read in one fixed frame (UTC). Seconds are enough. */
export function msOf(iso: unknown): number | null {
  if (typeof iso !== 'string') return null;
  const m = /^(\d{4})-(\d{2})-(\d{2})(?:[T ](\d{2}):(\d{2})(?::(\d{2}))?)?/.exec(iso);
  if (!m) return null;
  return Date.UTC(+m[1], +m[2] - 1, +m[3], +(m[4] ?? 0), +(m[5] ?? 0), +(m[6] ?? 0));
}

const dayMs = (day: string) => Date.UTC(+day.slice(0, 4), +day.slice(5, 7) - 1, +day.slice(8, 10));
export const addDays = (day: string, n: number) => new Date(dayMs(day) + n * DAY_MS).toISOString().slice(0, 10);
export const daysBetween = (from: string, to: string) => Math.round((dayMs(to) - dayMs(from)) / DAY_MS);
/** 0 = Sunday. */
export const weekdayOf = (day: string) => new Date(dayMs(day)).getUTCDay();
export const monthOf = (day: string) => day.slice(0, 7);
export const addMonths = (month: string, n: number) => {
  const d = new Date(Date.UTC(+month.slice(0, 4), +month.slice(5, 7) - 1 + n, 1));
  return `${d.getUTCFullYear()}-${pad(d.getUTCMonth() + 1)}`;
};

/** Now as a local Kampala time in the engine's frame (UTC+3, no daylight saving). */
export function kampalaNow(now: Date): { day: string; ms: number; iso: string } {
  const k = new Date(now.getTime() + 3 * 3600 * 1000);
  const iso = k.toISOString().slice(0, 19);
  return { day: iso.slice(0, 10), ms: msOf(iso) as number, iso };
}

/** The day a record belongs to: its own date field, else when it was made. */
export function recDay(r: Rec<object>, field?: string): string | null {
  const b = r.body as Record<string, unknown>;
  return (field ? dayOf(b[field]) : null) ?? dayOf(r.createdAt);
}

export const alive = <B>(rs: Rec<B>[] | undefined): Rec<B>[] => (rs ?? []).filter((r) => r && r.body && !r.isDeleted);
export const num = (v: unknown): number => (typeof v === 'number' && Number.isFinite(v) ? v : typeof v === 'string' && v.trim() !== '' && Number.isFinite(Number(v)) ? Number(v) : 0);

// ---------------------------------------------------------------- Statistics

export const sum = (xs: number[]) => xs.reduce((t, x) => t + x, 0);
export const mean = (xs: number[]) => (xs.length ? sum(xs) / xs.length : 0);

export function median(xs: number[]): number {
  if (!xs.length) return 0;
  const s = [...xs].sort((a, b) => a - b);
  const m = Math.floor(s.length / 2);
  return s.length % 2 ? s[m] : (s[m - 1] + s[m]) / 2;
}

/** Median absolute deviation, scaled to match a standard deviation for normal data. */
export function mad(xs: number[]): number {
  const m = median(xs);
  return 1.4826 * median(xs.map((x) => Math.abs(x - m)));
}

/**
 * Robust z-score of x against history: how unusual x is, using median and
 * MAD so one odd day does not hide another. Null when history is too short
 * or does not vary (then nothing can be called unusual).
 */
export function robustZ(x: number, history: number[], minPoints = 7): number | null {
  if (history.length < minPoints) return null;
  const m = median(history);
  let s = mad(history);
  // A very steady history: fall back to 5% of the median so tiny wobbles are not "unusual".
  if (s < Math.abs(m) * 0.05) s = Math.abs(m) * 0.05;
  if (s === 0) return null;
  return (x - m) / s;
}

export interface LineFit {
  slope: number;
  intercept: number;
  /** Standard deviation of what the line does not explain. */
  residualSd: number;
  r2: number;
  n: number;
}

/** Weighted least squares line y = a + b·x. */
export function fitLine(xs: number[], ys: number[], ws?: number[]): LineFit | null {
  const n = xs.length;
  if (n < 2 || ys.length !== n) return null;
  const w = ws ?? xs.map(() => 1);
  const W = sum(w);
  const mx = sum(xs.map((x, i) => x * w[i])) / W;
  const my = sum(ys.map((y, i) => y * w[i])) / W;
  let sxx = 0;
  let sxy = 0;
  for (let i = 0; i < n; i++) {
    sxx += w[i] * (xs[i] - mx) ** 2;
    sxy += w[i] * (xs[i] - mx) * (ys[i] - my);
  }
  const slope = sxx === 0 ? 0 : sxy / sxx;
  const intercept = my - slope * mx;
  let sse = 0;
  let sst = 0;
  for (let i = 0; i < n; i++) {
    sse += w[i] * (ys[i] - (intercept + slope * xs[i])) ** 2;
    sst += w[i] * (ys[i] - my) ** 2;
  }
  const residualSd = Math.sqrt(sse / W) * Math.sqrt(n / Math.max(1, n - 2));
  return { slope, intercept, residualSd, r2: sst === 0 ? 1 : Math.max(0, 1 - sse / sst), n };
}

/** Percentage change from before to now, rounded; null when before is 0. */
export function pctChange(now: number, before: number): number | null {
  if (!before) return null;
  return Math.round(((now - before) / before) * 100);
}

export const round1 = (x: number) => Math.round(x * 10) / 10;

// ---------------------------------------------------------------- Insights

/** Where a finding points, so the person can open the record. */
export interface Link {
  label: string;
  href: string;
}

/**
 * One finding: an alert, a recommendation or an insight. `id` is stable for
 * the same situation (kind + subject + period), so the same alert is never
 * shown twice and an acknowledgement sticks until the situation changes.
 */
export interface Finding {
  id: string;
  module: AiModule;
  severity: Severity;
  title: string;
  /** Why it was raised: the records and numbers behind it. */
  why: string;
  /** What to do. */
  action: string;
  method: Method;
  links: Link[];
  /** Record ids it is about (animals, batches, feeds…). */
  subjects: string[];
}

/** Sort by severity, then title; drop repeats of the same id. */
export function rankFindings(fs: Finding[]): Finding[] {
  const seen = new Set<string>();
  return fs
    .filter((f) => (seen.has(f.id) ? false : (seen.add(f.id), true)))
    .sort((a, b) => severityRank[a.severity] - severityRank[b.severity] || a.title.localeCompare(b.title));
}

// ---------------------------------------------------------------- Formats

export const fmtL = (l: number) => `${round1(l).toLocaleString('en-US')} L`;
export const fmtUgx = (n: number) => `UGX ${Math.round(n).toLocaleString('en-US')}`;
const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const wd = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
/** "Thu 12 Nov" */
export const fmtDay = (day: string) => `${wd[weekdayOf(day)]} ${+day.slice(8, 10)} ${months[+day.slice(5, 7) - 1]}`;
/** "Nov 2026" */
export const fmtMonth = (month: string) => `${months[+month.slice(5, 7) - 1]} ${month.slice(0, 4)}`;
export const plural = (n: number, one: string, many = `${one}s`) => `${n} ${n === 1 ? one : many}`;
