'use client';

// FarmTap AI chat (decision 0027): one box. Type a question, attach photos,
// PDFs, files or a short video with the plus, and get an answer. Online,
// Google Gemini answers with FarmTap's facts about the cow that was named;
// offline (or when it is switched off) the built-in assistant answers simple
// farm questions from the records. An answer about a named cow is saved to
// that cow's health history. Safety rules: shared/aiChat.ts.

import Link from 'next/link';
import { useEffect, useMemo, useRef, useState, type ClipboardEvent, type DragEvent, type KeyboardEvent } from 'react';
import { ChatText } from '@/components/ChatText';
import { Icon, type IconName } from '@/components/Icon';
import { MethodBadge } from '@/components/ai';
import { AiOff, AiState } from '@/components/ai';
import { useAiPage } from '@/components/aiPage';
import { alive, kampalaNow, type Method } from '@/shared/aiCore';
import { animalName, isActive } from '@/shared/aiData';
import { ask } from '@/shared/aiAssistant';
import { animalHealth } from '@/shared/aiHerd';
import { nameLabels, redact, restore } from '@/shared/aiPrivacy';
import { photoAllowed } from '@/shared/aiPhoto';
import {
  animalFacts,
  buildChatPrompt,
  CHAT_MAX_BYTES,
  CHAT_MAX_FILES,
  CHAT_SYSTEM,
  CHAT_UNSUPPORTED,
  chatAssessmentBody,
  chatFileKind,
  findAnimalMention,
  readChatReply,
} from '@/shared/aiChat';
import { farmAiOn, logAi } from '@/lib/ai';
import { askGemini, type ChatTurn } from '@/lib/aiChatClient';
import { addRecord, useRecords } from '@/lib/data';
import { firebase } from '@/lib/firebase';
import { shrinkImage } from '@/lib/images';
import { useSession } from '@/lib/session';

type Kind = 'photo' | 'video' | 'audio' | 'pdf' | 'text';
interface Attached {
  name: string;
  mime: string;
  kind: Kind;
  base64: string;
  /** Small picture for photos only. */
  thumb?: string;
}
interface Turn {
  id: number;
  who: 'me' | 'ai';
  text: string;
  files?: { name: string; kind: Kind; thumb?: string }[];
  method?: Method;
  aboutAnimal?: string;
  saved?: boolean;
  note?: string;
}

const KEY = 'farmtap.ai.chat2';
const ICON: Record<Kind, IconName> = { photo: 'camera', video: 'play', audio: 'play', pdf: 'list', text: 'list' };
const FAIL = {
  network: 'There is no internet right now.',
  busy: 'Online AI is busy. Try again in a minute.',
  appCheck: 'Online AI could not confirm this is the real FarmTap site.',
  unreadable: 'The answer could not be read. Try asking again.',
} as const;

const guessMime = (f: File) => {
  if (f.type) return f.type;
  const ext = f.name.split('.').pop()?.toLowerCase() ?? '';
  return ({ pdf: 'application/pdf', csv: 'text/csv', txt: 'text/plain', md: 'text/markdown', json: 'application/json', mp4: 'video/mp4', mov: 'video/quicktime', mp3: 'audio/mpeg', m4a: 'audio/mp4', wav: 'audio/wav' } as Record<string, string>)[ext] ?? '';
};
const readBase64 = (f: Blob) =>
  new Promise<string>((ok, no) => {
    const r = new FileReader();
    r.onload = () => ok(String(r.result).split(',')[1] ?? '');
    r.onerror = () => no(new Error('Could not read that file.'));
    r.readAsDataURL(f);
  });

export default function FarmTapChat() {
  const page = useAiPage('assistant');
  const { farm, cfg, ai } = page;
  const { user, canSave } = useSession();
  const [text, setText] = useState('');
  const [files, setFiles] = useState<Attached[]>([]);
  const [turns, setTurns] = useState<Turn[]>([]);
  const [busy, setBusy] = useState(false);
  const [problem, setProblem] = useState('');
  const [animalId, setAnimalId] = useState<string | null>(null);
  const pick = useRef<HTMLInputElement>(null);
  const end = useRef<HTMLDivElement>(null);
  const day = kampalaNow(new Date()).iso.slice(0, 10);
  const logs = useRecords<{ feature?: string; ok?: boolean }>(farm.id, 'aiLog', day);
  const usedToday = logs.data.filter((l) => l.body.feature === 'chat' && l.body.ok).length;
  const limit = photoAllowed(usedToday, cfg.ai.photo);
  const animals = useMemo(() => alive(ai.data.animals).filter(isActive), [ai.data.animals]);
  const about = animals.find((a) => a.id === animalId);

  useEffect(() => {
    const id = new URL(window.location.href).searchParams.get('animal');
    if (id) setAnimalId(id);
    try {
      const raw = window.sessionStorage.getItem(`${KEY}.${farm.id}`);
      if (raw) setTurns((JSON.parse(raw) as Turn[]).map((t) => ({ ...t, files: t.files?.map((f) => ({ name: f.name, kind: f.kind })) })));
    } catch {
      /* private window: start empty */
    }
  }, [farm.id]);
  useEffect(() => {
    try {
      window.sessionStorage.setItem(`${KEY}.${farm.id}`, JSON.stringify(turns.slice(-30).map((t) => ({ ...t, files: t.files?.map((f) => ({ name: f.name, kind: f.kind })) }))));
    } catch {
      /* not kept */
    }
    end.current?.scrollIntoView({ block: 'end', behavior: 'smooth' });
  }, [turns, farm.id]);

  const add = async (list: File[]) => {
    setProblem('');
    const next = [...files];
    for (const f of list) {
      const mime = guessMime(f);
      const kind = chatFileKind(mime);
      if (!kind) {
        setProblem(CHAT_UNSUPPORTED);
        continue;
      }
      if (next.length >= CHAT_MAX_FILES) {
        setProblem(`You can attach up to ${CHAT_MAX_FILES} files at a time.`);
        break;
      }
      try {
        if (kind === 'photo') {
          const s = await shrinkImage(f, { max: 1280, quality: 0.82 });
          next.push({ name: f.name, mime: 'image/jpeg', kind, base64: s.dataUrl.split(',')[1] ?? '', thumb: s.dataUrl });
        } else {
          next.push({ name: f.name, mime, kind, base64: await readBase64(f) });
        }
      } catch (e) {
        setProblem((e as Error).message || 'Could not read that file.');
      }
    }
    const bytes = next.reduce((t, x) => t + (x.base64.length * 3) / 4, 0);
    if (bytes > CHAT_MAX_BYTES) {
      setProblem('Those files are too big together. Remove one or use a shorter video.');
      return;
    }
    setFiles(next);
  };

  const onPaste = (e: ClipboardEvent) => {
    const fs = [...e.clipboardData.files];
    if (fs.length) {
      e.preventDefault();
      void add(fs);
    }
  };
  const onDrop = (e: DragEvent) => {
    e.preventDefault();
    if (e.dataTransfer.files.length) void add([...e.dataTransfer.files]);
  };

  const send = async () => {
    const q = text.trim();
    if ((!q && !files.length) || busy || ai.loading || !user) return;
    const question = q || 'Please look at what I attached.';
    const sent = files;
    const t0 = performance.now();
    setText('');
    setFiles([]);
    setProblem('');
    setBusy(true);
    const id = Date.now();
    setTurns((ts) => [...ts, { id, who: 'me', text: question, files: sent.map((f) => ({ name: f.name, kind: f.kind, thumb: f.thumb })) }]);
    const cows = animals.map((a) => ({ id: a.id, name: a.body.name ?? null, tag: a.body.tagNumber ?? null }));
    const named = findAnimalMention(question, cows) ?? animalId;
    if (named !== animalId) setAnimalId(named);
    const cow = animals.find((a) => a.id === named);
    const names = nameLabels({ animals: animals.map((a) => a.body), people: [user.displayName ?? ''], places: [farm.name] });
    const calc = ask(question, ai.data, { role: farm.role, cfg: cfg.ai, farmAiOn: true });
    const calcText = calc.ok ? [calc.text, ...calc.bullets.map((b) => `- ${b}`)].join('\n') : null;
    const finish = (t: Omit<Turn, 'id' | 'who'>) => setTurns((ts) => [...ts, { id: id + 1, who: 'ai', ...t }]);
    const offlineAnswer = (note: string) => {
      logAi(farm.id, 'assistant', calc.ok, performance.now() - t0, calc.method);
      const lines = calc.ok ? [calc.text, ...calc.bullets.map((b) => `- ${b}`)].join('\n') : `${note}\n\nI can answer simple questions about your milk, animals, feed and money from your records, even without internet.`;
      finish({ text: lines, method: calc.method, aboutAnimal: cow ? animalName(cow) : undefined, note: calc.ok ? note : undefined });
    };
    const online = cfg.ai.photo.enabled && limit.ok && typeof navigator !== 'undefined' && navigator.onLine;
    if (!online) {
      const why = !cfg.ai.photo.enabled ? 'Online AI is not switched on for FarmTap yet.' : !limit.ok ? 'Your farm has used all online AI answers for today.' : 'There is no internet.';
      offlineAnswer(sent.length ? `${why} Files and photos could not be read.` : why);
      setBusy(false);
      return;
    }
    try {
      const facts = cow ? animalFacts(animalHealth(ai.data, cow.id), cow.body, day) : [];
      const prompt = buildChatPrompt({ message: redact(question, names), facts, calculated: calcText ? redact(calcText, names) : null, files: sent.map((f) => ({ kind: f.kind })) });
      const history: ChatTurn[] = turns
        .slice(-8)
        .filter((t) => t.text)
        .map((t) => ({ role: t.who === 'me' ? 'user' : 'model', text: redact(t.text, names) }));
      const raw = await askGemini({ system: CHAT_SYSTEM, history, prompt, files: sent.map((f) => ({ mime: f.mime, base64: f.base64 })), model: cfg.ai.photo.model });
      const reply = readChatReply(raw, question);
      const shown = restore(reply.text, names);
      logAi(farm.id, 'chat', true, performance.now() - t0, 'model');
      let saved = false;
      if (cow && canSave) {
        try {
          const body = chatAssessmentBody(cow.id, question, { ...reply, text: shown }, [...new Set(sent.map((f) => f.kind))], cfg.ai.photo.model, kampalaNow(new Date()).iso);
          await addRecord(firebase().db, farm.id, 'healthAssessments', user.uid, body as unknown as Record<string, unknown>);
          saved = true;
        } catch {
          saved = false;
        }
      }
      finish({ text: shown, method: 'model', aboutAnimal: cow ? animalName(cow) : undefined, saved, note: reply.removed ? 'Some details about medicines were left out. Ask your vet.' : undefined });
    } catch (e) {
      logAi(farm.id, 'chat', false, performance.now() - t0, 'model');
      const f = (e as Error).message as keyof typeof FAIL;
      offlineAnswer(`${FAIL[f] ?? FAIL.unreadable}${sent.length ? ' Files and photos could not be read.' : ''}`);
    } finally {
      setBusy(false);
    }
  };

  const onKey = (e: KeyboardEvent<HTMLTextAreaElement>) => {
    if (e.key === 'Enter' && !e.shiftKey && !e.nativeEvent.isComposing) {
      e.preventDefault();
      void send();
    }
  };

  if (!farmAiOn(farm, cfg)) return <AiOff reason="AI Intelligence is switched off for this farm. Contact FarmTap support to turn it on." />;
  if (!page.allowed) return <AiOff reason="This part of AI Intelligence is not available to your role or has been switched off." />;

  return (
    <div className="chat" onDragOver={(e) => e.preventDefault()} onDrop={onDrop}>
      <div className="chat-top">
        <h1>FarmTap AI</h1>
        <div className="row">
          {turns.length > 0 && (
            <button className="btn sm ghost" onClick={() => setTurns([])}>
              <Icon name="refresh" /> New chat
            </button>
          )}
          <Link className="btn sm ghost" href="/ai/tools/">
            Insights and tools <Icon name="chevron" />
          </Link>
        </div>
      </div>
      <AiState ai={ai} skeleton={1}>
        <div className="chat-scroll" aria-live="polite">
          {turns.length === 0 && (
            <div className="chat-empty">
              <span className="icon-chip ai-chip" aria-hidden>
                <Icon name="spark" />
              </span>
              <h2>How can I help on your farm today?</h2>
            </div>
          )}
          {turns.map((t) =>
            t.who === 'me' ? (
              <div key={t.id} className="chat-me">
                {t.files && t.files.length > 0 && (
                  <div className="chat-files">
                    {t.files.map((f, i) => (
                      <span key={i} className="chat-file">
                        {f.thumb ? <img src={f.thumb} alt="" /> : <Icon name={ICON[f.kind]} />}
                        <span className="small">{f.name}</span>
                      </span>
                    ))}
                  </div>
                )}
                <p>{t.text}</p>
              </div>
            ) : (
              <div key={t.id} className="chat-ai" role="article">
                <ChatText text={t.text} />
                <div className="chat-meta">
                  {t.method && <MethodBadge method={t.method} />}
                  {t.saved && (
                    <span className="chip ok">
                      <Icon name="check" /> Saved to {t.aboutAnimal ?? 'the animal'}’s history
                    </span>
                  )}
                  {t.note && <span className="small muted">{t.note}</span>}
                </div>
              </div>
            ),
          )}
          {busy && (
            <div className="chat-ai muted" role="status">
              <span className="row">
                <Icon name="spark" /> Thinking…
              </span>
            </div>
          )}
          <div ref={end} />
        </div>
      </AiState>
      <div className="chat-composer">
        {about && (
          <span className="chip brand chat-about">
            About {animalName(about)}
            <button className="icon-btn" aria-label="Stop talking about this animal" onClick={() => setAnimalId(null)}>
              <Icon name="close" />
            </button>
          </span>
        )}
        {problem && (
          <div className="banner warn small" role="alert">
            {problem}
          </div>
        )}
        <div className="chat-box" onPaste={onPaste}>
          {files.length > 0 && (
            <div className="chat-files">
              {files.map((f, i) => (
                <span key={i} className="chat-file">
                  {f.thumb ? <img src={f.thumb} alt="" /> : <Icon name={ICON[f.kind]} />}
                  <span className="small">{f.name}</span>
                  <button className="icon-btn" aria-label={`Remove ${f.name}`} onClick={() => setFiles(files.filter((_, j) => j !== i))}>
                    <Icon name="close" />
                  </button>
                </span>
              ))}
            </div>
          )}
          <textarea
            value={text}
            rows={Math.min(6, Math.max(1, text.split('\n').length))}
            maxLength={2000}
            placeholder="Ask anything…"
            aria-label="Your message"
            onChange={(e) => setText(e.target.value)}
            onKeyDown={onKey}
          />
          <div className="chat-tools">
            <input ref={pick} hidden multiple type="file" accept="image/*,video/*,audio/*,application/pdf,text/plain,text/csv,text/markdown,application/json,.csv,.txt,.md,.json,.pdf" onChange={(e) => { void add([...(e.target.files ?? [])]); e.target.value = ''; }} />
            <button className="icon-btn" aria-label="Attach photos, PDFs, files or video" title="Attach photos, PDFs, files or video" disabled={busy} onClick={() => pick.current?.click()}>
              <Icon name="plus" />
            </button>
            <span className="grow" />
            <button className="btn sm" aria-label="Send" disabled={busy || ai.loading || (!text.trim() && !files.length)} onClick={() => void send()}>
              <Icon name="chat" />
            </button>
          </div>
        </div>
        <p className="small muted">FarmTap AI can make mistakes and never replaces your vet.</p>
      </div>
    </div>
  );
}
