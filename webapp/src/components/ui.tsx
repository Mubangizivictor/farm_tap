'use client';

import { useEffect, type ReactNode } from 'react';
import { Icon, type IconName } from './Icon';

export function Stat({
  icon,
  label,
  value,
  unit,
  hint,
  tone,
}: {
  icon: IconName;
  label: string;
  value: ReactNode;
  unit?: string;
  hint?: ReactNode;
  tone?: 'warn' | 'bad' | 'info' | 'gold';
}) {
  return (
    <div className={`card stat ${tone ?? ''}`}>
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
    </div>
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

export function PageHead({
  title,
  subtitle,
  children,
}: {
  title: string;
  subtitle?: ReactNode;
  children?: ReactNode;
}) {
  return (
    <div className="page-head">
      <div className="stack" style={{ gap: 'var(--s-xxs)' }}>
        <h1>{title}</h1>
        {subtitle && <p className="muted">{subtitle}</p>}
      </div>
      {children && <div className="row wrap no-print">{children}</div>}
    </div>
  );
}

export function SearchBox({ value, onChange, placeholder = 'Search' }: { value: string; onChange: (v: string) => void; placeholder?: string }) {
  return (
    <label className="row search">
      <span className="sr-only">{placeholder}</span>
      <input className="input" type="search" placeholder={placeholder} value={value} onChange={(e) => onChange(e.target.value)} />
    </label>
  );
}

export function ExportButtons({ onCsv }: { onCsv?: () => void }) {
  return (
    <>
      {onCsv && (
        <button className="btn outline sm" onClick={onCsv} title="Download for Excel">
          <Icon name="download" /> CSV
        </button>
      )}
      <button className="btn outline sm" onClick={() => window.print()} title="Print this page">
        <Icon name="print" /> Print
      </button>
    </>
  );
}

export function Dialog({ title, onClose, children }: { title: string; onClose: () => void; children: ReactNode }) {
  useEffect(() => {
    const esc = (e: KeyboardEvent) => e.key === 'Escape' && onClose();
    window.addEventListener('keydown', esc);
    return () => window.removeEventListener('keydown', esc);
  }, [onClose]);
  return (
    <div className="scrim" onMouseDown={(e) => e.target === e.currentTarget && onClose()}>
      <div className="dialog" role="dialog" aria-modal="true" aria-label={title}>
        <div className="row between">
          <h2>{title}</h2>
          <button className="icon-btn" aria-label="Close" onClick={onClose}>
            <Icon name="close" />
          </button>
        </div>
        {children}
      </div>
    </div>
  );
}

export function Empty({ children }: { children: ReactNode }) {
  return <div className="empty">{children}</div>;
}

export function LoadError({ code }: { code: string | null }) {
  if (!code) return null;
  return (
    <div className="banner bad">
      <Icon name="alert" />
      <span className="grow">
        {code === 'permission-denied' ? 'You do not have access to these records.' : 'Could not load. Check the internet and refresh.'}
      </span>
    </div>
  );
}

/** Save button that explains why it is off (offline or read-only). */
export function SaveHint({ canSave, online }: { canSave: boolean; online: boolean }) {
  if (canSave) return null;
  return <p className="small muted">{online ? 'Saving is off: the free trial or subscription has ended.' : 'Saving is off: no internet.'}</p>;
}
