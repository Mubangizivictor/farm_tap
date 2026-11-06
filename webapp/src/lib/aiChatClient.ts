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

/**
 * Sends the conversation so far, the new question and any files, and streams the
 * answer: `onText` is called with the whole text so far every time more arrives.
 * Tries each model in `models` in turn, with Google Search first and without it
 * if that is refused. Throws ChatError.
 */
export async function askGemini(opts: {
  system: string;
  history: ChatTurn[];
  prompt: string;
  files: ChatPart[];
  models: string[];
  onText?: (soFar: string) => void;
  signal?: AbortSignal;
}): Promise<{ text: string; grounding: ChatGrounding | null; model: string }> {
  firebase();
  startAppCheck();
  const contents: Content[] = [
    ...opts.history.map((h): Content => ({ role: h.role, parts: [{ text: h.text }] })),
    { role: 'user', parts: [{ text: opts.prompt }, ...opts.files.map((f) => ({ inlineData: { mimeType: f.mime, data: f.base64 } }))] },
  ];
  const stopped = () => new DOMException('stopped', 'AbortError');
  const run = async (modelName: string, search: boolean) => {
    const model = getGenerativeModel(getAI(getApp(), { backend: new GoogleAIBackend() }), {
      model: modelName,
      systemInstruction: opts.system,
      generationConfig: { temperature: 0.4, maxOutputTokens: 1500 },
      ...(search ? { tools: [{ googleSearch: {} }] } : {}),
    });
    const stream = await model.generateContentStream({ contents });
    let text = '';
    const read = async () => {
      for await (const chunk of stream.stream) {
        if (opts.signal?.aborted) throw stopped();
        text += chunk.text();
        opts.onText?.(text);
      }
      return stream.response;
    };
    let timer: ReturnType<typeof setTimeout> | undefined;
    const limit = new Promise<never>((_, no) => {
      timer = setTimeout(() => no(new Error('timeout')), 90000);
    });
    try {
      const res = await Promise.race([read(), limit]);
      return { text, res };
    } finally {
      clearTimeout(timer);
    }
  };
  let last: unknown = null;
  let tries = 0;
  for (const modelName of opts.models) {
    for (const search of [true, false]) {
      if (tries >= 4) break;
      tries++;
      try {
        if (opts.signal?.aborted) throw stopped();
        const { text, res } = await run(modelName, search);
        if (!text.trim()) throw new ChatError('unreadable', 'The model sent an empty answer.');
        const meta = search ? (res.candidates?.[0]?.groundingMetadata as Meta | undefined) : undefined;
        const sources = cleanSources((meta?.groundingChunks ?? []).map((c) => ({ uri: c.web?.uri, title: c.web?.title })));
        const grounding: ChatGrounding | null = meta ? { queries: (meta.webSearchQueries ?? []).slice(0, 4), sources, suggestionsHtml: meta.searchEntryPoint?.renderedContent ?? null } : null;
        return { text, grounding, model: modelName };
      } catch (e) {
        if ((e as Error)?.name === 'AbortError') throw e;
        last = e;
        const f = e instanceof ChatError ? e.failure : chatFailureOf(String((e as Error)?.message ?? e));
        opts.onText?.('');
        // These will fail the same way on any model.
        if (f === 'network' || f === 'appCheck' || (f === 'setup' && !search)) throw e instanceof ChatError ? e : new ChatError(f, String((e as Error)?.message ?? e).slice(0, 600));
      }
    }
  }
  if (last instanceof ChatError) throw last;
  const msg = String((last as Error)?.message ?? last);
  throw new ChatError(chatFailureOf(msg), msg.slice(0, 600));
}
