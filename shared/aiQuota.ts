// FarmTap AI — daily allowance for AI answers (decision 0028, layer 3).
//
// Only answers written by an AI model count. Built-in answers (records and
// calculations) are free and unlimited. The server (functions/src/ai.ts) is
// the only place that counts: it reserves one answer in a transaction before
// asking the model, keeps it when an answer comes back and gives it back when
// the request fails. The apps only show what the server wrote.

const obj = (v: unknown): Record<string, unknown> => (v && typeof v === 'object' && !Array.isArray(v) ? (v as Record<string, unknown>) : {});
const intIn = (v: unknown, lo: number, hi: number, d: number) => (typeof v === 'number' && Number.isFinite(v) && v >= lo && v <= hi ? Math.round(v) : d);
const numIn = (v: unknown, lo: number, hi: number, d: number) => (typeof v === 'number' && Number.isFinite(v) && v >= lo && v <= hi ? v : d);

// ---------------------------------------------------------------- Settings

export const AI_PROVIDERS = [{ id: 'gemini', label: 'Google Gemini' }] as const;
export type AiProviderId = (typeof AI_PROVIDERS)[number]['id'];

/**
 * platform/config.ai.assistant, set in Admin > AI Control Centre. Changing it
 * needs no app release.
 */
export interface AssistantConfig {
  /** AI answers for every farm. Off: built-in answers only. */
  enabled: boolean;
  provider: AiProviderId;
  model: string;
  /** Successful AI answers per farm per day (shared by everyone on the farm). 0 = none. */
  dailyLimit: number;
  /** Warn at this share of the limit (percent). */
  warnPct: number;
  /** The day starts at midnight here. */
  timezone: string;
  /** Longest question accepted, in characters. */
  maxChars: number;
  /** Longest wait for the model, in milliseconds. */
  timeoutMs: number;
  maxOutputTokens: number;
  /** Rough cap on what is sent (question, history and farm facts), in tokens (about 4 characters each). */
  maxInputTokens: number;
  /**
   * 'server': answers come through the FarmTap server, which enforces the
   * limit (needs Blaze and the aiAssistant function deployed).
   * 'client': the app calls Gemini itself (pilot, as before); the limit is
   * only counted in the app.
   */
  route: 'server' | 'client';
  /** Keep an AI answer this long for the same farm and the same question and facts (0 = no cache). */
  cacheHours: number;
  /** AI questions one person may send per minute (abuse guard). */
  perUserPerMinute: number;
  /** For the cost estimate in the AI Control Centre, USD per million tokens. 0 while on the free tier. */
  priceInPerM: number;
  priceOutPerM: number;
}

export const DEFAULT_TIMEZONE = 'Africa/Kampala';

export const defaultAssistantConfig: AssistantConfig = {
  enabled: false,
  provider: 'gemini',
  model: 'gemini-3.5-flash-lite',
  dailyLimit: 10,
  warnPct: 80,
  timezone: DEFAULT_TIMEZONE,
  maxChars: 2000,
  timeoutMs: 60000,
  maxOutputTokens: 1500,
  maxInputTokens: 8000,
  route: 'client',
  cacheHours: 6,
  perUserPerMinute: 6,
  priceInPerM: 0,
  priceOutPerM: 0,
};

export function validTimezone(tz: unknown): tz is string {
  if (typeof tz !== 'string' || !/^[A-Za-z_]+(\/[A-Za-z_+\-]+){0,2}$/.test(tz)) return false;
  try {
    new Intl.DateTimeFormat('en-US', { timeZone: tz });
    return true;
  } catch {
    return false;
  }
}

/**
 * Reads platform/config.ai. Older configs have no `assistant` yet: the chat
 * then follows the Photo Check switch and model, as it did before.
 */
export function assistantConfigFrom(ai: unknown): AssistantConfig {
  const o = obj(ai);
  const a = obj(o.assistant);
  const ph = obj(o.photo);
  const D = defaultAssistantConfig;
  const model = (v: unknown) => (typeof v === 'string' && /^[\w.\-]{3,64}$/.test(v) ? v : null);
  return {
    enabled: typeof a.enabled === 'boolean' ? a.enabled : typeof ph.enabled === 'boolean' ? ph.enabled : D.enabled,
    provider: AI_PROVIDERS.some((p) => p.id === a.provider) ? (a.provider as AiProviderId) : D.provider,
    model: model(a.model) ?? model(ph.model) ?? D.model,
    dailyLimit: intIn(a.dailyLimit, 0, 1000, D.dailyLimit),
    warnPct: intIn(a.warnPct, 50, 100, D.warnPct),
    timezone: validTimezone(a.timezone) ? a.timezone : D.timezone,
    maxChars: intIn(a.maxChars, 100, 8000, D.maxChars),
    timeoutMs: intIn(a.timeoutMs, 5000, 120000, D.timeoutMs),
    maxOutputTokens: intIn(a.maxOutputTokens, 128, 8192, D.maxOutputTokens),
    maxInputTokens: intIn(a.maxInputTokens, 500, 100000, D.maxInputTokens),
    route: a.route === 'server' || a.route === 'client' ? a.route : D.route,
    cacheHours: intIn(a.cacheHours, 0, 72, D.cacheHours),
    perUserPerMinute: intIn(a.perUserPerMinute, 1, 60, D.perUserPerMinute),
    priceInPerM: numIn(a.priceInPerM, 0, 1000, D.priceInPerM),
    priceOutPerM: numIn(a.priceOutPerM, 0, 1000, D.priceOutPerM),
  };
}

// ---------------------------------------------------------------- Days

function partsIn(tz: string, ms: number) {
  const f = new Intl.DateTimeFormat('en-US', { timeZone: tz, hourCycle: 'h23', year: 'numeric', month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit', second: '2-digit' });
  const p = Object.fromEntries(f.formatToParts(new Date(ms)).map((x) => [x.type, x.value]));
  return { y: +p.year, m: +p.month, d: +p.day, h: +p.hour, min: +p.minute, s: +p.second };
}

/** The allowance day ("2026-11-07") at [nowMs] in [tz]. Server clock only. */
export function quotaDay(nowMs: number, tz = DEFAULT_TIMEZONE): string {
  const p = partsIn(tz, nowMs);
  return `${p.y}-${String(p.m).padStart(2, '0')}-${String(p.d).padStart(2, '0')}`;
}

/** When the next allowance day starts (next midnight in [tz]), as epoch ms. */
export function nextResetMs(nowMs: number, tz = DEFAULT_TIMEZONE): number {
  const p = partsIn(tz, nowMs);
  // Offset of tz from UTC right now (ms), then midnight tomorrow local -> UTC.
  const offset = Date.UTC(p.y, p.m - 1, p.d, p.h, p.min, p.s) - Math.floor(nowMs / 1000) * 1000;
  const guess = Date.UTC(p.y, p.m - 1, p.d + 1) - offset;
  // Daylight-saving zones: correct once with the offset at the guess.
  const g = partsIn(tz, guess);
  const offset2 = Date.UTC(g.y, g.m - 1, g.d, g.h, g.min, g.s) - guess;
  return Date.UTC(p.y, p.m - 1, p.d + 1) - offset2;
}

// ---------------------------------------------------------------- Usage

/** tenants/{t}/aiUsage/{day}: written only by the server. */
export interface UsageDoc {
  day: string;
  /** Successful AI answers today. */
  used: number;
  /** Answers being written now: reservation id -> when it lapses (epoch ms). */
  pending: Record<string, number>;
  failed: number;
  /** Times someone was told the limit was reached. */
  limitHits: number;
  /** The limit when last written, so the apps can show it without reading the config. */
  limit: number;
  /** Next reset, epoch ms. */
  resetAt: number;
}

export function usageFrom(v: unknown, day: string): UsageDoc {
  const o = obj(v);
  const pending: Record<string, number> = {};
  for (const [k, x] of Object.entries(obj(o.pending))) if (typeof x === 'number') pending[k] = x;
  return {
    day: typeof o.day === 'string' ? o.day : day,
    used: intIn(o.used, 0, 1e6, 0),
    pending,
    failed: intIn(o.failed, 0, 1e6, 0),
    limitHits: intIn(o.limitHits, 0, 1e6, 0),
    limit: intIn(o.limit, 0, 1000, defaultAssistantConfig.dailyLimit),
    resetAt: typeof o.resetAt === 'number' ? o.resetAt : 0,
  };
}

/** Reservations still alive at [nowMs] (a crashed request lapses by itself). */
export const livePending = (u: UsageDoc, nowMs: number) => Object.values(u.pending).filter((exp) => exp > nowMs).length;

export type Reserve = { ok: true; next: UsageDoc } | { ok: false; reason: 'limit' | 'disabled'; next: UsageDoc };

/**
 * Takes one answer from today's allowance, or says the limit is reached.
 * Run inside a transaction: two requests at once cannot both take the last answer.
 */
export function reserve(cur: UsageDoc, o: { id: string; nowMs: number; limit: number; holdMs: number; resetAt: number }): Reserve {
  const pending: Record<string, number> = {};
  for (const [k, exp] of Object.entries(cur.pending)) if (exp > o.nowMs) pending[k] = exp; // drop lapsed ones
  const base = { ...cur, pending, limit: o.limit, resetAt: o.resetAt };
  if (o.limit <= 0) return { ok: false, reason: 'disabled', next: base };
  if (cur.used + Object.keys(pending).length >= o.limit) return { ok: false, reason: 'limit', next: { ...base, limitHits: cur.limitHits + 1 } };
  return { ok: true, next: { ...base, pending: { ...pending, [o.id]: o.nowMs + o.holdMs } } };
}

/** The answer came back: it counts. Counting twice for one id is impossible. */
export function commit(cur: UsageDoc, id: string): UsageDoc {
  if (!(id in cur.pending)) return cur;
  const pending = { ...cur.pending };
  delete pending[id];
  return { ...cur, used: cur.used + 1, pending };
}

/** The request failed or timed out: give the answer back. */
export function release(cur: UsageDoc, id: string): UsageDoc {
  if (!(id in cur.pending)) return { ...cur, failed: cur.failed + 1 };
  const pending = { ...cur.pending };
  delete pending[id];
  return { ...cur, pending, failed: cur.failed + 1 };
}

export interface UsageView {
  used: number;
  limit: number;
  remaining: number;
  /** 'warn' from warnPct, 'out' when nothing is left. */
  level: 'ok' | 'warn' | 'out';
  resetAt: number;
}

export function usageView(used: number, limit: number, warnPct: number, resetAt: number): UsageView {
  const u = Math.max(0, Math.min(used, limit));
  const remaining = Math.max(0, limit - used);
  const level = remaining === 0 ? 'out' : limit > 0 && (u / limit) * 100 >= warnPct ? 'warn' : 'ok';
  return { used: u, limit, remaining, level, resetAt };
}

/** "Midnight" for a reset at local midnight (always, today). Kept as a function for other reset times later. */
export const resetLabel = () => 'Midnight';

export function usageWarning(v: UsageView): { title: string; message: string } | null {
  if (v.level === 'warn')
    return {
      title: 'Approaching your daily AI limit',
      message: `You're approaching your daily AI limit. You have ${v.remaining} AI ${v.remaining === 1 ? 'response' : 'responses'} remaining today. Farm Tap's built-in intelligence and farm-management features remain unlimited.`,
    };
  if (v.level === 'out')
    return {
      title: 'Your daily AI allowance has been reached.',
      message: 'AI-powered responses will be available again after the daily reset at midnight. You can still ask about your records, production, money and alerts: those answers are unlimited.',
    };
  return null;
}

// ---------------------------------------------------------------- Errors

/**
 * Every way an AI request can end without an answer. The server sends the
 * word in HttpsError details.kind; the apps show the matching text. Raw
 * provider messages are never shown to farmers.
 */
export type AiErrorKind = 'limit' | 'unavailable' | 'network' | 'timeout' | 'disabled' | 'invalid' | 'capacity' | 'tooFast';

export const AI_ERROR_KINDS: AiErrorKind[] = ['limit', 'unavailable', 'network', 'timeout', 'disabled', 'invalid', 'capacity', 'tooFast'];

export function aiErrorText(kind: AiErrorKind, limit = defaultAssistantConfig.dailyLimit): { title: string; message: string } {
  switch (kind) {
    case 'limit':
      return {
        title: 'Daily AI limit reached',
        message: `You've used all ${limit} AI-powered responses available to your farm today. Your AI allowance resets at midnight. You can continue using Farm Tap's built-in farm intelligence, analytics and management features without limits.`,
      };
    case 'unavailable':
      return {
        title: 'AI temporarily unavailable',
        message: 'Our AI assistant is temporarily unavailable. You can still access your farm records, reports, calculations and automated insights. Please try again later.',
      };
    case 'network':
      return {
        title: 'Connection problem',
        message: "We couldn't connect to the AI service. Check your internet connection and try again. Your AI allowance has not been consumed.",
      };
    case 'timeout':
      return { title: 'Request timed out', message: 'The AI assistant took too long to respond. Please try again. Your request allowance has not been consumed.' };
    case 'disabled':
      return { title: 'AI assistant temporarily disabled', message: 'The AI assistant is currently unavailable. All other Farm Tap features remain accessible.' };
    case 'invalid':
      return { title: 'Unable to process request', message: 'Please rephrase your question and try again.' };
    case 'capacity':
      return {
        title: 'AI service capacity reached',
        message: 'Our AI service has temporarily reached its available capacity. Please try again later. Your farm-management tools and built-in intelligence remain available.',
      };
    case 'tooFast':
      return { title: 'Too many questions at once', message: 'Please wait a minute before asking the AI again. Your AI allowance has not been consumed, and built-in answers stay available.' };
  }
}

export const isAiErrorKind = (v: unknown): v is AiErrorKind => typeof v === 'string' && (AI_ERROR_KINDS as string[]).includes(v);

/**
 * Sorts a provider's HTTP status and message into one kind. [status] is 0 when
 * no answer came at all (connection failed).
 */
export function providerErrorKind(status: number, message: string): AiErrorKind {
  const m = message.toLowerCase();
  if (m.includes('abort') || m.includes('timeout') || m.includes('timed out') || status === 408 || status === 504) return 'timeout';
  if (status === 429 || m.includes('resource_exhausted') || m.includes('quota')) return 'capacity';
  if (status === 400 && (m.includes('safety') || m.includes('blocked') || m.includes('invalid argument') || m.includes('invalid_argument'))) return 'invalid';
  if (status === 0 || m.includes('fetch failed') || m.includes('enotfound') || m.includes('econnreset') || m.includes('network')) return 'network';
  return 'unavailable';
}

/** The old in-app chat's failure words (shared/aiChat.ts) as kinds, for the client route. */
export function chatFailureKind(f: string, detail = ''): AiErrorKind {
  if (f === 'network') return 'network';
  if (f === 'busy') return /timeout|timed out/i.test(detail) ? 'timeout' : 'capacity';
  if (f === 'blocked') return 'invalid';
  return 'unavailable';
}

/** Retry only what may work a moment later, and never more than [max] times. */
export const retryable = (k: AiErrorKind) => k === 'unavailable' || k === 'capacity' || k === 'network';
export const MAX_RETRIES = 2;

/** 0.5 s, 1 s, 2 s … capped at 4 s, with up to 25% jitter. [rand] in [0, 1). */
export function backoffMs(attempt: number, rand = 0.5): number {
  const base = Math.min(4000, 500 * 2 ** attempt);
  return Math.round(base * (1 + rand * 0.25));
}

/** Rough token count (about 4 characters a token) for the input cap and cost estimate. */
export const roughTokens = (text: string) => Math.ceil(text.length / 4);

/** Estimated USD for a number of tokens. */
export const costUsd = (tokensIn: number, tokensOut: number, c: Pick<AssistantConfig, 'priceInPerM' | 'priceOutPerM'>) => (tokensIn * c.priceInPerM + tokensOut * c.priceOutPerM) / 1e6;
