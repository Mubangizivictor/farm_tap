'use client';

// The AI allowance meter and the AI error card (decision 0028). Numbers come
// from the server (aiUsageNow, and every server answer); built-in answers
// never change them.

import { Icon } from '@/components/Icon';
import { aiErrorText, resetLabel, usageWarning, type AiErrorKind, type UsageView } from '@/shared/aiQuota';

export function AiUsageMeter({ view, trusted }: { view: UsageView; trusted: boolean }) {
  const pct = view.limit > 0 ? Math.round((view.used / view.limit) * 100) : 100;
  const warn = usageWarning(view);
  return (
    <section className="ai-usage" aria-label="AI assistant usage">
      <div className="ai-usage-head">
        <span className="ai-usage-title">AI assistant usage</span>
        <span className="small muted">Built-in farm answers: unlimited</span>
      </div>
      <div className={`ai-usage-bar ${view.level}`} role="progressbar" aria-valuemin={0} aria-valuemax={view.limit} aria-valuenow={view.used} aria-label={`${view.used} of ${view.limit} AI requests used`}>
        <span style={{ width: `${pct}%` }} />
      </div>
      <dl className="ai-usage-nums small">
        <div>
          <dt>AI requests used</dt>
          <dd>
            {view.used}/{view.limit}
          </dd>
        </div>
        <div>
          <dt>Remaining requests</dt>
          <dd>{view.remaining}</dd>
        </div>
        <div>
          <dt>Reset time</dt>
          <dd>{resetLabel()}</dd>
        </div>
      </dl>
      {!trusted && <p className="small muted">Counted on this farm’s devices while the secure server is being set up.</p>}
      {warn && (
        <div className={`banner small ${view.level === 'out' ? 'bad' : 'warn'}`} role="status">
          <Icon name={view.level === 'out' ? 'alert' : 'flag'} />
          <span className="grow">
            <strong>{warn.title}</strong> {warn.message}
          </span>
        </div>
      )}
    </section>
  );
}

/** A friendly card for a failed AI request. No technical details. */
export function AiErrorCard({ kind, limit }: { kind: AiErrorKind; limit: number }) {
  const e = aiErrorText(kind, limit);
  const tone = kind === 'limit' || kind === 'disabled' ? 'info' : 'warn';
  return (
    <div className={`banner small ai-error ${tone}`} role="alert">
      <Icon name={kind === 'network' ? 'alert' : 'flag'} />
      <span className="grow">
        <strong>{e.title}</strong>
        <br />
        {e.message}
      </span>
    </div>
  );
}
