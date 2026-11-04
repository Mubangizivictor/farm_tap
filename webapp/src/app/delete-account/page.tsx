'use client';

// Delete my account (decision 0024, Google Play and App Store requirement).
// Signed in: three steps (what happens, confirm, done). The account closes
// at once and is kept 90 days, then erased. Signed out: a request form that
// support answers after checking who is asking.

import Link from 'next/link';
import { useState, type FormEvent } from 'react';
import { Icon } from '@/components/Icon';
import { PublicShell } from '@/components/public';
import { Field, LogoLoader } from '@/components/ui';
import { closeAccount, HOLD_DAYS, requestDeletion, restoreDeadline } from '@/lib/account';
import { date } from '@/lib/format';
import { loadPublicInfo, useOnce } from '@/lib/publicData';
import { useSession } from '@/lib/session';
import { telHref, waHref } from '@/lib/site';

const WORD = 'DELETE';

const CONSEQUENCES = [
  'You are signed out on every phone and computer, and you cannot sign in again with this account.',
  'Every farm you own closes at once. Your workers, managers and milk suppliers lose access to it too.',
  'Your herd, milk, health, breeding, feeds, money, roster and worker records stop being available.',
  `We keep everything for ${HOLD_DAYS} days in case you change your mind. Call or WhatsApp support within that time to get it back.`,
  `After ${HOLD_DAYS} days everything is erased for good and cannot be brought back.`,
  'Any time left on your plan is not refunded when you delete. Receipts we must keep by law are kept, without your farm records.',
  'Farms you only work on (not your own) are not deleted. Their owners keep their records.',
];

export default function Page() {
  const { user } = useSession();
  return (
    <PublicShell wide={false}>
      <section className="stack lg">
        <div className="stack">
          <h1 className="pub-h1">Delete my FarmTap account</h1>
          <p className="muted">
            You can delete your account at any time. Please read what happens first. Nothing is deleted until you confirm.
          </p>
        </div>
        {user === undefined ? <LogoLoader text="Checking your sign-in…" /> : user ? <SignedIn /> : <SignedOut />}
      </section>
    </PublicShell>
  );
}

function Consequences() {
  return (
    <ul className="consequences">
      {CONSEQUENCES.map((c) => (
        <li key={c}>
          <Icon name="alert" />
          <span>{c}</span>
        </li>
      ))}
    </ul>
  );
}

function SupportLine() {
  const info = useOnce(loadPublicInfo);
  const phone = info?.config.support.phone ?? '';
  const wa = info?.config.support.whatsapp || phone;
  if (!phone) return null;
  return (
    <p className="small muted">
      Questions? Call <a href={telHref(phone)}>{phone}</a> or{' '}
      <a href={waHref(wa)} target="_blank" rel="noreferrer">
        WhatsApp us
      </a>
      .
    </p>
  );
}

function SignedIn() {
  const { user, signOut, online } = useSession();
  const [step, setStep] = useState<'read' | 'confirm' | 'done'>('read');
  const [ticked, setTicked] = useState(false);
  const [typed, setTyped] = useState('');
  const [reason, setReason] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const [closedOn, setClosedOn] = useState<Date | null>(null);
  if (!user) return null;

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    if (typed.trim().toUpperCase() !== WORD || !ticked) return;
    setBusy(true);
    setError('');
    try {
      await closeAccount({ uid: user.uid, email: user.email ?? user.phoneNumber ?? '', name: user.displayName ?? '', reason, source: 'web' });
      setClosedOn(new Date());
      setStep('done');
      await signOut();
    } catch (err) {
      const code = (err as { code?: string }).code ?? '';
      setError(
        code === 'permission-denied'
          ? 'This account is already closed, or you are not allowed to close one of its farms. Please contact support.'
          : 'We could not delete your account just now. Check your internet and try again.',
      );
    } finally {
      setBusy(false);
    }
  };

  if (step === 'done') {
    const by = restoreDeadline(closedOn);
    return (
      <div className="card stack">
        <h2 className="pub-h2">Your account is deleted</h2>
        <p>
          You have been signed out. We will keep your records until <strong>{date(by)}</strong>. If you change your mind before
          then, contact support and we will restore everything.
        </p>
        <SupportLine />
        <Link className="btn" href="/">
          Back to the home page
        </Link>
      </div>
    );
  }

  if (step === 'read') {
    return (
      <div className="card danger-card stack lg">
        <div className="stack">
          <h2 className="pub-h2">What happens when you delete</h2>
          <p className="small muted">Signed in as {user.email || user.phoneNumber || 'you'}</p>
        </div>
        <Consequences />
        <div className="banner">
          <Icon name="download" />
          <span>Want a copy first? Open Reports and download your records before you delete.</span>
        </div>
        <div className="row wrap">
          <Link className="btn" href="/home/">
            Keep my account
          </Link>
          <button type="button" className="btn outline danger" onClick={() => setStep('confirm')}>
            I understand, continue
          </button>
        </div>
        <SupportLine />
      </div>
    );
  }

  const ready = ticked && typed.trim().toUpperCase() === WORD && online;
  return (
    <form className="card danger-card stack lg" onSubmit={submit}>
      <h2 className="pub-h2">Are you sure?</h2>
      <p>This closes your account and every farm you own right now. You have {HOLD_DAYS} days to ask support to bring it back.</p>
      <Field label="Why are you leaving? (optional)" hint="It helps us make FarmTap better.">
        <textarea rows={3} maxLength={1000} value={reason} onChange={(e) => setReason(e.target.value)} />
      </Field>
      <label className="check-row">
        <input type="checkbox" checked={ticked} onChange={(e) => setTicked(e.target.checked)} />
        <span>I have read what happens and I want to delete my account.</span>
      </label>
      <Field label={`Type ${WORD} to confirm`}>
        <input value={typed} onChange={(e) => setTyped(e.target.value)} autoComplete="off" autoCapitalize="characters" />
      </Field>
      {!online && <p className="banner warn">You are offline. Connect to the internet to delete your account.</p>}
      {error && <p className="banner bad">{error}</p>}
      <div className="row wrap">
        <button type="button" className="btn outline" onClick={() => setStep('read')} disabled={busy}>
          Go back
        </button>
        <button type="submit" className="btn danger" disabled={!ready || busy}>
          {busy ? 'Deleting…' : 'Delete my account'}
        </button>
      </div>
    </form>
  );
}

function SignedOut() {
  const [f, setF] = useState({ name: '', email: '', phone: '', farmName: '', reason: '' });
  const [sent, setSent] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const set = (k: keyof typeof f) => (e: { target: { value: string } }) => setF({ ...f, [k]: e.target.value });

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    if (!f.name.trim() || (!f.email.trim() && !f.phone.trim())) {
      setError('Please give your name and a phone number or email so we can reach you.');
      return;
    }
    setBusy(true);
    setError('');
    try {
      await requestDeletion(f);
      setSent(true);
    } catch {
      setError('We could not send your request just now. Check your internet and try again.');
    } finally {
      setBusy(false);
    }
  };

  if (sent) {
    return (
      <div className="card stack">
        <h2 className="pub-h2">Request received</h2>
        <p>
          We will contact you to check that the account is yours, then delete it. Records are kept {HOLD_DAYS} days after that in case
          you change your mind, then erased for good.
        </p>
        <SupportLine />
      </div>
    );
  }

  return (
    <>
      <div className="card stack">
        <h2 className="pub-h2">The quickest way</h2>
        <p>Sign in, then come back to this page. You can delete your account yourself in under a minute.</p>
        <p className="small muted">In the phone app: More, then Settings, then Delete my account.</p>
        <div className="row wrap">
          <Link className="btn" href="/sign-in/?next=/delete-account/">
            Sign in to delete
          </Link>
        </div>
      </div>
      <div className="card stack lg">
        <div className="stack">
          <h2 className="pub-h2">Can&apos;t sign in? Ask us to delete it</h2>
          <p className="small muted">We reply within 3 working days.</p>
        </div>
        <Consequences />
        <form className="pub-form" onSubmit={submit}>
          <Field label="Your name">
            <input value={f.name} onChange={set('name')} maxLength={120} required />
          </Field>
          <Field label="Phone number used on FarmTap">
            <input value={f.phone} onChange={set('phone')} maxLength={40} inputMode="tel" />
          </Field>
          <Field label="Email (if you signed in with Google)">
            <input value={f.email} onChange={set('email')} maxLength={160} type="email" />
          </Field>
          <Field label="Farm name">
            <input value={f.farmName} onChange={set('farmName')} maxLength={160} />
          </Field>
          <Field label="Anything else (optional)" wide>
            <textarea rows={3} value={f.reason} onChange={set('reason')} maxLength={1000} />
          </Field>
          {error && <p className="banner bad wide">{error}</p>}
          <div className="row wrap wide">
            <button type="submit" className="btn danger" disabled={busy}>
              {busy ? 'Sending…' : 'Send deletion request'}
            </button>
          </div>
        </form>
        <SupportLine />
      </div>
    </>
  );
}
