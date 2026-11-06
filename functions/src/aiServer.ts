// The server side of the AI assistant (decision 0028): who may ask, the
// farm's daily allowance, the cache, the provider call and the monitoring
// numbers. Firestore is behind the AiStore interface (ai.ts has the real
// one), so all of this is tested without a database (aiServer.test.ts).
//
// Order of checks, cheapest first; nothing below the allowance line costs an
// AI answer unless the provider really answers:
//   1. AI switched on (platform/config.ai.assistant)  -> 'disabled'
//   2. the person is a member of the farm             -> permission-denied
//   3. the farm has AI and is open                     -> 'disabled'
//   4. the request is well formed and not too long    -> 'invalid'
//   5. not more than N questions a minute per person   -> 'tooFast'
//   6. the same question and facts answered lately     -> cached answer, free
//   ---- allowance: one answer reserved in a transaction ('limit' when none left)
//   7. the provider (models in turn, retries with back-off)
//   8. answer: the reservation counts. failure: it is given back.

import { createHash } from 'node:crypto';
import {
  assistantConfigFrom,
  backoffMs,
  commit,
  costUsd,
  MAX_RETRIES,
  nextResetMs,
  quotaDay,
  release,
  reserve,
  retryable,
  roughTokens,
  usageView,
  type AiErrorKind,
  type AssistantConfig,
  type UsageDoc,
  type UsageView,
} from './shared/aiQuota';
import { CHAT_ENGINE, CHAT_LANGUAGES, CHAT_MAX_BYTES, CHAT_MAX_FILES, CHAT_SYSTEM, buildChatPrompt, chatFileKind, chatHistory, chatModels, cleanSources, type ChatGrounding } from './shared/aiChat';
import { AiProviderError, type AiFile, type AiProvider, type AiTurn } from './aiProviders';

/** Errors the apps show (shared/aiQuota.ts AI_ERROR_KINDS) plus the abuse guard. */
export type ServerKind = AiErrorKind | 'forbidden';

export class AiFail extends Error {
  constructor(
    readonly kind: ServerKind,
    readonly usage: UsageView | null = null,
  ) {
    super(kind);
  }
}

// ---------------------------------------------------------------- Store

export interface FarmInfo {
  exists: boolean;
  aiOn: boolean;
  open: boolean;
}

export interface StatEvent {
  day: string;
  tenantId: string;
  outcome: 'ok' | 'failed' | 'cached' | 'limit' | 'disabled' | 'invalid' | 'tooFast';
  kind?: ServerKind;
  model?: string;
  ms?: number;
  tokensIn?: number;
  tokensOut?: number;
  costUsd?: number;
}

export interface CacheHit {
  text: string;
  grounding: ChatGrounding | null;
  model: string;
}

export interface AiStore {
  /** platform/config.ai */
  aiConfig(): Promise<unknown>;
  /** The member's role, or null when the person is not on this farm. */
  memberRole(tenantId: string, uid: string): Promise<string | null>;
  farm(tenantId: string): Promise<FarmInfo>;
  /** Runs [fn] on tenants/{t}/aiUsage/{day} in a transaction and writes what it returns. */
  usage<T>(tenantId: string, day: string, fn: (cur: UsageDoc) => { next: UsageDoc; out: T }): Promise<T>;
  /** Counts one question for [uid] in the minute [minute]; false when over [max]. Transactional. */
  rateHit(uid: string, minute: string, max: number): Promise<boolean>;
  cacheGet(tenantId: string, key: string, nowMs: number): Promise<CacheHit | null>;
  cachePut(tenantId: string, key: string, hit: CacheHit, expiresMs: number): Promise<void>;
  stat(e: StatEvent): Promise<void>;
  /** Technical details for admins (aiErrors). Never shown to farmers. */
  logError(e: { day: string; tenantId: string; kind: ServerKind; status: number; model: string; detail: string }): Promise<void>;
  geminiKey(): Promise<string>;
}

export interface Deps {
  store: AiStore;
  provider: (id: string, key: string) => AiProvider;
  now: () => number;
  sleep: (ms: number) => Promise<void>;
  rand: () => number;
  newId: () => string;
}

// ---------------------------------------------------------------- Request

export interface AskInput {
  tenantId: string;
  /** The farmer's words, names already replaced by labels on the device. */
  message: string;
  /** Facts from the farm's records about the animal asked about (no names). */
  facts: string[];
  /** FarmTap's own calculated answer, when it had one. */
  calculated: string | null;
  history: AiTurn[];
  files: AiFile[];
  language: string | null;
  search: boolean;
}

const str = (v: unknown, max: number) => (typeof v === 'string' && v.length <= max ? v : null);
const B64 = /^[A-Za-z0-9+/]+={0,2}$/;
// Strict phone and email patterns only: farm facts contain dates and litres that must not be touched.
const PHONE = /(?:\+?256|\b0)7\d{2}[\s-]?\d{3}[\s-]?\d{3}\b/g;
const EMAIL = /[\w.+-]+@[\w-]+\.[\w.]+/g;
const scrubPersonal = (t: string) => t.replace(EMAIL, '[email]').replace(PHONE, '[phone]');

/** Checks every field. Returns null for anything malformed (no allowance is used). */
export function parseAsk(data: unknown, cfg: AssistantConfig): AskInput | null {
  if (!data || typeof data !== 'object') return null;
  const d = data as Record<string, unknown>;
  const tenantId = typeof d.tenantId === 'string' && /^[\w-]{1,128}$/.test(d.tenantId) ? d.tenantId : null;
  const message = str(d.message, cfg.maxChars)?.trim() ?? null;
  if (!tenantId || !message) return null;
  const facts = Array.isArray(d.facts) ? d.facts : [];
  if (facts.length > 20 || facts.some((f) => str(f, 400) == null)) return null;
  const calculated = d.calculated == null ? null : str(d.calculated, 4000);
  if (d.calculated != null && calculated == null) return null;
  const history = Array.isArray(d.history) ? d.history : [];
  if (history.length > 16) return null;
  const turns: AiTurn[] = [];
  for (const h of history) {
    const o = h as Record<string, unknown>;
    const text = str(o?.text, 4000);
    if ((o?.role !== 'user' && o?.role !== 'model') || text == null) return null;
    turns.push({ role: o.role, text: scrubPersonal(text) });
  }
  const files = Array.isArray(d.files) ? d.files : [];
  if (files.length > CHAT_MAX_FILES) return null;
  let bytes = 0;
  const parts: AiFile[] = [];
  for (const f of files) {
    const o = f as Record<string, unknown>;
    if (typeof o?.mime !== 'string' || !chatFileKind(o.mime) || typeof o.base64 !== 'string' || !o.base64 || !B64.test(o.base64)) return null;
    bytes += Math.floor((o.base64.length * 3) / 4);
    parts.push({ mime: o.mime.toLowerCase(), base64: o.base64 });
  }
  if (bytes > CHAT_MAX_BYTES) return null;
  const language = d.language == null || d.language === 'auto' ? null : CHAT_LANGUAGES.some((l) => l.id === d.language) ? (d.language as string) : null;
  return {
    tenantId,
    message: scrubPersonal(message),
    facts: (facts as string[]).map(scrubPersonal),
    calculated: calculated == null ? null : scrubPersonal(calculated),
    history: chatHistory(turns),
    files: parts,
    language,
    search: d.search === true,
  };
}

/** The prompt and history, trimmed to the input cap (oldest turns go first). Null when even the question alone is too long. */
export function fitInput(i: AskInput, cfg: AssistantConfig): { prompt: string; history: AiTurn[] } | null {
  const prompt = buildChatPrompt({ message: i.message, facts: i.facts, calculated: i.calculated, files: i.files.map((f) => ({ kind: chatFileKind(f.mime)! })), search: i.search, language: i.language });
  let history = [...i.history];
  const size = () => roughTokens(CHAT_SYSTEM) + roughTokens(prompt) + history.reduce((t, h) => t + roughTokens(h.text), 0);
  while (history.length && size() > cfg.maxInputTokens) history = chatHistory(history.slice(2));
  return size() > cfg.maxInputTokens ? null : { prompt, history };
}

/** Same farm, same model list, same prompt, same history: same answer. Never shared between farms. */
export function cacheKey(tenantId: string, models: string[], prompt: string, history: AiTurn[]): string {
  return createHash('sha256').update(JSON.stringify([CHAT_ENGINE, tenantId, models, prompt, history])).digest('hex');
}

export interface AskOutput {
  text: string;
  grounding: ChatGrounding | null;
  model: string;
  cached: boolean;
  usage: UsageView;
}

const minuteOf = (ms: number) => new Date(ms).toISOString().slice(0, 16);

// ---------------------------------------------------------------- Usage now

/** Today's allowance for a farm the person belongs to (for the meter in the chat). */
export async function usageNow(data: unknown, uid: string, deps: Deps): Promise<UsageView & { enabled: boolean; route: string }> {
  const tenantId = data && typeof data === 'object' ? (data as Record<string, unknown>).tenantId : null;
  if (typeof tenantId !== 'string' || !/^[\w-]{1,128}$/.test(tenantId)) throw new AiFail('invalid');
  if (!(await deps.store.memberRole(tenantId, uid))) throw new AiFail('forbidden');
  const cfg = assistantConfigFrom(await deps.store.aiConfig());
  const now = deps.now();
  const day = quotaDay(now, cfg.timezone);
  const resetAt = nextResetMs(now, cfg.timezone);
  const used = await deps.store.usage(tenantId, day, (cur) => ({ next: cur, out: cur.used }));
  return { ...usageView(used, cfg.dailyLimit, cfg.warnPct, resetAt), enabled: cfg.enabled, route: cfg.route };
}

// ---------------------------------------------------------------- Ask

export async function runAsk(data: unknown, uid: string, deps: Deps, onText?: (soFar: string) => void): Promise<AskOutput> {
  const { store } = deps;
  const started = deps.now();
  const cfg = assistantConfigFrom(await store.aiConfig());
  const day = quotaDay(started, cfg.timezone);
  const resetAt = nextResetMs(started, cfg.timezone);
  const tenantGuess = data && typeof data === 'object' && typeof (data as Record<string, unknown>).tenantId === 'string' ? ((data as Record<string, unknown>).tenantId as string).slice(0, 128) : '';

  // 1 to 3: who and whether
  if (!uid) throw new AiFail('forbidden');
  if (!tenantGuess || !(await store.memberRole(tenantGuess, uid))) throw new AiFail('forbidden');
  if (!cfg.enabled || cfg.dailyLimit <= 0) {
    await store.stat({ day, tenantId: tenantGuess, outcome: 'disabled' });
    throw new AiFail('disabled');
  }
  const farm = await store.farm(tenantGuess);
  if (!farm.exists || !farm.aiOn || !farm.open) {
    await store.stat({ day, tenantId: tenantGuess, outcome: 'disabled' });
    throw new AiFail('disabled');
  }
  // 4: well formed
  const input = parseAsk(data, cfg);
  const fitted = input ? fitInput(input, cfg) : null;
  if (!input || !fitted) {
    await store.stat({ day, tenantId: tenantGuess, outcome: 'invalid' });
    throw new AiFail('invalid');
  }
  const t = input.tenantId;
  // 5: abuse guard
  if (!(await store.rateHit(uid, minuteOf(started), cfg.perUserPerMinute))) {
    await store.stat({ day, tenantId: t, outcome: 'tooFast' });
    throw new AiFail('tooFast');
  }
  const media = input.files.some((f) => /^(image|video)\//.test(f.mime));
  const models = chatModels(cfg.model, media);
  const view = (used: number) => usageView(used, cfg.dailyLimit, cfg.warnPct, resetAt);

  // 6: cache (questions without files only)
  const key = cfg.cacheHours > 0 && !input.files.length ? cacheKey(t, models, fitted.prompt, fitted.history) : null;
  if (key) {
    const hit = await store.cacheGet(t, key, started);
    if (hit) {
      const used = await store.usage(t, day, (cur) => ({ next: cur, out: cur.used }));
      await store.stat({ day, tenantId: t, outcome: 'cached', model: hit.model, ms: deps.now() - started });
      return { ...hit, cached: true, usage: view(used) };
    }
  }

  // Allowance: reserve one answer
  const rid = deps.newId();
  const holdMs = cfg.timeoutMs * 2 + 30000;
  const got = await store.usage(t, day, (cur) => {
    const r = reserve(cur, { id: rid, nowMs: started, limit: cfg.dailyLimit, holdMs, resetAt });
    return { next: r.next, out: r };
  });
  if (!got.ok) {
    await store.stat({ day, tenantId: t, outcome: got.reason === 'limit' ? 'limit' : 'disabled' });
    throw new AiFail(got.reason, view(got.next.used));
  }

  // 7: the provider
  const provider = deps.provider(cfg.provider, cfg.provider === 'gemini' ? await store.geminiKey() : '');
  const plan: [string, boolean][] = [];
  for (const m of models) {
    if (input.search && !media) plan.push([m, true]);
    plan.push([m, false]);
  }
  const deadline = started + cfg.timeoutMs;
  let last: AiProviderError | null = null;
  let attempt = 0;
  for (const [model, search] of plan) {
    if (attempt > MAX_RETRIES || deps.now() >= deadline) break;
    if (attempt > 0) {
      onText?.('');
      await deps.sleep(backoffMs(attempt - 1, deps.rand()));
      if (deps.now() >= deadline) break;
    }
    attempt++;
    try {
      const res = await provider.generate({
        model,
        system: CHAT_SYSTEM,
        history: fitted.history,
        prompt: fitted.prompt,
        files: input.files,
        search,
        maxOutputTokens: cfg.maxOutputTokens,
        timeoutMs: Math.max(1000, deadline - deps.now()),
        onText,
      });
      const grounding: ChatGrounding | null = res.grounding ? { queries: res.grounding.queries, sources: cleanSources(res.grounding.sources), suggestionsHtml: res.grounding.suggestionsHtml } : null;
      // 8: it counts
      const used = await store.usage(t, day, (cur) => {
        const next = commit(cur, rid);
        return { next, out: next.used };
      });
      const tokensIn = res.tokensIn ?? roughTokens(CHAT_SYSTEM + fitted.prompt) + fitted.history.reduce((n, h) => n + roughTokens(h.text), 0);
      const tokensOut = res.tokensOut ?? roughTokens(res.text);
      await store.stat({ day, tenantId: t, outcome: 'ok', model, ms: deps.now() - started, tokensIn, tokensOut, costUsd: costUsd(tokensIn, tokensOut, cfg) });
      if (key) await store.cachePut(t, key, { text: res.text, grounding, model }, deps.now() + cfg.cacheHours * 3600_000).catch(() => undefined);
      return { text: res.text, grounding, model, cached: false, usage: view(used) };
    } catch (e) {
      last = e instanceof AiProviderError ? e : new AiProviderError('unavailable', 0, String((e as Error)?.message ?? e).slice(0, 600));
      await store.logError({ day, tenantId: t, kind: last.kind, status: last.status, model, detail: last.detail }).catch(() => undefined);
      // A blocked question or a timeout will not get better by asking again.
      if (last.kind === 'invalid' && !search) break;
      if (last.kind === 'timeout') break;
      if (!retryable(last.kind) && last.kind !== 'invalid') break;
    }
  }
  // 8: give the reservation back
  const kind: AiErrorKind = last?.kind ?? 'timeout';
  const used = await store.usage(t, day, (cur) => {
    const next = release(cur, rid);
    return { next, out: next.used };
  });
  await store.stat({ day, tenantId: t, outcome: 'failed', kind, model: models[0], ms: deps.now() - started });
  throw new AiFail(kind, view(used));
}
