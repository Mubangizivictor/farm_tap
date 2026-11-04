'use client';

import { GoogleAuthProvider, signInWithPopup } from 'firebase/auth';
import { doc, getDoc } from 'firebase/firestore';
import { useRouter } from 'next/navigation';
import { useEffect, useState } from 'react';
import { Loading } from '@/components/Loading';
import { Icon } from '@/components/Icon';
import { firebase, firebaseConfigured } from '@/lib/firebase';
import { useSession } from '@/lib/session';

/** Only these two Google accounts can access the control panel. */
const ALLOWED = ['farmtap.ug@gmail.com', 'mubangizivic@gmail.com'];

export default function AdminSignIn() {
  const { user, signOut } = useSession();
  const router = useRouter();
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');

  // Once signed in, check the allowlist then go to the panel.
  useEffect(() => {
    if (!user) return;
    if (!ALLOWED.includes(user.email ?? '')) {
      void signOut();
      setError('That Google account is not authorised. Only Victorbee staff can sign in here.');
      return;
    }
    router.replace('/admin/');
  }, [user, router, signOut]);

  if (user === undefined) return <Loading />;
  if (user && ALLOWED.includes(user.email ?? '')) return <Loading />;

  async function signInWithGoogle() {
    setError('');
    setBusy(true);
    try {
      const g = new GoogleAuthProvider();
      g.setCustomParameters({ prompt: 'select_account' });
      const result = await signInWithPopup(firebase().auth, g);
      const { uid, email } = result.user;

      if (!ALLOWED.includes(email ?? '')) {
        void signOut();
        setError('That Google account is not authorised. Only Victorbee staff can sign in here.');
        setBusy(false);
        return;
      }

      // Verify the platformAdmins document is readable before navigating.
      try {
        const snap = await getDoc(doc(firebase().db, 'platformAdmins', uid));
        if (!snap.exists()) {
          setError(`No admin record found for UID: ${uid} — create platformAdmins/${uid} in Firestore with { role: "owner", active: true, name: "Victor", email: "${email}", perms: [] }`);
          setBusy(false);
          return;
        }
        const d = snap.data();
        if (d.active !== true) {
          setError(`Admin account exists but is not active (active=${String(d.active)}). Set active: true in Firestore.`);
          setBusy(false);
          return;
        }
        // All good — navigate.
        router.replace('/admin/');
      } catch (fsErr) {
        const code = (fsErr as { code?: string }).code ?? 'unknown';
        setError(`Signed in as ${email} (UID: ${uid}) but cannot read admin record: ${code}. Check Firestore Security Rules allow read on platformAdmins/${uid}.`);
        setBusy(false);
      }
    } catch (e) {
      const code = (e as { code?: string }).code ?? '';
      if (code !== 'auth/popup-closed-by-user' && code !== 'auth/cancelled-popup-request') {
        if (code === 'auth/unauthorized-domain') {
          setError('This web address is not allowed to sign in yet. Add it to the allowed sign-in addresses in the project console.');
        } else {
          setError(`Sign-in failed (${code || 'unknown error'}). Try again.`);
        }
      }
      setBusy(false);
    }
  }

  return (
    <div className="full-screen">
      <div className="box">
        <div className="logo-mark lg" aria-hidden />
        <div className="stack" style={{ gap: 'var(--s-xs)' }}>
          <span className="small muted">Victorbee Technologies</span>
          <h1>FarmTap control panel</h1>
        </div>
        <div className="card stack" style={{ width: '100%', textAlign: 'left' }}>
          <p className="muted">Authorised staff only. Sign in with your Victorbee Google account.</p>
          {error && (
            <div role="alert" className="banner bad">
              {error}
            </div>
          )}
          <button className="btn outline block" onClick={() => void signInWithGoogle()} disabled={busy || !firebaseConfigured}>
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img src="/brand/google_g.svg" alt="" className="icon" />
            {busy ? 'Opening Google…' : 'Sign in with Google'}
          </button>
          <div className="row small muted">
            <Icon name="lock" className="icon" />
            All sign-in attempts are logged and monitored.
          </div>
        </div>
        <span className="small muted">FarmTap · {new Date().getFullYear()}</span>
      </div>
    </div>
  );
}
