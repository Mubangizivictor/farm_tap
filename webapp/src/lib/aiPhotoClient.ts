'use client';

// The web's call to Google Gemini through Firebase AI Logic (decision 0026).
// The Firebase project holds the key, this page holds none. App Check proves
// the request comes from the real FarmTap site; it is switched on when the
// site key NEXT_PUBLIC_APPCHECK_SITE_KEY is set. Whatever comes back goes
// through readPhotoReply() (shared/aiPhoto.ts) before anyone reads it.

import { getApp } from 'firebase/app';
import { initializeAppCheck, ReCaptchaV3Provider } from 'firebase/app-check';
import { getAI, getGenerativeModel, GoogleAIBackend } from 'firebase/ai';
import { firebase } from './firebase.ts';

export type PhotoFailure = 'network' | 'busy' | 'appCheck' | 'unreadable';

let appCheckDone = false;
export function startAppCheck() {
  if (appCheckDone) return;
  appCheckDone = true;
  const key = process.env.NEXT_PUBLIC_APPCHECK_SITE_KEY;
  if (!key) return;
  try {
    initializeAppCheck(getApp(), { provider: new ReCaptchaV3Provider(key), isTokenAutoRefreshEnabled: true });
  } catch {
    /* already started */
  }
}

/** Sends one photo and returns the model's text. Throws a PhotoFailure word. */
export async function analyzePhoto(opts: { base64: string; mime: string; prompt: string; system: string; model: string }): Promise<string> {
  firebase();
  startAppCheck();
  try {
    const model = getGenerativeModel(getAI(getApp(), { backend: new GoogleAIBackend() }), {
      model: opts.model,
      systemInstruction: opts.system,
      generationConfig: { responseMimeType: 'application/json', temperature: 0.2, maxOutputTokens: 1500 },
    });
    const run = model.generateContent([opts.prompt, { inlineData: { mimeType: opts.mime, data: opts.base64 } }]);
    const res = await Promise.race([run, new Promise<never>((_, no) => setTimeout(() => no(new Error('timeout')), 60000))]);
    const text = res.response.text();
    if (!text.trim()) throw new Error('empty');
    return text;
  } catch (e) {
    throw new Error(photoFailureOf(e));
  }
}

/** Plain word for what went wrong. */
export function photoFailureOf(e: unknown): PhotoFailure {
  const m = String((e as Error)?.message ?? e).toLowerCase();
  if (m.includes('app check') || m.includes('app-check') || m.includes('appcheck') || m.includes('403') || m.includes('permission')) return 'appCheck';
  if (m.includes('429') || m.includes('quota') || m.includes('resource') || m.includes('503') || m.includes('overload') || m.includes('timeout')) return 'busy';
  if (m.includes('network') || m.includes('fetch') || m.includes('offline')) return 'network';
  if (m === 'network' || m === 'busy' || m === 'appcheck' || m === 'unreadable') return m === 'appcheck' ? 'appCheck' : (m as PhotoFailure);
  return 'unreadable';
}
