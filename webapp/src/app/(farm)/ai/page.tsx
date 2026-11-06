'use client';

// FarmTap AI chat (decision 0027): one box. Type, talk, or attach photos, PDFs, files or a short
// video, and get an answer. Online, Google Gemini answers with FarmTap's facts about the cow that
// was named; offline (or when it is switched off) the built-in assistant answers simple farm
// questions from the records. An answer about a named cow is saved to that cow's health history.
// Safety rules: shared/aiChat.ts. The look: styles/chat.css (design pack farmtap-ai-design).

import Link from 'next/link';
import { useCallback, useEffect, useMemo, useRef, useState, type DragEvent } from 'react';
import { ChatText } from '@/components/ChatText';
import { CaseCard, ChatRefs, ChatThinking, CowPicker, TriageCard, type SharePhoto } from '@/components/ChatCards';
import { Composer, type Attached } from '@/components/chat/Composer';
import { History } from '@/components/chat/History';
import { Lightbox, type LightPhoto } from '@/components/chat/Lightbox';
import { CowCard, PhotoPins, ReplyBar, Sources, UserMsg } from '@/components/chat/Messages';
import { Welcome } from '@/components/chat/Welcome';
import { Icon } from '@/components/Icon';
import { MethodBadge } from '@/components/ai';
import { ChatPopup, popupOf, type Popup } from '@/components/popups/ChatPopup';
import { Dialog, useToast } from '@/components/ui';
import { AiOff, AiState } from '@/components/ai';
import { useAiPage } from '@/components/aiPage';
import { alive, kampalaNow } from '@/shared/aiCore';
import { animalName, isActive } from '@/shared/aiData';
import { animalHealth } from '@/shared/aiHerd';
import { nameLabels, redact, restore } from '@/shared/aiPrivacy';
import { contextFacts, cowSpark, farmToday, type ContextKind } from '@/shared/aiToday';
import {
  animalFacts,
  buildChatPrompt,
  CHAT_MAX_BYTES,
  CHAT_MAX_FILES,
  CHAT_SYSTEM,
  CHAT_UNSUPPORTED,
  caseText,
  chatActions,
  chatAssessmentBody,
  chatCategory,
  chatDoActions,
  chatFileKind,
  chatFollowUps,
  chatHistory,
  chatModels,
  chatTitle,
  findAnimalMention,
  needsSearch,
  partialChatText,
  readChatReply,
  readHeard,
  readPins,
  triageOf,
  vetSummary,
  whatsappLink,
  type CaseAnswers,
  type CaseId,
  type ChatGrounding,
  type ChatReply,
} from '@/shared/aiChat';
import { farmAiOn, logAi } from '@/lib/ai';
import { askGemini, ChatError } from '@/lib/aiChatClient';
import { askServer, AiRequestError, serverUsage as fetchServerUsage } from '@/lib/aiServerClient';
import { AiErrorCard, AiUsageMeter } from '@/components/AiUsage';
import { classify, layerLabel, workingText } from '@/shared/aiRoute';
import { chatFailureKind, usageView, usageWarning, type AiErrorKind, type UsageView } from '@/shared/aiQuota';
import { chatAsText, printReport } from '@/lib/aiChatExport';
import { loadChats, storeChats, upsertChat, type SavedChat, type SavedTurn } from '@/lib/aiChatStore';
import { addRecord, useRecords } from '@/lib/data';
import { alive as aliveRec, type ContactBody } from '@/lib/domain';
import { firebase } from '@/lib/firebase';
import { shrinkImage } from '@/lib/images';
import { useSession } from '@/lib/session';
import { useRecorder } from '@/lib/useRecorder';

type Turn = SavedTurn;

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
const keep = (k: string, v: string) => {
  try {
    window.localStorage.setItem(k, v);
  } catch {
    /* not kept */
  }
};
const recall = (k: string) => {
  try {
    return window.localStorage.getItem(k);
  } catch {
    return null;
  }
};
const VOICE_Q = 'Please listen to my voice note.';
const URG = { now: 3, today: 2, soon: 1 } as const;

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
  const [menu, setMenu] = useState(false);
  const [busy, setBusy] = useState(false);
  const [problem, setProblem] = useState('');
  const [animalId, setAnimalId] = useState<string | null>(null);
  const [live, setLive] = useState('');
  const liveRef = useRef('');
  const [status, setStatus] = useState('');
  const [popup, setPopup] = useState<Popup | null>(null);
  const [light, setLight] = useState<{ photos: LightPhoto[]; start: number; turn: number } | null>(null);
  const [speaking, setSpeaking] = useState<number | null>(null);
  const [caseInfo, setCaseInfo] = useState<CaseAnswers>({});
  const [lang, setLang] = useState('auto');
  const [searchOn, setSearchOn] = useState(true);
  const [fast, setFast] = useState(false);
  const [context, setContext] = useState<ContextKind[]>([]);
  const [online, setOnline] = useState(true);
  const [skipPick, setSkipPick] = useState<Set<number>>(new Set());
  const contacts = useRecords<ContactBody>(farm.id, 'contacts');
  const vet = useMemo(() => aliveRec(contacts.data).find((c) => c.body.kind === 'vet' && (c.body.phone ?? '').replace(/\D/g, '').length >= 9), [contacts.data]);
  const vetPhone = vet?.body.phone ?? null;
  const end = useRef<HTMLDivElement>(null);
  const stop = useRef<AbortController | null>(null);
  /** Files of questions asked in this visit, so "Try again" and the photo viewer can use them. They are never saved. */
  const sentFiles = useRef(new Map<number, Attached[]>());
  const day = kampalaNow(new Date()).iso.slice(0, 10);
  const logs = useRecords<{ feature?: string; ok?: boolean }>(farm.id, 'aiLog', day);
  const usedToday = logs.data.filter((l) => l.body.feature === 'chat' && l.body.ok).length;
  const assistant = cfg.ai.assistant;
  /** Server route: the server's own count. Client route: counted from this farm's AI log. */
  const [serverUsage, setServerUsage] = useState<UsageView | null>(null);
  const [showUsage, setShowUsage] = useState(false);
  useEffect(() => {
    if (assistant.route !== 'server' || !assistant.enabled) return;
    let live = true;
    void fetchServerUsage(farm.id).then((u) => {
      if (live && u) setServerUsage(u);
    });
    return () => {
      live = false;
    };
  }, [farm.id, assistant.route, assistant.enabled]);
  const usage: UsageView | null = !assistant.enabled ? null : assistant.route === 'server' ? serverUsage : usageView(usedToday, assistant.dailyLimit, assistant.warnPct, 0);
  const animals = useMemo(() => alive(ai.data.animals).filter(isActive), [ai.data.animals]);
  const about = animals.find((a) => a.id === animalId);
  const today = useMemo(() => (ai.loading ? null : farmToday(ai.data)), [ai.data, ai.loading]);
  const rec = useRecorder();

  useEffect(() => {
    const id = new URL(window.location.href).searchParams.get('animal');
    if (id) setAnimalId(id);
    setLang(recall('farmtap.ai.lang') ?? 'auto');
    setSearchOn(recall('farmtap.ai.search') !== 'off');
    setFast(recall('farmtap.ai.fast') === 'on');
    const saved = loadChats(farm.id);
    setChats(saved);
    // Pick up the chat that was open last time on this device.
    const c = saved.find((x) => x.id === recall(`farmtap.ai.open.${farm.id}`));
    if (c && !id) {
      setChatId(c.id);
      setTurns(c.turns);
    }
  }, [farm.id]);
  useEffect(() => {
    const set = () => setOnline(navigator.onLine);
    set();
    window.addEventListener('online', set);
    window.addEventListener('offline', set);
    return () => {
      window.removeEventListener('online', set);
      window.removeEventListener('offline', set);
    };
  }, []);

  useEffect(() => {
    if (!turns.length) return;
    const first = turns.find((t) => t.who === 'me');
    const hadMedia = turns.some((t) => t.hadMedia || t.files?.some((f) => f.kind === 'photo' || f.kind === 'video'));
    const worst = turns.reduce<'now' | 'today' | 'soon' | undefined>((w, t) => (t.triage && (!w || URG[t.triage.level] > URG[w]) ? t.triage.level : w), undefined);
    const cow = [...turns].reverse().find((t) => t.aboutAnimal)?.aboutAnimal;
    setChats((list) => {
      const next = upsertChat(list, {
        id: chatId,
        title: chatTitle(first?.text ?? ''),
        updatedAt: Date.now(),
        cat: chatCategory({ question: first?.text ?? '', hadMedia, health: !!worst }),
        urg: worst,
        cow,
        turns: turns.map((t) => ({ ...t, files: t.files?.map((f) => ({ name: f.name, kind: f.kind })) })),
      });
      storeChats(farm.id, next);
      return next;
    });
    keep(`farmtap.ai.open.${farm.id}`, chatId);
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
    rec.cancel();
    setTurns([]);
    setCaseInfo({});
    setChatId(String(Date.now()));
    setFiles([]);
    setProblem('');
    setText('');
    setContext([]);
    setShowChats(false);
    setMenu(false);
    try {
      window.localStorage.removeItem(`farmtap.ai.open.${farm.id}`);
    } catch {
      /* ok */
    }
  }, [farm.id, rec]);
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
  const pinChat = (id: string) => {
    setChats((list) => {
      const next = list.map((c) => (c.id === id ? { ...c, pinned: !c.pinned } : c));
      storeChats(farm.id, next);
      return next;
    });
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
  const onDrop = (e: DragEvent) => {
    e.preventDefault();
    if (e.dataTransfer.files.length) void add([...e.dataTransfer.files]);
  };

  /**
   * Answers one question. `before` is every turn that came before it.
   * Decision 0028: the question is classified first. Records and built-in insights answer at once
   * (no AI, no allowance used); only questions that need reasoning, or carry a file, go to the AI.
   */
  const answer = async (question: string, sent: Attached[], before: Turn[], meId: number, ctx: ContextKind[]) => {
    if (!user) return;
    const t0 = performance.now();
    const aiId = meId + 1;
    const cows = animals.map((a) => ({ id: a.id, name: a.body.name ?? null, tag: a.body.tagNumber ?? null }));
    const named = findAnimalMention(question, cows) ?? animalId;
    if (named !== animalId) setAnimalId(named);
    const cow = animals.find((a) => a.id === named);
    const cowRef = cow ? { id: cow.id, name: animalName(cow) } : null;
    const route = classify(question, ai.data, { role: farm.role, cfg: cfg.ai, farmAiOn: true, files: sent.length, maxChars: assistant.maxChars });
    const calc = route.answer;
    const calcText = calc?.ok ? [calc.text, ...calc.bullets.map((b) => `- ${b}`)].join('\n') : null;
    const finish = (t: Omit<Turn, 'id' | 'who'>) => setTurns((ts) => [...ts, { id: aiId, who: 'ai', asked: question, ...t }]);
    /** The built-in answer (layers 1 and 2), with the reason the AI did not answer when it was asked. */
    const builtIn = (errorKind?: AiErrorKind, note?: string) => {
      logAi(farm.id, 'assistant', !!calc?.ok, performance.now() - t0, calc?.method ?? 'calculated');
      const shown = calc
        ? [calc.text, ...calc.bullets.map((b) => `- ${b}`)].join('\n')
        : 'I can answer questions about your milk, animals, breeding, feed and money from your records at any time. Try "How much milk did we produce today?" or "Which cows have reduced production?"';
      const actions = chatActions({ question, answer: shown, health: false, callVet: null, animal: cowRef });
      if (!actions.length && calc?.links[0]) actions.push({ label: `Go to ${calc.links[0].label}`, href: calc.links[0].href });
      finish({ text: shown, method: calc?.method ?? 'calculated', layer: route.layer === 'records' ? 'records' : 'insight', errorKind, aboutAnimal: cow ? animalName(cow) : undefined, note, actions });
    };
    if (route.reason === 'tooLong') {
      finish({ text: `Keep your question under ${assistant.maxChars.toLocaleString('en-US')} characters.`, method: 'calculated', layer: 'insight', errorKind: 'invalid' });
      return;
    }
    // Layers 1 and 2: straight away, no spinner, unlimited.
    if (route.layer !== 'ai') {
      builtIn();
      return;
    }
    const lost = sent.length ? 'Files and photos could not be read.' : undefined;
    const blocked: AiErrorKind | null = !assistant.enabled ? 'disabled' : usage && usage.level === 'out' ? 'limit' : typeof navigator !== 'undefined' && !navigator.onLine ? 'network' : null;
    if (blocked) {
      builtIn(blocked, lost);
      return;
    }
    setBusy(true);
    setStatus(workingText('ai', 'model'));
    liveRef.current = '';
    const ctl = new AbortController();
    stop.current = ctl;
    const names = nameLabels({ animals: animals.map((a) => a.body), people: [user.displayName ?? ''], places: [farm.name] });
    const onText = (t: string) => {
      liveRef.current = readHeard(partialChatText(t)).text;
      setLive(liveRef.current);
    };
    try {
      const facts = [...(cow ? animalFacts(animalHealth(ai.data, cow.id), cow.body, day) : []), ...ctx.flatMap((k) => contextFacts(k, ai.data))];
      const media = sent.some((f) => f.kind === 'photo' || f.kind === 'video');
      const search = searchOn && needsSearch(question, { calculated: !!calc?.ok, animal: !!cow });
      const message = redact(question, names);
      const calculated = calcText ? redact(calcText, names) : null;
      const history = chatHistory(before.filter((t) => t.text && !t.errorKind).map((t) => ({ role: t.who === 'me' ? ('user' as const) : ('model' as const), text: redact(t.text, names) })));
      const parts = sent.map((f) => ({ mime: f.mime, base64: f.base64 }));
      let got: { text: string; grounding: ChatGrounding | null; model: string };
      if (assistant.route === 'server') {
        const r = await askServer({ tenantId: farm.id, message, facts, calculated, history, files: parts, language: lang === 'auto' ? null : lang, search }, { signal: ctl.signal, timeoutMs: assistant.timeoutMs, onText });
        setServerUsage(r.usage);
        got = r;
      } else {
        const prompt = buildChatPrompt({ message, facts, calculated, files: sent.map((f) => ({ kind: f.kind })), search, language: lang });
        let models = chatModels(assistant.model, media);
        const lite = models.find((m) => /lite/i.test(m));
        if (fast && lite) models = [lite, ...models.filter((m) => m !== lite)];
        got = await askGemini({ system: CHAT_SYSTEM, history, prompt, files: parts, models, search, signal: ctl.signal, onStatus: setStatus, onText });
      }
      const heard = readHeard(got.text);
      const pinned = readPins(heard.text);
      const reply = readChatReply(pinned.text, question);
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
      const hasPhoto = sent.some((f) => f.kind === 'photo');
      finish({
        text: shown,
        method: 'model',
        layer: 'ai',
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
        heard: heard.heard ? restore(heard.heard, names) : undefined,
        pins: hasPhoto && pinned.pins.length ? pinned.pins.map((p) => ({ ...p, label: restore(p.label, names) })) : undefined,
      });
    } catch (e) {
      if ((e as Error)?.name === 'AbortError') {
        const part = restore(liveRef.current, names).trim();
        setTurns((ts) => [...ts, { id: aiId, who: 'ai', asked: question, text: part || 'Stopped.', note: part ? 'You stopped this answer early.' : 'You stopped this answer.' }]);
        return;
      }
      logAi(farm.id, 'chat', false, performance.now() - t0, 'model');
      let kind: AiErrorKind = 'unavailable';
      if (e instanceof AiRequestError) {
        kind = e.kind;
        if (e.usage) setServerUsage(e.usage);
      } else if (e instanceof ChatError) {
        kind = chatFailureKind(e.failure, e.detail);
        // For the FarmTap owner in the browser console only; farmers see the plain card.
        console.warn('[FarmTap AI]', e.failure, e.detail);
      }
      builtIn(kind, lost);
    } finally {
      stop.current = null;
      setLive('');
      setStatus('');
      setBusy(false);
    }
  };

  const submit = (question: string, sent: Attached[], voiceSeconds?: number) => {
    const ctx = context;
    const me: Turn = { id: Date.now(), who: 'me', text: question, files: sent.map((f) => ({ name: f.name, kind: f.kind })), voice: voiceSeconds };
    sentFiles.current.set(me.id, sent);
    setText('');
    setFiles([]);
    setProblem('');
    setContext([]);
    const before = turns.map((t) => (t.followUps ? { ...t, followUps: undefined } : t));
    setTurns([...before, me]);
    void answer(question, sent, before, me.id, ctx);
  };
  const send = (override?: string) => {
    const q = (override ?? text).trim();
    if ((!q && !files.length) || busy || ai.loading || !user) return;
    const sent = override ? [] : files;
    const voice = sent.find((f) => f.kind === 'audio');
    submit(q || (voice ? VOICE_Q : 'Please look at what I attached.'), sent, voice?.seconds);
  };

  const sendVoice = async () => {
    const note = await rec.stop();
    if (!note) return;
    const f: Attached = { name: 'Voice note', mime: 'audio/wav', kind: 'audio', base64: note.base64, seconds: note.seconds };
    if (busy || !user) {
      setFiles([...files, f]);
      return;
    }
    submit(text.trim() || VOICE_Q, [...files, f], note.seconds);
  };

  const again = (aiTurn: Turn) => {
    if (busy) return;
    const i = turns.findIndex((t) => t.id === aiTurn.id);
    const me = turns[i - 1];
    if (i < 1 || me?.who !== 'me') return;
    const before = turns.slice(0, i - 1);
    setTurns(turns.slice(0, i));
    void answer(me.text, sentFiles.current.get(me.id) ?? [], before, me.id, []);
  };

  /** Puts a question back in the box so it can be changed and sent again. */
  const edit = (t: Turn) => {
    if (busy) return;
    const i = turns.findIndex((x) => x.id === t.id);
    if (i < 0) return;
    setText(t.text === VOICE_Q ? '' : t.text);
    setFiles(sentFiles.current.get(t.id) ?? []);
    setTurns(turns.slice(0, i));
    document.querySelector<HTMLTextAreaElement>('.ct-ta')?.focus();
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
  const copy = async (t: string) => {
    try {
      await navigator.clipboard.writeText(t);
      toast('Copied');
    } catch {
      toast('Could not copy');
    }
  };
  const share = async (t: string) => {
    try {
      if (navigator.share) await navigator.share({ text: t });
      else await copy(t);
    } catch {
      /* the farmer closed the share sheet */
    }
  };

  const cowOf = (t: Turn) => animals.find((a) => a.id === t.animalId);
  const meOf = (t: Turn) => turns[turns.findIndex((x) => x.id === t.id) - 1];
  const photosOf = (t: Turn): SharePhoto[] => {
    const me = meOf(t);
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
        const me = meOf(t);
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
  const openPhotos = (t: Turn, start: number) => {
    const me = t.who === 'me' ? t : meOf(t);
    const ph = (me ? (sentFiles.current.get(me.id) ?? []) : []).filter((f) => f.thumb).map((f) => ({ src: f.thumb!, name: f.name }));
    if (ph.length) setLight({ photos: ph, start, turn: t.who === 'me' ? t.id + 1 : t.id });
  };
  const openDraftPhoto = (i: number) => {
    const ph = files.filter((f) => f.thumb).map((f) => ({ src: f.thumb!, name: f.name }));
    const at = ph.findIndex((p) => p.src === files[i]?.thumb);
    if (ph.length) setLight({ photos: ph, start: Math.max(0, at), turn: -1 });
  };

  const title = chats.find((c) => c.id === chatId)?.title;
  const open = chats.find((c) => c.id === chatId);
  const lastAi = [...turns].reverse().find((t) => t.who === 'ai');
  const lightPins = turns.find((t) => t.id === light?.turn)?.pins ?? [];
  const spoken = (k: string, v: string) => keep(`farmtap.ai.${k}`, v);

  if (!farmAiOn(farm, cfg)) return <AiOff reason="AI Intelligence is switched off for this farm. Contact FarmTap support to turn it on." />;
  if (!page.allowed) return <AiOff reason="This part of AI Intelligence is not available to your role or has been switched off." />;

  const canSend = !!text.trim() || files.length > 0;
  return (
    <div className="ct" onDragOver={(e) => e.preventDefault()} onDrop={onDrop}>
      <header className="ct-top">
        <button className="ct-ib" aria-label="Your chats" title="Your chats" onClick={() => setShowChats(true)}>
          <Icon name="clock" />
        </button>
        <h1 className="ct-title">
          <span className="ct-pill"><span className="live" aria-hidden /> {title ?? 'FarmTap AI'}</span>
          {open?.pinned && <Icon name="pinFill" />}
        </h1>
        {usage && (
          <button className={`ct-chip${usage.level === 'out' ? ' bad' : usage.level === 'warn' ? ' gold' : ' line'}`} onClick={() => setShowUsage(true)} aria-label={`AI requests used: ${usage.used} of ${usage.limit}. Open AI usage`} title="AI assistant usage">
            <Icon name="spark" /> {usage.used}/{usage.limit}
          </button>
        )}
        <button className="ct-ib" aria-label="New chat" title="New chat" onClick={newChat}>
          <Icon name="edit" />
        </button>
        <span className="ct-menuwrap">
          <button className={`ct-ib${menu ? ' on' : ''}`} aria-label="More" aria-expanded={menu} title="More" onClick={() => setMenu(!menu)}>
            <Icon name="more" />
          </button>
          {menu && (
            <>
              <button className="ct-scrim clear" aria-label="Close menu" onClick={() => setMenu(false)} />
              <div className="ct-dropdown" role="menu">
                <button role="menuitem" disabled={!open} onClick={() => { if (open) pinChat(open.id); setMenu(false); }}><Icon name={open?.pinned ? 'pinFill' : 'pin'} /> {open?.pinned ? 'Unpin this chat' : 'Pin this chat'}</button>
                <button role="menuitem" disabled={!open} onClick={() => { if (open) void copy(chatAsText(open)); setMenu(false); }}><Icon name="copy" /> Copy the whole chat</button>
                <button
                  role="menuitem"
                  disabled={!lastAi?.triage}
                  onClick={() => {
                    if (lastAi && !printReport('FarmTap — message for the vet', messageOf(lastAi))) toast('Allow pop-ups to print');
                    setMenu(false);
                  }}
                >
                  <Icon name="print" /> Print the vet report
                </button>
                <Link role="menuitem" href="/ai/tools/"><Icon name="chart" /> Insights and tools</Link>
                <button role="menuitem" className="bad" disabled={!open} onClick={() => { if (open) removeChat(open.id); setMenu(false); }}><Icon name="trash" /> Delete this chat</button>
              </div>
            </>
          )}
        </span>
      </header>
      <AiState ai={ai} skeleton={1}>
        <div className="ct-col ct-msgs" aria-live="polite">
          {turns.length === 0 && (
            <Welcome
              today={today}
              name={(user?.displayName ?? '').split(' ')[0]}
              onAsk={(q) => send(q)}
              onPhoto={() => document.querySelector<HTMLButtonElement>('.ct-tools .ct-ib')?.click()}
              onVoice={() => void rec.start()}
              canVoice={rec.supported}
              usage={usage ? <AiUsageMeter view={usage} trusted={assistant.route === 'server'} /> : null}
            />
          )}
          {turns.map((t) => {
            if (t.who === 'me') return <UserMsg key={t.id} t={t} full={sentFiles.current.get(t.id) ?? []} busy={busy} onOpen={(i) => openPhotos(t, i)} onCopy={() => void copy(t.text)} onEdit={() => edit(t)} />;
            const cow = cowOf(t);
            const photo = (sentFiles.current.get(meOf(t)?.id ?? 0) ?? []).find((f) => f.thumb);
            const acts = t.method === 'model' ? chatActions({ question: t.asked ?? '', answer: t.text, health: !!t.triage, callVet: t.triage?.level ?? null, animal: cow ? { id: cow.id, name: animalName(cow) } : null }) : (t.actions ?? []);
            const dos = chatDoActions({ animal: cow ? { id: cow.id, name: animalName(cow) } : null, triage: t.triage ?? null, day });
            return (
              <div key={t.id} id={`t${t.id}`} className={`ct-ai${t === lastAi ? ' last' : ''}`} role="article">
                <span className="ct-av" aria-hidden><Icon name="spark" /></span>
                <div className="ct-body">
                  <div className="ct-meta">
                    <b>FarmTap AI</b>
                    {cow && <span className="ct-chip gold"><Icon name="cow" /> {animalName(cow)}</span>}
                    {t.layer && <span className="small muted">{layerLabel(t.layer)}</span>}
                    {t.method && <MethodBadge method={t.method} detail={t.layer ? layerLabel(t.layer) : undefined} />}
                  </div>
                  {t.heard && (
                    <div className="ct-heard">
                      <Icon name="mic" />
                      <span><small>I heard</small>“{t.heard}”</span>
                    </div>
                  )}
                  {photo && t.pins && t.pins.length > 0 && <PhotoPins src={photo.thumb!} pins={t.pins} onOpen={() => openPhotos(t, 0)} />}
                  {t.errorKind && <AiErrorCard kind={t.errorKind} limit={usage?.limit ?? assistant.dailyLimit} />}
                  <ChatText text={t.text} />
                  {t.triage && (
                    <TriageCard triage={t.triage} message={messageOf(t)} whatsapp={whatsappLink(vet?.body.phone, messageOf(t)) ?? whatsappLink(null, messageOf(t))!} vetName={vet?.body.name ?? null} photos={photosOf(t)} toast={toast} />
                  )}
                  {cow && t.method === 'model' && <CowCard name={animalName(cow)} spark={cowSpark(ai.data, cow.id, 7)} onOpen={() => setPopup({ kind: 'animal', id: cow.id })} />}
                  {t.method === 'model' && !t.animalId && (t.triage || t.hadMedia) && !skipPick.has(t.id) && (
                    <CowPicker animals={animals.map((a) => ({ id: a.id, label: `${animalName(a)}${a.body.name && a.body.tagNumber ? ` (${a.body.tagNumber})` : ''}` }))} onPick={(id) => void pickCow(t, id)} onSkip={() => setSkipPick(new Set(skipPick).add(t.id))} />
                  )}
                  {acts.length + dos.length > 0 && (
                    <div className="ct-acts">
                      {[...dos, ...acts].map((a) => {
                        const pop = popupOf(a.href);
                        const tel = a.href.startsWith('/contacts') && vetPhone ? `tel:${vetPhone.replace(/[^\d+]/g, '')}` : null;
                        if (tel)
                          return (
                            <a key={a.href} className="ct-btn" href={tel}>
                              <Icon name="phone" /> {vet?.body.name ? `Call ${vet.body.name}` : a.label}
                            </a>
                          );
                        return pop ? (
                          <button key={a.href} className="ct-btn" onClick={() => setPopup(pop)}>
                            {a.label} <Icon name="chevron" />
                          </button>
                        ) : (
                          <Link key={a.href} className="ct-btn" href={a.href}>
                            {a.label} <Icon name="chevron" />
                          </Link>
                        );
                      })}
                    </div>
                  )}
                  {t === lastAi && t.triage && !busy && <CaseCard answers={caseInfo} animalKnown={!!t.animalId} onAnswer={answerCase} busy={busy} onSend={() => send(`More details about this animal. ${caseText(caseInfo)}.`)} />}
                  {t.grounding && <Sources g={t.grounding} />}
                  {t.method === 'model' && t.asked && <ChatRefs question={t.asked} answer={t.text} cowNamed={!!t.animalId} general={!!t.grounding} />}
                  {(t.saved || t.note) && (
                    <div className="ct-saved">
                      {t.saved && (
                        <span className="ct-chip ok">
                          <Icon name="check" /> Saved to {t.aboutAnimal ?? 'the animal'}’s history
                        </span>
                      )}
                      {t.note && <span className="small muted">{t.note}</span>}
                      {t.errorKind && t.errorKind !== 'limit' && t.errorKind !== 'disabled' && t.errorKind !== 'invalid' && t.asked && (
                        <button className="ct-btn sm" disabled={busy} onClick={() => again(t)}>
                          <Icon name="refresh" /> Try again
                        </button>
                      )}
                    </div>
                  )}
                  <ReplyBar t={t} speaking={speaking === t.id} canSpeak={canSpeak} busy={busy} onCopy={() => void copy(t.text)} onVote={(v) => vote(t, v)} onSpeak={() => speak(t)} onAgain={() => again(t)} onTranslate={(l) => send(`Please say your last answer again in ${l}.`)} onShare={() => void share(t.text)} />
                  {t === lastAi && !busy && t.followUps && t.followUps.length > 0 && (
                    <div className="ct-follow">
                      {t.followUps.map((f) => (
                        <button key={f} className="ct-chip line" onClick={() => send(f)}>
                          {f}
                        </button>
                      ))}
                    </div>
                  )}
                </div>
              </div>
            );
          })}
          {busy && (
            <div className="ct-ai">
              <span className="ct-av working" aria-hidden><Icon name="spark" /></span>
              <div className="ct-body">
                {live && <ChatText text={live} streaming />}
                <ChatThinking status={status} hasText={!!live} />
              </div>
            </div>
          )}
          <div ref={end} />
        </div>
      </AiState>
      <div className="ct-col">
        {usage && usage.level !== 'ok' && (
          <div className={`banner small ${usage.level === 'out' ? 'bad' : 'warn'}`} role="status">
            <Icon name={usage.level === 'out' ? 'alert' : 'flag'} />
            <span className="grow">
              <strong>{usageWarning(usage)!.title}</strong> {usageWarning(usage)!.message}
            </span>
          </div>
        )}
        <Composer
          text={text}
          setText={setText}
          files={files}
          removeFile={(i) => setFiles(files.filter((_, j) => j !== i))}
          openFile={openDraftPhoto}
          onFiles={(l) => void add(l)}
          busy={busy}
          canSend={canSend}
          send={() => send()}
          stop={() => stop.current?.abort()}
          problem={problem}
          about={about ? animalName(about) : null}
          clearAbout={() => setAnimalId(null)}
          search={searchOn}
          setSearch={(v) => { setSearchOn(v); spoken('search', v ? 'on' : 'off'); }}
          fast={fast}
          setFast={(v) => { setFast(v); spoken('fast', v ? 'on' : 'off'); }}
          lang={lang}
          setLang={(v) => { setLang(v); spoken('lang', v); }}
          context={context}
          toggleContext={(k) => setContext((c) => (c.includes(k) ? c.filter((x) => x !== k) : [...c, k]))}
          voice={{ supported: rec.supported, recording: rec.recording, seconds: rec.seconds, levels: rec.levels, error: rec.error, start: () => void rec.start(), cancel: rec.cancel, sendNow: () => void sendVoice() }}
          left={usage ? Math.max(0, usage.limit - usage.used) : null}
          leftPct={usage && usage.limit > 0 ? (Math.max(0, usage.limit - usage.used) / usage.limit) * 100 : 0}
          offline={!online}
        />
      </div>
      {showUsage && usage && (
        <Dialog title="AI assistant usage" subtitle="For your whole farm, today." onClose={() => setShowUsage(false)}>
          <AiUsageMeter view={usage} trusted={assistant.route === 'server'} />
          <p className="small muted">Questions about your records, milk, breeding, feed and money are answered by FarmTap’s built-in intelligence. They are free and never count here.</p>
        </Dialog>
      )}
      {popup && <ChatPopup popup={popup} onOpen={setPopup} onClose={() => setPopup(null)} />}
      {light && <Lightbox photos={light.photos} start={light.start} pins={lightPins} onClose={() => setLight(null)} />}
      {showChats && <History chats={chats} openId={chatId} onOpen={openChat} onNew={newChat} onPin={pinChat} onDelete={removeChat} onClose={() => setShowChats(false)} />}
    </div>
  );
}

