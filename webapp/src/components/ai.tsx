'use client';

// Building blocks of the AI Intelligence pages (decision 0025): how an
// answer was made, how serious a finding is, finding cards with
// acknowledge / resolve, and the states every page handles.

import Link from 'next/link';
import { useEffect, useState, type ReactNode } from 'react';
import { Icon, type IconName } from '@/components/Icon';
import { Empty, LoadError, SkelCard, useToast } from '@/components/ui';
import { methodLabel, type AiModule, type Method, type Severity } from '@/shared/aiCore';
import { severityLabel, type FindingWithState } from '@/shared/aiRisk';
import { cacheInsights, cachedInsights, setAlertState, type AiFarm } from '@/lib/ai';
import { useFarm, useSession } from '@/lib/session';

export const moduleIcon: Record<AiModule, IconName> = {
  assistant: 'chat',
  vet: 'health',
  screening: 'camera',
  milk: 'drop',
  quality: 'thermo',
  predictions: 'trend',
  feed: 'feed',
  breeding: 'cow',
  health: 'shield',
  finance: 'money',
  inventory: 'list',
  reports: 'chart',
  risks: 'alert',
  recommendations: 'spark',
  alerts: 'flag',
};

export const moduleHref: Record<AiModule, string> = {
  assistant: '/ai/assistant/',
  vet: '/ai/vet/',
  screening: '/ai/screening/',
  milk: '/ai/milk/',
  quality: '/ai/quality/',
  predictions: '/ai/predictions/',
  feed: '/ai/feed/',
  breeding: '/ai/breeding/',
  health: '/ai/health/',
  finance: '/ai/finance/',
  inventory: '/ai/inventory/',
  reports: '/ai/reports/',
  risks: '/ai/risks/',
  recommendations: '/ai/tools/',
  alerts: '/ai/alerts/',
};

const methodIcon: Record<Method, IconName> = { calculated: 'check', statistical: 'trend', rules: 'list', model: 'spark', experimental: 'flag' };

/** How an answer was made. Shown on every AI card, so a sum is never called AI. */
export function MethodBadge({ method, detail }: { method: Method; detail?: string }) {
  return (
    <span className={`chip ${method === 'experimental' ? 'warn' : method === 'model' ? 'gold' : ''}`} title={detail ?? methodLabel[method]}>
      <Icon name={methodIcon[method]} />
      {methodLabel[method]}
    </span>
  );
}

const sevTone: Record<Severity, string> = { critical: 'bad', high: 'bad', medium: 'warn', low: 'brand' };
const sevIcon: Record<Severity, IconName> = { critical: 'alert', high: 'alert', medium: 'flag', low: 'check' };

export function SeverityChip({ severity }: { severity: Severity }) {
  return (
    <span className={`chip ${sevTone[severity]}`}>
      <Icon name={sevIcon[severity]} />
      {severityLabel[severity]}
    </span>
  );
}

/** One finding: what, why, what to do, where to look, and (optionally) acknowledge / resolve. */
export function FindingCard({ f, actions = true, compact = false }: { f: FindingWithState; actions?: boolean; compact?: boolean }) {
  const farm = useFarm();
  const { user, canSave } = useSession();
  const toast = useToast();
  const [busy, setBusy] = useState(false);
  const mark = async (status: 'acknowledged' | 'resolved') => {
    setBusy(true);
    try {
      await setAlertState(farm.id, f.id, status, user?.displayName || user?.email || '');
      toast(status === 'resolved' ? 'Marked as resolved' : 'Marked as seen');
    } catch {
      toast('Could not save. Check the internet and try again.');
    } finally {
      setBusy(false);
    }
  };
  return (
    <article className={`card ai-finding sev-${f.severity} ${f.state === 'acknowledged' ? 'seen' : ''}`}>
      <div className="row between wrap">
        <div className="chips">
          <SeverityChip severity={f.severity} />
          {f.state === 'acknowledged' && (
            <span className="chip">
              <Icon name="eye" /> Seen
            </span>
          )}
        </div>
        {!compact && <MethodBadge method={f.method} />}
      </div>
      <h3>{f.title}</h3>
      <p className="small">
        <strong>Why: </strong>
        {f.why}
      </p>
      <p className="small">
        <strong>Do: </strong>
        {f.action}
      </p>
      <div className="row wrap">
        {f.links.map((l) => (
          <Link key={l.href + l.label} className="btn sm outline" href={l.href}>
            {l.label} <Icon name="chevron" />
          </Link>
        ))}
        {actions && (
          <span className="row wrap ai-actions">
            {f.state === 'new' && (
              <button className="btn sm ghost" disabled={busy || !canSave} onClick={() => void mark('acknowledged')} title="Keep it on the list, marked as seen">
                <Icon name="eye" /> Mark seen
              </button>
            )}
            <button className="btn sm ghost" disabled={busy || !canSave} onClick={() => void mark('resolved')} title="Hide it until the situation changes">
              <Icon name="check" /> Resolved
            </button>
          </span>
        )}
      </div>
    </article>
  );
}

export function FindingList({ fs, empty, actions = true, limit }: { fs: FindingWithState[]; empty: ReactNode; actions?: boolean; limit?: number }) {
  if (!fs.length) return <Empty icon="check">{empty}</Empty>;
  return (
    <div className="stack">
      {(limit ? fs.slice(0, limit) : fs).map((f) => (
        <FindingCard key={f.id} f={f} actions={actions} />
      ))}
    </div>
  );
}

/** Loading, error and the farm-turned-off states in one place. */
export function AiState({ ai, children, skeleton = 3 }: { ai: Pick<AiFarm, 'loading' | 'error'>; children: ReactNode; skeleton?: number }) {
  if (ai.error) return <LoadError code={ai.error} />;
  if (ai.loading)
    return (
      <div className="stack" aria-busy="true" aria-label="Working it out from your records">
        {Array.from({ length: skeleton }, (_, i) => (
          <SkelCard key={i} lines={3} />
        ))}
      </div>
    );
  return <>{children}</>;
}

export function AiOff({ reason }: { reason: string }) {
  return (
    <Empty icon="lock" action={<Link className="btn outline" href="/home/">Go home</Link>}>
      <strong>Not available</strong>
      <p className="muted">{reason}</p>
    </Empty>
  );
}

/** "Today's AI farm insights", with the last copy kept for when the internet drops. */
export function InsightsPanel({ fs, loading, n, title = "Today's AI farm insights" }: { fs: FindingWithState[]; loading: boolean; n: number; title?: string }) {
  const farm = useFarm();
  const { online } = useSession();
  const [cached, setCached] = useState<{ at: Date; fs: FindingWithState[] } | null>(null);
  useEffect(() => {
    if (!loading && online) cacheInsights(farm.id, fs);
    if (!online) setCached(cachedInsights(farm.id));
  }, [fs, loading, online, farm.id]);
  const show = !online && cached ? cached.fs : fs;
  return (
    <section className="card stack ai-insights" aria-label={title}>
      <div className="card-head">
        <h2>
          <Icon name="spark" /> {title}
        </h2>
        <Link className="btn sm ghost" href="/ai/alerts/">
          All alerts <Icon name="chevron" />
        </Link>
      </div>
      {!online && cached && (
        <div className="banner warn small" role="status">
          <Icon name="offline" />
          <span className="grow">Offline: showing insights saved {cached.at.toLocaleString('en-GB', { weekday: 'short', hour: 'numeric', minute: '2-digit' })}. They may be out of date.</span>
        </div>
      )}
      {loading && online ? (
        <SkelCard lines={4} />
      ) : show.length ? (
        <ul className="ai-insight-list">
          {show.slice(0, n).map((f) => (
            <li key={f.id}>
              <SeverityChip severity={f.severity} />
              <span className="grow">
                <strong>{f.title}</strong>
                <span className="small muted"> {f.action}</span>
              </span>
              {f.links[0] && (
                <Link className="icon-btn" href={f.links[0].href} aria-label={`Open ${f.links[0].label}`} title={`Open ${f.links[0].label}`}>
                  <Icon name="chevron" />
                </Link>
              )}
            </li>
          ))}
        </ul>
      ) : (
        <p className="muted small">Nothing needs attention in your records today. FarmTap checks milk, health, breeding, feed{fs.some((f) => f.module === 'finance') ? ' and money' : ''} every time you open it.</p>
      )}
    </section>
  );
}

/** Simple bars for a forecast: recorded days solid, predicted days outlined with their likely range. */
export function ForecastBars({ past, next, label }: { past: { day: string; litres: number; recorded: boolean }[]; next: { day: string; litres: number; low: number; high: number }[]; label: string }) {
  const max = Math.max(1, ...past.map((p) => p.litres), ...next.map((n) => n.high));
  return (
    <div className="stack chart-box">
      <div className="bars ai-bars" role="img" aria-label={label}>
        {past.map((p) => (
          <div className="bar-col" key={p.day} title={`${p.day}: ${p.recorded ? `${p.litres} L` : 'not recorded'}`}>
            <div className={`bar ${p.recorded ? '' : 'zero'}`} style={{ height: `${(p.litres / max) * 100}%` }} />
            <span className="bar-label">{+p.day.slice(8, 10)}</span>
          </div>
        ))}
        {next.map((n) => (
          <div className="bar-col" key={n.day} title={`${n.day}: about ${n.litres} L (likely ${n.low} to ${n.high})`}>
            <div className="bar ai-range" style={{ height: `${(n.high / max) * 100}%` }}>
              <div className="bar predicted" style={{ height: `${n.high ? (n.litres / n.high) * 100 : 0}%` }} />
            </div>
            <span className="bar-label">{+n.day.slice(8, 10)}</span>
          </div>
        ))}
      </div>
      <div className="row wrap small muted">
        <span className="legend-dot" /> Recorded
        <span className="legend-dot predicted" /> Predicted
        <span className="legend-dot range" /> Likely range
      </div>
    </div>
  );
}

export function ModuleHead({ module, title, subtitle, children }: { module: AiModule; title: string; subtitle: string; children?: ReactNode }) {
  return (
    <div className="page-head">
      <div className="stack head-text">
        <Link className="small muted no-print" href="/ai/tools/">
          Insights and tools
        </Link>
        <h1 className="row ai-title">
          <span className="icon-chip ai-chip" aria-hidden>
            <Icon name={moduleIcon[module]} />
          </span>
          {title}
        </h1>
        <p className="muted">{subtitle}</p>
      </div>
      {children && <div className="head-actions no-print">{children}</div>}
    </div>
  );
}

/** A table that becomes cards on phones (the app's .rt tables); the first column leads. */
export function AiTable({ columns, rows, label, right = [] }: { columns: string[]; rows: ReactNode[][]; label: string; right?: number[] }) {
  return (
    <div className="table-wrap">
      <table className="table rt" aria-label={label}>
        <thead>
          <tr>
            {columns.map((c, i) => (
              <th key={c} className={right.includes(i) ? 'r' : undefined}>
                {c}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {rows.map((r, i) => (
            <tr key={i}>
              {r.map((cell, j) => (
                <td key={j} data-label={columns[j]} className={j === 0 ? 'lead' : right.includes(j) ? 'r' : undefined}>
                  {cell}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
