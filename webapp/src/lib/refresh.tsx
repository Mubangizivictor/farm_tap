'use client';

// One refresh for the whole web app: the refresh button in the top bar and
// pull-to-refresh on phones and tablets both call refresh(). It reloads the
// signed-in farm and profile, re-opens every live list (useRecords) and
// re-runs every panel load (useLoad), and shows the turning FarmTap logo for
// at least 1.5 seconds so people can see it happened.

import { createContext, useCallback, useContext, useEffect, useRef, useState, type ReactNode } from 'react';
import { useSession } from './session.tsx';

/** Shortest time the refresh logo is shown, so a quick refresh is still visible. */
export const REFRESH_MS = 1500;
/** How far to pull down before letting go refreshes. */
const PULL_PX = 72;

interface Refresh {
  /** Goes up by one on every refresh; data hooks list it as a dependency. */
  tick: number;
  refreshing: boolean;
  refresh: () => Promise<void>;
}

const Ctx = createContext<Refresh>({ tick: 0, refreshing: false, refresh: async () => undefined });

export const useRefresh = () => useContext(Ctx);
export const useRefreshTick = () => useContext(Ctx).tick;

export function RefreshProvider({ children }: { children: ReactNode }) {
  const { reloadFarms, reloadProfile, user } = useSession();
  const [tick, setTick] = useState(0);
  const [refreshing, setRefreshing] = useState(false);
  const busy = useRef(false);

  const refresh = useCallback(async () => {
    if (busy.current) return;
    busy.current = true;
    setRefreshing(true);
    const started = Date.now();
    setTick((t) => t + 1);
    try {
      if (user) await Promise.allSettled([reloadFarms(), reloadProfile()]);
    } finally {
      const left = REFRESH_MS - (Date.now() - started);
      if (left > 0) await new Promise((ok) => setTimeout(ok, left));
      busy.current = false;
      setRefreshing(false);
    }
  }, [reloadFarms, reloadProfile, user]);

  return (
    <Ctx.Provider value={{ tick, refreshing, refresh }}>
      {children}
      <PullToRefresh onRefresh={refresh} refreshing={refreshing} />
      {refreshing && (
        <div className="refresh-veil" role="status" aria-live="polite">
          <div className="refresh-card">
            <div className="logo-mark spin-logo" aria-hidden />
            <span>Refreshing…</span>
          </div>
        </div>
      )}
    </Ctx.Provider>
  );
}

/** Pull down from the top of the page (touch screens) to refresh. */
function PullToRefresh({ onRefresh, refreshing }: { onRefresh: () => Promise<void>; refreshing: boolean }) {
  const [pull, setPull] = useState(0);
  const start = useRef<number | null>(null);
  const dist = useRef(0);
  useEffect(() => {
    const down = (e: TouchEvent) => {
      // Not inside dialogs, sheets, menus or the chat's own scrolling list.
      const t = e.target as HTMLElement | null;
      if (window.scrollY > 0 || refreshing || t?.closest('dialog, .dialog, .sheet, .menu, .drawer, .chat-scroll, [data-no-pull]')) {
        start.current = null;
        return;
      }
      start.current = e.touches[0].clientY;
      dist.current = 0;
    };
    const move = (e: TouchEvent) => {
      if (start.current == null) return;
      const d = e.touches[0].clientY - start.current;
      if (d <= 0 || window.scrollY > 0) {
        dist.current = 0;
        setPull(0);
        return;
      }
      // Resist a little so it feels like pulling, not scrolling.
      dist.current = Math.min(PULL_PX * 1.6, d * 0.55);
      setPull(dist.current);
    };
    const up = () => {
      if (start.current == null) return;
      start.current = null;
      const go = dist.current >= PULL_PX;
      dist.current = 0;
      setPull(0);
      if (go) void onRefresh();
    };
    window.addEventListener('touchstart', down, { passive: true });
    window.addEventListener('touchmove', move, { passive: true });
    window.addEventListener('touchend', up);
    window.addEventListener('touchcancel', up);
    return () => {
      window.removeEventListener('touchstart', down);
      window.removeEventListener('touchmove', move);
      window.removeEventListener('touchend', up);
      window.removeEventListener('touchcancel', up);
    };
  }, [onRefresh, refreshing]);
  if (!pull) return null;
  const ready = pull >= PULL_PX;
  return (
    <div className="pull-refresh" style={{ transform: `translate(-50%, ${pull}px)` }} aria-hidden>
      <div className="logo-mark" style={{ transform: `rotate(${pull * 4}deg)`, opacity: Math.min(1, pull / PULL_PX) }} />
      <span className="small">{ready ? 'Let go to refresh' : 'Pull to refresh'}</span>
    </div>
  );
}
