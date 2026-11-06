'use client';

// Free reading and pictures for a chat answer (decision 0027): a short summary and a
// photo from Wikipedia for the topic the farmer asked about. It uses no Gemini
// credits and sends only the topic name, never the farm's data. Anything that goes
// wrong is ignored: the answer is never held back for it.

export interface Ref {
  title: string;
  extract: string;
  thumb: string | null;
  url: string;
}

const cache = new Map<string, Promise<Ref | null>>();

export function wikiRef(title: string): Promise<Ref | null> {
  const hit = cache.get(title);
  if (hit) return hit;
  const p = (async (): Promise<Ref | null> => {
    const ctl = new AbortController();
    const t = setTimeout(() => ctl.abort(), 6000);
    try {
      const res = await fetch(`https://en.wikipedia.org/api/rest_v1/page/summary/${encodeURIComponent(title)}`, { signal: ctl.signal });
      if (!res.ok) return null;
      const j = (await res.json()) as { type?: string; title?: string; extract?: string; thumbnail?: { source?: string }; content_urls?: { desktop?: { page?: string } } };
      if (j.type === 'disambiguation' || !j.title || !j.extract) return null;
      return { title: j.title, extract: j.extract, thumb: j.thumbnail?.source ?? null, url: j.content_urls?.desktop?.page ?? `https://en.wikipedia.org/wiki/${encodeURIComponent(title)}` };
    } catch {
      return null;
    } finally {
      clearTimeout(t);
    }
  })();
  cache.set(title, p);
  return p;
}
