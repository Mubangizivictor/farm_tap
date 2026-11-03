'use client';

import { onAuthStateChanged, signOut as fbSignOut, type User } from 'firebase/auth';
import { createContext, useCallback, useContext, useEffect, useMemo, useState, type ReactNode } from 'react';
import { loadFarms } from './data.ts';
import { canWrite, type Farm } from './domain.ts';
import { firebase, firebaseConfigured } from './firebase.ts';

const LAST_FARM = 'farmtap.lastFarm';

export interface Session {
  /** undefined while Firebase is still checking the saved sign-in. */
  user: User | null | undefined;
  farms: Farm[] | undefined;
  farm: Farm | null;
  farmsError: string | null;
  online: boolean;
  /** Online, not read-only, and allowed to save. */
  canSave: boolean;
  openFarm: (id: string) => void;
  reloadFarms: () => Promise<void>;
  signOut: () => Promise<void>;
}

const Ctx = createContext<Session | null>(null);

function readLast(uid: string): string | null {
  try {
    return localStorage.getItem(`${LAST_FARM}.${uid}`);
  } catch {
    return null;
  }
}

function writeLast(uid: string, id: string | null) {
  try {
    if (id) localStorage.setItem(`${LAST_FARM}.${uid}`, id);
    else localStorage.removeItem(`${LAST_FARM}.${uid}`);
  } catch {
    /* private window: still works, just not remembered */
  }
}

export function SessionProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null | undefined>(firebaseConfigured ? undefined : null);
  const [farms, setFarms] = useState<Farm[] | undefined>(undefined);
  const [farmId, setFarmId] = useState<string | null>(null);
  const [farmsError, setFarmsError] = useState<string | null>(null);
  const [online, setOnline] = useState(true);
  const [now, setNow] = useState(() => new Date());

  useEffect(() => {
    if (!firebaseConfigured) return;
    return onAuthStateChanged(firebase().auth, setUser);
  }, []);

  useEffect(() => {
    const update = () => setOnline(navigator.onLine);
    update();
    window.addEventListener('online', update);
    window.addEventListener('offline', update);
    // Re-check the trial every minute so read-only starts on time.
    const t = setInterval(() => setNow(new Date()), 60_000);
    return () => {
      window.removeEventListener('online', update);
      window.removeEventListener('offline', update);
      clearInterval(t);
    };
  }, []);

  const reloadFarms = useCallback(async () => {
    if (!user) return;
    setFarmsError(null);
    try {
      const list = await loadFarms(user.uid);
      setFarms(list);
      // Returning user: open the farm they used last on this browser, or
      // their only farm. The list only shows for multi-farm accounts.
      const last = readLast(user.uid);
      const pick = list.find((f) => f.id === last) ?? (list.length === 1 ? list[0] : undefined);
      setFarmId(pick?.id ?? null);
    } catch (e) {
      setFarms([]);
      setFarmsError((e as { code?: string }).code ?? 'unknown');
    }
  }, [user]);

  useEffect(() => {
    if (user) void reloadFarms();
    else if (user === null) {
      setFarms(undefined);
      setFarmId(null);
    }
  }, [user, reloadFarms]);

  const openFarm = useCallback(
    (id: string) => {
      setFarmId(id);
      if (user) writeLast(user.uid, id);
    },
    [user],
  );

  const signOut = useCallback(async () => {
    if (user) writeLast(user.uid, null);
    await fbSignOut(firebase().auth);
  }, [user]);

  const farm = farms?.find((f) => f.id === farmId) ?? null;
  const value = useMemo<Session>(
    () => ({
      user,
      farms,
      farm,
      farmsError,
      online,
      canSave: online && farm != null && canWrite(farm.subscription, now),
      openFarm,
      reloadFarms,
      signOut,
    }),
    [user, farms, farm, farmsError, online, now, openFarm, reloadFarms, signOut],
  );
  return <Ctx.Provider value={value}>{children}</Ctx.Provider>;
}

export function useSession(): Session {
  const s = useContext(Ctx);
  if (!s) throw new Error('useSession outside SessionProvider');
  return s;
}

/** The open farm; only use inside the farm shell, which guarantees one. */
export function useFarm(): Farm {
  const { farm } = useSession();
  if (!farm) throw new Error('No farm open');
  return farm;
}

// ---------------------------------------------------------------- Theme

export type ThemeChoice = 'device' | 'light' | 'dark';
const THEME = 'farmtap.theme';

export function applyTheme(choice: ThemeChoice) {
  const root = document.documentElement;
  if (choice === 'device') root.removeAttribute('data-theme');
  else root.setAttribute('data-theme', choice);
}

export function useTheme(): [ThemeChoice, (c: ThemeChoice) => void] {
  const [choice, setChoice] = useState<ThemeChoice>('device');
  useEffect(() => {
    try {
      setChoice((localStorage.getItem(THEME) as ThemeChoice | null) ?? 'device');
    } catch {
      /* ignore */
    }
  }, []);
  const set = useCallback((c: ThemeChoice) => {
    setChoice(c);
    applyTheme(c);
    try {
      localStorage.setItem(THEME, c);
    } catch {
      /* ignore */
    }
  }, []);
  return [choice, set];
}

/** Runs before first paint (in layout) so a dark choice never flashes light. */
export const themeBootScript = `try{var t=localStorage.getItem('${THEME}');if(t==='light'||t==='dark')document.documentElement.setAttribute('data-theme',t)}catch(e){}`;
