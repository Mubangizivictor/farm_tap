'use client';

// The web's chat call to Google Gemini through Firebase AI Logic (decision
// 0027). Same rules as aiPhotoClient.ts: the Firebase project holds the key,
// App Check proves the request comes from the real FarmTap site, and the
// reply goes through readChatReply() (shared/aiChat.ts) before anyone reads it.
//
// Answers use Google Search (grounding) so general farming questions get
// current, sourced replies. If Google Search is not allowed for the model the
// question is asked again without it, so the farmer still gets an answer.

import { getApp } from 'firebase/app';
import { getAI, getGenerativeModel, GoogleAIBackend, type Content } from 'firebase/ai';
import { firebase } from './firebase.ts';
import { startAppCheck } from './aiPhotoClient.ts';
import { chatFailureOf, cleanSources, type ChatFailure, type ChatGrounding } from '@/shared/aiChat';

export interface ChatTurn {
  role: 'user' | 'model';
  /** Already through redact(). */
  text: string;
}
export interface ChatPart {
  mime: string;
  base64: string;
}

export type { ChatFailure };

/** What went wrong, in one word, and the real message for the Details line. */
export class ChatError extends Error {
  constructor(
    readonly failure: ChatFailure,
    readonly detail: string,
  ) {
    super(failure);
  }
}

interface Meta {
  webSearchQueries?: string[];
  searchEntryPoint?: { renderedContent?: string };
  groundingChunks?: { web?: { uri?: string; title?: string } }[];
}

/** Sends the conversation so far, the new question and any files. Throws ChatError. */
export async function askGemini(opts: {
  system: string;
  history: ChatTurn[];
  prompt: string;
  files: ChatPart[];
  model: string;
  signal?: AbortSignal;
}): Promise<{ text: string; grounding: ChatGrounding | null }> {
  firebase();
  startAppCheck();
  const contents: Content[] = [
    ...opts.history.map((h): Content => ({ role: h.role, parts: [{ text: h.text }] })),
    { role: 'user', parts: [{ text: opts.prompt }, ...opts.files.map((f) => ({ inlineData: { mimeType: f.mime, data: f.base64 } }))] },
  ];
  const run = async (search: boolean) => {
    const model = getGenerativeModel(getAI(getApp(), { backend: new GoogleAIBackend() }), {
      model: opts.model,
      systemInstruction: opts.system,
      generationConfig: { temperature: 0.4, maxOutputTokens: 1500 },
      ...(search ? { tools: [{ googleSearch: {} }] } : {}),
    });
    let timer: ReturnType<typeof setTimeout> | undefined;
    const limit = new Promise<never>((_, no) => {
      timer = setTimeout(() => no(new Error('timeout')), 90000);
    });
    const abort = new Promise<never>((_, no) => opts.signal?.addEventListener('abort', () => no(new DOMException('stopped', 'AbortError'))));
    try {
      return await Promise.race([model.generateContent({ contents }), limit, abort]);
    } finally {
      clearTimeout(timer);
    }
  };
  try {
    let res;
    let searched = true;
    try {
      res = await run(true);
    } catch (e) {
      const f = chatFailureOf(String((e as Error)?.message ?? e));
      if ((e as Error)?.name === 'AbortError' || f === 'network' || f === 'appCheck') throw e;
      searched = false;
      res = await run(false);
    }
    let text: string;
    try {
      text = res.response.text();
    } catch (e) {
      throw new ChatError('blocked', String((e as Error)?.message ?? e));
    }
    if (!text.trim()) throw new ChatError('unreadable', 'The model sent an empty answer.');
    const meta = searched ? (res.response.candidates?.[0]?.groundingMetadata as Meta | undefined) : undefined;
    const sources = cleanSources((meta?.groundingChunks ?? []).map((c) => ({ uri: c.web?.uri, title: c.web?.title })));
    const grounding: ChatGrounding | null = meta ? { queries: (meta.webSearchQueries ?? []).slice(0, 4), sources, suggestionsHtml: meta.searchEntryPoint?.renderedContent ?? null } : null;
    return { text, grounding };
  } catch (e) {
    if (e instanceof ChatError) throw e;
    if ((e as Error)?.name === 'AbortError') throw e;
    throw new ChatError(chatFailureOf(String((e as Error)?.message ?? e)), String((e as Error)?.message ?? e).slice(0, 600));
  }
}
