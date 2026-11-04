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
import { sectorName } from '@/lib/labels';
import { defaultConfig, type PlatformConfig } from '@/lib/platform';
import { useSession } from '@/lib/session';
import { getDoc } from 'firebase/firestore';

async function loadSetupConfig(): Promise<PlatformConfig> {
  try {
    const snap = await getDoc(doc(firebase().db, 'platform', 'config'));
    if (!snap.exists()) return defaultConfig;
    const { configFromDoc } = await import('@/lib/platform');
    return configFromDoc(snap.data() as Record<string, unknown>);
  } catch {
    return defaultConfig;
  }
}

/**
 * Farm setup on the web. Respects signup.open and sectors from platform/config.
 */
export default function Setup() {
  const { user, farms, online, reloadFarms, openFarm } = useSession();
  const router = useRouter();
  const [cfg, setCfg] = useState<PlatformConfig>(defaultConfig);
  const [cfgLoaded, setCfgLoaded] = useState(false);
  const [name, setName] = useState('');
  const [type, setType] = useState<'farm' | 'centre' | 'both'>('farm');
  const [sector, setSector] = useState('dairy');
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
    void loadSetupConfig().then((c) => {
      setCfg(c);
      // Set the first open sector as the default
      if (c.signup.sectors.length > 0) setSector(c.signup.sectors[0]);
      setCfgLoaded(true);
    });
  }, []);

  useEffect(() => {
    if (user === null) router.replace('/sign-in/');
    else if (farms && farms.length > 0) router.replace('/');
  }, [user, farms, router]);

  if (!user || farms === undefined || !cfgLoaded) return <Loading />;

  // Signup closed: show waiting list message
  if (!cfg.signup.open) {
    return (
      <div className="auth-main">
        <div className="auth-box stack" style={{ gap: 'var(--s-md)', textAlign: 'center' }}>
          <div className="auth-brand">
            <div className="logo-mark lg" aria-hidden />
            <h1>Joining the waitlist</h1>
          </div>
          <p>{cfg.signup.closedMessage || 'FarmTap is not taking new farms right now. We will reach out when space opens.'}</p>
          <p className="small muted">We have your contact. If you would like to follow up, reach out to our team.</p>
          <a
            className="btn"
            href="https://wa.me/256793128137?text=Hello+FarmTap,+I+would+like+to+join+the+waiting+list."
            target="_blank"
            rel="noreferrer"
          >
            <Icon name="whatsapp" /> Message us on WhatsApp
          </a>
          <button className="btn ghost sm" onClick={() => router.replace('/sign-in/')}>
            <Icon name="logout" /> Sign out
          </button>
        </div>
      </div>
    );
  }

  const openSectors = cfg.signup.sectors;
  // If the selected sector is not in the open list, reset it
  const activeSector = openSectors.includes(sector) ? sector : (openSectors[0] ?? 'dairy');

  const trialDays = cfg.trialDays ?? 14;

  async function submit(ev: FormEvent) {
    ev.preventDefault();
    if (!user) return;
    setBusy(true);
    setError('');
    const { db } = firebase();
    const id = crypto.randomUUID();
    const start = startOfDay(new Date());
    const end = addDays(start, trialDays);
    try {
      const tenant = doc(db, 'tenants', id);
      await setDoc(tenant, {
        ownerUid: user.uid,
        name: name.trim(),
        type,
        sector: activeSector,
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
          <p className="muted">Takes one minute. Your {trialDays}-day free trial starts today.</p>
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
                ['farm', 'Farm'],
                ['centre', 'Collection centre'],
                ['both', 'Both'],
              ] as const
            ).map(([v, label]) => (
              <button type="button" key={v} aria-pressed={type === v} onClick={() => setType(v)}>
                {label}
              </button>
            ))}
          </div>
        </div>

        {openSectors.length > 1 && (
          <div className="field">
            <span>What type of farm?</span>
            <select className="input" value={activeSector} onChange={(e) => setSector(e.target.value)}>
              {openSectors.map((k) => (
                <option key={k} value={k}>
                  {sectorName[k as keyof typeof sectorName] ?? k}
                </option>
              ))}
            </select>
          </div>
        )}

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
            <span>How many animals do you have?</span>
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
