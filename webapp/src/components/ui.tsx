'use client';

import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useRef,
  useState,
  type FormEvent,
  type ReactNode,
} from 'react';
import Link from 'next/link';
import { saveError } from '@/lib/data';
import { Icon, type IconName } from './Icon';

// ---------------------------------------------------------------- Loading

/** The FarmTap mark, gently turning: the app's loader everywhere. */
export function LogoLoader({ text, size = 'md' }: { text?: string; size?: 'sm' | 'md' | 'lg' }) {
  return (
    <div className={`logo-loader ${size}`} role="status" aria-live="polite">
      <div className="logo-mark spin-logo" aria-hidden />
      {text && <span className="muted small">{text}</span>}
      {!text && <span className="sr-only">Loading</span>}
    </div>
  );
}

/** A grey placeholder bar that shimmers while data loads. */
export function Skel({ w = '100%', h, r, className = '' }: { w?: string; h?: string; r?: string; className?: string }) {
  return <span className={`skel ${className}`} style={{ width: w, height: h, borderRadius: r }} aria-hidden />;
}

/** Placeholder for a stat tile, same size as the real one. */
export function SkelStat() {
  return (
    <div className="card stat" aria-hidden>
      <div className="row between">
        <Skel w="45%" />
        <Skel w="var(--z-avatar)" h="var(--z-avatar)" r="var(--r-sm)" />
      </div>
      <Skel w="55%" h="var(--z-skel-value)" />
      <Skel w="70%" />
    </div>
  );
}

/** Placeholder rows for a table or list while it loads. */
export function SkelRows({ rows = 5, cols = 4 }: { rows?: number; cols?: number }) {
  return (
    <div className="skel-rows" aria-hidden>
      {Array.from({ length: rows }, (_, i) => (
        <div key={i} className="skel-row">
          {Array.from({ length: cols }, (_, j) => (
            <Skel key={j} w={j === 0 ? '30%' : `${12 + ((i + j) % 3) * 6}%`} />
          ))}
        </div>
      ))}
      <span className="sr-only">Loading</span>
    </div>
  );
}

/** Placeholder for a card with a title and a few lines. */
export function SkelCard({ lines = 4 }: { lines?: number }) {
  return (
    <section className="card stack" aria-hidden>
      <Skel w="40%" h="var(--fs-title-lg)" />
      {Array.from({ length: lines }, (_, i) => (
        <Skel key={i} w={`${90 - i * 12}%`} />
      ))}
    </section>
  );
}

// ---------------------------------------------------------------- Tiles

export function Stat({
  icon,
  label,
  value,
  unit,
  hint,
  tone,
  href,
  loading,
}: {
  icon: IconName;
  label: string;
  value: ReactNode;
  unit?: string;
  hint?: ReactNode;
  tone?: 'warn' | 'bad' | 'info' | 'gold';
  href?: string;
  loading?: boolean;
}) {
  if (loading) return <SkelStat />;
  const inner = (
    <>
      <div className="row between">
        <span className="label">{label}</span>
        <div className="icon-chip">
          <Icon name={icon} />
        </div>
      </div>
      <div className={`value ${typeof value === 'string' && value.startsWith('UGX') ? 'money' : ''}`}>
        {value}
        {unit && <small>{unit}</small>}
      </div>
      {hint && <div className="hint">{hint}</div>}
    </>
  );
  return href ? (
    <Link className={`card stat link ${tone ?? ''}`} href={href}>
      {inner}
    </Link>
  ) : (
    <div className={`card stat ${tone ?? ''}`}>{inner}</div>
  );
}

export function Change({ pct, goodWhenUp = true }: { pct: number | null; goodWhenUp?: boolean }) {
  if (pct == null) return null;
  const good = goodWhenUp ? pct >= 0 : pct <= 0;
  return (
    <span className={good ? 'up' : 'down'}>
      {pct >= 0 ? '▲' : '▼'} {Math.abs(pct)}%
    </span>
  );
}

// ---------------------------------------------------------------- Page parts

export function PageHead({ title, subtitle, children }: { title: string; subtitle?: ReactNode; children?: ReactNode }) {
  return (
    <div className="page-head">
      <div className="stack head-text">
        <h1>{title}</h1>
        {subtitle && <p className="muted">{subtitle}</p>}
      </div>
      {children && <div className="head-actions no-print">{children}</div>}
    </div>
  );
}

export function SearchBox({ value, onChange, placeholder = 'Search' }: { value: string; onChange: (v: string) => void; placeholder?: string }) {
  return (
    <label className="search">
      <span className="sr-only">{placeholder}</span>
      <Icon name="search" />
      <input className="input" type="search" placeholder={placeholder} value={value} onChange={(e) => onChange(e.target.value)} />
    </label>
  );
}

/** Print the page (A4). Menus, buttons and the sidebar are left out of the print. */
export function PrintButton() {
  return (
    <button className="btn outline sm print-btn" onClick={() => window.print()} title="Print this page">
      <Icon name="print" /> <span className="btn-text">Print</span>
    </button>
  );
}

export function ExportButtons({ onCsv, print = true }: { onCsv?: () => void; print?: boolean }) {
  return (
    <>
      {onCsv && (
        <button className="btn outline sm" onClick={onCsv} title="Download for Excel">
          <Icon name="download" /> <span className="btn-text">CSV</span>
        </button>
      )}
      {print && (
        <button className="btn outline sm print-btn" onClick={() => window.print()} title="Print this page">
          <Icon name="print" /> <span className="btn-text">Print</span>
        </button>
      )}
    </>
  );
}

/** Tabs that switch what a page shows, with optional counts. */
export function Tabs<T extends string>({ value, onChange, items, label }: { value: T; onChange: (v: T) => void; items: readonly (readonly [T, string, number?])[]; label: string }) {
  return (
    <div className="tabs" role="tablist" aria-label={label}>
      {items.map(([v, text, n]) => (
        <button key={v} role="tab" type="button" aria-selected={value === v} onClick={() => onChange(v)}>
          {text}
          {n != null && <span className="tab-count">{n}</span>}
        </button>
      ))}
    </div>
  );
}

/** Pick one of a few options (segmented control). */
export function Seg<T extends string>({ value, onChange, items, label, disabled }: { value: T; onChange: (v: T) => void; items: readonly (readonly [T, string])[]; label: string; disabled?: boolean }) {
  return (
    <div className="seg" role="group" aria-label={label}>
      {items.map(([v, text]) => (
        <button key={v} type="button" aria-pressed={value === v} onClick={() => onChange(v)} disabled={disabled}>
          {text}
        </button>
      ))}
    </div>
  );
}

// ---------------------------------------------------------------- States

export function Empty({ children, icon, action }: { children: ReactNode; icon?: IconName; action?: ReactNode }) {
  return (
    <div className="empty">
      {icon && (
        <span className="empty-icon">
          <Icon name={icon} />
        </span>
      )}
      <div>{children}</div>
      {action && <div className="no-print">{action}</div>}
    </div>
  );
}

export function LoadError({ code }: { code: string | null | undefined }) {
  if (!code) return null;
  return (
    <div className="banner bad" role="alert">
      <Icon name="alert" />
      <span className="grow">
        {code === 'permission-denied' ? 'You do not have access to these records.' : 'Could not load. Check the internet and refresh the page.'}
      </span>
      <button className="btn sm outline" onClick={() => window.location.reload()}>
        Refresh
      </button>
    </div>
  );
}

/** Why saving is off (offline or read-only). */
export function SaveHint({ canSave, online }: { canSave: boolean; online: boolean }) {
  if (canSave) return null;
  return (
    <div className="banner warn small">
      <Icon name={online ? 'lock' : 'offline'} />
      <span className="grow">{online ? 'Saving is off: the free trial or subscription has ended, or the farm is paused.' : 'Saving is off: no internet.'}</span>
    </div>
  );
}

// ---------------------------------------------------------------- Forms

export function Field({ label, hint, error, children, wide }: { label: string; hint?: ReactNode; error?: string | null; children: ReactNode; wide?: boolean }) {
  return (
    <label className={`field ${error ? 'has-error' : ''} ${wide ? 'wide' : ''}`}>
      <span>{label}</span>
      {children}
      {error ? <em className="error-text">{error}</em> : hint ? <small className="muted">{hint}</small> : null}
    </label>
  );
}

/** Busy flag and friendly error for one save. run() returns true when it worked. */
export function useSave() {
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const run = useCallback(async (fn: () => Promise<unknown>) => {
    setBusy(true);
    setError('');
    try {
      await fn();
      return true;
    } catch (e) {
      const code = (e as { code?: string }).code;
      setError(code ? saveError(code) : (e as Error).message || saveError(undefined));
      return false;
    } finally {
      setBusy(false);
    }
  }, []);
  return { busy, error, setError, run };
}

// ---------------------------------------------------------------- Dialogs

export function Dialog({
  title,
  subtitle,
  onClose,
  children,
  size = 'md',
}: {
  title: string;
  subtitle?: ReactNode;
  onClose: () => void;
  children: ReactNode;
  size?: 'md' | 'lg';
}) {
  const box = useRef<HTMLDivElement>(null);
  useEffect(() => {
    const esc = (e: KeyboardEvent) => e.key === 'Escape' && onClose();
    window.addEventListener('keydown', esc);
    const before = document.activeElement as HTMLElement | null;
    document.body.classList.add('no-scroll');
    // Focus the first field (or the dialog) so typing starts at once.
    const first = box.current?.querySelector<HTMLElement>('[autofocus], input:not([type=hidden]), select, textarea');
    (first ?? box.current)?.focus();
    return () => {
      window.removeEventListener('keydown', esc);
      document.body.classList.remove('no-scroll');
      before?.focus?.();
    };
  }, [onClose]);
  return (
    <div className="scrim" onMouseDown={(e) => e.target === e.currentTarget && onClose()}>
      <div ref={box} tabIndex={-1} className={`dialog ${size}`} role="dialog" aria-modal="true" aria-label={title}>
        <div className="dialog-head">
          <div className="stack grow head-text">
            <h2>{title}</h2>
            {subtitle && <p className="small muted">{subtitle}</p>}
          </div>
          <button className="icon-btn" aria-label="Close" onClick={onClose}>
            <Icon name="close" />
          </button>
        </div>
        {children}
      </div>
    </div>
  );
}

/** A dialog holding one form: fields, the error, why saving is off, and Cancel / Save. */
export function FormDialog({
  title,
  subtitle,
  onClose,
  onSubmit,
  busy,
  error,
  canSave,
  online,
  submit,
  children,
  size,
  danger,
  extra,
}: {
  title: string;
  subtitle?: ReactNode;
  onClose: () => void;
  onSubmit: () => void | Promise<void>;
  busy: boolean;
  error?: string;
  canSave: boolean;
  online: boolean;
  submit: string;
  children: ReactNode;
  size?: 'md' | 'lg';
  danger?: boolean;
  /** Left of Cancel, e.g. a Remove button. */
  extra?: ReactNode;
}) {
  return (
    <Dialog title={title} subtitle={subtitle} onClose={onClose} size={size}>
      <form
        className="stack dialog-form"
        noValidate={false}
        onSubmit={(e: FormEvent) => {
          e.preventDefault();
          if (!busy) void onSubmit();
        }}
      >
        <div className="dialog-body stack">{children}</div>
        {error && (
          <div className="banner bad small" role="alert">
            <Icon name="alert" />
            <span className="grow">{error}</span>
          </div>
        )}
        <SaveHint canSave={canSave} online={online} />
        <div className="actions">
          {extra && <div className="grow row">{extra}</div>}
          <button type="button" className="btn outline" onClick={onClose}>
            Cancel
          </button>
          <button type="submit" className={`btn ${danger ? 'danger' : ''}`} disabled={busy || !canSave}>
            {busy ? (
              <>
                <span className="spinner sm" aria-hidden /> Saving…
              </>
            ) : (
              submit
            )}
          </button>
        </div>
      </form>
    </Dialog>
  );
}

export function ConfirmDialog({
  title,
  children,
  confirm,
  danger,
  busy,
  error,
  onConfirm,
  onClose,
}: {
  title: string;
  children: ReactNode;
  confirm: string;
  danger?: boolean;
  busy?: boolean;
  error?: string;
  onConfirm: () => void;
  onClose: () => void;
}) {
  return (
    <Dialog title={title} onClose={onClose}>
      <div className="small">{children}</div>
      {error && <div className="banner bad small">{error}</div>}
      <div className="actions">
        <button type="button" className="btn outline" onClick={onClose}>
          Cancel
        </button>
        <button type="button" className={`btn ${danger ? 'danger' : ''}`} disabled={busy} onClick={onConfirm}>
          {busy ? 'Working…' : confirm}
        </button>
      </div>
    </Dialog>
  );
}

// ---------------------------------------------------------------- Toast

const ToastCtx = createContext<(text: string) => void>(() => undefined);

/** Short "Saved" messages at the bottom of the screen. */
export function ToastProvider({ children }: { children: ReactNode }) {
  const [items, setItems] = useState<{ id: number; text: string }[]>([]);
  const next = useRef(0);
  const show = useCallback((text: string) => {
    const id = ++next.current;
    setItems((x) => [...x.slice(-2), { id, text }]);
    setTimeout(() => setItems((x) => x.filter((t) => t.id !== id)), 3200);
  }, []);
  return (
    <ToastCtx.Provider value={show}>
      {children}
      <div className="toasts no-print" aria-live="polite">
        {items.map((t) => (
          <div key={t.id} className="toast" role="status">
            <Icon name="check" /> {t.text}
          </div>
        ))}
      </div>
    </ToastCtx.Provider>
  );
}

export const useToast = () => useContext(ToastCtx);

/** Small title + link header inside a card. */
export function CardHead({ title, children }: { title: string; children?: ReactNode }) {
  return (
    <div className="card-head">
      <h2>{title}</h2>
      {children}
    </div>
  );
}
