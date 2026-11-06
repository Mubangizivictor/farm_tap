// FarmTap AI — which layer answers a question (decision 0028).
//
//   records  (layer 1): plain look-ups in the farm's records ("How many cows do I have?")
//   insight  (layer 2): calculations, statistics and rules ("Which cows have reduced production?")
//   ai       (layer 3): needs an AI model to reason or explain ("Why is milk production declining?")
//
// Layers 1 and 2 never call a model and never use the daily allowance. A
// question goes to the AI only when it asks for reasoning, carries a file, or
// nothing built in can answer it. When unsure and a built-in answer exists,
// the built-in answer wins: a reliable number beats a guessed paragraph.

import { ask, type Answer } from './aiAssistant.ts';
import { seesMoney, type AiConfig, type FarmRole } from './aiAccess.ts';
import type { FarmData } from './aiData.ts';
import { askInsight } from './aiInsights.ts';

export type Layer = 'records' | 'insight' | 'ai';

export interface Route {
  layer: Layer;
  /** Why: 'empty' and 'tooLong' are refused before anything runs. */
  reason: 'empty' | 'tooLong' | 'files' | 'reasoning' | 'matched' | 'unknown';
  /** The built-in answer when one exists (also sent to the AI as facts). */
  answer: Answer | null;
}

/** Built-in answers that are look-ups, not analysis. */
const RECORD_INTENTS = new Set(['herdSize', 'withdrawal', 'pregnant']);

/**
 * Words that ask for reasoning, explanation or advice. "What should we do
 * today" stays built-in (it is the priorities list).
 */
const REASONING =
  /\b(why|explain\w*|recommend\w*|advi[cs]e\w*|suggest\w*|improv\w*|cause[sd]?|causing|reasons?|symptoms?|interpret\w*|help me understand|what does .+ mean|tips?|best way|how (can|could|do|should) (i|we) (increase|reduce|improve|fix|stop|prevent|treat|raise|boost|get)|should i (sell|buy|cull|keep|change|switch)|is it (good|bad|normal|safe)|what (might|could) be)\b/i;

/** Answers from records first; [answerInternally] runs them both. */
export function answerInternally(question: string, d: FarmData, opts: { role: FarmRole; cfg: AiConfig; farmAiOn?: boolean }): Answer {
  const extra = askInsight(question, d, { seesMoney: seesMoney(opts.role) });
  if (extra) return { intent: extra.intent, ok: extra.ok, text: extra.text, bullets: extra.bullets, links: extra.links, method: extra.method };
  return ask(question, d, opts);
}

/** Picks the layer. Pure and quick: safe to run on every keystroke. */
export function classify(
  question: string,
  d: FarmData,
  opts: { role: FarmRole; cfg: AiConfig; farmAiOn?: boolean; files?: number; maxChars?: number },
): Route {
  const q = question.trim();
  if (!q && !opts.files) return { layer: 'insight', reason: 'empty', answer: null };
  if (opts.maxChars && q.length > opts.maxChars) return { layer: 'ai', reason: 'tooLong', answer: null };
  const a = q ? answerInternally(q, d, opts) : null;
  const known = a && a.intent !== 'unknown' && a.intent !== 'empty' ? a : null;
  if (opts.files) return { layer: 'ai', reason: 'files', answer: known };
  if (REASONING.test(q)) return { layer: 'ai', reason: 'reasoning', answer: known };
  if (known) return { layer: RECORD_INTENTS.has(known.intent) ? 'records' : 'insight', reason: 'matched', answer: known };
  return { layer: 'ai', reason: 'unknown', answer: null };
}

/** What the screen says while it works. Built-in answers come at once, without a spinner. */
export function workingText(layer: Layer, step: 'start' | 'model' = 'start'): string {
  if (layer === 'records') return 'Checking your farm records...';
  if (layer === 'insight') return 'Analysing production data...';
  return step === 'model' ? 'Preparing your AI response...' : 'Checking your farm records...';
}

/** The label under an answer, so a calculation is never mistaken for AI and the other way round. */
export function layerLabel(layer: Layer): string {
  return layer === 'ai' ? 'AI-generated: check important advice with your vet or adviser' : 'Calculated from your farm records';
}
