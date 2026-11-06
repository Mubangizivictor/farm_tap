'use client';

// FarmTap AI chat (decision 0027): one box. Type a question, attach photos,
// PDFs, files or a short video with the plus, and get an answer. Online,
// Google Gemini answers with FarmTap's facts about the cow that was named;
// offline (or when it is switched off) the built-in assistant answers simple
// farm questions from the records. An answer about a named cow is saved to
// that cow's health history. Safety rules: shared/aiChat.ts.

import Link from 'next/link';
import { useCallback, useEffect, useMemo, useRef, useState, type ClipboardEvent, type DragEvent, type KeyboardEvent } from 'react';
import { ChatText } from '@/components/ChatText';
import { Icon, type IconName } from '@/components/Icon';
import { MethodBadge } from '@/components/ai';
import { Dialog, useToast } from '@/components/ui';
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
  CHAT_FAIL,
  chatActions,
  chatFollowUps,
  chatHistory,
  chatTitle,
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
import { askGemini, ChatError } from '@/lib/aiChatClient';
import { groupChats, loadChats, searchChats, storeChats, upsertChat, type SavedChat, type SavedTurn } from '@/lib/aiChatStore';
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
type Turn = SavedTurn;

const ICON: Record<Kind, IconName> = { photo: 'camera', video: 'play', audio: 'play', pdf: 'list', text: 'list' };

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
  const toast = useToast();
  const [text, setText] = useState('');
  const [files, setFiles] = useState<Attached[]>([]);
  const [turns, setTurns] = useState<Turn[]>([]);
  const [chatId, setChatId] = useState(() => String(Date.now()));
  const [chats, setChats] = useState<SavedChat[]>([]);
  const [showChats, setShowChats] = useState(false);
  const [find, setFind] = useState('');
  const [busy, setBusy] = useState(false);
  const [problem, setProblem] = useState('');
  const [animalId, setAnimalId] = useState<string | null>(null);
  const pick = useRef<HTMLInputElement>(null);
  const end = useRef<HTMLDivElement>(null);
  const stop = useRef<AbortController | null>(null);
  /** Files of questions asked in this visit, so "Try again" can send them again. They are never saved. */
  const sentFiles = useRef(new Map<number, Attached[]>());
  const day = kampalaNow(new Date()).iso.slice(0, 10);
  const logs = useRecords<{ feature?: string; ok?: boolean }>(farm.id, 'aiLog', day);
  const usedToday = logs.data.filter((l) => l.body.feature === 'chat' && l.body.ok).length;
  const limit = photoAllowed(usedToday, cfg.ai.photo);
  const animals = useMemo(() => alive(ai.data.animals).filter(isActive), [ai.data.animals]);
  const about = animals.find((a) => a.id === animalId);

  useEffect(() => {
    const id = new URL(window.location.href).searchParams.get('animal');
    if (id) setAnimalId(id);
    const saved = loadChats(farm.id);
    setChats(saved);
    // Pick up the chat that was open last time on this device.
    try {
      const last = window.localStorage.getItem(`farmtap.ai.open.${farm.id}`);
      const c = saved.find((x) => x.id === last);
      if (c && !id) {
        setChatId(c.id);
        setTurns(c.turns);
      }
    } catch {
      /* start empty */
    }
  }, [farm.id]);

  useEffect(() => {
    if (!turns.length) return;
    const first = turns.find((t) => t.who === 'me');
    setChats((list) => {
      const next = upsertChat(list, { id: chatId, title: chatTitle(first?.text ?? ''), updatedAt: Date.now(), turns: turns.map((t) => ({ ...t, files: t.files?.map((f) => ({ name: f.name, kind: f.kind })) })) });
      storeChats(farm.id, next);
      return next;
    });
    try {
      window.localStorage.setItem(`farmtap.ai.open.${farm.id}`, chatId);
    } catch {
      /* not kept */
    }
    end.current?.scrollIntoView({ block: 'end', behavior: 'smooth' });
  }, [turns, chatId, farm.id]);

  const newChat = useCallback(() => {
    stop.current?.abort();
    setTurns([]);
    setChatId(String(Date.now()));
    setFiles([]);
    setProblem('');
    setText('');
    setShowChats(false);
    try {
      window.localStorage.removeItem(`farmtap.ai.open.${farm.id}`);
    } catch {
      /* ok */
    }
  }, [farm.id]);
  const openChat = (c: SavedChat) => {
    stop.current?.abort();
    setChatId(c.id);
    setTurns(c.turns);
    setShowChats(false);
  };
  const removeChat = (id: string) => {
    const next = chats.filter((c) => c.id !== id);
    setChats(next);
    storeChats(farm.id, next);
    if (id === chatId) newChat();
  };

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

  /** Answers one question. `before` is every turn that came before it. */
  const answer = async (question: string, sent: Attached[], before: Turn[], meId: number) => {
    if (!user) return;
    const t0 = performance.now();
    setBusy(true);
    const aiId = meId + 1;
    const cows = animals.map((a) => ({ id: a.id, name: a.body.name ?? null, tag: a.body.tagNumber ?? null }));
    const named = findAnimalMention(question, cows) ?? animalId;
    if (named !== animalId) setAnimalId(named);
    const cow = animals.find((a) => a.id === named);
    const cowRef = cow ? { id: cow.id, name: animalName(cow) } : null;
    const names = nameLabels({ animals: animals.map((a) => a.body), people: [user.displayName ?? ''], places: [farm.name] });
    const calc = ask(question, ai.data, { role: farm.role, cfg: cfg.ai, farmAiOn: true });
    const calcText = calc.ok ? [calc.text, ...calc.bullets.map((b) => `- ${b}`)].join('\n') : null;
    const finish = (t: Omit<Turn, 'id' | 'who'>) => setTurns((ts) => [...ts, { id: aiId, who: 'ai', asked: question, ...t }]);
    const offlineAnswer = (note: string, detail?: string) => {
      logAi(farm.id, 'assistant', calc.ok, performance.now() - t0, calc.method);
      const shown = calc.ok ? calcText! : `${note}\n\nI can answer simple questions about your milk, animals, feed and money from your records, even without internet.`;
      const actions = chatActions({ question, answer: shown, health: false, callVet: null, animal: cowRef });
      if (!actions.length && calc.links[0]) actions.push({ label: `Go to ${calc.links[0].label}`, href: calc.links[0].href });
      finish({ text: shown, method: calc.method, aboutAnimal: cow ? animalName(cow) : undefined, note: calc.ok ? note : undefined, detail, actions });
    };
    const online = cfg.ai.photo.enabled && limit.ok && typeof navigator !== 'undefined' && navigator.onLine;
    if (!online) {
      const why = !cfg.ai.photo.enabled ? 'Online AI is not switched on for FarmTap yet.' : !limit.ok ? 'Your farm has used all online AI answers for today.' : 'There is no internet.';
      offlineAnswer(sent.length ? `${why} Files and photos could not be read.` : why);
      setBusy(false);
      return;
    }
    const ctl = new AbortController();
    stop.current = ctl;
    try {
      const facts = cow ? animalFacts(animalHealth(ai.data, cow.id), cow.body, day) : [];
      const prompt = buildChatPrompt({ message: redact(question, names), facts, calculated: calcText ? redact(calcText, names) : null, files: sent.map((f) => ({ kind: f.kind })) });
      const history = chatHistory(before.filter((t) => t.text).map((t) => ({ role: t.who === 'me' ? ('user' as const) : ('model' as const), text: redact(t.text, names) })));
      const got = await askGemini({ system: CHAT_SYSTEM, history, prompt, files: sent.map((f) => ({ mime: f.mime, base64: f.base64 })), model: cfg.ai.photo.model, signal: ctl.signal });
      const reply = readChatReply(got.text, question);
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
      const grounding = got.grounding ? { ...got.grounding, queries: got.grounding.queries.map((q) => restore(q, names)) } : null;
      finish({
        text: shown,
        method: 'model',
        aboutAnimal: cow ? animalName(cow) : undefined,
        saved,
        note: reply.removed ? 'Some details about medicines were left out. Ask your vet.' : undefined,
        actions: chatActions({ question, answer: shown, health: reply.health, callVet: reply.callVet, animal: cowRef }),
        followUps: chatFollowUps({ question, answer: shown, health: reply.health }),
        grounding,
      });
    } catch (e) {
      if ((e as Error)?.name === 'AbortError') {
        setTurns((ts) => [...ts, { id: aiId, who: 'ai', asked: question, text: 'Stopped.', note: 'You stopped this answer.' }]);
        return;
      }
      logAi(farm.id, 'chat', false, performance.now() - t0, 'model');
      const err = e instanceof ChatError ? e : new ChatError('unreadable', String((e as Error)?.message ?? e));
      offlineAnswer(`${CHAT_FAIL[err.failure]}${sent.length ? ' Files and photos could not be read.' : ''}`, err.detail);
    } finally {
      stop.current = null;
      setBusy(false);
    }
  };

  const send = (override?: string) => {
    const q = (override ?? text).trim();
    if ((!q && !files.length) || busy || ai.loading || !user) return;
    const question = q || 'Please look at what I attached.';
    const sent = override ? [] : files;
    const me: Turn = { id: Date.now(), who: 'me', text: question, files: sent.map((f) => ({ name: f.name, kind: f.kind, thumb: f.thumb })) };
    sentFiles.current.set(me.id, sent);
    setText('');
    setFiles([]);
    setProblem('');
    const before = turns.map((t) => (t.followUps ? { ...t, followUps: undefined } : t));
    setTurns([...before, me]);
    void answer(question, sent, before, me.id);
  };

  const again = (aiTurn: Turn) => {
    if (busy) return;
    const i = turns.findIndex((t) => t.id === aiTurn.id);
    const me = turns[i - 1];
    if (i < 1 || me?.who !== 'me') return;
    const before = turns.slice(0, i - 1);
    setTurns(turns.slice(0, i));
    void answer(me.text, sentFiles.current.get(me.id) ?? [], before, me.id);
  };

  const copy = async (t: string) => {
    try {
      await navigator.clipboard.writeText(t);
      toast('Copied');
    } catch {
      toast('Could not copy');
    }
  };

  const onKey = (e: KeyboardEvent<HTMLTextAreaElement>) => {
    if (e.key === 'Enter' && !e.shiftKey && !e.nativeEvent.isComposing) {
      e.preventDefault();
      send();
    }
  };

  const shownChats = useMemo(() => searchChats(chats, find), [chats, find]);
  const title = chats.find((c) => c.id === chatId)?.title;
  const lastAi = [...turns].reverse().find((t) => t.who === 'ai');

  if (!farmAiOn(farm, cfg)) return <AiOff reason="AI Intelligence is switched off for this farm. Contact FarmTap support to turn it on." />;
  if (!page.allowed) return <AiOff reason="This part of AI Intelligence is not available to your role or has been switched off." />;

  return (
    <div className="chat" onDragOver={(e) => e.preventDefault()} onDrop={onDrop}>
      <div className="chat-top">
        <button className="btn sm ghost" onClick={() => setShowChats(true)} aria-label="Open your chats">
          <Icon name="clock" /> Chats
        </button>
        <h1 className="chat-title">{title ?? 'FarmTap AI'}</h1>
        <div className="row">
          <button className="icon-btn" aria-label="New chat" title="New chat" onClick={newChat}>
            <Icon name="edit" />
          </button>
          <Link className="icon-btn" aria-label="Insights and tools" title="Insights and tools" href="/ai/tools/">
            <Icon name="more" />
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
                        {'thumb' in f && f.thumb ? <img src={String(f.thumb)} alt="" /> : <Icon name={ICON[f.kind as Kind] ?? 'list'} />}
                        <span className="small">{f.name}</span>
                      </span>
                    ))}
                  </div>
                )}
                <p>{t.text}</p>
              </div>
            ) : (
              <div key={t.id} className="chat-ai" role="article">
                <span className="chat-avatar" aria-hidden>
                  <Icon name="spark" />
                </span>
                <div className="chat-answer">
                  <ChatText text={t.text} />
                  {t.actions && t.actions.length > 0 && (
                    <div className="chat-actions">
                      {t.actions.map((a) => (
                        <Link key={a.href} className="btn sm ghost" href={a.href}>
                          {a.label} <Icon name="chevron" />
                        </Link>
                      ))}
                    </div>
                  )}
                  {t.grounding && t.grounding.sources.length > 0 && (
                    <div className="chat-sources">
                      <span className="small muted">Sources from Google</span>
                      <div className="chips">
                        {t.grounding.sources.map((s) => (
                          <a key={s.uri} className="chip" href={s.uri} target="_blank" rel="noopener noreferrer">
                            <Icon name="link" /> {s.title}
                          </a>
                        ))}
                      </div>
                    </div>
                  )}
                  {t.grounding?.suggestionsHtml && <iframe className="chat-suggest" title="Google Search suggestions" sandbox="allow-popups allow-popups-to-escape-sandbox" srcDoc={t.grounding.suggestionsHtml} />}
                  <div className="chat-meta">
                    {t.method && <MethodBadge method={t.method} />}
                    {t.saved && (
                      <span className="chip ok">
                        <Icon name="check" /> Saved to {t.aboutAnimal ?? 'the animal'}’s history
                      </span>
                    )}
                    {t.note && <span className="small muted">{t.note}</span>}
                  </div>
                  {t.detail && (
                    <details className="chat-detail small muted">
                      <summary>Details for the FarmTap owner</summary>
                      <code>{t.detail}</code>
                    </details>
                  )}
                  <div className="chat-bar">
                    <button className="icon-btn" aria-label="Copy answer" title="Copy" onClick={() => void copy(t.text)}>
                      <Icon name="copy" />
                    </button>
                    {t.asked && (
                      <button className="icon-btn" aria-label="Ask again" title="Ask again" disabled={busy} onClick={() => again(t)}>
                        <Icon name="refresh" />
                      </button>
                    )}
                  </div>
                  {t === lastAi && !busy && t.followUps && t.followUps.length > 0 && (
                    <div className="chips chat-follow">
                      {t.followUps.map((f) => (
                        <button key={f} className="chip brand chip-btn" onClick={() => send(f)}>
                          {f}
                        </button>
                      ))}
                    </div>
                  )}
                </div>
              </div>
            ),
          )}
          {busy && (
            <div className="chat-ai muted" role="status">
              <span className="chat-avatar" aria-hidden>
                <Icon name="spark" />
              </span>
              <span className="row chat-answer">Thinking and searching…</span>
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
            {busy ? (
              <button className="btn sm" aria-label="Stop" onClick={() => stop.current?.abort()}>
                <Icon name="stop" />
              </button>
            ) : (
              <button className="btn sm" aria-label="Send" disabled={ai.loading || (!text.trim() && !files.length)} onClick={() => send()}>
                <Icon name="up" />
              </button>
            )}
          </div>
        </div>
        <p className="small muted">FarmTap AI can make mistakes and never replaces your vet. Answers can use Google Search.</p>
      </div>
      {showChats && (
        <Dialog title="Your chats" subtitle="Kept on this phone or computer only." onClose={() => setShowChats(false)}>
          <div className="stack">
            <button className="btn" onClick={newChat}>
              <Icon name="edit" /> New chat
            </button>
            <input className="input" type="search" placeholder="Search your chats" aria-label="Search your chats" value={find} onChange={(e) => setFind(e.target.value)} />
            {groupChats(shownChats, Date.now()).map((g) => (
              <div key={g.label} className="stack chat-group">
                <span className="small muted">{g.label}</span>
                {g.chats.map((c) => (
                  <div key={c.id} className={`chat-row${c.id === chatId ? ' on' : ''}`}>
                    <button className="chat-row-open" onClick={() => openChat(c)}>
                      {c.title}
                    </button>
                    <button className="icon-btn" aria-label={`Delete ${c.title}`} onClick={() => removeChat(c.id)}>
                      <Icon name="trash" />
                    </button>
                  </div>
                ))}
              </div>
            ))}
            {!shownChats.length && <p className="small muted">{chats.length ? 'No chat matches that.' : 'Your chats will show here.'}</p>}
          </div>
        </Dialog>
      )}
    </div>
  );
}
