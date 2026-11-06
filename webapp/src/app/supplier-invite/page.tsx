'use client';

import { Suspense, useEffect, useState } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import { doc, getDoc, writeBatch } from 'firebase/firestore';
import { Icon } from '@/components/Icon';
import { Loading } from '@/components/Loading';
import { firebase } from '@/lib/firebase';
import { useSession } from '@/lib/session';

interface InviteDoc {
  tenantId: string;
  farmerId: string;
  farmerName: string;
  farmName: string;
  createdAt: string;
  expiresAt: string;
  used: boolean;
}

function AcceptInvite() {
  const params = useSearchParams();
  const code = params.get('code') ?? '';
  const { user } = useSession();
  const router = useRouter();
  const [invite, setInvite] = useState<InviteDoc | null>(null);
  const [state, setState] = useState<'loading' | 'ready' | 'invalid' | 'used' | 'expired' | 'done' | 'error'>('loading');
  const [busy, setBusy] = useState(false);
  const [errorMsg, setErrorMsg] = useState('');

  useEffect(() => {
    if (!code) { setState('invalid'); return; }
    const { db } = firebase();
    getDoc(doc(db, 'farmerInvites', code)).then((snap) => {
      if (!snap.exists()) { setState('invalid'); return; }
      const d = snap.data() as InviteDoc;
      if (d.used) { setState('used'); return; }
      if (new Date(d.expiresAt) < new Date()) { setState('expired'); return; }
      setInvite(d);
      setState('ready');
    }).catch(() => setState('invalid'));
  }, [code]);

  async function accept() {
    if (!user || !invite || !code) return;
    setBusy(true);
    try {
      const { db } = firebase();
      const me = await getDoc(doc(db, 'users', user.uid));
      const links = ((me.data()?.farmerLinks as { tenantId: string; farmerId: string }[] | undefined) ?? []);
      if (!links.some((l) => l.tenantId === invite.tenantId && l.farmerId === invite.farmerId)) {
        // Link the account and use up the invite in one write: the rules
        // accept the link only together with its unused invite.
        const b = writeBatch(db);
        b.set(
          doc(db, 'users', user.uid),
          // The centre's name too: a supplier cannot open the farm itself.
          { farmerLinks: [...links, { tenantId: invite.tenantId, farmerId: invite.farmerId }], inviteCode: code, centreNames: { [invite.tenantId]: invite.farmName } },
          { merge: true },
        );
        b.update(doc(db, 'farmerInvites', code), { used: true, usedBy: user.uid, usedAt: new Date().toISOString() });
        await b.commit();
      }
      setState('done');
      setTimeout(() => router.replace('/supplier/'), 1500);
    } catch (e) {
      const code = (e as { code?: string }).code;
      setErrorMsg(
        code === 'permission-denied'
          ? 'This invite cannot be used any more. Ask the collection centre for a new link.'
          : code === 'unavailable'
            ? 'No internet. Check the connection and try again.'
            : 'Could not accept the invite. Try again.',
      );
      setBusy(false);
    }
  }

  if (user === undefined || state === 'loading') return <Loading />;

  return (
    <div className="full-screen stack" style={{ alignItems: 'center', justifyContent: 'center', gap: 'var(--s-lg)', textAlign: 'center', padding: 'var(--s-xl)' }}>
      {state === 'invalid' && (
        <>
          <Icon name="alert" className="icon" />
          <h2>Invite not found</h2>
          <p className="muted">This link is invalid or has already been used. Ask the collection centre to send you a new one.</p>
        </>
      )}
      {state === 'used' && (
        <>
          <Icon name="check" className="icon" />
          <h2>Already accepted</h2>
          <p className="muted">This invite was already used. <a href="/supplier/">Go to your portal</a>.</p>
        </>
      )}
      {state === 'expired' && (
        <>
          <Icon name="alert" className="icon" />
          <h2>Invite expired</h2>
          <p className="muted">This link has expired (links are valid for 7 days). Ask the collection centre for a new one.</p>
        </>
      )}
      {state === 'done' && (
        <>
          <Icon name="check" className="icon" />
          <h2>All set!</h2>
          <p className="muted">Your account is now linked. Opening your portal…</p>
        </>
      )}
      {state === 'ready' && invite && (
        <>
          <div className="logo-mark" aria-hidden style={{ width: 'var(--s-xxl)', height: 'var(--s-xxl)' }} />
          <div className="stack" style={{ gap: 'var(--s-xs)' }}>
            <h2>You're invited to FarmTap</h2>
            <p className="muted">
              <strong>{invite.farmName}</strong> has invited <strong>{invite.farmerName}</strong> to view their delivery records and payments online.
            </p>
          </div>
          {!user ? (
            <div className="stack" style={{ gap: 'var(--s-sm)', alignItems: 'center' }}>
              <p className="small muted">Sign in or make a free account to accept this invite.</p>
              <a className="btn" href={`/sign-in/?next=${encodeURIComponent(`/supplier-invite/?code=${code}`)}`}>Sign in to accept</a>
            </div>
          ) : (
            <div className="stack" style={{ gap: 'var(--s-sm)', alignItems: 'center' }}>
              <p className="small muted">Signing in as: {user.email}</p>
              {errorMsg && <div className="banner bad">{errorMsg}</div>}
              <button className="btn" onClick={() => void accept()} disabled={busy}>
                {busy ? 'Accepting…' : 'Accept invite'}
              </button>
              <p className="small muted">Not you? <a href="/sign-in/">Sign in with a different account</a></p>
            </div>
          )}
        </>
      )}
    </div>
  );
}

export default function SupplierInvitePage() {
  return (
    <Suspense fallback={<Loading />}>
      <AcceptInvite />
    </Suspense>
  );
}
