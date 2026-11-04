'use client';

import { Children, isValidElement, useCallback, useEffect, useRef, useState, type CSSProperties, type ReactNode } from 'react';
import { useAdmin } from '@/lib/adminSession';
import { fitPresets, rowSizes, type FitKind } from '@/lib/fit';
import type { Permission } from '@/lib/platform';
import { Icon } from './Icon';

/** Loads data once (and again on reload()). */
export function useLoad<T>(load: () => Promise<T>, deps: unknown[] = []) {
  const [data, setData] = useState<T | undefined>(undefined);
  const [error, setError] = useState<string | null>(null);
  const [n, setN] = useState(0);
  useEffect(() => {
    let live = true;
    setError(null);
    load()
      .then((d) => live && setData(d))
      .catch((e) => live && setError((e as { code?: string }).code ?? 'unknown'));
    return () => {
      live = false;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [n, ...deps]);
  const reload = useCallback(() => setN((x) => x + 1), []);
  return { data, error, reload };
}

export type Msg = { ok: boolean; text: string } | null;

export function adminError(e: unknown): string {
  const code = (e as { code?: string }).code;
  if (code === 'permission-denied') return 'Not allowed. Your admin role does not cover this, or the change was refused by the security rules.';
  if (code === 'unavailable') return 'No internet. Try again when you are back online.';
  return 'Could not save. Try again.';
}

/** Runs a change and reports the result. */
export function useAction() {
  const [busy, setBusy] = useState(false);
  const [msg, setMsg] = useState<Msg>(null);
  const run = useCallback(async (fn: () => Promise<unknown>, ok = 'Saved.') => {
    setBusy(true);
    setMsg(null);
    try {
      await fn();
      setMsg({ ok: true, text: ok });
      return true;
    } catch (e) {
      setMsg({ ok: false, text: adminError(e) });
      return false;
    } finally {
      setBusy(false);
    }
  }, []);
  return { busy, msg, setMsg, run };
}

export function MsgBanner({ msg }: { msg: Msg }) {
  if (!msg) return null;
  return (
    <div className={`banner ${msg.ok ? 'ok' : 'bad'}`} role="status">
      <Icon name={msg.ok ? 'check' : 'alert'} />
      <span className="grow">{msg.text}</span>
    </div>
  );
}

export function Toggle({ label, hint, checked, onChange, disabled }: { label: ReactNode; hint?: ReactNode; checked: boolean; onChange: (v: boolean) => void; disabled?: boolean }) {
  return (
    <label className="toggle">
      <span className="t-text">
        <strong>{label}</strong>
        {hint && <span className="small muted">{hint}</span>}
      </span>
      <input type="checkbox" role="switch" checked={checked} disabled={disabled} onChange={(e) => onChange(e.target.checked)} />
    </label>
  );
}

/** Default / On / Off for a plan or farm override of a feature. */
export function Tri({ value, onChange, disabled, inherited }: { value: boolean | undefined; onChange: (v: boolean | undefined) => void; disabled?: boolean; inherited: boolean }) {
  return (
    <div className="tri" role="group">
      <button type="button" disabled={disabled} aria-pressed={value === undefined} onClick={() => onChange(undefined)} title="Follow the plan or default">
        Default ({inherited ? 'on' : 'off'})
      </button>
      <button type="button" className="on" disabled={disabled} aria-pressed={value === true} onClick={() => onChange(true)}>
        On
      </button>
      <button type="button" className="off" disabled={disabled} aria-pressed={value === false} onClick={() => onChange(false)}>
        Off
      </button>
    </div>
  );
}

/** Shows children only with the permission, else a short note. */
export function Need({ perm, children }: { perm: Permission | Permission[]; children: ReactNode }) {
  const { can } = useAdmin();
  const ok = (Array.isArray(perm) ? perm : [perm]).some(can);
  if (!ok) return <div className="banner info">Your admin role does not include this area. Ask the owner if you need it.</div>;
  return <>{children}</>;
}

export function Confirm({
  title,
  children,
  confirm,
  danger,
  onConfirm,
  onClose,
  busy,
}: {
  title: string;
  children: ReactNode;
  confirm: string;
  danger?: boolean;
  onConfirm: () => void;
  onClose: () => void;
  busy?: boolean;
}) {
  useEffect(() => {
    const esc = (e: KeyboardEvent) => e.key === 'Escape' && onClose();
    window.addEventListener('keydown', esc);
    return () => window.removeEventListener('keydown', esc);
  }, [onClose]);
  return (
    <div className="scrim" onMouseDown={(e) => e.target === e.currentTarget && onClose()}>
      <div className="dialog" role="dialog" aria-modal="true" aria-label={title}>
        <h2>{title}</h2>
        {children}
        <div className="actions">
          <button className="btn outline" onClick={onClose}>
            Cancel
          </button>
          <button className={`btn ${danger ? 'danger' : ''}`} disabled={busy} onClick={onConfirm}>
            {busy ? 'Working…' : confirm}
          </button>
        </div>
      </div>
    </div>
  );
}

export const toDateInput = (d: Date | null) =>
  d ? `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}` : '';
export const fromDateInput = (s: string): Date | null => {
  if (!s) return null;
  const [y, m, d] = s.split('-').map(Number);
  return new Date(y, m - 1, d);
};

/**
 * Even grid: items share rows evenly for the space they have (see lib/fit).
 * One item is full width; 2 to 4 share a row; leftovers stretch, so no row
 * leaves an empty column. Columns follow the container's width, not the
 * screen's, so the same grid works in a page, a card or a dialog.
 */
export function Fit({ kind = 'cards', cols, children, className = '' }: { kind?: FitKind; cols?: readonly number[]; children: ReactNode; className?: string }) {
  const items = Children.toArray(children);
  const tiers = cols ?? fitPresets[kind];
  const sizes = tiers.map((c) => rowSizes(items.length, c));
  return (
    <div className="fit-c">
      <div className={`fit ${className}`}>
        {items.map((child, i) => {
          const style = Object.fromEntries(sizes.map((s, t) => [`--k${t}`, s[i]])) as CSSProperties;
          return (
            <div key={isValidElement(child) && child.key != null ? child.key : i} className="fit-i" style={style}>
              {child}
            </div>
          );
        })}
      </div>
    </div>
  );
}

/** Sticky jump links for a long page; the section in view is highlighted. */
export function JumpNav({ items }: { items: readonly (readonly [id: string, label: string])[] }) {
  const [active, setActive] = useState(items[0]?.[0] ?? '');
  const lock = useRef(0);
  useEffect(() => {
    // On scroll: the last section whose top has passed the sticky bars.
    // Read fresh each time, so sections that render late still count.
    let frame = 0;
    const pick = () => {
      frame = 0;
      if (Date.now() < lock.current) return;
      const line = window.innerHeight * 0.3;
      let current = items[0]?.[0] ?? '';
      let currentTop = -Infinity;
      for (const [id] of items) {
        const el = document.getElementById(id);
        const top = el?.getBoundingClientRect().top;
        // Sections side by side share a top: keep the first of them.
        if (top != null && top <= line && top > currentTop + 1) {
          current = id;
          currentTop = top;
        }
      }
      if (window.innerHeight + window.scrollY >= document.documentElement.scrollHeight - 2) current = items[items.length - 1]?.[0] ?? current;
      setActive(current);
    };
    const onScroll = () => (frame ||= requestAnimationFrame(pick));
    pick();
    window.addEventListener('scroll', onScroll, { passive: true });
    window.addEventListener('resize', onScroll);
    return () => {
      window.removeEventListener('scroll', onScroll);
      window.removeEventListener('resize', onScroll);
      if (frame) cancelAnimationFrame(frame);
    };
  }, [items]);
  return (
    <nav className="jump no-print" aria-label="On this page">
      {items.map(([id, label]) => (
        <a
          key={id}
          href={`#${id}`}
          aria-current={active === id ? 'true' : undefined}
          onClick={(e) => {
            e.preventDefault();
            setActive(id);
            lock.current = Date.now() + 1000;
            document.getElementById(id)?.scrollIntoView({ behavior: 'smooth', block: 'start' });
            history.replaceState(null, '', `#${id}`);
          }}
        >
          {label}
        </a>
      ))}
    </nav>
  );
}

/** A titled group of cards that JumpNav can jump to. */
export function Anchor({ id, title, hint, children }: { id: string; title: string; hint?: ReactNode; children: ReactNode }) {
  return (
    <section id={id} className="anchor stack">
      <div className="anchor-head">
        <h2>{title}</h2>
        {hint && <span className="small muted">{hint}</span>}
      </div>
      {children}
    </section>
  );
}
