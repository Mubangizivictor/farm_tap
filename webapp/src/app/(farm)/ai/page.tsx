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
import { CaseCard, ChatThinking, CowPicker, TriageCard, type SharePhoto } from '@/components/ChatCards';
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
  CHAT_LANGUAGES,
  caseText,
  chatActions,
  chatDoActions,
  chatModels,
  needsSearch,
  partialChatText,
  triageOf,
  vetSummary,
  whatsappLink,
  type CaseAnswers,
  type CaseId,
  type ChatReply,
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
import { alive as aliveRec, type ContactBody } from '@/lib/domain';
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

const IDEAS = ['My cow has a swollen udder', 'How do I stop mastitis?', 'How much milk did we collect this week?', 'What should I feed when milk drops?'];

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
  const [live, setLive] = useState('');
  const liveRef = useRef('');
  const [status, setStatus] = useState('');
  const [speaking, setSpeaking] = useState<number | null>(null);
  const [caseInfo, setCaseInfo] = useState<CaseAnswers>({});
  const [lang, setLang] = useState('auto');
  const [skipPick, setSkipPick] = useState<Set<number>>(new Set());
  const contacts = useRecords<ContactBody>(farm.id, 'contacts');
  const vet = useMemo(() => aliveRec(contacts.data).find((c) => c.body.kind === 'vet' && (c.body.phone ?? '').replace(/\D/g, '').length >= 9), [contacts.data]);
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
    try {
      setLang(window.localStorage.getItem('farmtap.ai.lang') ?? 'auto');
    } catch {
      /* default */
    }
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
    // A new answer is shown from its first line; a new question from the bottom.
    const last = turns[turns.length - 1];
    const el = last?.who === 'ai' ? document.getElementById(`t${last.id}`) : null;
    (el ?? end.current)?.scrollIntoView({ block: el ? 'start' : 'end', behavior: 'smooth' });
  }, [turns, chatId, farm.id]);

  useEffect(() => {
    if (live) end.current?.scrollIntoView({ block: 'end' });
  }, [live]);
  useEffect(
    () => () => {
      if (typeof window !== 'undefined') window.speechSynthesis?.cancel();
    },
    [],
  );

  const newChat = useCallback(() => {
    stop.current?.abort();
    setTurns([]);
    setCaseInfo({});
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
    setCaseInfo({});
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
    setStatus('');
    liveRef.current = '';
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
      const media = sent.some((f) => f.kind === 'photo' || f.kind === 'video');
      const search = needsSearch(question, { calculated: calc.ok, animal: !!cow });
      const prompt = buildChatPrompt({ message: redact(question, names), facts, calculated: calcText ? redact(calcText, names) : null, files: sent.map((f) => ({ kind: f.kind })), search, language: lang });
      const history = chatHistory(before.filter((t) => t.text).map((t) => ({ role: t.who === 'me' ? ('user' as const) : ('model' as const), text: redact(t.text, names) })));
      const got = await askGemini({ system: CHAT_SYSTEM, history, prompt, files: sent.map((f) => ({ mime: f.mime, base64: f.base64 })), models: chatModels(cfg.ai.photo.model, media), search, signal: ctl.signal, onStatus: setStatus, onText: (t) => { liveRef.current = partialChatText(t); setLive(liveRef.current); } });
      const reply = readChatReply(got.text, question);
      const shown = restore(reply.text, names);
      logAi(farm.id, 'chat', true, performance.now() - t0, 'model');
      let saved = false;
      if (cow && canSave) {
        try {
          const body = chatAssessmentBody(cow.id, question, { ...reply, text: shown }, [...new Set(sent.map((f) => f.kind))], got.model, kampalaNow(new Date()).iso);
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
        triage: triageOf({ ...reply, text: shown }, question),
        animalId: cow?.id,
        hadMedia: media,
        model: got.model,
      });
    } catch (e) {
      if ((e as Error)?.name === 'AbortError') {
        const part = restore(liveRef.current, names).trim();
        setTurns((ts) => [...ts, { id: aiId, who: 'ai', asked: question, text: part || 'Stopped.', note: part ? 'You stopped this answer early.' : 'You stopped this answer.' }]);
        return;
      }
      logAi(farm.id, 'chat', false, performance.now() - t0, 'model');
      const err = e instanceof ChatError ? e : new ChatError('unreadable', String((e as Error)?.message ?? e));
      offlineAnswer(`${CHAT_FAIL[err.failure]}${sent.length ? ' Files and photos could not be read.' : ''}`, err.detail);
    } finally {
      stop.current = null;
      setLive('');
      setStatus('');
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

  /** Puts a question back in the box so it can be changed and sent again. */
  const edit = (t: Turn) => {
    if (busy) return;
    const i = turns.findIndex((x) => x.id === t.id);
    if (i < 0) return;
    setText(t.text);
    setFiles(sentFiles.current.get(t.id) ?? []);
    setTurns(turns.slice(0, i));
    document.querySelector<HTMLTextAreaElement>('.chat-box textarea')?.focus();
  };
  const vote = (t: Turn, v: 'up' | 'down') => {
    setTurns((ts) => ts.map((x) => (x.id === t.id ? { ...x, vote: x.vote === v ? undefined : v } : x)));
    toast(t.vote === v ? 'Feedback removed' : v === 'up' ? 'Marked as helpful' : 'Marked as not helpful');
  };
  const speak = (t: Turn) => {
    const synth = typeof window !== 'undefined' ? window.speechSynthesis : undefined;
    if (!synth) return;
    if (speaking === t.id) {
      synth.cancel();
      setSpeaking(null);
      return;
    }
    synth.cancel();
    const u = new SpeechSynthesisUtterance(t.text.replace(/[*#]/g, ''));
    u.onend = () => setSpeaking(null);
    u.onerror = () => setSpeaking(null);
    setSpeaking(t.id);
    synth.speak(u);
  };
  const canSpeak = typeof window !== 'undefined' && 'speechSynthesis' in window;
  const clock = (id: number) => new Date(id).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });

  const copy = async (t: string) => {
    try {
      await navigator.clipboard.writeText(t);
      toast('Copied');
    } catch {
      toast('Could not copy');
    }
  };

  const cowOf = (t: Turn) => animals.find((a) => a.id === t.animalId);
  const photosOf = (t: Turn): SharePhoto[] => {
    const me = turns[turns.findIndex((x) => x.id === t.id) - 1];
    return (me ? (sentFiles.current.get(me.id) ?? []) : []).filter((f) => f.kind === 'photo').map((f) => ({ name: f.name, mime: f.mime, base64: f.base64 }));
  };
  const messageOf = (t: Turn) => {
    const cow = cowOf(t);
    const label = cow ? `${animalName(cow)}${cow.body.name && cow.body.tagNumber ? ` (${cow.body.tagNumber})` : ''}` : '';
    return vetSummary({
      farm: farm.name,
      animal: cow ? { label, facts: animalFacts(animalHealth(ai.data, cow.id), cow.body, day) } : null,
      question: t.asked ?? '',
      answer: t.text,
      answers: caseInfo,
      triage: t.triage ?? null,
      hasPhoto: photosOf(t).length > 0 || !!t.hadMedia,
      day,
    });
  };
  const pickCow = async (t: Turn, id: string) => {
    const cow = animals.find((a) => a.id === id);
    if (!cow || !user) return;
    setAnimalId(id);
    let saved = false;
    if (canSave) {
      try {
        const me = turns[turns.findIndex((x) => x.id === t.id) - 1];
        const kinds = [...new Set((me?.files ?? []).map((f) => f.kind))];
        const tr = t.triage;
        const risk: ChatReply['risk'] = tr?.level === 'now' ? 'critical' : tr?.level === 'today' ? 'high' : tr ? 'medium' : 'low';
        const body = chatAssessmentBody(id, t.asked ?? '', { text: t.text, removed: 0, health: !!tr, risk, callVet: tr?.level ?? null, report: !!tr?.report }, kinds, t.model ?? cfg.ai.photo.model, kampalaNow(new Date()).iso);
        await addRecord(firebase().db, farm.id, 'healthAssessments', user.uid, body as unknown as Record<string, unknown>);
        saved = true;
      } catch {
        saved = false;
      }
    }
    setTurns((ts) => ts.map((x) => (x.id === t.id ? { ...x, animalId: id, aboutAnimal: animalName(cow), saved } : x)));
    toast(saved ? `Saved to ${animalName(cow)}’s history` : 'Could not save to the history');
  };
  const answerCase = (id: CaseId, v: string) => setCaseInfo((a) => ({ ...a, [id]: v }));

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
              <p className="muted">Ask about a sick animal, milk, feed or money. Add a photo and I will look at it.</p>
              <div className="chips chat-ideas">
                {IDEAS.map((q) => (
                  <button key={q} className="chip chip-btn" onClick={() => send(q)}>
                    {q}
                  </button>
                ))}
              </div>
            </div>
          )}
          {turns.map((t) =>
            t.who === 'me' ? (
              <div key={t.id} className="chat-me-wrap">
              <div className="chat-me">
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
              <div className="chat-bar end">
                <span className="small muted chat-time">{clock(t.id)}</span>
                <button className="icon-btn" aria-label="Copy your message" title="Copy" onClick={() => void copy(t.text)}>
                  <Icon name="copy" />
                </button>
                <button className="icon-btn" aria-label="Edit your message" title="Edit and ask again" disabled={busy} onClick={() => edit(t)}>
                  <Icon name="edit" />
                </button>
              </div>
              </div>
            ) : (
              <div key={t.id} id={`t${t.id}`} className={`chat-ai${t === lastAi ? ' last' : ''}`} role="article">
                <span className="chat-avatar" aria-hidden>
                  <Icon name="spark" />
                </span>
                <div className="chat-answer">
                  <ChatText text={t.text} />
                  {t.triage && (
                    <TriageCard
                      triage={t.triage}
                      message={messageOf(t)}
                      whatsapp={whatsappLink(vet?.body.phone, messageOf(t)) ?? whatsappLink(null, messageOf(t))!}
                      vetName={vet?.body.name ?? null}
                      photos={photosOf(t)}
                      toast={toast}
                    />
                  )}
                  {t.method === 'model' && !t.animalId && (t.triage || t.hadMedia) && !skipPick.has(t.id) && (
                    <CowPicker animals={animals.map((a) => ({ id: a.id, label: `${animalName(a)}${a.body.name && a.body.tagNumber ? ` (${a.body.tagNumber})` : ''}` }))} onPick={(id) => void pickCow(t, id)} onSkip={() => setSkipPick(new Set(skipPick).add(t.id))} />
                  )}
                  {(() => {
                    const cow = cowOf(t);
                    const acts = t.method === 'model' ? chatActions({ question: t.asked ?? '', answer: t.text, health: !!t.triage, callVet: t.triage?.level ?? null, animal: cow ? { id: cow.id, name: animalName(cow) } : null }) : (t.actions ?? []);
                    const dos = chatDoActions({ animal: cow ? { id: cow.id, name: animalName(cow) } : null, triage: t.triage ?? null, day });
                    return acts.length + dos.length > 0 ? (
                      <div className="chat-actions">
                        {[...dos, ...acts].map((a) => (
                          <Link key={a.href} className="btn sm ghost" href={a.href}>
                            {a.label} <Icon name="chevron" />
                          </Link>
                        ))}
                      </div>
                    ) : null;
                  })()}
                  {t === lastAi && t.triage && !busy && <CaseCard answers={caseInfo} animalKnown={!!t.animalId} onAnswer={answerCase} busy={busy} onSend={() => send(`More details about this animal. ${caseText(caseInfo)}.`)} />}
                  {t.grounding && t.grounding.sources.length > 0 && (
                    <div className="chat-sources">
                      <span className="small muted" title={t.grounding.queries.length > 0 ? `Searched: ${t.grounding.queries.join(', ')}` : undefined}>
                        Sources from Google
                      </span>
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
                  {(t.saved || t.note) && (
                    <div className="chat-meta">
                      {t.saved && (
                        <span className="chip ok">
                          <Icon name="check" /> Saved to {t.aboutAnimal ?? 'the animal'}’s history
                        </span>
                      )}
                      {t.note && <span className="small muted">{t.note}</span>}
                    </div>
                  )}
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
                    {t.method === 'model' && (
                      <>
                        <button className={`icon-btn${t.vote === 'up' ? ' on' : ''}`} aria-label="Good answer" aria-pressed={t.vote === 'up'} title="Good answer" onClick={() => vote(t, 'up')}>
                          <Icon name="thumbUp" />
                        </button>
                        <button className={`icon-btn${t.vote === 'down' ? ' on' : ''}`} aria-label="Bad answer" aria-pressed={t.vote === 'down'} title="Bad answer" onClick={() => vote(t, 'down')}>
                          <Icon name="thumbDown" />
                        </button>
                      </>
                    )}
                    {canSpeak && (
                      <button className={`icon-btn${speaking === t.id ? ' on' : ''}`} aria-label={speaking === t.id ? 'Stop reading aloud' : 'Read aloud'} title={speaking === t.id ? 'Stop reading' : 'Read aloud'} onClick={() => speak(t)}>
                        <Icon name={speaking === t.id ? 'stop' : 'volume'} />
                      </button>
                    )}
                    {t.asked && (
                      <button className="icon-btn" aria-label="Ask again" title="Ask again" disabled={busy} onClick={() => again(t)}>
                        <Icon name="refresh" />
                      </button>
                    )}
                    {t.method && <MethodBadge method={t.method} />}
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
            <div className="chat-ai">
              <span className="chat-avatar working" aria-hidden>
                <Icon name="spark" />
              </span>
              <div className="chat-answer">
                {live && <ChatText text={live} streaming />}
                <ChatThinking status={status} hasText={!!live} />
              </div>
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
            <select
              className="chat-lang"
              aria-label="Reply language"
              title="Reply language"
              value={lang}
              onChange={(e) => {
                setLang(e.target.value);
                try {
                  window.localStorage.setItem('farmtap.ai.lang', e.target.value);
                } catch {
                  /* not kept */
                }
              }}
            >
              {CHAT_LANGUAGES.map((l) => (
                <option key={l.id} value={l.id}>
                  {l.id === 'auto' ? 'Language: auto' : l.label}
                </option>
              ))}
            </select>
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
