'use client';

import {
  createUserWithEmailAndPassword,
  getRedirectResult,
  GoogleAuthProvider,
  OAuthProvider,
  sendPasswordResetEmail,
  signInWithEmailAndPassword,
  signInWithPopup,
  signInWithRedirect,
  updateProfile,
  type AuthProvider,
} from 'firebase/auth';
import { useRouter } from 'next/navigation';
import { useEffect, useState, type FormEvent } from 'react';
import { Icon } from '@/components/Icon';
import { Loading } from '@/components/Loading';
import { SUPPORT_WHATSAPP } from '@/lib/support';
import { firebase, firebaseConfigured } from '@/lib/firebase';
import { useSession } from '@/lib/session';

type Mode = 'signIn' | 'create' | 'reset';

/** Plain words for Firebase sign-in errors (low-literacy friendly). */
function message(code: string): string {
  switch (code) {
    case 'auth/invalid-credential':
    case 'auth/wrong-password':
    case 'auth/user-not-found':
    case 'auth/invalid-login-credentials':
      return 'Email or password is wrong. Try again, or tap "Forgot password".';
    case 'auth/invalid-email':
      return 'That email does not look right.';
    case 'auth/email-already-in-use':
      return 'This email already has an account. Sign in instead.';
    case 'auth/weak-password':
      return 'Use at least 6 characters for the password.';
    case 'auth/popup-closed-by-user':
    case 'auth/cancelled-popup-request':
      return '';
    case 'auth/operation-not-allowed':
    case 'auth/invalid-oauth-client-id':
      return 'This sign-in is not set up for the web yet. Use Google or Email for now.';
    case 'auth/unauthorized-domain':
      return 'This web address is not allowed to sign in yet. Add it in Firebase → Authentication → Authorized domains.';
    case 'auth/network-request-failed':
      return 'No internet. Check your connection and try again.';
    case 'auth/too-many-requests':
      return 'Too many tries. Wait a few minutes and try again.';
    case 'auth/account-exists-with-different-credential':
      return 'This email already signs in another way (Google, Apple or Email). Use that one.';
    default:
      return 'Could not sign in. Try again.';
  }
}

const features = [
  { icon: 'drop' as const, title: 'Every litre counted', text: 'Milk, deliveries and payments in one place.' },
  { icon: 'workers' as const, title: 'Your team, on record', text: 'Who came, who worked, who was paid.' },
  { icon: 'money' as const, title: 'Know your money', text: 'What came in, what went out, this month.' },
];

function Features() {
  return (
    <div className="feature-cards">
      {features.map((f) => (
        <div key={f.title} className="feature-card">
          <div className="stat">
            <div className="icon-chip">
              <Icon name={f.icon} />
            </div>
          </div>
          <div className="stack" style={{ gap: 'var(--s-xxs)' }}>
            <strong>{f.title}</strong>
            <span className="small muted">{f.text}</span>
          </div>
        </div>
      ))}
    </div>
  );
}

export default function SignIn() {
  const { user } = useSession();
  const router = useRouter();
  const [mode, setMode] = useState<Mode>('signIn');
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [busy, setBusy] = useState<string | null>(null);
  const [error, setError] = useState('');
  const [info, setInfo] = useState('');

  // Already signed in on this browser: never ask again (go to the farm).
  useEffect(() => {
    if (user) router.replace('/');
  }, [user, router]);

  // Finish a redirect sign-in (used when the browser blocks pop-ups).
  useEffect(() => {
    if (!firebaseConfigured) return;
    getRedirectResult(firebase().auth).catch((e) => setError(message(e.code)));
  }, []);

  if (user === undefined || user) return <Loading />;

  async function withProvider(id: 'google' | 'apple') {
    setError('');
    setInfo('');
    setBusy(id);
    let provider: AuthProvider;
    if (id === 'google') {
      const g = new GoogleAuthProvider();
      g.setCustomParameters({ prompt: 'select_account' });
      provider = g;
    } else {
      const a = new OAuthProvider('apple.com');
      a.addScope('email');
      a.addScope('name');
      provider = a;
    }
    try {
      await signInWithRedirect(firebase().auth, provider);
    } catch (e) {
      const code = (e as { code: string }).code;
      setError(message(code));
      setBusy(null);
    }
  }

  async function onSubmit(ev: FormEvent) {
    ev.preventDefault();
    setError('');
    setInfo('');
    setBusy('email');
    const { auth } = firebase();
    try {
      if (mode === 'reset') {
        await sendPasswordResetEmail(auth, email.trim());
        setInfo(`We sent a link to ${email.trim()}. Open it to set a new password, then sign in.`);
        setMode('signIn');
      } else if (mode === 'create') {
        const cred = await createUserWithEmailAndPassword(auth, email.trim(), password);
        if (name.trim()) await updateProfile(cred.user, { displayName: name.trim() });
      } else {
        await signInWithEmailAndPassword(auth, email.trim(), password);
      }
    } catch (e) {
      setError(message((e as { code: string }).code));
    } finally {
      setBusy(null);
    }
  }

  const title = mode === 'create' ? 'Create your account' : mode === 'reset' ? 'Forgot password' : 'Sign in to FarmTap';

  return (
    <div className="auth">
      <aside className="auth-side">
        <div className="logo-full" aria-label="FarmTap" role="img" />
        <div className="stack">
          <h1>Your farm records, on any computer.</h1>
          <p>See today’s work, your team and your money from the office or at home.</p>
        </div>
        <Features />
      </aside>
      <main className="auth-main">
        <div className="auth-box">
          <div className="auth-brand">
            <div className="logo-mark lg spin-slow" aria-hidden />
            <h1>{title}</h1>
            <p className="muted">
              {mode === 'reset'
                ? 'Type your email. We will send you a link to set a new password.'
                : 'Owners and managers. Workers use the farm phone with their card and PIN.'}
            </p>
          </div>

          {!firebaseConfigured && (
            <div className="banner warn">
              <Icon name="alert" />
              <span className="grow">Sign-in is not connected yet. Add the Firebase web settings in webapp/.env.local.</span>
            </div>
          )}

          {mode !== 'reset' && (
            <>
              <button className="btn provider outline block" disabled={!!busy || !firebaseConfigured} onClick={() => withProvider('google')}>
                {/* Google's own "G" mark (brand asset, not a theme colour). */}
                <img src="/brand/google_g.svg" alt="" className="icon" />
                {busy === 'google' ? 'Opening Google…' : 'Continue with Google'}
              </button>
              <button className="btn provider outline block" disabled={!!busy || !firebaseConfigured} onClick={() => withProvider('apple')}>
                <Icon name="apple" />
                {busy === 'apple' ? 'Opening Apple…' : 'Continue with Apple'}
              </button>
              <div className="divider">or with email</div>
            </>
          )}

          <form className="stack" onSubmit={onSubmit}>
            {mode === 'create' && (
              <label className="field">
                <span>Your name</span>
                <input className="input" value={name} onChange={(e) => setName(e.target.value)} autoComplete="name" required />
              </label>
            )}
            <label className="field">
              <span>Email</span>
              <input className="input" type="email" value={email} onChange={(e) => setEmail(e.target.value)} autoComplete="email" required />
            </label>
            {mode !== 'reset' && (
              <label className="field">
                <span>Password</span>
                <input
                  className="input"
                  type="password"
                  value={password}
                  minLength={6}
                  onChange={(e) => setPassword(e.target.value)}
                  autoComplete={mode === 'create' ? 'new-password' : 'current-password'}
                  required
                />
              </label>
            )}
            {error && (
              <p className="error-text" role="alert">
                {error}
              </p>
            )}
            {info && (
              <div className="banner ok" role="status">
                <Icon name="check" />
                <span className="grow">{info}</span>
              </div>
            )}
            <button className="btn block" type="submit" disabled={!!busy || !firebaseConfigured}>
              {busy === 'email' ? 'Please wait…' : mode === 'create' ? 'Create account' : mode === 'reset' ? 'Send link' : 'Sign in'}
            </button>
          </form>

          <div className="row between wrap small">
            {mode === 'signIn' ? (
              <>
                <button className="btn ghost sm" onClick={() => setMode('reset')}>
                  Forgot password?
                </button>
                <button className="btn ghost sm" onClick={() => setMode('create')}>
                  New here? Create account
                </button>
              </>
            ) : (
              <button className="btn ghost sm" onClick={() => setMode('signIn')}>
                Back to sign in
              </button>
            )}
          </div>

          <Features />

          <p className="small muted" style={{ textAlign: 'center' }}>
            Need help?{' '}
            <a href={`https://wa.me/${SUPPORT_WHATSAPP.replace(/\D/g, '')}`} target="_blank" rel="noreferrer">
              WhatsApp {SUPPORT_WHATSAPP}
            </a>
          </p>
        </div>
      </main>
    </div>
  );
}
