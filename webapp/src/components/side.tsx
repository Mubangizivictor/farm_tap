'use client';

// The sidebar's top row, shared by the farm app and the control panel:
// the logo (a link home, or "open the sidebar" when it is closed), the name,
// and a button that opens and closes the sidebar on wide screens.
import Link from 'next/link';
import { useCallback, useEffect, useState } from 'react';
import { Icon } from './Icon';

const KEY = 'farmtap.sidebar';

/** Whether the wide sidebar is closed to icons. Remembered in this browser only. */
export function useSidebar() {
  const [closed, setClosed] = useState(false);
  useEffect(() => {
    try {
      setClosed(window.localStorage.getItem(KEY) === 'closed');
    } catch {
      /* private window: start open */
    }
  }, []);
  const toggle = useCallback(() => {
    setClosed((c) => {
      try {
        window.localStorage.setItem(KEY, c ? 'open' : 'closed');
      } catch {
        /* not saved, still works for this visit */
      }
      return !c;
    });
  }, []);
  // Ctrl/Cmd + B, as in most apps with a sidebar.
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 'b' && !(e.target instanceof HTMLInputElement || e.target instanceof HTMLTextAreaElement)) {
        e.preventDefault();
        toggle();
      }
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [toggle]);
  return { closed, toggle };
}

export function SideHead({ home, closed, onToggle }: { home: string; closed: boolean; onToggle: () => void }) {
  return (
    <div className="side-head">
      {closed ? (
        <button className="side-logo wide-only" onClick={onToggle} aria-label="Open sidebar" title="Open sidebar">
          <span className="logo-mark" aria-hidden />
          <Icon name="sidebar" />
        </button>
      ) : null}
      <Link href={home} className={`side-logo ${closed ? 'rail-only' : ''}`} aria-label="FarmTap home" title="Home">
        <span className="logo-mark" aria-hidden />
        <strong className="brand-text">FarmTap</strong>
      </Link>
      {!closed && (
        <button className="icon-btn side-toggle" onClick={onToggle} aria-label="Close sidebar" title="Close sidebar (Ctrl+B)">
          <Icon name="sidebar" />
        </button>
      )}
    </div>
  );
}
