'use client';

import { doc, updateDoc } from 'firebase/firestore';
import { useRouter } from 'next/navigation';
import { useState, type FormEvent } from 'react';
import { Icon } from '@/components/Icon';
import { PageHead } from '@/components/ui';
import { saveError } from '@/lib/data';
import { ugandaDistricts } from '@/lib/districts';
import { manages, planState } from '@/lib/domain';
import { date } from '@/lib/format';
import { firebase } from '@/lib/firebase';
import { farmKind, planText, roleName } from '@/lib/labels';
import { useFarm, useSession, useTheme, type ThemeChoice } from '@/lib/session';
import { SUPPORT_WHATSAPP, supportWhatsAppLink } from '@/lib/support';

function FarmProfile() {
  const farm = useFarm();
  const { online, reloadFarms } = useSession();
  const boss = manages(farm);
  const [name, setName] = useState(farm.name);
  const [district, setDistrict] = useState(farm.district);
  const [village, setVillage] = useState(farm.village);
  const [whatsapp, setWhatsapp] = useState(farm.whatsapp);
  const [sms, setSms] = useState(farm.sms);
  const [busy, setBusy] = useState(false);
  const [msg, setMsg] = useState<{ ok: boolean; text: string } | null>(null);

  async function save(ev: FormEvent) {
    ev.preventDefault();
    setBusy(true);
    setMsg(null);
    try {
      // Profile only: the rules refuse any change to subscription, owner or review.
      await updateDoc(doc(firebase().db, 'tenants', farm.id), {
        name: name.trim(),
        district: district.trim(),
        place: district.trim(),
        village: village.trim(),
        'contacts.whatsapp': whatsapp.trim(),
        'contacts.sms': sms.trim(),
      });
      await reloadFarms();
      setMsg({ ok: true, text: 'Saved. The phones show the new details next time they open the farm.' });
    } catch (e) {
      setMsg({ ok: false, text: saveError((e as { code?: string }).code) });
    } finally {
      setBusy(false);
    }
  }

  return (
    <section className="card">
      <form className="stack" onSubmit={save}>
        <div className="card-head">
          <h2>Farm details</h2>
          <span className="chip brand">{farmKind(farm)}</span>
        </div>
        <div className="grid">
          <label className="field">
            <span>Name</span>
            <input className="input" value={name} onChange={(e) => setName(e.target.value)} disabled={!boss} required />
          </label>
          <label className="field">
            <span>District</span>
            <input className="input" list="districts" value={district} onChange={(e) => setDistrict(e.target.value)} disabled={!boss} />
            <datalist id="districts">
              {ugandaDistricts.map((d) => (
                <option key={d} value={d} />
              ))}
            </datalist>
          </label>
          <label className="field">
            <span>Village</span>
            <input className="input" value={village} onChange={(e) => setVillage(e.target.value)} disabled={!boss} />
          </label>
          <label className="field">
            <span>WhatsApp (daily report)</span>
            <input className="input" type="tel" value={whatsapp} onChange={(e) => setWhatsapp(e.target.value)} disabled={!boss} />
          </label>
          <label className="field">
            <span>SMS alerts number</span>
            <input className="input" type="tel" value={sms} onChange={(e) => setSms(e.target.value)} disabled={!boss} />
          </label>
        </div>
        {msg && <div className={`banner ${msg.ok ? 'ok' : 'bad'}`}>{msg.text}</div>}
        {boss ? (
          <div className="row">
            <button className="btn" disabled={busy || !online}>
              {busy ? 'Saving…' : 'Save details'}
            </button>
          </div>
        ) : (
          <p className="small muted">Only the owner or manager can change farm details.</p>
        )}
      </form>
    </section>
  );
}

export default function Settings() {
  const farm = useFarm();
  const { user, farms, signOut } = useSession();
  const router = useRouter();
  const [theme, setTheme] = useTheme();
  const now = new Date();
  const plan = planState(farm.subscription, now);
  const pt = planText(plan);

  return (
    <>
      <PageHead title="Settings" />

      <FarmProfile />

      <div className="grid cols">
        <section className="card stack">
          <div className="card-head">
            <h2>Subscription</h2>
            <span className={`chip ${pt.tone}`}>{pt.text}</span>
          </div>
          {farm.subscription.trialStartedAt && <p className="small muted">Free trial started {date(farm.subscription.trialStartedAt)}.</p>}
          <p className="small">
            {plan.kind === 'readOnly'
              ? 'Your records are safe and you can see everything. Pay to record again.'
              : 'When the trial or subscription ends, FarmTap becomes read-only until you pay. Nothing is deleted.'}
          </p>
          <p className="small muted">Mobile Money (MTN, Airtel) and card payments inside the app are coming. For now, pay through FarmTap support.</p>
          <div className="row">
            <a className="btn" href={supportWhatsAppLink(`Hello FarmTap, I want to pay for ${farm.name}.`)} target="_blank" rel="noreferrer">
              <Icon name="whatsapp" /> Pay on WhatsApp
            </a>
          </div>
        </section>

        <section className="card stack">
          <div className="card-head">
            <h2>You</h2>
            <span className="chip brand">{roleName(farm)}</span>
          </div>
          <div className="row">
            <span className="avatar lg">{user?.photoURL ? <img src={user.photoURL} alt="" referrerPolicy="no-referrer" /> : (user?.displayName || user?.email || '?').slice(0, 1).toUpperCase()}</span>
            <div className="stack" style={{ gap: 'var(--s-xxs)' }}>
              <strong>{user?.displayName || 'No name'}</strong>
              <span className="small muted">{user?.email}</span>
            </div>
          </div>
          <p className="small muted">This browser stays signed in until you sign out. Sign out on shared computers.</p>
          <div className="row wrap">
            {farms && farms.length > 1 && (
              <button className="btn outline" onClick={() => router.push('/farms/')}>
                <Icon name="switch" /> Switch place
              </button>
            )}
            <button className="btn outline" onClick={() => void signOut().then(() => router.replace('/sign-in/'))}>
              <Icon name="logout" /> Sign out
            </button>
          </div>
        </section>

        <section className="card stack">
          <div className="card-head">
            <h2>Look</h2>
          </div>
          <div className="seg" role="group" aria-label="Theme">
            {(
              [
                ['device', 'Same as device'],
                ['light', 'Light'],
                ['dark', 'Dark'],
              ] as [ThemeChoice, string][]
            ).map(([v, l]) => (
              <button key={v} aria-pressed={theme === v} onClick={() => setTheme(v)}>
                {l}
              </button>
            ))}
          </div>
        </section>

        <section className="card stack">
          <div className="card-head">
            <h2>Help</h2>
          </div>
          <p className="small">WhatsApp, call or SMS FarmTap support: {SUPPORT_WHATSAPP}</p>
          <div className="row wrap">
            <a className="btn outline" href={supportWhatsAppLink()} target="_blank" rel="noreferrer">
              <Icon name="whatsapp" /> WhatsApp
            </a>
            <a className="btn outline" href={`tel:${SUPPORT_WHATSAPP.replace(/\s/g, '')}`}>
              <Icon name="help" /> Call
            </a>
          </div>
        </section>
      </div>
    </>
  );
}
