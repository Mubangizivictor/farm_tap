'use client';

// The pieces of one chat message (decision 0027): the farmer's bubble with its attachments, the
// photo with numbered pins, the sources, the animal's milk card and the hover toolbar.

import { useState } from 'react';
import { Icon } from '@/components/Icon';
import { kindTag, type Attached } from '@/components/chat/Composer';
import { CHAT_LANGUAGES, type ChatGrounding, type ChatPin } from '@/shared/aiChat';
import type { SavedTurn } from '@/lib/aiChatStore';

const mmss = (s: number) => `${Math.floor(s / 60)}:${String(s % 60).padStart(2, '0')}`;
export const clock = (id: number) => new Date(id).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });

/** What the farmer sent, as a bubble. `full` has the real files (only in this visit); saved chats have names only. */
export function UserMsg({ t, full, onOpen, onCopy, onEdit, busy }: { t: SavedTurn; full: Attached[]; onOpen: (i: number) => void; onCopy: () => void; onEdit: () => void; busy: boolean }) {
  const photos = full.filter((f) => f.thumb);
  const others = (t.files ?? []).filter((f) => f.kind !== 'photo');
  const savedPhotos = (t.files ?? []).filter((f) => f.kind === 'photo').length;
  return (
    <div className="ct-me-wrap">
      {photos.length > 0 && (
        <div className={`ct-collage n${Math.min(photos.length, 4)}`}>
          {photos.slice(0, 4).map((f, i) => (
            <button key={i} className="c" onClick={() => onOpen(full.indexOf(f))} aria-label={`Open ${f.name}`}>
              <img src={f.thumb} alt="" />
              {i === 3 && photos.length > 4 && <span className="more">+{photos.length - 3}</span>}
            </button>
          ))}
        </div>
      )}
      {savedPhotos > 0 && photos.length === 0 && (
        <span className="ct-mf">
          <Icon name="image" /> {savedPhotos} {savedPhotos === 1 ? 'photo' : 'photos'}
        </span>
      )}
      {others.map((f, i) => (
        <span key={i} className="ct-mf">
          <span className="ft">{f.kind === 'audio' ? <Icon name="mic" /> : kindTag(f)}</span>
          <span className="txt">
            <b>{f.name}</b>
            {f.kind === 'audio' && t.voice != null && <small>{mmss(t.voice)}</small>}
          </span>
        </span>
      ))}
      <div className="ct-me">{t.text}</div>
      <div className="ct-bar end">
        <span className="small muted">{clock(t.id)}</span>
        <button className="ct-ib sm" aria-label="Copy your message" title="Copy" onClick={onCopy}><Icon name="copy" /></button>
        <button className="ct-ib sm" aria-label="Edit your message" title="Edit and ask again" disabled={busy} onClick={onEdit}><Icon name="edit" /></button>
      </div>
    </div>
  );
}

/** A photo with numbered pins on the places the AI looked at, and the list of what each pin is. */
export function PhotoPins({ src, pins, onOpen }: { src: string; pins: ChatPin[]; onOpen: () => void }) {
  return (
    <div className="ct-annot-wrap">
      <div className="ct-annot">
        <img src={src} alt="Your photo with numbered points" />
        {pins.map((p) => (
          <span key={p.n} className={`ct-pin ${p.tone}`} style={{ left: `${p.x}%`, top: `${p.y}%` }}>{p.n}</span>
        ))}
        <span className="tag"><span className="ct-chip dark"><Icon name="scan" /> {pins.length} {pins.length === 1 ? 'point' : 'points'}</span></span>
        <button className="exp" aria-label="Open the photo bigger" onClick={onOpen}><Icon name="zoomIn" /></button>
      </div>
      <PinList pins={pins} />
    </div>
  );
}

export function PinList({ pins }: { pins: ChatPin[] }) {
  return (
    <div className="ct-finds">
      {pins.map((p) => (
        <div key={p.n} className="ct-find">
          <span className={`pn ${p.tone}`}>{p.n}</span>
          <span className="txt"><b>{p.label}</b></span>
          <span className="conf small muted">{p.sure === 'likely' ? 'Likely' : 'Possible'}</span>
        </div>
      ))}
    </div>
  );
}

const host = (uri: string) => {
  try {
    return new URL(uri).hostname.replace(/^www\./, '');
  } catch {
    return uri;
  }
};

/** Numbered source chips from Google, with the site name under each title. */
export function Sources({ g }: { g: ChatGrounding }) {
  if (!g.sources.length) return null;
  return (
    <section className="ct-srcs" aria-label="Sources from Google">
      <span className="ct-label" title={g.queries.length ? `Searched: ${g.queries.join(', ')}` : undefined}>Sources from Google</span>
      <div className="ct-srcrow">
        {g.sources.map((s, i) => (
          <a key={s.uri} className="ct-src" href={s.uri} target="_blank" rel="noopener noreferrer">
            <span className="fav">{(host(s.uri)[0] ?? '?').toUpperCase()}</span>
            <span className="txt">
              <b>{s.title}</b>
              <small>{host(s.uri)}</small>
            </span>
            <span className="n">{i + 1}</span>
          </a>
        ))}
      </div>
      {g.suggestionsHtml && <iframe className="chat-suggest" title="Google Search suggestions" sandbox="allow-popups allow-popups-to-escape-sandbox" srcDoc={g.suggestionsHtml} />}
    </section>
  );
}

/** The animal this answer is about: seven days of milk as a small chart. */
export function CowCard({ name, spark, onOpen }: { name: string; spark: number[]; onOpen: () => void }) {
  const total = spark.reduce((a, b) => a + b, 0);
  const got = spark.filter((x) => x > 0);
  if (!got.length) return null;
  const max = Math.max(...spark, 1);
  const pts = spark.map((v, i) => `${(i / (spark.length - 1)) * 100},${30 - (v / max) * 26}`).join(' ');
  return (
    <section className="ct-facts" aria-label={`${name}'s milk`}>
      <div className="fh"><Icon name="cow" /> {name} · last {spark.length} days <button className="link-btn small" onClick={onOpen}>Open</button></div>
      <div className="fg">
        <div><span className="k">Total</span><span className="v">{Math.round(total * 10) / 10} L</span></div>
        <div><span className="k">Average</span><span className="v">{Math.round((total / got.length) * 10) / 10} L</span></div>
        <div><span className="k">Best day</span><span className="v">{Math.max(...spark)} L</span></div>
        <div className="sp">
          <svg viewBox="0 0 100 32" preserveAspectRatio="none" className="ct-spark" role="img" aria-label="Milk by day">
            <polyline points={pts} fill="none" stroke="currentColor" strokeWidth="2" strokeLinejoin="round" strokeLinecap="round" vectorEffect="non-scaling-stroke" />
          </svg>
        </div>
      </div>
    </section>
  );
}

/** Copy, good/bad, read aloud, translate, ask again and share: shown when you point at an answer. */
export function ReplyBar({
  t,
  speaking,
  canSpeak,
  busy,
  onCopy,
  onVote,
  onSpeak,
  onAgain,
  onTranslate,
  onShare,
}: {
  t: SavedTurn;
  speaking: boolean;
  canSpeak: boolean;
  busy: boolean;
  onCopy: () => void;
  onVote: (v: 'up' | 'down') => void;
  onSpeak: () => void;
  onAgain: () => void;
  onTranslate: (label: string) => void;
  onShare: () => void;
}) {
  const [tr, setTr] = useState(false);
  const btn = (icon: Parameters<typeof Icon>[0]['name'], label: string, on: () => void, extra = '', disabled = false, pressed?: boolean) => (
    <button className={`ct-ib sm${extra ? ` ${extra}` : ''}`} aria-label={label} title={label} aria-pressed={pressed} disabled={disabled} onClick={on}>
      <Icon name={icon} />
    </button>
  );
  return (
    <div className="ct-bar">
      {btn('copy', 'Copy answer', onCopy)}
      {t.method === 'model' && (
        <>
          {btn('thumbUp', 'Good answer', () => onVote('up'), t.vote === 'up' ? 'on' : '', false, t.vote === 'up')}
          {btn('thumbDown', 'Bad answer', () => onVote('down'), t.vote === 'down' ? 'on' : '', false, t.vote === 'down')}
        </>
      )}
      {canSpeak && btn(speaking ? 'stop' : 'volume', speaking ? 'Stop reading aloud' : 'Read aloud', onSpeak, speaking ? 'on' : '')}
      {t.method === 'model' && (
        <span className="ct-trwrap">
          {btn('translate', 'Say it in another language', () => setTr(!tr), tr ? 'on' : '', busy)}
          {tr && (
            <span className="ct-trmenu" role="menu">
              {CHAT_LANGUAGES.filter((l) => l.id !== 'auto').map((l) => (
                <button key={l.id} role="menuitem" onClick={() => { setTr(false); onTranslate(l.label); }}>{l.label}</button>
              ))}
            </span>
          )}
        </span>
      )}
      {btn('share', 'Share', onShare)}
      {t.asked && btn('refresh', 'Ask again', onAgain, '', busy)}
      <span className="grow" />
      <span className="sep" aria-hidden />
      {t.model && <span className="small muted" title="Answered by">{t.model.replace(/^gemini-/, 'Gemini ')}</span>}
    </div>
  );
}

