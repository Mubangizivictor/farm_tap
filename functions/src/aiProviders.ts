// AI providers for the server assistant (decision 0028).
//
// The assistant talks to one small interface, so another provider (for
// example DeepSeek or a self-hosted model) is one more class here and a new
// id in shared/aiQuota.ts AI_PROVIDERS, not a rewrite. Only Gemini is
// implemented; nothing here signs up for or pays for anything new.
//
// The key is read from platformSecrets/gemini_api_key (pasted in the panel,
// never readable by an app) or, if set, the GEMINI_API_KEY environment
// variable. It never leaves this server.

import { providerErrorKind, type AiErrorKind } from './shared/aiQuota';

export interface AiFile {
  mime: string;
  base64: string;
}
export interface AiTurn {
  role: 'user' | 'model';
  text: string;
}

export interface AiRequest {
  model: string;
  system: string;
  history: AiTurn[];
  prompt: string;
  files: AiFile[];
  /** Ask the provider to search the web (Gemini: Google Search grounding). */
  search: boolean;
  maxOutputTokens: number;
  timeoutMs: number;
  /** Called with the whole text so far as it arrives (streaming). */
  onText?: (soFar: string) => void;
}

export interface AiGrounding {
  queries: string[];
  sources: { title?: string; uri?: string }[];
  suggestionsHtml: string | null;
}

export interface AiResult {
  text: string;
  grounding: AiGrounding | null;
  tokensIn: number | null;
  tokensOut: number | null;
}

/** A failed provider call, already sorted into a kind the apps understand. */
export class AiProviderError extends Error {
  constructor(
    readonly kind: AiErrorKind,
    readonly status: number,
    /** For the admin error log only; never shown to farmers. */
    readonly detail: string,
  ) {
    super(kind);
  }
}

export interface AiProvider {
  readonly id: string;
  generate(req: AiRequest): Promise<AiResult>;
}

type Fetch = typeof fetch;

interface GeminiPart {
  text?: string;
}
interface GeminiChunk {
  candidates?: {
    content?: { parts?: GeminiPart[] };
    finishReason?: string;
    groundingMetadata?: {
      webSearchQueries?: string[];
      searchEntryPoint?: { renderedContent?: string };
      groundingChunks?: { web?: { uri?: string; title?: string } }[];
    };
  }[];
  promptFeedback?: { blockReason?: string };
  usageMetadata?: { promptTokenCount?: number; candidatesTokenCount?: number };
  error?: { code?: number; message?: string; status?: string };
}

/** Removes the key from anything that will be logged. */
const scrub = (s: string, key: string) => (key ? s.split(key).join('[key]') : s).replace(/key=[\w-]+/g, 'key=[key]').slice(0, 600);

/** Google Gemini through the Gemini Developer API (the same free tier the apps used through Firebase AI Logic). */
export class GeminiProvider implements AiProvider {
  readonly id = 'gemini';
  constructor(
    private readonly key: string,
    private readonly fetchFn: Fetch = fetch,
    private readonly base = 'https://generativelanguage.googleapis.com/v1beta',
  ) {}

  async generate(req: AiRequest): Promise<AiResult> {
    if (!this.key) throw new AiProviderError('unavailable', 0, 'No Gemini API key: paste it in Admin > APIs and keys as gemini_api_key.');
    const body = {
      systemInstruction: { parts: [{ text: req.system }] },
      contents: [
        ...req.history.map((h) => ({ role: h.role, parts: [{ text: h.text }] })),
        { role: 'user', parts: [{ text: req.prompt }, ...req.files.map((f) => ({ inlineData: { mimeType: f.mime, data: f.base64 } }))] },
      ],
      generationConfig: { temperature: 0.4, maxOutputTokens: req.maxOutputTokens },
      ...(req.search ? { tools: [{ googleSearch: {} }] } : {}),
    };
    const ctl = new AbortController();
    const timer = setTimeout(() => ctl.abort(), req.timeoutMs);
    const url = `${this.base}/models/${encodeURIComponent(req.model)}:streamGenerateContent?alt=sse`;
    let res: Response;
    try {
      res = await this.fetchFn(url, { method: 'POST', headers: { 'content-type': 'application/json', 'x-goog-api-key': this.key }, body: JSON.stringify(body), signal: ctl.signal });
    } catch (e) {
      clearTimeout(timer);
      const msg = String((e as Error)?.name === 'AbortError' ? 'timeout' : ((e as Error)?.message ?? e));
      throw new AiProviderError(providerErrorKind(0, msg), 0, scrub(msg, this.key));
    }
    try {
      if (!res.ok) {
        const t = await res.text().catch(() => '');
        throw new AiProviderError(providerErrorKind(res.status, t), res.status, scrub(`${res.status} ${t}`, this.key));
      }
      return await this.read(res, req);
    } catch (e) {
      if (e instanceof AiProviderError) throw e;
      const msg = String((e as Error)?.name === 'AbortError' ? 'timeout' : ((e as Error)?.message ?? e));
      throw new AiProviderError(providerErrorKind(0, msg), 0, scrub(msg, this.key));
    } finally {
      clearTimeout(timer);
    }
  }

  /** Reads the server-sent events: one JSON chunk per "data:" line. */
  private async read(res: Response, req: AiRequest): Promise<AiResult> {
    let text = '';
    let grounding: AiGrounding | null = null;
    let tokensIn: number | null = null;
    let tokensOut: number | null = null;
    let blocked = '';
    const handle = (json: string) => {
      let c: GeminiChunk;
      try {
        c = JSON.parse(json) as GeminiChunk;
      } catch {
        return;
      }
      if (c.error) throw new AiProviderError(providerErrorKind(c.error.code ?? 500, `${c.error.status ?? ''} ${c.error.message ?? ''}`), c.error.code ?? 500, scrub(c.error.message ?? '', this.key));
      if (c.promptFeedback?.blockReason) blocked = c.promptFeedback.blockReason;
      const cand = c.candidates?.[0];
      const piece = (cand?.content?.parts ?? []).map((p) => p.text ?? '').join('');
      if (piece) {
        text += piece;
        req.onText?.(text);
      }
      if (cand?.finishReason === 'SAFETY' || cand?.finishReason === 'PROHIBITED_CONTENT') blocked = cand.finishReason;
      const g = cand?.groundingMetadata;
      if (g)
        grounding = {
          queries: (g.webSearchQueries ?? []).slice(0, 4),
          sources: (g.groundingChunks ?? []).map((x) => ({ uri: x.web?.uri, title: x.web?.title })),
          suggestionsHtml: g.searchEntryPoint?.renderedContent ?? null,
        };
      if (c.usageMetadata) {
        tokensIn = c.usageMetadata.promptTokenCount ?? tokensIn;
        tokensOut = c.usageMetadata.candidatesTokenCount ?? tokensOut;
      }
    };
    let buf = '';
    await streamText(res, (piece) => {
      buf += piece;
      const lines = buf.split(/\r?\n/);
      buf = lines.pop() ?? '';
      for (const line of lines) if (line.startsWith('data:')) handle(line.slice(5).trim());
    });
    if (buf.startsWith('data:')) handle(buf.slice(5).trim());
    if (!text.trim()) {
      if (blocked) throw new AiProviderError('invalid', 400, `Blocked: ${blocked}`);
      throw new AiProviderError('unavailable', 200, 'The model sent an empty answer.');
    }
    return { text, grounding, tokensIn, tokensOut };
  }
}

/** The whole body as text (calls [onChunk] as pieces arrive). */
async function streamText(res: Response, onChunk: (s: string) => void): Promise<string> {
  if (!res.body) {
    const all = await res.text();
    onChunk(all);
    return all;
  }
  const reader = res.body.getReader();
  const dec = new TextDecoder();
  let out = '';
  for (;;) {
    const { done, value } = await reader.read();
    if (done) break;
    const s = dec.decode(value, { stream: true });
    out += s;
    onChunk(s);
  }
  const rest = dec.decode();
  if (rest) onChunk(rest);
  return out + rest;
}

/** The provider chosen in the panel. New providers are added here. */
export function providerFor(id: string, keys: { gemini: string }, fetchFn: Fetch = fetch): AiProvider {
  switch (id) {
    case 'gemini':
    default:
      return new GeminiProvider(keys.gemini, fetchFn);
  }
}
