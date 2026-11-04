'use client';

import { GoogleAuthProvider, signInWithPopup, signOut as fbSignOut } from 'firebase/auth';
import { doc, getDoc } from 'firebase/firestore';
import { useEffect, useState } from 'react';
import { firebase } from '@/lib/firebase';
import { useSession } from '@/lib/session';

export default function AdminDebug() {
  const { user } = useSession();
  const [fsResult, setFsResult] = useState<string>('not checked yet');
  const [fsData, setFsData] = useState<string>('');
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    if (!user) return;
    setFsResult('reading...');
    getDoc(doc(firebase().db, 'platformAdmins', user.uid))
      .then((snap) => {
        if (!snap.exists()) {
          setFsResult('MISSING — document does not exist');
        } else {
          const d = snap.data();
          setFsResult('SUCCESS — document found');
          setFsData(JSON.stringify(d, null, 2));
        }
      })
      .catch((e: { code?: string; message?: string }) => {
        setFsResult(`ERROR: ${e.code ?? 'unknown'} — ${e.message ?? ''}`);
      });
  }, [user]);

  async function signIn() {
    setBusy(true);
    try {
      const g = new GoogleAuthProvider();
      g.setCustomParameters({ prompt: 'select_account' });
      await signInWithPopup(firebase().auth, g);
    } catch (e: unknown) {
      alert(`signInWithPopup error: ${(e as { code?: string }).code ?? String(e)}`);
    } finally {
      setBusy(false);
    }
  }

  const mono: React.CSSProperties = {
    fontFamily: 'monospace',
    fontSize: 13,
    background: '#111',
    color: '#0f0',
    padding: 12,
    borderRadius: 6,
    whiteSpace: 'pre-wrap',
    wordBreak: 'break-all',
  };

  return (
    <div style={{ padding: 24, fontFamily: 'monospace', maxWidth: 700, margin: '0 auto' }}>
      <h1 style={{ fontSize: 20, marginBottom: 24 }}>FarmTap Admin Debug</h1>

      <section style={{ marginBottom: 24 }}>
        <h2 style={{ fontSize: 15, marginBottom: 8 }}>Auth state</h2>
        <div style={mono}>
          {user === undefined && 'loading...'}
          {user === null && 'NOT SIGNED IN'}
          {user && `UID:   ${user.uid}\nEmail: ${user.email}\nVerified: ${String(user.emailVerified)}\nProvider: ${user.providerData.map((p) => p.providerId).join(', ')}`}
        </div>
      </section>

      <section style={{ marginBottom: 24 }}>
        <h2 style={{ fontSize: 15, marginBottom: 8 }}>platformAdmins/{'{uid}'} read</h2>
        <div style={mono}>{user ? fsResult : '(sign in first)'}</div>
        {fsData && <div style={{ ...mono, marginTop: 8 }}>{fsData}</div>}
      </section>

      <section style={{ display: 'flex', gap: 12, flexWrap: 'wrap' }}>
        {!user && (
          <button onClick={() => void signIn()} disabled={busy}
            style={{ padding: '10px 18px', cursor: 'pointer', fontFamily: 'monospace' }}>
            {busy ? 'signing in...' : 'Sign in with Google'}
          </button>
        )}
        {user && (
          <button onClick={() => void fbSignOut(firebase().auth)}
            style={{ padding: '10px 18px', cursor: 'pointer', fontFamily: 'monospace' }}>
            Sign out
          </button>
        )}
        {user && fsResult.startsWith('SUCCESS') && fsData.includes('"active": true') && (
          <a href="/admin/" style={{ padding: '10px 18px', background: '#0a0', color: '#fff', textDecoration: 'none', fontFamily: 'monospace' }}>
            → Open admin panel
          </a>
        )}
      </section>
    </div>
  );
}
