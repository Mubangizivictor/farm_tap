'use client';

import { arrayUnion, doc, serverTimestamp, setDoc, Timestamp } from 'firebase/firestore';
import { useRouter } from 'next/navigation';
import { useEffect, useState, type FormEvent } from 'react';
import { Icon } from '@/components/Icon';
import { Loading } from '@/components/Loading';
import { addDays, startOfDay } from '@/lib/dates';
import { saveError } from '@/lib/data';
import { ugandaDistricts } from '@/lib/districts';
import { firebase } from '@/lib/firebase';
import { useSession } from '@/lib/session';

const TRIAL_DAYS = 7; // product decision 3 Nov 2026 (freeTrialDays in the phone app)

/**
 * Farm setup on the web, the same farm the phone's onboarding (B01–B10)
 * makes: tenants/{t} on a 7-day trial, waiting for Victorbee's review.
 * Dairy only for now (binding rule 1); one farm per account here.
 */
export default function Setup() {
  const { user, farms, online, reloadFarms, openFarm } = useSession();
  const router = useRouter();
  const [name, setName] = useState('');
  const [type, setType] = useState<'farm' | 'centre' | 'both'>('farm');
  const [district, setDistrict] = useState('');
  const [village, setVillage] = useState('');
  const [cows, setCows] = useState('');
  const [role, setRole] = useState<'owner' | 'manager'>('owner');
  const [title, setTitle] = useState('');
  const [whatsapp, setWhatsapp] = useState('');
  const [sms, setSms] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    if (user === null) router.replace('/sign-in/');
    // One farm per account: a second farm is a paid extra, not offered here.
    else if (farms && farms.length > 0) router.replace('/');
  }, [user, farms, router]);

  if (!user || farms === undefined) return <Loading />;

  async function submit(ev: FormEvent) {
    ev.preventDefault();
    if (!user) return;
    setBusy(true);
    setError('');
    const { db } = firebase();
    const id = crypto.randomUUID();
    const start = startOfDay(new Date());
    const end = addDays(start, TRIAL_DAYS);
    try {
      const tenant = doc(db, 'tenants', id);
      // In order: the rules check the farm exists before the membership.
      await setDoc(tenant, {
        ownerUid: user.uid,
        name: name.trim(),
        type,
        sector: 'dairy',
        district: district.trim() || null,
        place: district.trim(),
        village: village.trim() || null,
        cows: type === 'centre' ? null : Number(cows) || 0,
        contacts: { whatsapp: whatsapp.trim(), sms: (sms || whatsapp).trim(), dailyReport: true, smsAlerts: true },
        subscription: { trialStartedAt: Timestamp.fromDate(start), trialEndsAt: Timestamp.fromDate(end) },
        createdAt: serverTimestamp(),
        owner: { uid: user.uid, name: user.displayName ?? '', email: user.email ?? '' },
        review: { status: 'pending' },
      });
      await setDoc(doc(tenant, 'members', user.uid), { role, title: title.trim() });
      await setDoc(doc(db, 'users', user.uid), { memberships: arrayUnion({ tenantId: id, role }) }, { merge: true });
      openFarm(id);
      await reloadFarms();
      router.replace('/home/');
    } catch (e) {
      setError(saveError((e as { code?: string }).code));
      setBusy(false);
    }
  }

  return (
    <div className="auth-main">
      <form className="auth-box" onSubmit={submit}>
        <div className="auth-brand">
          <div className="logo-mark lg" aria-hidden />
          <h1>Set up your farm</h1>
          <p className="muted">Takes one minute. Your 7-day free trial starts today.</p>
        </div>

        <label className="field">
          <span>Farm or centre name</span>
          <input className="input" value={name} onChange={(e) => setName(e.target.value)} required placeholder="e.g. Rwemiyaga Dairy" />
        </label>

        <div className="field">
          <span>What do you run?</span>
          <div className="seg" role="group">
            {(
              [
                ['farm', 'Dairy farm'],
                ['centre', 'Collection centre'],
                ['both', 'Both'],
              ] as const
            ).map(([v, label]) => (
              <button type="button" key={v} aria-pressed={type === v} onClick={() => setType(v)}>
                {label}
              </button>
            ))}
          </div>
          <span className="small muted">Poultry, pigs and other farms are coming soon.</span>
        </div>

        <label className="field">
          <span>District</span>
          <input className="input" list="districts" value={district} onChange={(e) => setDistrict(e.target.value)} required placeholder="Start typing, e.g. Mbarara" />
          <datalist id="districts">
            {ugandaDistricts.map((d) => (
              <option key={d} value={d} />
            ))}
          </datalist>
        </label>
        <label className="field">
          <span>Village or area (optional)</span>
          <input className="input" value={village} onChange={(e) => setVillage(e.target.value)} />
        </label>
        {type !== 'centre' && (
          <label className="field">
            <span>How many cows do you have?</span>
            <input className="input" type="number" min={0} inputMode="numeric" value={cows} onChange={(e) => setCows(e.target.value)} required />
          </label>
        )}

        <div className="field">
          <span>You are the</span>
          <div className="seg" role="group">
            <button type="button" aria-pressed={role === 'owner'} onClick={() => setRole('owner')}>
              Owner
            </button>
            <button type="button" aria-pressed={role === 'manager'} onClick={() => setRole('manager')}>
              Manager
            </button>
          </div>
          <input className="input" value={title} onChange={(e) => setTitle(e.target.value)} placeholder="Your title (optional), e.g. Farm director" />
        </div>

        <label className="field">
          <span>WhatsApp number</span>
          <input className="input" type="tel" value={whatsapp} onChange={(e) => setWhatsapp(e.target.value)} required placeholder="+256 7XX XXX XXX" />
        </label>
        <label className="field">
          <span>SMS number (if different)</span>
          <input className="input" type="tel" value={sms} onChange={(e) => setSms(e.target.value)} placeholder="Same as WhatsApp" />
        </label>

        {error && (
          <p className="error-text" role="alert">
            {error}
          </p>
        )}
        <button className="btn block" type="submit" disabled={busy || !online}>
          {busy ? 'Setting up…' : online ? 'Start my free trial' : 'No internet'}
        </button>
        <button type="button" className="btn ghost sm" onClick={() => router.replace('/farms/')}>
          <Icon name="chevron" /> Back
        </button>
      </form>
    </div>
  );
}
