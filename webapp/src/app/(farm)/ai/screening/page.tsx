'use client';

// Disease Screening (decision 0025): EXPERIMENTAL. No validated, licensed
// model is installed, so FarmTap never says what a photo shows. It checks
// the photo is usable, saves it to the animal's health history for the vet,
// and points to the Vet Assistant.

import Link from 'next/link';
import { useEffect, useMemo, useState } from 'react';
import { Icon } from '@/components/Icon';
import { AiTable, MethodBadge, ModuleHead } from '@/components/ai';
import { AiGate, useAiPage } from '@/components/aiPage';
import { Field, useToast } from '@/components/ui';
import { alive, kampalaNow } from '@/shared/aiCore';
import { animalName, isActive } from '@/shared/aiData';
import { photoQuality, SCREENING_ENGINE, screeningTargets, type PhotoQuality } from '@/shared/aiScreening';
import type { HealthAssessmentBody } from '@/shared/aiVet';
import { logAi } from '@/lib/ai';
import { addRecord } from '@/lib/data';
import { firebase } from '@/lib/firebase';
import { shrinkImage, storeImage } from '@/lib/images';
import { useSession } from '@/lib/session';

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

export default function Screening() {
  const page = useAiPage('screening', ['herd']);
  const { farm, ai } = page;
  const { user, canSave } = useSession();
  const toast = useToast();
  const [target, setTarget] = useState(screeningTargets[0].key);
  const [animalId, setAnimalId] = useState('');
  const [photo, setPhoto] = useState<string | null>(null);
  const [quality, setQuality] = useState<PhotoQuality | null>(null);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  useEffect(() => {
    const id = new URL(window.location.href).searchParams.get('animal');
    if (id) setAnimalId(id);
  }, []);
  const animals = useMemo(() => alive(ai.data.animals).filter(isActive), [ai.data.animals]);
  const t = screeningTargets.find((x) => x.key === target)!;

  const pick = async (f: File) => {
    setError('');
    setQuality(null);
    try {
      const t0 = performance.now();
      const shrunk = await shrinkImage(f, { max: 1280, quality: 0.82 });
      setPhoto(shrunk.dataUrl);
      const { g, w, h } = await grayOf(shrunk.dataUrl);
      const q = photoQuality(g, w, h);
      setQuality(q);
      logAi(farm.id, 'screening', true, performance.now() - t0, 'experimental');
    } catch (e) {
      setError((e as Error).message || 'Could not read that picture.');
    }
  };

  const save = async () => {
    if (!photo || !animalId || !user) return;
    setBusy(true);
    try {
      const id = crypto.randomUUID();
      const url = await storeImage(`tenants/${farm.id}/photos/health-${id}.jpg`, photo);
      const body: HealthAssessmentBody = {
        animalId,
        kind: 'screening',
        signs: [],
        tempC: null,
        daysSinceCalving: null,
        days: null,
        note: `Photo for: ${t.label}`,
        photo: url,
        risk: 'low',
        possible: [],
        redFlags: [],
        callVet: 'soon',
        engine: SCREENING_ENGINE,
        model: null,
        at: kampalaNow(new Date()).iso,
      };
      await addRecord(firebase().db, farm.id, 'healthAssessments', user.uid, body as unknown as Record<string, unknown>, id);
      toast(url ? 'Photo saved to the health history for your vet' : 'Saved; the photo stays out until file storage is switched on');
    } catch {
      setError('Could not save. Check the internet and try again.');
    } finally {
      setBusy(false);
    }
  };

  return (
    <>
      <ModuleHead module="screening" title="Disease Screening" subtitle="Take a good photo for your vet. Automatic screening is experimental and not switched on." />
      <AiGate page={page}>
        <div className="banner warn" role="note">
          <Icon name="flag" />
          <span className="grow">
            <strong>Experimental.</strong> FarmTap has no tested model that can recognise cattle diseases from photos, so it will not guess what this photo shows. Use the{' '}
            <Link href={`/ai/vet/${animalId ? `?animal=${animalId}` : ''}`}>Vet Assistant</Link> for the signs you see, and show the photo to your vet.
          </span>
        </div>
        <section className="card stack">
          <div className="row wrap">
            <Field label="What to check">
              <select className="input" value={target} onChange={(e) => setTarget(e.target.value)}>
                {screeningTargets.map((x) => (
                  <option key={x.key} value={x.key}>
                    {x.label}
                  </option>
                ))}
              </select>
            </Field>
            <Field label="Animal">
              <select className="input" value={animalId} onChange={(e) => setAnimalId(e.target.value)}>
                <option value="">Choose an animal</option>
                {animals.map((a) => (
                  <option key={a.id} value={a.id}>
                    {animalName(a)}
                  </option>
                ))}
              </select>
            </Field>
          </div>
          <p className="small">
            <strong>How to take it: </strong>
            {t.photo}
          </p>
          <Field label="Photo">
            <input type="file" accept="image/*" capture="environment" onChange={(e) => e.target.files?.[0] && void pick(e.target.files[0])} />
          </Field>
          {error && <div className="banner bad small">{error}</div>}
          {photo && <img className="ai-photo" src={photo} alt="Photo to screen" />}
          {quality && (
            <div className={`banner ${quality.ok ? 'info' : 'warn'} small`} role="status">
              <Icon name={quality.ok ? 'check' : 'camera'} />
              <span className="grow">
                {quality.ok ? 'Good photo: bright and sharp enough for your vet.' : quality.problems.join(' ')}
                <span className="muted"> (brightness {quality.brightness}, sharpness {quality.sharpness})</span>
              </span>
            </div>
          )}
          {quality && (
            <div className="card flat stack">
              <div className="row between wrap">
                <strong>Screening result</strong>
                <MethodBadge method="experimental" />
              </div>
              <p>No screening model is installed for “{t.label.toLowerCase()}”. FarmTap cannot tell what the photo shows.</p>
              <p className="small muted">Why: {t.note}</p>
            </div>
          )}
          <div className="row wrap">
            <button className="btn" disabled={!photo || !animalId || busy || !canSave} onClick={() => void save()} title={!animalId ? 'Choose the animal first' : undefined}>
              <Icon name="check" /> {busy ? 'Saving…' : 'Save photo to health history'}
            </button>
            <Link className="btn outline" href={`/ai/vet/${animalId ? `?animal=${animalId}` : ''}`}>
              <Icon name="health" /> Check the signs instead
            </Link>
          </div>
        </section>
        <section className="card stack">
          <h2>What screening could do later</h2>
          <p className="small muted">A model is switched on only after it is tested on labelled photos from East African farms and meets these levels. Until then, every check below says “No model”.</p>
          <AiTable
            label="Screening checks"
            columns={['Check', 'Status', 'Needs to find', 'Needs to clear']}
            rows={screeningTargets.map((x) => [x.label, x.status === 'noModel' ? 'No model' : x.status, `${Math.round(x.minSensitivity * 100)}% of sick animals`, `${Math.round(x.minSpecificity * 100)}% of healthy animals`])}
          />
        </section>
      </AiGate>
    </>
  );
}
