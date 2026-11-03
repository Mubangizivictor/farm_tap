'use client';

import { useCallback, useEffect, useState, type ReactNode } from 'react';
import { useAdmin } from '@/lib/adminSession';
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
