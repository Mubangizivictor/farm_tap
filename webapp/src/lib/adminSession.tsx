'use client';

import { doc, getDoc, onSnapshot, serverTimestamp, setDoc } from 'firebase/firestore';
import { createContext, useCallback, useContext, useEffect, useState, type ReactNode } from 'react';
import { firebase } from './firebase.ts';
import { adminCan, type AdminMe, type Permission } from './platform.ts';
import { useSession } from './session.tsx';

export interface Invite {
  role: string;
  perms: Permission[];
  active: boolean;
}

interface AdminSession {
  /** undefined while loading; null when this account is not staff. */
  me: AdminMe | null | undefined;
  invite: Invite | null;
  acceptInvite: () => Promise<void>;
  can: (p: Permission) => boolean;
  /** Who to write in the audit log. */
  actor: { uid: string; name: string };
}

const Ctx = createContext<AdminSession | null>(null);

export function AdminProvider({ children }: { children: ReactNode }) {
  const { user } = useSession();
  const [me, setMe] = useState<AdminMe | null | undefined>(undefined);
  const [invite, setInvite] = useState<Invite | null>(null);

  useEffect(() => {
    if (!user) return;
    const { db } = firebase();
    return onSnapshot(
      doc(db, 'platformAdmins', user.uid),
      (snap) => {
        const d = snap.data();
        setMe(
          snap.exists() && d
            ? { uid: user.uid, role: d.role ?? 'custom', perms: d.perms ?? [], active: d.active === true, name: d.name ?? user.displayName ?? '', email: d.email ?? user.email ?? '' }
            : null,
        );
      },
      () => setMe(null),
    );
  }, [user]);

  useEffect(() => {
    if (!user?.email || me !== null) return;
    void getDoc(doc(firebase().db, 'adminInvites', user.email.toLowerCase()))
      .then((s) => setInvite(s.exists() && s.data().active === true ? (s.data() as Invite) : null))
      .catch(() => setInvite(null));
  }, [user, me]);

  const acceptInvite = useCallback(async () => {
    if (!user?.email || !invite) return;
    await setDoc(doc(firebase().db, 'platformAdmins', user.uid), {
      role: invite.role,
      perms: invite.perms,
      active: true,
      name: user.displayName ?? '',
      email: user.email.toLowerCase(),
      invitedBy: 'invite',
    });
  }, [user, invite]);

  const can = useCallback((p: Permission) => adminCan(me, p), [me]);
  const actor = { uid: user?.uid ?? '', name: me?.name || user?.displayName || user?.email || '' };

  return <Ctx.Provider value={{ me: user ? me : null, invite, acceptInvite, can, actor }}>{children}</Ctx.Provider>;
}

export function useAdmin(): AdminSession {
  const s = useContext(Ctx);
  if (!s) throw new Error('useAdmin outside AdminProvider');
  return s;
}

/** For the farm side: is this account Victorbee staff? (shows a link to the panel). */
export function useIsPlatformAdmin(): boolean {
  const { user } = useSession();
  const [yes, setYes] = useState(false);
  useEffect(() => {
    if (!user) return setYes(false);
    getDoc(doc(firebase().db, 'platformAdmins', user.uid))
      .then((s) => setYes(s.exists() && s.data().active === true))
      .catch(() => setYes(false));
  }, [user]);
  return yes;
}

/** Farm side: when a manager opened the farm last, at most once a day per browser. */
export function markFarmSeen(tenantId: string) {
  const key = `farmtap.seen.${tenantId}`;
  const today = new Date().toDateString();
  try {
    if (localStorage.getItem(key) === today) return;
    localStorage.setItem(key, today);
  } catch {
    /* private window: still mark it */
  }
  void setDoc(doc(firebase().db, 'tenants', tenantId), { lastSeenAt: serverTimestamp() }, { merge: true }).catch(() => undefined);
}
