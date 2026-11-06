'use client';

// AI Veterinary Assistant (decision 0025, ROADMAP AI-03): what was seen ->
// possible causes, warning signs and when to call the vet. A guide, never a
// diagnosis, a drug or a dose. Saved results go to the animal's health
// history (healthAssessments, append-only).

import Link from 'next/link';
import { useEffect, useMemo, useState } from 'react';
import { Icon } from '@/components/Icon';
import { MethodBadge, ModuleHead, SeverityChip } from '@/components/ai';
import { AiGate, useAiPage } from '@/components/aiPage';
import { Empty, Field, useToast } from '@/components/ui';
import { alive, kampalaNow } from '@/shared/aiCore';
import { animalName, breedingState, isActive } from '@/shared/aiData';
import { animalHealth } from '@/shared/aiHerd';
import { assess, signs, VET_ENGINE, type HealthAssessmentBody, type SignKey, type VetResult } from '@/shared/aiVet';
import { logAi } from '@/lib/ai';
import { addRecord, useRecords } from '@/lib/data';
import { firebase } from '@/lib/firebase';
import { storeImage, shrinkImage } from '@/lib/images';
import { useSession } from '@/lib/session';

const groups = [...new Set(signs.map((s) => s.group))];
const callText: Record<VetResult['callVet'], string> = { now: 'Call your vet now', today: 'Call your vet today', soon: 'Ask your vet soon' };

/** The whole assistant. `animal` and `embedded` are used when it opens as a pop-up in the AI chat. */
export function VetAssistant({ animal, embedded = false }: { animal?: string; embedded?: boolean } = {}) {
  const page = useAiPage('vet', ['herd']);
  const { farm, ai } = page;
  const { user, canSave } = useSession();
  const toast = useToast();
  const [animalId, setAnimalId] = useState('');
  useEffect(() => {
    const id = animal ?? new URL(window.location.href).searchParams.get('animal');
    if (id) setAnimalId(id);
  }, [animal]);
  const [picked, setPicked] = useState<Set<SignKey>>(new Set());
  const [temp, setTemp] = useState('');
  const [days, setDays] = useState('');
  const [note, setNote] = useState('');
  const [photo, setPhoto] = useState<string | null>(null);
  const [result, setResult] = useState<VetResult | null>(null);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');
  const history = useRecords<HealthAssessmentBody>(farm.id, 'healthAssessments');

  const animals = useMemo(() => alive(ai.data.animals).filter(isActive).sort((a, b) => animalName(a).localeCompare(animalName(b))), [ai.data.animals]);
  const day = ai.data.now.slice(0, 10);
  const breeding = animalId ? breedingState(animalId, ai.data.breeding ?? [], day) : null;
  const dsc = breeding?.daysInMilk ?? null;
  const health = animalId ? animalHealth(ai.data, animalId) : null;
  const past = history.data.filter((h) => h.body.animalId === animalId).sort((a, b) => b.body.at.localeCompare(a.body.at)).slice(0, 5);

  const tempC = temp.trim() ? Number(temp.replace(',', '.')) : null;
  const tempBad = tempC != null && (!Number.isFinite(tempC) || tempC < 30 || tempC > 45);
  const toggle = (k: SignKey) =>
    setPicked((p) => {
      const n = new Set(p);
      if (n.has(k)) n.delete(k);
      else n.add(k);
      return n;
    });

  const run = () => {
    const t0 = performance.now();
    const r = assess({ signs: [...picked], tempC: tempBad ? null : tempC, daysSinceCalving: dsc != null && dsc <= 60 ? dsc : null, days: days ? Number(days) : null });
    logAi(farm.id, 'vet', true, performance.now() - t0, 'rules');
    setResult(r);
  };

  const save = async () => {
    if (!result || !animalId || !user) return;
    setSaving(true);
    setError('');
    try {
      const id = crypto.randomUUID();
      const url = photo ? await storeImage(`tenants/${farm.id}/photos/health-${id}.jpg`, photo) : null;
      const body: HealthAssessmentBody = {
        animalId,
        kind: 'vet',
        signs: [...picked],
        tempC: tempBad ? null : tempC,
        daysSinceCalving: dsc,
        days: days ? Number(days) : null,
        note: note.trim() || null,
        photo: url,
        risk: result.risk,
        possible: result.possible.map((p) => p.name),
        redFlags: result.redFlags,
        callVet: result.callVet,
        engine: VET_ENGINE,
        model: null,
        at: kampalaNow(new Date()).iso,
      };
      await addRecord(firebase().db, farm.id, 'healthAssessments', user.uid, body as unknown as Record<string, unknown>, id);
      toast('Saved to the animal’s health history');
      if (photo && !url) toast('Photo kept out: file storage is not switched on yet');
    } catch {
      setError('Could not save. Check the internet and try again.');
    } finally {
      setSaving(false);
    }
  };

  return (
    <>
      {!embedded && <ModuleHead module="vet" title="Veterinary Assistant" subtitle="Tick what you see. FarmTap lists possible causes and warning signs, and tells you how soon to call the vet." />}
      <div className="banner info small" role="note">
        <Icon name="shield" />
        <span className="grow">A guide, not a diagnosis. Only a vet can examine your animal. FarmTap never suggests drugs or doses.</span>
      </div>
      <AiGate page={page}>
        <section className="card stack">
          <Field label="Animal">
            <select className="input" value={animalId} onChange={(e) => setAnimalId(e.target.value)}>
              <option value="">Choose an animal (optional)</option>
              {animals.map((a) => (
                <option key={a.id} value={a.id}>
                  {animalName(a)} {a.body.tagNumber && a.body.name ? `(${a.body.tagNumber})` : ''}
                </option>
              ))}
            </select>
          </Field>
          {health && (
            <div className="small muted">
              {health.treatments90 ? `${health.treatments90} treatments in 90 days` : 'No treatment in 90 days'}
              {health.conditions[0] ? ` · last: ${health.conditions[0].condition}` : ''}
              {dsc != null ? ` · calved ${dsc} days ago` : ''}
              {health.milkChangePct != null ? ` · milk ${health.milkChangePct > 0 ? '+' : ''}${health.milkChangePct}% this week` : ''}
            </div>
          )}
          {groups.map((g) => (
            <fieldset key={g} className="stack" style={{ gap: 'var(--s-xs)', border: 0, padding: 0, margin: 0 }}>
              <legend className="small muted">{g}</legend>
              <div className="ai-signs">
                {signs
                  .filter((s) => s.group === g)
                  .map((s) => (
                    <label key={s.key}>
                      <input type="checkbox" checked={picked.has(s.key)} onChange={() => toggle(s.key)} />
                      <span>{s.label}</span>
                    </label>
                  ))}
              </div>
            </fieldset>
          ))}
          <div className="row wrap">
            <Field label="Temperature (°C)" hint="Normal is about 38.0 to 39.3" error={tempBad ? 'Type a temperature between 30 and 45' : null}>
              <input className="input" inputMode="decimal" value={temp} onChange={(e) => setTemp(e.target.value)} placeholder="Not taken" />
            </Field>
            <Field label="Seen for how many days?">
              <input className="input" inputMode="numeric" value={days} onChange={(e) => setDays(e.target.value.replace(/\D/g, '').slice(0, 3))} placeholder="0" />
            </Field>
          </div>
          <Field label="Anything else you saw (optional)">
            <textarea className="input" rows={2} maxLength={500} value={note} onChange={(e) => setNote(e.target.value)} />
          </Field>
          <Field label="Photo (optional)" hint="Kept with the record for your vet. FarmTap does not read the photo.">
            <input
              type="file"
              accept="image/*"
              capture="environment"
              onChange={async (e) => {
                const f = e.target.files?.[0];
                if (!f) return;
                try {
                  setPhoto((await shrinkImage(f, { max: 1280, quality: 0.8 })).dataUrl);
                } catch (err) {
                  setError((err as Error).message);
                }
              }}
            />
          </Field>
          {photo && <img className="ai-photo" src={photo} alt="Photo of the animal" />}
          <div className="row wrap">
            <button className="btn lg" disabled={picked.size === 0 && !temp} onClick={run}>
              <Icon name="health" /> Check signs
            </button>
            {(picked.size > 0 || result) && (
              <button
                className="btn ghost"
                onClick={() => {
                  setPicked(new Set());
                  setResult(null);
                  setTemp('');
                  setDays('');
                  setNote('');
                  setPhoto(null);
                }}
              >
                Start again
              </button>
            )}
          </div>
        </section>

        {result && (
          <section className={`card stack ai-finding sev-${result.risk}`} aria-live="polite">
            <div className="row between wrap">
              <SeverityChip severity={result.risk} />
              <MethodBadge method="rules" />
            </div>
            <h2>{callText[result.callVet]}</h2>
            {result.redFlags.length > 0 && (
              <div className="banner bad">
                <Icon name="alert" />
                <span className="grow">
                  <strong>Warning signs: </strong>
                  {result.redFlags.join('; ')}.
                </span>
              </div>
            )}
            {result.possible.length ? (
              <div className="stack">
                <h3>Possible causes</h3>
                {result.possible.map((p) => (
                  <div key={p.key} className="stack" style={{ gap: 'var(--s-xxs)' }}>
                    <strong>
                      {p.name}
                      {p.notifiable && <span className="chip warn"> Must be reported</span>}
                    </strong>
                    <span className="small muted">Matches: {p.matched.join(', ')}</span>
                  </div>
                ))}
              </div>
            ) : (
              <p>The signs ticked do not point clearly to one common problem. Watch her closely and ask your vet.</p>
            )}
            <div className="stack">
              <h3>What to do now</h3>
              <ol>
                {result.steps.map((s, i) => (
                  <li key={i}>{s}</li>
                ))}
              </ol>
            </div>
            <p className="small muted">{result.disclaimer}</p>
            {error && <div className="banner bad small">{error}</div>}
            <div className="row wrap">
              <Link className="btn outline" href="/contacts/">
                <Icon name="phone" /> Vet’s number
              </Link>
              <button className="btn" disabled={!animalId || !canSave || saving} onClick={() => void save()} title={!animalId ? 'Choose the animal first' : undefined}>
                <Icon name="check" /> {saving ? 'Saving…' : 'Save to health history'}
              </button>
            </div>
          </section>
        )}

        {animalId && (
          <section className="card stack">
            <h2>Earlier checks for {animalName(ai.data.animals?.find((a) => a.id === animalId))}</h2>
            {past.length ? (
              <ul className="ai-insight-list">
                {past.map((h) => (
                  <li key={h.id}>
                    <SeverityChip severity={h.body.risk} />
                    <span className="grow">
                      <strong>{h.body.at.replace('T', ' ').slice(0, 16)}</strong>
                      <span className="small muted"> {h.body.kind === 'chat' ? `Asked: ${h.body.question ?? ''} — ${h.body.summary ?? ''}` : `${h.body.possible.join(', ') || 'No clear cause'}${h.body.kind === 'screening' ? ' (photo screening)' : ''}`}</span>
                    </span>
                  </li>
                ))}
              </ul>
            ) : (
              <Empty icon="health">No saved checks for this animal yet.</Empty>
            )}
          </section>
        )}
      </AiGate>
    </>
  );
}
