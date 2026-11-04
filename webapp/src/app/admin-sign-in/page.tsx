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
          setError('This domain is not authorised in Firebase. Add it under Firebase → Authentication → Settings → Authorized domains.');
        } else {
          setError(`Sign-in failed (${code || 'unknown error'}). Try again.`);
        }
      }
      setBusy(false);
    }
  }

  return (
    <div
      style={{
        minHeight: '100dvh',
        background: 'linear-gradient(135deg, #060810 0%, #0d1117 60%, #060810 100%)',
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        padding: '24px',
        fontFamily: 'var(--font-sans, system-ui, sans-serif)',
        position: 'relative',
        overflow: 'hidden',
      }}
    >
      {/* Subtle grid overlay */}
      <div
        aria-hidden
        style={{
          position: 'absolute',
          inset: 0,
          backgroundImage:
            'linear-gradient(rgba(255,255,255,0.025) 1px, transparent 1px), linear-gradient(90deg, rgba(255,255,255,0.025) 1px, transparent 1px)',
          backgroundSize: '48px 48px',
          pointerEvents: 'none',
        }}
      />

      {/* Glow */}
      <div
        aria-hidden
        style={{
          position: 'absolute',
          top: '-120px',
          left: '50%',
          transform: 'translateX(-50%)',
          width: '600px',
          height: '300px',
          background: 'radial-gradient(ellipse, rgba(34,197,94,0.07) 0%, transparent 70%)',
          pointerEvents: 'none',
        }}
      />

      <div
        style={{
          position: 'relative',
          width: '100%',
          maxWidth: '380px',
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          gap: '28px',
        }}
      >
        {/* Logo badge */}
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '14px' }}>
          <div
            style={{
              width: '56px',
              height: '56px',
              borderRadius: '14px',
              background: 'rgba(34,197,94,0.1)',
              border: '1px solid rgba(34,197,94,0.25)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              color: 'rgba(34,197,94,0.9)',
            }}
          >
            <Icon name="shield" />
          </div>
          <div style={{ textAlign: 'center' }}>
            <p
              style={{
                color: 'rgba(255,255,255,0.35)',
                fontSize: '11px',
                fontWeight: 600,
                letterSpacing: '0.12em',
                textTransform: 'uppercase',
                margin: '0 0 6px',
              }}
            >
              Victorbee Technologies
            </p>
            <h1
              style={{
                color: '#fff',
                fontSize: '22px',
                fontWeight: 700,
                letterSpacing: '-0.4px',
                margin: 0,
              }}
            >
              Platform Administration
            </h1>
          </div>
        </div>

        {/* Sign-in card */}
        <div
          style={{
            width: '100%',
            background: 'rgba(255,255,255,0.03)',
            border: '1px solid rgba(255,255,255,0.08)',
            borderRadius: '16px',
            padding: '28px 24px',
            display: 'flex',
            flexDirection: 'column',
            gap: '18px',
            backdropFilter: 'blur(8px)',
          }}
        >
          <div>
            <p
              style={{
                color: 'rgba(255,255,255,0.5)',
                fontSize: '13.5px',
                margin: '0 0 18px',
                lineHeight: 1.5,
              }}
            >
              Authorised staff only. Sign in with your Victorbee Google account.
            </p>

            {error && (
              <div
                role="alert"
                style={{
                  background: 'rgba(239,68,68,0.08)',
                  border: '1px solid rgba(239,68,68,0.25)',
                  borderRadius: '8px',
                  padding: '11px 14px',
                  color: '#fca5a5',
                  fontSize: '13px',
                  lineHeight: 1.5,
                  marginBottom: '14px',
                }}
              >
                {error}
              </div>
            )}

            <button
              onClick={() => void signInWithGoogle()}
              disabled={busy || !firebaseConfigured}
              style={{
                width: '100%',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                gap: '11px',
                padding: '13px 20px',
                background: busy ? 'rgba(255,255,255,0.04)' : 'rgba(255,255,255,0.07)',
                border: '1px solid rgba(255,255,255,0.14)',
                borderRadius: '10px',
                color: busy ? 'rgba(255,255,255,0.4)' : '#fff',
                fontSize: '14.5px',
                fontWeight: 500,
                cursor: busy ? 'not-allowed' : 'pointer',
                transition: 'background 0.15s, border-color 0.15s',
                letterSpacing: '-0.1px',
              }}
            >
              <img src="/brand/google_g.svg" alt="" style={{ width: '19px', height: '19px', opacity: busy ? 0.5 : 1 }} />
              {busy ? 'Opening Google…' : 'Sign in with Google'}
            </button>
          </div>

          <div
            style={{
              borderTop: '1px solid rgba(255,255,255,0.06)',
              paddingTop: '14px',
              display: 'flex',
              alignItems: 'center',
              gap: '8px',
              color: 'rgba(255,255,255,0.22)',
              fontSize: '12px',
            }}
          >
            <Icon name="lock" className="icon" />
            All sign-in attempts are logged and monitored.
          </div>
        </div>

        <p style={{ color: 'rgba(255,255,255,0.18)', fontSize: '12px', margin: 0, textAlign: 'center' }}>
          FarmTap · {new Date().getFullYear()}
        </p>
      </div>
    </div>
  );
}
