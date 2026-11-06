// AI assistant callables (decision 0028): aiAssistant (ask) and aiUsageNow
// (the meter). The rules are in aiServer.ts; this file is only Firestore and
// the HTTPS wrapper.
//
// Where things live (all written only here; the rules let no app write them):
//   tenants/{t}/aiUsage/{day}     today's allowance for one farm (members may read)
//   tenants/{t}/aiCache/{hash}    recent answers of that farm only (no app may read)
//   aiRate/{uid}                  questions per minute per person
//   aiStats/{day}                 totals for the AI Control Centre
//   aiStats/{day}/farms/{t}       the same per farm
//   aiErrors/{id}                 provider errors for admins (expireAt: set a TTL policy)
//
// Nothing is deployed or switched on by this code: the apps keep calling
// Gemini themselves until platform/config.ai.assistant.route is 'server'.

import { randomUUID } from 'node:crypto';
import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions';
import { HttpsError, onCall, type FunctionsErrorCode } from 'firebase-functions/v2/https';
import { usageFrom, type UsageDoc } from './shared/aiQuota';
import { providerFor } from './aiProviders';
import { AiFail, runAsk, usageNow, type AiStore, type Deps, type ServerKind } from './aiServer';
import { db, secret } from './server';

const firestoreStore: AiStore = {
  async aiConfig() {
    return (await db().doc('platform/config').get()).get('ai');
  },
  async memberRole(t, uid) {
    const m = await db().doc(`tenants/${t}/members/${uid}`).get();
    if (!m.exists) return null;
    const role = m.get('role');
    return typeof role === 'string' ? role : 'worker';
  },
  async farm(t) {
    const f = await db().doc(`tenants/${t}`).get();
    if (!f.exists) return { exists: false, aiOn: false, open: false };
    return { exists: true, aiOn: f.get('features.ai') !== false, open: f.get('status') !== 'suspended' && f.get('closure') == null };
  },
  async usage(t, day, fn) {
    const ref = db().doc(`tenants/${t}/aiUsage/${day}`);
    return db().runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      const cur = usageFrom(snap.data(), day);
      const { next, out } = fn(cur);
      if (next === cur) return out; // a read: nothing to write
      const doc: UsageDoc & { tenantId: string; updatedAt: FieldValue } = { ...next, day, tenantId: t, updatedAt: FieldValue.serverTimestamp() };
      tx.set(ref, doc);
      return out;
    });
  },
  async rateHit(uid, minute, max) {
    const ref = db().doc(`aiRate/${uid}`);
    return db().runTransaction(async (tx) => {
      const s = await tx.get(ref);
      const n = s.get('minute') === minute ? Number(s.get('n') ?? 0) : 0;
      if (n >= max) return false;
      tx.set(ref, { minute, n: n + 1, expireAt: Timestamp.fromMillis(Date.now() + 86400_000) });
      return true;
    });
  },
  async cacheGet(t, key, nowMs) {
    const s = await db().doc(`tenants/${t}/aiCache/${key}`).get();
    if (!s.exists) return null;
    const exp = s.get('expireAt') as Timestamp | undefined;
    if (!exp || exp.toMillis() <= nowMs || typeof s.get('text') !== 'string') return null;
    return { text: s.get('text'), grounding: s.get('grounding') ?? null, model: String(s.get('model') ?? '') };
  },
  async cachePut(t, key, hit, expiresMs) {
    await db().doc(`tenants/${t}/aiCache/${key}`).set({ ...hit, tenantId: t, createdAt: FieldValue.serverTimestamp(), expireAt: Timestamp.fromMillis(expiresMs) });
  },
  async stat(e) {
    const inc = FieldValue.increment;
    const day: Record<string, unknown> = { day: e.day, [e.outcome]: inc(1), total: inc(e.outcome === 'disabled' || e.outcome === 'invalid' ? 0 : 1), updatedAt: FieldValue.serverTimestamp() };
    const farm: Record<string, unknown> = { tenantId: e.tenantId, day: e.day, [e.outcome]: inc(1), updatedAt: FieldValue.serverTimestamp() };
    if (e.outcome === 'ok') {
      Object.assign(day, { msOk: inc(e.ms ?? 0), tokensIn: inc(e.tokensIn ?? 0), tokensOut: inc(e.tokensOut ?? 0), costUsd: inc(e.costUsd ?? 0), lastOkAt: FieldValue.serverTimestamp() });
      if (e.model) day[`byModel.${e.model.replace(/[^\w-]/g, '_')}`] = inc(1);
      Object.assign(farm, { tokensIn: inc(e.tokensIn ?? 0), tokensOut: inc(e.tokensOut ?? 0) });
    }
    if (e.outcome === 'failed') Object.assign(day, { [`byKind.${e.kind ?? 'unavailable'}`]: inc(1), lastFailAt: FieldValue.serverTimestamp(), lastFailKind: e.kind ?? 'unavailable' });
    const b = db().batch();
    b.set(db().doc(`aiStats/${e.day}`), day, { merge: true });
    if (e.tenantId) b.set(db().doc(`aiStats/${e.day}/farms/${e.tenantId}`), farm, { merge: true });
    await b.commit().catch((err) => logger.warn('aiStats write failed', { err: String(err) }));
  },
  async logError(e) {
    logger.error('AI provider error', { tenantId: e.tenantId, kind: e.kind, status: e.status, model: e.model, detail: e.detail });
    await db().collection('aiErrors').add({ ...e, at: FieldValue.serverTimestamp(), expireAt: Timestamp.fromMillis(Date.now() + 30 * 86400_000) });
  },
  async geminiKey() {
    return process.env.GEMINI_API_KEY?.trim() || (await secret('gemini_api_key'));
  },
};

const deps: Deps = {
  store: firestoreStore,
  provider: (id, key) => providerFor(id, { gemini: key }),
  now: () => Date.now(),
  sleep: (ms) => new Promise((ok) => setTimeout(ok, ms)),
  rand: () => Math.random(),
  newId: () => randomUUID(),
};

const CODE: Record<ServerKind, FunctionsErrorCode> = {
  limit: 'resource-exhausted',
  capacity: 'resource-exhausted',
  tooFast: 'resource-exhausted',
  disabled: 'failed-precondition',
  invalid: 'invalid-argument',
  timeout: 'deadline-exceeded',
  network: 'unavailable',
  unavailable: 'unavailable',
  forbidden: 'permission-denied',
};

/** Plain words only: the apps show their own text for each kind. */
function toHttps(e: unknown): HttpsError {
  if (e instanceof HttpsError) return e;
  if (e instanceof AiFail) return new HttpsError(CODE[e.kind], e.kind, { kind: e.kind, usage: e.usage });
  logger.error('aiAssistant crashed', { err: String((e as Error)?.stack ?? e).slice(0, 2000) });
  return new HttpsError('internal', 'unavailable', { kind: 'unavailable', usage: null });
}

/** Ask the AI. Streams the text so far as { text } chunks when the app asks for streaming. */
export const aiAssistant = onCall({ timeoutSeconds: 150, memory: '512MiB', maxInstances: 20, concurrency: 40 }, async (req, res) => {
  if (!req.auth) throw new HttpsError('unauthenticated', 'forbidden', { kind: 'forbidden', usage: null });
  try {
    let lastSent = 0;
    const onText = req.acceptsStreaming
      ? (soFar: string) => {
          // At most a few chunks a second; an empty text means "start again" (a retry).
          if (soFar && Date.now() - lastSent < 250) return;
          lastSent = Date.now();
          void res?.sendChunk({ text: soFar });
        }
      : undefined;
    return await runAsk(req.data, req.auth.uid, deps, onText);
  } catch (e) {
    throw toHttps(e);
  }
});

/** Today's allowance for the meter. Free: it never uses an AI answer. */
export const aiUsageNow = onCall({ timeoutSeconds: 20, maxInstances: 20, concurrency: 80 }, async (req) => {
  if (!req.auth) throw new HttpsError('unauthenticated', 'forbidden', { kind: 'forbidden', usage: null });
  try {
    return await usageNow(req.data, req.auth.uid, deps);
  } catch (e) {
    throw toHttps(e);
  }
});
