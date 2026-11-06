'use client';

// AI Intelligence hub (decision 0025): today's insights, the risk count and
// every AI module this person may use.

import Link from 'next/link';
import { Fit } from '@/components/fit';
import { Icon } from '@/components/Icon';
import { InsightsPanel, moduleHref, moduleIcon } from '@/components/ai';
import { AiOff, AiState } from '@/components/ai';
import { useAiPage } from '@/components/aiPage';
import { PageHead, Stat } from '@/components/ui';
import { aiModules } from '@/shared/aiCore';
import { countBySeverity } from '@/shared/aiRisk';
import { farmAiOn } from '@/lib/ai';

export default function AiHub() {
  const page = useAiPage('recommendations');
  const { farm, cfg, ai, findings, modules } = page;
  if (!farmAiOn(farm, cfg)) return <AiOff reason="AI Intelligence is switched off for this farm. Contact FarmTap support to turn it on." />;
  const counts = countBySeverity(findings);
  const perModule = (k: string) => findings.filter((f) => f.module === k).length;
  return (
    <>
      <PageHead title="AI Intelligence" subtitle="What your records say today, what to do first, and what may happen next">
        {modules.includes('assistant') && (
          <Link className="btn" href="/ai/assistant/">
            <Icon name="chat" /> Ask FarmTap
          </Link>
        )}
      </PageHead>
      <AiState ai={ai} skeleton={2}>
        {modules.includes('recommendations') && <InsightsPanel fs={findings} loading={ai.loading} n={cfg.ai.insightsCount} />}
        {modules.includes('risks') && (
          <Fit kind="stats">
            <Stat icon="alert" label="Critical" value={String(counts.critical)} tone={counts.critical ? 'bad' : undefined} href="/ai/risks/?level=critical" />
            <Stat icon="alert" label="High" value={String(counts.high)} tone={counts.high ? 'bad' : undefined} href="/ai/risks/?level=high" />
            <Stat icon="flag" label="Medium" value={String(counts.medium)} tone={counts.medium ? 'warn' : undefined} href="/ai/risks/?level=medium" />
            <Stat icon="check" label="Low" value={String(counts.low)} href="/ai/risks/?level=low" />
          </Fit>
        )}
      </AiState>
      <Fit kind="cards">
        {aiModules
          .filter((m) => modules.includes(m.key) && m.key !== 'recommendations')
          .map((m) => (
            <Link key={m.key} className="card ai-tile" href={moduleHref[m.key]}>
              <span className="icon-chip" aria-hidden>
                <Icon name={moduleIcon[m.key]} />
              </span>
              <span className="stack" style={{ gap: 'var(--s-xxs)' }}>
                <strong>{m.label}</strong>
                <span className="small muted">{m.hint}</span>
              </span>
              {perModule(m.key) > 0 && <span className="chip warn count">{perModule(m.key)}</span>}
              {m.key === 'screening' && <span className="chip warn count">Experimental</span>}
            </Link>
          ))}
      </Fit>
      <section className="card stack small">
        <h2>How FarmTap AI works</h2>
        <p>
          <strong>Free and private.</strong> Everything here is worked out from your own farm records, in your browser. FarmTap AI does not send your records to any AI company and
          does not charge per question.
        </p>
        <p>
          Every card says how its answer was made: <strong>Calculated</strong> (sums of your records), <strong>Statistical estimate</strong> (a trend or an unusual day,
          with how sure it is), <strong>Rule-based guide</strong> (the vet guide) or <strong>Experimental</strong>. Nothing is a vet diagnosis. When the records are too few,
          FarmTap says so instead of guessing.
        </p>
      </section>
    </>
  );
}
