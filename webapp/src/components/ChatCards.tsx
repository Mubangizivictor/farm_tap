'use client';

// The cards under a chat answer (decision 0027): the urgency card with the
// message for the vet, the vet's questions, and "which cow is this?".

import { useEffect, useState } from 'react';
import { Icon } from '@/components/Icon';
import { wikiRef, type Ref } from '@/lib/aiRefs';
import { chatTopics, cleanTemp, googleLinks, openCaseQuestions, type CaseAnswers, type CaseId, type Triage } from '@/shared/aiChat';

const toBlob = (b64: string, mime: string) => {
  const bin = atob(b64);
  const bytes = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
  return new Blob([bytes], { type: mime });
};

export interface SharePhoto {
  name: string;
  mime: string;
  base64: string;
}

/** Urgency badge, the "do now" list and the buttons that send the vet a message. */
export function TriageCard({
  triage,
  message,
  whatsapp,
  vetName,
  photos,
  toast,
}: {
  triage: Triage;
  message: string;
  /** wa.me link for the farm's vet (or WhatsApp's own picker when no vet is saved). */
  whatsapp: string;
  vetName: string | null;
  photos: SharePhoto[];
  toast: (t: string) => void;
}) {
  const [open, setOpen] = useState(false);
  const [all, setAll] = useState(false);
  const share = async () => {
    try {
      const files = photos.slice(0, 3).map((p) => new File([toBlob(p.base64, p.mime)], p.name || 'photo.jpg', { type: p.mime }));
      if (files.length && navigator.canShare?.({ files })) await navigator.share({ files, text: message });
      else if (navigator.share) await navigator.share({ text: message });
      else {
        await navigator.clipboard.writeText(message);
        toast('Message copied. Paste it in WhatsApp.');
      }
    } catch {
      /* the farmer closed the share sheet */
    }
  };
  const copy = async () => {
    try {
      await navigator.clipboard.writeText(message);
      toast('Message copied');
    } catch {
      toast('Could not copy');
    }
  };
  return (
    <section className={`triage ${triage.level}`} aria-label="What to do now">
      <div className="triage-head">
        <Icon name="alert" />
        <strong>{triage.label}</strong>
      </div>
      <p className="small muted">While you wait for the vet:</p>
      <ul>
        {(all ? triage.doNow : triage.doNow.slice(0, 3)).map((d) => (
          <li key={d}>{d}</li>
        ))}
      </ul>
      {triage.doNow.length > 3 && (
        <button className="link-btn small" onClick={() => setAll(!all)} aria-expanded={all}>
          {all ? 'Show fewer' : `Show all ${triage.doNow.length} steps`}
        </button>
      )}
      <div className="triage-actions">
        <a className="btn sm" href={whatsapp} target="_blank" rel="noopener noreferrer">
          <Icon name="whatsapp" /> {vetName ? `WhatsApp ${vetName}` : 'Send to my vet on WhatsApp'}
        </a>
        {photos.length > 0 && (
          <button className="btn sm ghost" onClick={() => void share()}>
            <Icon name="camera" /> Share with photo
          </button>
        )}
        <button className="btn sm ghost" onClick={() => setOpen(!open)} aria-expanded={open}>
          <Icon name="list" /> {open ? 'Hide message' : 'See the message'}
        </button>
      </div>
      {open && (
        <div className="stack">
          <pre className="triage-msg">{message}</pre>
          <button className="btn sm ghost" onClick={() => void copy()}>
            <Icon name="copy" /> Copy message
          </button>
        </div>
      )}
    </section>
  );
}

/** The questions a vet asks first. Tapping an answer fills the vet message; the button sends them to the AI. */
export function CaseCard({
  answers,
  animalKnown,
  onAnswer,
  onSend,
  busy,
}: {
  answers: CaseAnswers;
  animalKnown: boolean;
  onAnswer: (id: CaseId, value: string) => void;
  onSend: () => void;
  busy: boolean;
}) {
  const [temp, setTemp] = useState('');
  const [shown, setShown] = useState(false);
  const open = openCaseQuestions(answers, animalKnown);
  const given = Object.keys(answers).length;
  if (!open.length && !given) return null;
  if (!shown)
    return (
      <button className="btn sm ghost case-open" onClick={() => setShown(true)}>
        <Icon name="list" /> Add what you know for the vet{given > 0 ? ` (${given})` : ''}
      </button>
    );
  return (
    <section className="case" aria-label="Questions the vet will ask">
      <strong>Help the vet help you</strong>
      <p className="small muted">Tap what you know. It goes into your message for the vet.</p>
      {open.map((q) => (
        <div key={q.id} className="case-q">
          <span className="small">{q.label}</span>
          {q.options.length > 0 ? (
            <div className="chips">
              {q.options.map((o) => (
                <button key={o} className="chip chip-btn" onClick={() => onAnswer(q.id, o)}>
                  {o}
                </button>
              ))}
            </div>
          ) : (
            <div className="row">
              <input className="input case-temp" inputMode="decimal" placeholder="e.g. 40.5" value={temp} onChange={(e) => setTemp(e.target.value)} aria-label="Temperature in degrees" />
              <button
                className="btn sm ghost"
                disabled={cleanTemp(temp) == null}
                onClick={() => {
                  const t = cleanTemp(temp);
                  if (t) onAnswer(q.id, t);
                  setTemp('');
                }}
              >
                Add
              </button>
            </div>
          )}
        </div>
      ))}
      {given > 0 && (
        <button className="btn sm" disabled={busy} onClick={onSend}>
          <Icon name="spark" /> Update the advice with these
        </button>
      )}
    </section>
  );
}

/** "Which cow is this?" after a photo or a health answer, so the answer is saved to that cow. */
export function CowPicker({ animals, onPick, onSkip }: { animals: { id: string; label: string }[]; onPick: (id: string) => void; onSkip: () => void }) {
  const [id, setId] = useState('');
  if (!animals.length) return null;
  return (
    <section className="case" aria-label="Which cow is this?">
      <strong>Which cow is this?</strong>
      <div className="row">
        <select className="input" value={id} onChange={(e) => setId(e.target.value)} aria-label="Choose the cow">
          <option value="">Choose a cow…</option>
          {animals.map((a) => (
            <option key={a.id} value={a.id}>
              {a.label}
            </option>
          ))}
        </select>
        <button className="btn sm" disabled={!id} onClick={() => onPick(id)}>
          Save
        </button>
        <button className="btn sm ghost" onClick={onSkip}>
          Not now
        </button>
      </div>
    </section>
  );
}

const STAGES = ['Reading your question…', 'Checking the facts…', 'Writing the answer…'];

/** Shown while the answer is on its way: what is happening, how long it has taken, and a placeholder. */
export function ChatThinking({ status, hasText }: { status: string; hasText: boolean }) {
  const [secs, setSecs] = useState(0);
  useEffect(() => {
    const t = setInterval(() => setSecs((s) => s + 1), 1000);
    return () => clearInterval(t);
  }, []);
  const what = status || STAGES[Math.min(STAGES.length - 1, Math.floor(secs / 4))];
  return (
    <div className="think" role="status">
      <div className="think-row">
        <span className="dots" aria-hidden>
          <i />
          <i />
          <i />
        </span>
        <span>{hasText ? 'Writing…' : what}</span>
        {secs >= 6 && !hasText && <span className="small muted">{secs}s{secs >= 20 ? ' · taking longer than usual. You can press Stop.' : ''}</span>}
      </div>
      {!hasText && (
        <div className="think-lines" aria-hidden>
          <span className="skel" />
          <span className="skel" />
          <span className="skel" />
        </div>
      )}
    </div>
  );
}

/** Free extras under an answer: a photo and a short read from Wikipedia, and links to Google's own results and pictures. */
export function ChatRefs({ question, answer, cowNamed, general }: { question: string; answer: string; cowNamed: boolean; /** The answer was a general-knowledge one (it used Google Search). */ general: boolean }) {
  const topics = chatTopics(question, answer);
  const key = topics.map((t) => t.wiki).join('|');
  const [refs, setRefs] = useState<Ref[]>([]);
  useEffect(() => {
    let live = true;
    void Promise.all(topics.map((t) => wikiRef(t.wiki))).then((r) => live && setRefs(r.filter((x): x is Ref => !!x)));
    return () => {
      live = false;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [key]);
  // A named cow's name is never put in a Google link: use the topic, or nothing.
  const query = topics[0]?.q ?? (general && !cowNamed ? question : '');
  if (!refs.length && !query) return null;
  const links = query ? googleLinks(query) : null;
  return (
    <section className="refs" aria-label="Learn more">
      {refs.length > 0 && (
        <div className="ref-cards">
          {refs.map((r) => (
            <a key={r.url} className="ref" href={r.url} target="_blank" rel="noopener noreferrer">
              {r.thumb && <img src={r.thumb} alt="" loading="lazy" />}
              <span className="ref-text">
                <strong>{r.title}</strong>
                <span className="small muted">{r.extract.length > 150 ? `${r.extract.slice(0, 147)}…` : r.extract}</span>
                <span className="small muted">Wikipedia</span>
              </span>
            </a>
          ))}
        </div>
      )}
      {links && (
        <div className="chips">
          <a className="chip" href={links.images} target="_blank" rel="noopener noreferrer">
            <Icon name="camera" /> See pictures on Google
          </a>
          <a className="chip" href={links.web} target="_blank" rel="noopener noreferrer">
            <Icon name="search" /> Search Google
          </a>
        </div>
      )}
    </section>
  );
}
