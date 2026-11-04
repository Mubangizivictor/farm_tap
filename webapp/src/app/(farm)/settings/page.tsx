'use client';

import { doc, updateDoc } from 'firebase/firestore';
import { sendPasswordResetEmail, updateProfile } from 'firebase/auth';
import { useRouter } from 'next/navigation';
import { useEffect, useState, type FormEvent } from 'react';
import { Fit } from '@/components/fit';
import { Icon } from '@/components/Icon';
import { PlansSection } from '@/components/plans';
import { PhotoPicker } from '@/components/upload';
import { BillingDocsSection } from '@/components/billingDocs';
import { AlertSettingsSection } from '@/components/alertSettings';
import { removeProfilePhoto, saveProfilePhoto } from '@/lib/account';
import { storeImage } from '@/lib/images';
import { Field, PageHead, Tabs, useSave, useToast } from '@/components/ui';
import { saveError, upsertRecord, useRecords } from '@/lib/data';
import { ugandaDistricts } from '@/lib/districts';
import { isCentre, manages, planState } from '@/lib/domain';
import { date, ugx } from '@/lib/format';
import { firebase } from '@/lib/firebase';
import { farmKind, planText, roleName } from '@/lib/labels';
import { useFarm, useSession } from '@/lib/session';
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
      <div className="row wrap">
        <a className="small muted" href={config.legal.termsUrl || '/terms/'} target="_blank" rel="noreferrer">Terms of use</a>
        <a className="small muted" href={config.legal.privacyUrl || '/privacy/'} target="_blank" rel="noreferrer">Privacy policy</a>
        <a className="small muted" href="/delete-account/">Delete my account</a>
      </div>
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

type Tab = 'farm' | 'plan' | 'reminders' | 'account' | 'help';
const TABS: readonly (readonly [Tab, string])[] = [
  ['farm', 'Farm'],
  ['plan', 'Plan and payment'],
  ['reminders', 'Reminders'],
  ['account', 'Your account'],
  ['help', 'Help'],
];

export default function Settings() {
  const farm = useFarm();
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

      {tab === 'plan' && (
        <>
          <PlansSection farm={farm} />
          {manages(farm) && <BillingDocsSection farm={farm} />}
        </>
      )}

      {tab === 'reminders' && <AlertSettingsSection farm={farm} />}

      {tab === 'account' && <AccountSection />}

      {tab === 'help' && <HelpSection />}
    </>
  );
}

const providerName: Record<string, string> = { 'google.com': 'Google', 'apple.com': 'Apple', password: 'Email and password', phone: 'Phone number' };

/**
 * Your account (web). Name, email, theme, switch and sign out already sit in
 * the profile menu at the top, so this tab holds what that menu cannot:
 * editing your name, how you sign in, farms on the account, and your data.
 */
function AccountSection() {
  const farm = useFarm();
  const { user, canSwitch, reloadFarms, photo, reloadProfile, online } = useSession();
  const { config } = usePlatform();
  const router = useRouter();
  const toast = useToast();
  const save = useSave();
  const [name, setName] = useState(user?.displayName ?? '');
  const [resetSent, setResetSent] = useState(false);
  const methods = (user?.providerData ?? []).map((p) => providerName[p.providerId] ?? p.providerId);
  const hasPassword = (user?.providerData ?? []).some((p) => p.providerId === 'password');
  const phone = config.support.phone || '+256 793 128 137';
  const ask = (text: string) => supportWhatsAppLink(`Hello FarmTap, ${text} My account: ${user?.email ?? ''}. Farm: ${farm.name}.`);
  const when = (iso?: string) => (iso ? date(new Date(iso)) : '–');

  async function saveName(ev: FormEvent) {
    ev.preventDefault();
    if (!user || !name.trim()) return;
    const ok = await save.run(async () => {
      await updateProfile(user, { displayName: name.trim() });
      await reloadFarms();
    });
    if (ok) toast('Name saved');
  }

  async function sendReset() {
    if (!user?.email) return;
    const ok = await save.run(() => sendPasswordResetEmail(firebase().auth, user.email!));
    if (ok) setResetSent(true);
  }

  return (
    <Fit kind="cards" cols={[1, 2, 2, 2]}>
      <section className="card stack">
        <div className="card-head">
          <h2>Your photo</h2>
        </div>
        <p className="small muted">Shown at the top of FarmTap and to people on your farm.</p>
        <PhotoPicker
          photo={photo}
          name={user?.displayName || user?.email || ''}
          disabled={!online || !user}
          onPick={async (img) => {
            if (!user) return;
            const url = await storeImage(`profiles/${user.uid}/photo.jpg`, img.dataUrl);
            await saveProfilePhoto(user.uid, img.dataUrl, url);
            await reloadProfile();
            toast('Photo saved');
          }}
          onRemove={async () => {
            if (!user) return;
            await removeProfilePhoto(user.uid);
            await reloadProfile();
            toast('Photo removed');
          }}
        />
      </section>

      <section className="card">
        <form className="stack" onSubmit={saveName}>
          <div className="card-head">
            <h2>Your name</h2>
            <span className="chip brand">{roleName(farm)}</span>
          </div>
          <p className="small muted">Workers see this name on tasks, the duty roster and payments you record.</p>
          <Field label="Full name" error={save.error || null}>
            <input className="input" value={name} onChange={(e) => setName(e.target.value)} autoComplete="name" placeholder="For example Victor Mubangizi" required />
          </Field>
          <div className="row">
            <button className="btn" type="submit" disabled={save.busy || !name.trim() || name.trim() === (user?.displayName ?? '')}>
              {save.busy ? 'Saving…' : 'Save name'}
            </button>
          </div>
        </form>
      </section>

      <section className="card stack">
        <div className="card-head">
          <h2>Sign-in and security</h2>
        </div>
        <div className="list">
          <div className="list-row">
            <span className="grow">Signs in with</span>
            <strong>{methods.join(', ') || '–'}</strong>
          </div>
          <div className="list-row">
            <span className="grow">Last sign-in</span>
            <span>{when(user?.metadata.lastSignInTime)}</span>
          </div>
          <div className="list-row">
            <span className="grow">Account made</span>
            <span>{when(user?.metadata.creationTime)}</span>
          </div>
        </div>
        {hasPassword ? (
          resetSent ? (
            <p className="small up">We sent a link to {user?.email}. Open it to choose a new password.</p>
          ) : (
            <div className="row">
              <button className="btn outline" onClick={() => void sendReset()} disabled={save.busy}>
                <Icon name="key" /> Change password
              </button>
            </div>
          )
        ) : (
          <p className="small muted">Your password is kept by {methods[0] || 'your sign-in provider'}, not FarmTap.</p>
        )}
        <p className="small muted">This browser stays signed in until you sign out from the picture at the top. Sign out on shared computers.</p>
      </section>

      <section className="card stack">
        <div className="card-head">
          <h2>Farms on this account</h2>
        </div>
        {canSwitch ? (
          <>
            <p className="small">
              This account has more than one farm. Each keeps its own animals, records, workers, cards and plan; nothing is mixed between them.
            </p>
            <div className="row">
              <button className="btn outline" onClick={() => router.push('/farms/')}>
                <Icon name="switch" /> Open another farm
              </button>
            </div>
          </>
        ) : (
          <>
            <p className="small">One account runs one farm. For a second farm or a collection centre, ask FarmTap. Each farm then has its own plan.</p>
            <div className="row wrap">
              <a className="btn outline" href={ask('I want to add another farm to my account.')} target="_blank" rel="noreferrer">
                <Icon name="whatsapp" /> Ask for another farm
              </a>
              <a className="btn ghost" href={`tel:${phone.replace(/\s/g, '')}`}>
                <Icon name="phone" /> {phone}
              </a>
            </div>
          </>
        )}
      </section>

      <section className="card stack">
        <div className="card-head">
          <h2>Your data</h2>
        </div>
        <p className="small muted">
          Your farm records belong to you. Download them from each page (CSV) or ask for a full copy. Deleting your account closes it at once; we keep the
          records 90 days in case you change your mind, then erase them.
        </p>
        <div className="row wrap">
          <a className="btn outline" href={ask('please send me a full copy of my farm records.')} target="_blank" rel="noreferrer">
            <Icon name="download" /> Ask for a copy
          </a>
          <a className="btn ghost danger-text" href="/delete-account/">
            <Icon name="close" /> Delete my account
          </a>
        </div>
        <p className="small">
          <a href={config.legal.privacyUrl || '/privacy/'} target="_blank" rel="noreferrer">
            Privacy policy
          </a>
          {' · '}
          <a href={config.legal.termsUrl || '/terms/'} target="_blank" rel="noreferrer">
            Terms of use
          </a>
        </p>
      </section>
    </Fit>
  );
}
