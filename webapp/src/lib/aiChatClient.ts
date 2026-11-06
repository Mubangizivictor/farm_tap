'use client';

// The web's chat call to Google Gemini through Firebase AI Logic (decision
// 0027). Same rules as aiPhotoClient.ts: the Firebase project holds the key,
// App Check proves the request comes from the real FarmTap site, and the
// reply goes through readChatReply() (shared/aiChat.ts) before anyone reads it.

import { getApp } from 'firebase/app';
import { getAI, getGenerativeModel, GoogleAIBackend, type Content } from 'firebase/ai';
import { firebase } from './firebase.ts';
import { photoFailureOf, startAppCheck, type PhotoFailure } from './aiPhotoClient.ts';

export interface ChatTurn {
  role: 'user' | 'model';
  /** Already through redact(). */
  text: string;
}
export interface ChatPart {
  mime: string;
  base64: string;
}

/** Sends the conversation so far, the new question and any files. Throws a failure word. */
export async function askGemini(opts: { system: string; history: ChatTurn[]; prompt: string; files: ChatPart[]; model: string }): Promise<string> {
  firebase();
  startAppCheck();
  try {
    const model = getGenerativeModel(getAI(getApp(), { backend: new GoogleAIBackend() }), {
      model: opts.model,
      systemInstruction: opts.system,
      generationConfig: { temperature: 0.4, maxOutputTokens: 1500 },
    });
    const contents: Content[] = [
      ...opts.history.map((h): Content => ({ role: h.role, parts: [{ text: h.text }] })),
      { role: 'user', parts: [{ text: opts.prompt }, ...opts.files.map((f) => ({ inlineData: { mimeType: f.mime, data: f.base64 } }))] },
    ];
    const run = model.generateContent({ contents });
    const res = await Promise.race([run, new Promise<never>((_, no) => setTimeout(() => no(new Error('timeout')), 90000))]);
    const text = res.response.text();
    if (!text.trim()) throw new Error('empty');
    return text;
  } catch (e) {
    throw new Error(photoFailureOf(e));
  }
}

export type { PhotoFailure as ChatFailure };
