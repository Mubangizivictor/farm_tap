'use client';

import { doc, updateDoc } from 'firebase/firestore';
import { useRouter } from 'next/navigation';
import { useEffect, useState, type FormEvent } from 'react';
import { Fit } from '@/components/fit';
import { Icon } from '@/components/Icon';
import { Field, PageHead, Seg, Tabs, useSave, useToast } from '@/components/ui';
import { saveError, upsertRecord, useRecords } from '@/lib/data';
import { ugandaDistricts } from '@/lib/districts';
import { isCentre, manages, planState } from '@/lib/domain';
import { date, ugx } from '@/lib/format';
import { firebase } from '@/lib/firebase';
import { farmKind, planText, roleName } from '@/lib/labels';
import { useFarm, useSession, useTheme, type ThemeChoice } from '@/lib/session';
import { supportWhatsAppLink } from '@/lib/support';
import { usePlatform } from '@/lib/usePlatform';

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
  const toast = useToast();
  const phoneOk = (p: string) => !p.trim() || /^\+?[\d\s-]{9,16}$/.test(p.trim());

  async function save(ev: FormEvent) {
    ev.preventDefault();
    if (!name.trim()) return setMsg({ ok: false, text: 'The farm needs a name.' });
    if (!phoneOk(whatsapp) || !phoneOk(sms)) return setMsg({ ok: false, text: 'A phone number does not look right. Example: 0772 123 456.' });
    setBusy(true);
    setMsg(null);
    try {
      await updateDoc(doc(firebase().db, 'tenants', farm.id), {
        name: name.trim(),
        district: district.trim(),
        place: district.trim(),
        village: village.trim(),
        'contacts.whatsapp': whatsapp.trim(),
        'contacts.sms': sms.trim(),
      });
      await reloadFarms();
      toast('Farm details saved');
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
        </div>
        <Fit kind="fields" cols={[1, 2, 3, 3]}>
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
          <label className="field">
            <span>Farm type</span>
            <input className="input" value={farmKind(farm)} disabled readOnly />
          </label>
        </Fit>
        {msg && <div className={`banner ${msg.ok ? 'ok' : 'bad'}`}>{msg.text}</div>}
        {boss ? (
          <div className="row">
            <button className="btn" disabled={busy || !online}>
              {busy ? 'Saving…' : 'Save details'}
            </button>
            {!online && <span className="small muted">No internet: saving is off.</span>}
          </div>
        ) : (
          <p className="small muted">Only the owner or manager can change farm details.</p>
        )}
      </form>
    </section>
  );
}

function SubscriptionSection() {
  const farm = useFarm();
  const { config } = usePlatform();
  const now = new Date();
  const plan = planState(farm.subscription, now);
  const pt = planText(plan);

  const enabledGateways = config.payments.gateways.filter((g) => g.enabled);

  return (
    <section className="card stack">
      <div className="card-head">
        <h2>Subscription and payment</h2>
        <span className={`chip ${pt.tone}`}>{pt.text}</span>
      </div>
      {farm.subscription.trialStartedAt && <p className="small muted">Free trial started {date(farm.subscription.trialStartedAt)}.</p>}
      <p className="small">
        {plan.kind === 'readOnly'
          ? 'Your records are safe and you can see everything. Pay to record again.'
          : 'When the trial or subscription ends, FarmTap becomes read-only until you pay. Nothing is deleted.'}
      </p>

      {enabledGateways.length > 0 && (
        <>
          <h3>How to pay</h3>
          <div className="list">
            {enabledGateways.map((g) => (
              <div key={g.id} className="list-row wrap">
                <div className="stack grow" style={{ gap: 'var(--s-xxs)' }}>
                  <strong>{g.name}</strong>
                  {g.payCode && <span className="mono small">{g.payCode}</span>}
                  {g.accountName && <span className="small muted">{g.accountName}</span>}
                  {g.instructions && <span className="small">{g.instructions}</span>}
                </div>
              </div>
            ))}
          </div>
          {config.payments.manualNote && <p className="small muted">{config.payments.manualNote}</p>}
        </>
      )}

      <div className="row wrap">
        <a className="btn" href={supportWhatsAppLink(`Hello FarmTap, I want to pay for ${farm.name}.`)} target="_blank" rel="noreferrer">
          <Icon name="whatsapp" /> Pay on WhatsApp
        </a>
      </div>
    </section>
  );
}

function HelpSection() {
  const { config } = usePlatform();
  const phone = config.support.phone || '+256793128137';
  const whatsapp = config.support.whatsapp || '+256793128137';
  const email = config.support.email;
  const hours = config.support.hours;

  return (
    <section className="card stack">
      <div className="card-head">
        <h2>Help and support</h2>
      </div>
      {hours && <p className="small muted">{hours}</p>}
      <div className="row wrap">
        <a className="btn outline" href={`https://wa.me/${whatsapp.replace(/[^0-9]/g, '')}`} target="_blank" rel="noreferrer">
          <Icon name="whatsapp" /> WhatsApp
        </a>
        <a className="btn outline" href={`tel:${phone.replace(/\s/g, '')}`}>
          <Icon name="phone" /> Call
        </a>
        {email && (
          <a className="btn outline" href={`mailto:${email}`}>
            <Icon name="mail" /> Email
          </a>
        )}
      </div>
      {config.legal.termsUrl && (
        <div className="row wrap">
          <a className="small muted" href={config.legal.termsUrl} target="_blank" rel="noreferrer">Terms of use</a>
          {config.legal.privacyUrl && <a className="small muted" href={config.legal.privacyUrl} target="_blank" rel="noreferrer">Privacy policy</a>}
        </div>
      )}
    </section>
  );
}

/** The centre's price per litre (settings/centrePrice), the same number the centre phone uses. */
function CentrePrice() {
  const farm = useFarm();
  const { user, canSave } = useSession();
  const toast = useToast();
  const boss = manages(farm);
  const settings = useRecords<{ pricePerLitre?: number }>(farm.id, 'settings');
  const current = settings.data.find((r) => r.id === 'centrePrice')?.body.pricePerLitre;
  const [price, setPrice] = useState('');
  const { busy, error, setError, run } = useSave();
  useEffect(() => {
    if (current != null) setPrice(String(current));
  }, [current]);

  async function save(ev: FormEvent) {
    ev.preventDefault();
    if (!user) return;
    const n = Number(price);
    if (!Number.isInteger(n) || n <= 0) return setError('Type the price for one litre in whole shillings, e.g. 1200.');
    if (await run(() => upsertRecord(firebase().db, farm.id, 'settings', 'centrePrice', user.uid, { pricePerLitre: n }))) toast(`Price set to ${ugx(n)} a litre`);
  }

  return (
    <section className="card">
      <form className="stack" onSubmit={save}>
        <div className="card-head">
          <h2>Milk price paid to suppliers</h2>
          {current != null && <span className="chip brand">{ugx(current)} a litre</span>}
        </div>
        <p className="small muted">Used for supplier statements and payouts on the centre phone.</p>
        <div className="inline-form short">
          <Field label="Price per litre (UGX)" error={error || null}>
            <input className="input" type="number" min={1} step={1} inputMode="numeric" value={price} onChange={(e) => setPrice(e.target.value)} disabled={!boss} />
          </Field>
          {boss && (
            <button className="btn" disabled={busy || !canSave}>
              {busy ? 'Saving…' : 'Save price'}
            </button>
          )}
        </div>
      </form>
    </section>
  );
}

type Tab = 'farm' | 'plan' | 'account' | 'help';
const TABS: readonly (readonly [Tab, string])[] = [
  ['farm', 'Farm'],
  ['plan', 'Plan and payment'],
  ['account', 'Your account'],
  ['help', 'Help'],
];

export default function Settings() {
  const farm = useFarm();
  const { user, farms, signOut } = useSession();
  const router = useRouter();
  const [theme, setTheme] = useTheme();
  const [tab, setTabState] = useState<Tab>('farm');

  // The tab lives in the address (#plan), so a link can open it.
  useEffect(() => {
    const read = () => {
      const h = window.location.hash.slice(1) as Tab;
      if (TABS.some(([t]) => t === h)) setTabState(h);
    };
    read();
    window.addEventListener('hashchange', read);
    return () => window.removeEventListener('hashchange', read);
  }, []);
  const setTab = (t: Tab) => {
    setTabState(t);
    history.replaceState(null, '', `#${t}`);
  };

  return (
    <>
      <PageHead title="Settings" subtitle={`${farm.name} · ${farmKind(farm)}`} />
      <Tabs label="Settings" value={tab} onChange={setTab} items={TABS} />

      {tab === 'farm' && (
        <>
          <FarmProfile />
          {isCentre(farm) && <CentrePrice />}
        </>
      )}

      {tab === 'plan' && <SubscriptionSection />}

      {tab === 'account' && (
        <Fit kind="cards" cols={[1, 2, 2, 2]}>
          <section className="card stack">
            <div className="card-head">
              <h2>You</h2>
              <span className="chip brand">{roleName(farm)}</span>
            </div>
            <div className="row">
              <span className="avatar lg">
                {user?.photoURL ? <img src={user.photoURL} alt="" referrerPolicy="no-referrer" /> : (user?.displayName || user?.email || '?').slice(0, 1).toUpperCase()}
              </span>
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
            <p className="small muted">Dark is easier on the eyes at night and saves battery on many phones.</p>
            <Seg
              label="Theme"
              value={theme}
              onChange={(v: ThemeChoice) => setTheme(v)}
              items={[
                ['device', 'Same as device'],
                ['light', 'Light'],
                ['dark', 'Dark'],
              ]}
            />
          </section>
        </Fit>
      )}

      {tab === 'help' && <HelpSection />}
    </>
  );
}
