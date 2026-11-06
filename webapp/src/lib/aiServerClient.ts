'use client';

// The web's way to the server AI assistant (decision 0028): functions/src/ai.ts.
// The server checks the person, the farm and the daily allowance, picks the
// model and holds the key. This file only sends the question, streams the
// text back and turns failures into one of the kinds in shared/aiQuota.ts.

import { httpsCallable } from 'firebase/functions';
import { functions } from './firebase.ts';
import { isAiErrorKind, type AiErrorKind, type UsageView } from '@/shared/aiQuota';
import type { ChatGrounding } from '@/shared/aiChat';

export interface ServerAsk {
  tenantId: string;
  message: string;
  facts: string[];
  calculated: string | null;
  history: { role: 'user' | 'model'; text: string }[];
  files: { mime: string; base64: string }[];
  language: string | null;
  search: boolean;
}

export interface ServerAnswer {
  text: string;
  grounding: ChatGrounding | null;
  model: string;
  cached: boolean;
  usage: UsageView;
}

/** A failed AI request: the kind decides the message; usage is the server's count when it sent one. */
export class AiRequestError extends Error {
  constructor(
    readonly kind: AiErrorKind,
    readonly usage: UsageView | null = null,
  ) {
    super(kind);
  }
}

/** Sorts a Firebase Functions error into a kind. Never shows the raw text. */
export function kindOfCallError(e: unknown): { kind: AiErrorKind; usage: UsageView | null } {
  const err = e as { code?: string; details?: { kind?: unknown; usage?: UsageView | null }; name?: string; message?: string };
  const usage = err?.details?.usage ?? null;
  if (isAiErrorKind(err?.details?.kind)) return { kind: err.details!.kind as AiErrorKind, usage };
  if (typeof navigator !== 'undefined' && !navigator.onLine) return { kind: 'network', usage };
  switch (err?.code) {
    case 'functions/deadline-exceeded':
      return { kind: 'timeout', usage };
    case 'functions/resource-exhausted':
      return { kind: 'capacity', usage };
    case 'functions/invalid-argument':
      return { kind: 'invalid', usage };
    case 'functions/failed-precondition':
      return { kind: 'disabled', usage };
    case 'functions/unavailable':
      return { kind: /network|fetch/i.test(err.message ?? '') ? 'network' : 'unavailable', usage };
    default:
      return { kind: 'unavailable', usage };
  }
}

/** Asks the server; `onText` gets the whole text so far as it streams in ('' means it started again). */
export async function askServer(input: ServerAsk, opts: { onText?: (soFar: string) => void; signal?: AbortSignal; timeoutMs: number }): Promise<ServerAnswer> {
  const call = httpsCallable<ServerAsk, ServerAnswer, { text: string }>(functions(), 'aiAssistant', { timeout: opts.timeoutMs + 30000 });
  try {
    const res = await call.stream(input, { signal: opts.signal });
    for await (const chunk of res.stream) opts.onText?.(chunk?.text ?? '');
    return await res.data;
  } catch (e) {
    if ((e as Error)?.name === 'AbortError' || opts.signal?.aborted) throw new DOMException('stopped', 'AbortError');
    const { kind, usage } = kindOfCallError(e);
    throw new AiRequestError(kind, usage);
  }
}

/** Today's allowance from the server (free: no AI answer is used). */
export async function serverUsage(tenantId: string): Promise<(UsageView & { enabled: boolean; route: string }) | null> {
  try {
    const call = httpsCallable<{ tenantId: string }, UsageView & { enabled: boolean; route: string }>(functions(), 'aiUsageNow', { timeout: 15000 });
    return (await call({ tenantId })).data;
  } catch {
    return null;
  }
}
