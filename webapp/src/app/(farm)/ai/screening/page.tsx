'use client';

// Photo Check (decision 0026): take or choose a photo, Google Gemini says
// what it can see and lists possible causes. It covers animal health (skin,
// eyes, udder, hooves, dung, calves) and the rest of the farm (feed, water,
// pasture, sheds). It is never a diagnosis: drugs, doses and certain-sounding
// diagnoses are removed by readPhotoReply, and every health result says to
// call the vet. The words of a result are saved to the health history; the
// picture is not stored.

import Link from 'next/link';
import { useEffect, useMemo, useState } from 'react';
import { Icon } from '@/components/Icon';
import { MethodBadge, ModuleHead, SeverityChip } from '@/components/ai';
import { AiGate, useAiPage } from '@/components/aiPage';
import { Field } from '@/components/ui';
import { alive, kampalaNow } from '@/shared/aiCore';
import { animalName, breedingState, isActive } from '@/shared/aiData';
import { nameLabels, redact } from '@/shared/aiPrivacy';
import {
  buildPhotoPrompt,
  PHOTO_MAX_BYTES,
  PHOTO_MAX_SIDE,
  PHOTO_SYSTEM,
  photoAllowed,
  photoAssessmentBody,
  photoChecks,
  photoDisclaimer,
  photoGroups,
  readPhotoReply,
  type PhotoCheck,
  type PhotoResult,
} from '@/shared/aiPhoto';
import { photoQuality, type PhotoQuality } from '@/shared/aiScreening';
import { logAi } from '@/lib/ai';
import { analyzePhoto, photoFailureOf, type PhotoFailure } from '@/lib/aiPhotoClient';
import { addRecord, useRecords } from '@/lib/data';
import { firebase } from '@/lib/firebase';
import { shrinkImage } from '@/lib/images';
import { useSession } from '@/lib/session';

const FAILURE: Record<PhotoFailure, string> = {
  network: 'No internet. Photo Check needs a connection.',
  busy: 'Photo Check is busy. Try again in a minute.',
  appCheck: 'Photo Check could not confirm this is the real FarmTap site.',
  unreadable: 'The answer could not be read. Take another photo and try again.',
};
const CERTAINTY = { clear: 'Clear in the photo', possible: 'Possible', unsure: 'Not sure' } as const;
const CALL = { now: 'Call a vet now', today: 'Call a vet today', soon: 'Ask a vet to look soon' } as const;

/** Grey pixels of a data URL, scaled to 320 px wide, for the quality check. */
async function grayOf(dataUrl: string): Promise<{ g: Uint8ClampedArray; w: number; h: number }> {
  const img = new Image();
  img.src = dataUrl;
  await img.decode();
  const w = Math.min(320, img.naturalWidth);
  const h = Math.max(1, Math.round((img.naturalHeight / img.naturalWidth) * w));
  const c = document.createElement('canvas');
  c.width = w;
  c.height = h;
  const ctx = c.getContext('2d');
  if (!ctx) throw new Error('This browser cannot read pictures.');
  ctx.drawImage(img, 0, 0, w, h);
  const px = ctx.getImageData(0, 0, w, h).data;
  const g = new Uint8ClampedArray(w * h);
  for (let i = 0; i < w * h; i++) g[i] = 0.299 * px[i * 4] + 0.587 * px[i * 4 + 1] + 0.114 * px[i * 4 + 2];
  return { g, w, h };
}

export default function PhotoCheckPage() {
  const page = useAiPage('screening', ['herd']);
  const { farm, ai, cfg } = page;
  const { user, canSave } = useSession();
  const [check, setCheck] = useState<PhotoCheck>(photoChecks[0]);
  const [animalId, setAnimalId] = useState('');
  const [note, setNote] = useState('');
  const [photo, setPhoto] = useState<string | null>(null);
  const [quality, setQuality] = useState<PhotoQuality | null>(null);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const [result, setResult] = useState<PhotoResult | null>(null);
  const [saved, setSaved] = useState(false);
  useEffect(() => {
    const id = new URL(window.location.href).searchParams.get('animal');
    if (id) setAnimalId(id);
  }, []);
  const animals = useMemo(() => alive(ai.data.animals).filter(isActive), [ai.data.animals]);
  const past = useRecords<{ kind?: string; at?: string }>(farm.id, 'healthAssessments');
  const today = kampalaNow(new Date()).iso.slice(0, 10);
  const usedToday = past.data.filter((r) => r.body.kind === 'photo' && (r.body.at ?? '').slice(0, 10) === today).length;
  const limit = photoAllowed(usedToday, cfg.ai.photo);
  const ready = cfg.ai.photo.enabled;

  const pick = async (f: File) => {
    setError('');
    setQuality(null);
    setResult(null);
    setSaved(false);
    try {
      const shrunk = await shrinkImage(f, { max: PHOTO_MAX_SIDE, quality: 0.82 });
      setPhoto(shrunk.dataUrl);
      const { g, w, h } = await grayOf(shrunk.dataUrl);
      setQuality(photoQuality(g, w, h));
    } catch (e) {
      setError((e as Error).message || 'Could not read that picture.');
    }
  };

  const run = async () => {
    if (!photo || !user) return;
    const m = /^data:(image\/[a-z]+);base64,(.+)$/.exec(photo);
    if (!m || m[2].length * 0.75 > PHOTO_MAX_BYTES) {
      setError('That picture is too big. Choose a smaller one.');
      return;
    }
    setBusy(true);
    setError('');
    setResult(null);
    setSaved(false);
    const t0 = performance.now();
    const cow = animals.find((a) => a.id === animalId);
    const names = nameLabels({ animals: animals.map((a) => a.body), people: [user.displayName ?? ''], places: [farm.name] });
    const dsc = cow ? breedingState(cow.id, ai.data.breeding ?? [], today).daysInMilk : null;
    const cleanNote = redact(note, names).trim();
    const model = cfg.ai.photo.model;
    try {
      const text = await analyzePhoto({ base64: m[2], mime: m[1], prompt: buildPhotoPrompt({ check, note: cleanNote, daysSinceCalving: dsc }), system: PHOTO_SYSTEM, model });
      const r = readPhotoReply(text, check);
      const ms = performance.now() - t0;
      if (!r) {
        logAi(farm.id, 'photo', false, ms, 'model');
        setError(FAILURE.unreadable);
        return;
      }
      logAi(farm.id, 'photo', true, ms, 'model');
      setResult(r);
      if (r.usable) {
        const body = photoAssessmentBody(r, check, animalId || null, cleanNote || null, model, kampalaNow(new Date()).iso);
        await addRecord(firebase().db, farm.id, 'healthAssessments', user.uid, body as unknown as Record<string, unknown>);
        setSaved(true);
      }
    } catch (e) {
      logAi(farm.id, 'photo', false, performance.now() - t0, 'model');
      setError(FAILURE[photoFailureOf(new Error((e as Error).message))]);
    } finally {
      setBusy(false);
    }
  };

  const reset = () => {
    setPhoto(null);
    setQuality(null);
    setResult(null);
    setError('');
    setSaved(false);
    setNote('');
  };

  return (
    <>
      <ModuleHead module="screening" title="Photo Check" subtitle="Take a photo of a sign, the udder, hooves, dung or feed. Get what can be seen and when to call the vet." />
      <AiGate page={page}>
        <div className="banner info small" role="note">
          <Icon name="flag" />
          <span className="grow">{photoDisclaimer}</span>
        </div>
        {!ready && (
          <div className="banner warn" role="status">
            <Icon name="flag" />
            <span className="grow">
              <strong>Photo Check is not switched on yet.</strong> The FarmTap team turns it on when it is ready for your farm. For the signs you can see, use the <Link href="/ai/vet/">Vet Assistant</Link>.
            </span>
          </div>
        )}
        <section className="card stack">
          <div className="row wrap">
            <Field label="What do you want to check?">
              <select
                className="input"
                value={check.key}
                onChange={(e) => {
                  setCheck(photoChecks.find((c) => c.key === e.target.value) ?? photoChecks[0]);
                  setResult(null);
                }}
              >
                {photoGroups.map((g) => (
                  <optgroup key={g} label={g}>
                    {photoChecks
                      .filter((c) => c.group === g)
                      .map((c) => (
                        <option key={c.key} value={c.key}>
                          {c.label}
                        </option>
                      ))}
                  </optgroup>
                ))}
              </select>
            </Field>
            {check.kind === 'health' && (
              <Field label="Which animal? (optional)">
                <select className="input" value={animalId} onChange={(e) => setAnimalId(e.target.value)}>
                  <option value="">No animal</option>
                  {animals.map((a) => (
                    <option key={a.id} value={a.id}>
                      {animalName(a)}
                    </option>
                  ))}
                </select>
              </Field>
            )}
          </div>
          <p className="small">
            <strong>How to take the photo: </strong>
            {check.how}
          </p>
          <Field label="What have you noticed? (optional)" hint="For example: since yesterday, eating less">
            <input className="input" value={note} maxLength={400} onChange={(e) => setNote(e.target.value)} />
          </Field>
          <Field label="Photo">
            <input type="file" accept="image/*" capture="environment" disabled={busy} onChange={(e) => e.target.files?.[0] && void pick(e.target.files[0])} />
          </Field>
          {error && (
            <div className="banner bad small" role="alert">
              {error}
            </div>
          )}
          {photo && <img className="ai-photo" src={photo} alt="Photo to check" />}
          {quality && !quality.ok && (
            <div className="banner warn small" role="status">
              <Icon name="camera" />
              <span className="grow">
                <strong>Take it again in good light, closer and steady.</strong> {quality.problems.join(' ')}
              </span>
            </div>
          )}
          {photo && (
            <>
              <p className="small muted">The photo is sent to Google to be read. It is not saved by FarmTap. Do not include people in the photo.</p>
              <div className="row wrap">
                <button className="btn" disabled={!ready || !limit.ok || busy || !canSave} onClick={() => void run()}>
                  <Icon name="spark" /> {busy ? 'Reading the photo…' : quality && !quality.ok ? 'Check anyway' : 'Check this photo'}
                </button>
                <button className="btn outline" disabled={busy} onClick={reset}>
                  Clear
                </button>
              </div>
              {ready && !limit.ok && <div className="banner warn small">Your farm has used all photo checks for today. Try again tomorrow, or call your vet.</div>}
              {ready && limit.ok && <p className="small muted">{limit.left} photo checks left today</p>}
            </>
          )}
        </section>
        {result && <ResultCard r={result} saved={saved} />}
      </AiGate>
    </>
  );
}

function ResultCard({ r, saved }: { r: PhotoResult; saved: boolean }) {
  return (
    <section className="card stack" aria-live="polite">
      <div className="row between wrap">
        <div className="row">
          <SeverityChip severity={r.risk} />
          <strong>{r.callVet ? CALL[r.callVet] : r.usable ? 'What can be seen' : 'Take it again in good light, closer and steady.'}</strong>
        </div>
        <MethodBadge method="model" />
      </div>
      <p>{r.summary}</p>
      {r.report && (
        <div className="banner bad small" role="alert">
          <Icon name="alert" /> This may need to be reported to the authorities.
        </div>
      )}
      {r.signs.length > 0 && (
        <div className="stack">
          <h2>What can be seen</h2>
          {r.signs.map((s, i) => (
            <div key={i}>
              <strong>{s.what}</strong>
              <div className="small muted">{[s.where, CERTAINTY[s.certainty]].filter(Boolean).join(' · ')}</div>
            </div>
          ))}
        </div>
      )}
      {r.possible.length > 0 && (
        <div className="stack">
          <h2>Possible causes</h2>
          {r.possible.map((c, i) => (
            <div key={i}>
              <strong>{c.name}</strong>
              {c.why && <div className="small muted">{c.why}</div>}
            </div>
          ))}
        </div>
      )}
      {r.steps.length > 0 && (
        <div className="stack">
          <h2>What to do now</h2>
          <ul>
            {r.steps.map((s, i) => (
              <li key={i}>{s}</li>
            ))}
          </ul>
        </div>
      )}
      {r.questions.length > 0 && (
        <div className="stack">
          <h2>Questions that would help</h2>
          <ul>
            {r.questions.map((s, i) => (
              <li key={i}>{s}</li>
            ))}
          </ul>
        </div>
      )}
      {r.retake && <div className="banner warn small">{r.retake}</div>}
      {saved && (
        <div className="banner info small">
          <Icon name="check" /> Saved to the health history
        </div>
      )}
      <p className="small muted">{r.disclaimer}</p>
    </section>
  );
}
