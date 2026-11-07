'use client';

/**
 * usePlatform – live connection to platform/config and announcements.
 * Used by the farm shell to gate maintenance, refresh banners, suspended
 * state, and to pass support contacts and feature flags to the app.
 */

import { collection, getDocs, onSnapshot, type Unsubscribe } from 'firebase/firestore';
import { createContext, useContext, useEffect, useState, type ReactNode } from 'react';
import { firebase } from './firebase.ts';
import { announcementFor, configFromDoc, defaultConfig, planFromDoc, type Announcement, type Plan, type PlatformConfig } from './platform.ts';
import type { Farm } from './domain.ts';
import { doc } from 'firebase/firestore';

interface PlatformCtx {
  config: PlatformConfig;
  announcements: Announcement[];
  /** All active plans (loaded live). */
  plans: Plan[];
  /** Announcements relevant to this farm, filtered and live. */
  farmAnnouncements: (farm: Farm) => Announcement[];
}

const Ctx = createContext<PlatformCtx>({
  config: defaultConfig,
  announcements: [],
  plans: [],
  farmAnnouncements: () => [],
});

export function PlatformProvider({ children }: { children: ReactNode }) {
  const [config, setConfig] = useState<PlatformConfig>(defaultConfig);
  const [announcements, setAnnouncements] = useState<Announcement[]>([]);
  const [plans, setPlans] = useState<Plan[]>([]);

  useEffect(() => {
    const { db } = firebase();
    // Live-subscribe to platform/config
    const unsub: Unsubscribe = onSnapshot(doc(db, 'platform', 'config'), (snap) => {
      if (snap.exists()) setConfig(configFromDoc(snap.data() as Record<string, unknown>));
    });
    // Live-subscribe to plans so feature gates update without a reload
    const unsubPlans: Unsubscribe = onSnapshot(collection(db, 'plans'), (snap) => {
      setPlans(snap.docs.map((d) => planFromDoc(d.id, d.data())));
    });

    // Load announcements once (they rarely change mid-session)
    async function loadAnnouncements() {
      const snap = await getDocs(collection(db, 'announcements'));
      const now = new Date();
      const active = snap.docs
        .map((d) => {
          const data = d.data() as Record<string, unknown>;
          const a: Announcement = {
            id: d.id,
            title: (data.title as string) ?? '',
            body: (data.body as string) ?? '',
            level: ((data.level as string) === 'warn' ? 'warn' : 'info') as 'info' | 'warn',
            audience: (data.audience as Announcement['audience']) ?? { kind: 'all', sector: '', tenantId: '' },
            startsAt: data.startsAt ? (data.startsAt as { toDate(): Date }).toDate() : null,
            endsAt: data.endsAt ? (data.endsAt as { toDate(): Date }).toDate() : null,
            active: (data.active as boolean) ?? false,
            createdAt: data.createdAt ? (data.createdAt as { toDate(): Date }).toDate() : null,
          };
          return a;
        })
        .filter((a) => {
          if (!a.active) return false;
          if (a.endsAt && a.endsAt < now) return false;
          if (a.startsAt && a.startsAt > now) return false;
          return true;
        });
      setAnnouncements(active);
    }
    void loadAnnouncements();

    return () => { unsub(); unsubPlans(); };
  }, []);

  const farmAnnouncements = (farm: Farm) => {
    const now = new Date();
    return announcements.filter((a) => announcementFor(a, farm, now));
  };

  return <Ctx.Provider value={{ config, announcements, plans, farmAnnouncements }}>{children}</Ctx.Provider>;
}

export function usePlatform() {
  return useContext(Ctx);
}
