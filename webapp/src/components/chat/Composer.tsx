'use client';

// The message box (decision 0027): attachments tray, text, the plus menu (a pop-up on a computer, a
// bottom sheet on a phone), web-search switch, voice notes and send/stop.

import { useEffect, useRef, useState, type ClipboardEvent, type KeyboardEvent, type ReactNode } from 'react';
import { Icon, type IconName } from '@/components/Icon';
import { CONTEXT_KINDS, type ContextKind } from '@/shared/aiToday';
import { CHAT_LANGUAGES } from '@/shared/aiChat';
import { VOICE_MAX_SECONDS } from '@/lib/useRecorder';

export type Kind = 'photo' | 'video' | 'audio' | 'pdf' | 'text';
export interface Attached {
  name: string;
  mime: string;
  kind: Kind;
  base64: string;
  /** Small picture for photos only. */
  thumb?: string;
  /** Length of a voice note, in seconds. */
  seconds?: number;
}

export const KIND_ICON: Record<Kind, IconName> = { photo: 'image', video: 'video', audio: 'mic', pdf: 'file', text: 'file' };
const KIND_TAG: Record<Kind, string> = { photo: 'IMG', video: 'MP4', audio: 'WAV', pdf: 'PDF', text: 'TXT' };
export const kindTag = (f: { kind: string; name: string }) => (f.name.split('.').pop() ?? '').slice(0, 4).toUpperCase() || KIND_TAG[f.kind as Kind] || 'FILE';

const mmss = (s: number) => `${Math.floor(s / 60)}:${String(s % 60).padStart(2, '0')}`;

export interface ComposerProps {
  text: string;
  setText: (t: string) => void;
  files: Attached[];
  removeFile: (i: number) => void;
  openFile: (i: number) => void;
  onFiles: (list: File[]) => void;
  busy: boolean;
  canSend: boolean;
  send: () => void;
  stop: () => void;
  problem: string;
  about: string | null;
  clearAbout: () => void;
  search: boolean;
  setSearch: (v: boolean) => void;
  fast: boolean;
  setFast: (v: boolean) => void;
  lang: string;
  setLang: (v: string) => void;
  context: ContextKind[];
  toggleContext: (k: ContextKind) => void;
  voice: { supported: boolean; recording: boolean; seconds: number; levels: number[]; error: string; start: () => void; cancel: () => void; sendNow: () => void };
  left: number | null;
  leftPct: number;
  offline: boolean;
  footer?: ReactNode;
}

export function Composer(p: ComposerProps) {
  const [menu, setMenu] = useState(false);
  const box = useRef<HTMLTextAreaElement>(null);
  const pickAny = useRef<HTMLInputElement>(null);
  const pickPhoto = useRef<HTMLInputElement>(null);
  const pickCam = useRef<HTMLInputElement>(null);
  const pickVideo = useRef<HTMLInputElement>(null);

  useEffect(() => {
    if (!menu) return;
    const esc = (e: globalThis.KeyboardEvent) => e.key === 'Escape' && setMenu(false);
    window.addEventListener('keydown', esc);
    return () => window.removeEventListener('keydown', esc);
  }, [menu]);
  useEffect(() => {
    const el = box.current;
    if (!el) return;
    el.style.height = 'auto';
    el.style.height = `${el.scrollHeight}px`;
  }, [p.text]);

  const onKey = (e: KeyboardEvent<HTMLTextAreaElement>) => {
    if (e.key === 'Enter' && !e.shiftKey && !e.nativeEvent.isComposing) {
      e.preventDefault();
      p.send();
    }
  };
  const onPaste = (e: ClipboardEvent) => {
    const fs = [...e.clipboardData.files];
    if (fs.length) {
      e.preventDefault();
      p.onFiles(fs);
    }
  };
  const input = (ref: React.RefObject<HTMLInputElement | null>, accept: string, capture?: 'environment') => (
    <input
      ref={ref}
      hidden
      multiple={!capture}
      type="file"
      accept={accept}
      capture={capture}
      onChange={(e) => {
        p.onFiles([...(e.target.files ?? [])]);
        e.target.value = '';
        setMenu(false);
      }}
    />
  );
  const go = (ref: React.RefObject<HTMLInputElement | null>) => () => ref.current?.click();

  const item = (icon: IconName, tone: string, title: string, hint: string, on: () => void, tail?: ReactNode, disabled?: boolean) => (
    <button key={title} className="ct-mi" onClick={on} disabled={disabled}>
      <span className={`ico t-${tone}`}><Icon name={icon} /></span>
      <span className="txt">
        <b>{title}</b>
        <small>{hint}</small>
      </span>
      {tail && <span className="tail">{tail}</span>}
    </button>
  );
  const sw = (on: boolean) => <span className={`ct-sw${on ? ' on' : ''}`} aria-hidden />;

  const menuBody = (
    <>
      <div className="ct-msec">Add to your question</div>
      {item('camera', 'pri', 'Take a photo', 'Open the camera', go(pickCam))}
      {item('image', 'blue', 'Photos', 'Up to 5 from your gallery', go(pickPhoto))}
      {item('file', 'gold', 'PDF or file', 'PDF, text or CSV', go(pickAny))}
      {item('video', 'bad', 'Short video', 'A cow walking or breathing', go(pickVideo))}
      {item('mic', 'ok', 'Voice note', 'Just talk, any language', () => { setMenu(false); p.voice.start(); }, undefined, !p.voice.supported)}
      <div className="ct-msec">Use my farm records</div>
      {CONTEXT_KINDS.map((k) => item(k.id === 'milk' ? 'milk' : k.id === 'health' ? 'health' : 'money', k.id === 'milk' ? 'pri' : k.id === 'health' ? 'bad' : 'warn', k.label, k.hint, () => p.toggleContext(k.id), sw(p.context.includes(k.id))))}
      <div className="ct-msec">Answers</div>
      {item('search', 'blue', 'Search the web', 'Add Google results when useful', () => p.setSearch(!p.search), sw(p.search))}
      {item('bolt', 'gold', 'Fast answers', 'Quicker, a little shorter', () => p.setFast(!p.fast), sw(p.fast))}
      <div className="ct-note"><Icon name="shield" /> Names, phone numbers and places are hidden before anything is sent.</div>
    </>
  );

  const rec = p.voice.recording;
  return (
    <div className="ct-dock">
      {p.offline && (
        <div className="ct-offline" role="status">
          <Icon name="wifiOff" /> No internet. I can still answer simple questions from your records.
        </div>
      )}
      {p.problem && (
        <div className="banner warn small" role="alert">
          {p.problem}
        </div>
      )}
      {p.voice.error && (
        <div className="banner warn small" role="alert">
          {p.voice.error}
        </div>
      )}
      <div className="ct-composer" onPaste={onPaste}>
        {p.files.length > 0 && (
          <div className="ct-att">
            {p.files.map((f, i) => (
              <div key={i} className={f.thumb ? 'ct-th' : 'ct-fc'}>
                {f.thumb ? (
                  <button className="open" onClick={() => p.openFile(i)} aria-label={`Open ${f.name}`}>
                    <img src={f.thumb} alt="" />
                  </button>
                ) : (
                  <>
                    <span className={`ft t-${f.kind === 'pdf' ? 'bad' : f.kind === 'audio' ? 'ok' : f.kind === 'video' ? 'blue' : 'gold'}`}>{f.kind === 'audio' ? <Icon name="mic" /> : kindTag(f)}</span>
                    <span className="txt">
                      <b>{f.name}</b>
                      <small>{f.kind === 'audio' && f.seconds != null ? mmss(f.seconds) : `${Math.max(1, Math.round((f.base64.length * 3) / 4 / 1024))} KB`}</small>
                    </span>
                  </>
                )}
                <button className="x" aria-label={`Remove ${f.name}`} onClick={() => p.removeFile(i)}>
                  <Icon name="close" />
                </button>
              </div>
            ))}
          </div>
        )}
        {(p.about || p.context.length > 0) && (
          <div className="ct-ctx">
            {p.about && (
              <span className="ct-chip cow">
                <Icon name="cow" /> About {p.about}
                <button aria-label="Stop talking about this animal" onClick={p.clearAbout}><Icon name="close" /></button>
              </span>
            )}
            {p.context.map((k) => (
              <span key={k} className="ct-chip pri">
                <Icon name={k === 'milk' ? 'milk' : k === 'health' ? 'health' : 'money'} /> {CONTEXT_KINDS.find((c) => c.id === k)?.label}
                <button aria-label="Remove" onClick={() => p.toggleContext(k)}><Icon name="close" /></button>
              </span>
            ))}
          </div>
        )}
        {rec ? (
          <div className="ct-rec" role="status">
            <span className="dot" aria-hidden />
            <span className="t">{mmss(p.voice.seconds)}</span>
            <span className="ct-wave" aria-hidden>
              {Array.from({ length: 40 }, (_, i) => {
                const lv = p.voice.levels[i - (40 - p.voice.levels.length)] ?? 0;
                return <i key={i} style={{ height: `calc(var(--z-wave) * ${0.12 + lv * 0.88})` }} />;
              })}
            </span>
            <span className="small">max {mmss(VOICE_MAX_SECONDS)}</span>
            <button className="ct-ib" aria-label="Cancel recording" onClick={p.voice.cancel}><Icon name="trash" /></button>
            <button className="ct-send" aria-label="Send voice note" onClick={p.voice.sendNow}><Icon name="up" /></button>
          </div>
        ) : (
          <>
            <textarea ref={box} className="ct-ta" value={p.text} rows={1} maxLength={2000} placeholder={p.files.some((f) => f.kind === 'photo') ? 'Add a question about the photo…' : 'Ask anything…'} aria-label="Your message" onChange={(e) => p.setText(e.target.value)} onKeyDown={onKey} />
            <div className="ct-tools">
              <button className={`ct-ib${menu ? ' on' : ''}`} aria-label="Add photos, files or voice" aria-expanded={menu} disabled={p.busy} onClick={() => setMenu(!menu)}>
                <Icon name="plus" />
              </button>
              <button className={`ct-tg${p.search ? ' on' : ''}`} aria-pressed={p.search} onClick={() => p.setSearch(!p.search)} title="Use Google Search for questions about the world">
                <Icon name="globe" /> <span className="lbl">Search</span>
              </button>
              <label className="ct-tg" title="Reply language">
                <Icon name="translate" />
                <select aria-label="Reply language" value={p.lang} onChange={(e) => p.setLang(e.target.value)}>
                  {CHAT_LANGUAGES.map((l) => (
                    <option key={l.id} value={l.id}>
                      {l.id === 'auto' ? 'Auto' : l.label}
                    </option>
                  ))}
                </select>
              </label>
              <span className="grow" />
              {p.busy ? (
                <button className="ct-send" aria-label="Stop" onClick={p.stop}>
                  <Icon name="stop" />
                </button>
              ) : p.canSend ? (
                <button className="ct-send" aria-label="Send" onClick={p.send}>
                  <Icon name="up" />
                </button>
              ) : (
                <button className="ct-send mic" aria-label="Record a voice note" disabled={!p.voice.supported} onClick={p.voice.start}>
                  <Icon name="mic" />
                </button>
              )}
            </div>
          </>
        )}
        {menu && (
          <>
            <button className="ct-scrim" aria-label="Close menu" onClick={() => setMenu(false)} />
            <div className="ct-pop" role="menu">
              <span className="ct-grab" aria-hidden />
              {menuBody}
            </div>
          </>
        )}
      </div>
      {input(pickAny, 'application/pdf,text/plain,text/csv,text/markdown,application/json,audio/*,.csv,.txt,.md,.json,.pdf')}
      {input(pickPhoto, 'image/*')}
      {input(pickCam, 'image/*', 'environment')}
      {input(pickVideo, 'video/*')}
      <p className="ct-foot">
        <span>FarmTap AI can make mistakes and never replaces your vet.</span>
        {p.left != null && <span className="ct-meter" title="Online answers left today for your farm"><i><b style={{ width: `${Math.min(100, p.leftPct)}%` }} /></i> {p.left} left today</span>}
      </p>
    </div>
  );
}
