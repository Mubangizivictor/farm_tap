'use client';

// What every AI page needs: the farm, the platform switches, the farm's
// records for the engine, and whether this person may see this module.

import { useMemo, type ReactNode } from 'react';
import type { AiModule } from '@/shared/aiCore';
import type { FindingWithState } from '@/shared/aiRisk';
import Link from 'next/link';
import { Icon } from '@/components/Icon';
import { AiOff, AiState, FindingList, InsightsPanel, MethodBadge, moduleHref, SeverityChip } from '@/components/ai';
import { fmtDay, fmtL } from '@/shared/aiCore';
import { animalHealth } from '@/shared/aiHerd';
import { cowForecast, herdForecast } from '@/shared/aiMilk';
import { SkelCard } from '@/components/ui';
import { farmAiOn, useAiFarm, useFindings, visibleModules, type AiFarm, type Need } from '@/lib/ai';
import type { Farm } from '@/lib/domain';
import type { PlatformConfig } from '@/lib/platform';
import { useFarm } from '@/lib/session';
import { usePlatform } from '@/lib/usePlatform';

export interface AiPage {
  farm: Farm;
  cfg: PlatformConfig;
  ai: AiFarm;
  findings: FindingWithState[];
  allowed: boolean;
  modules: AiModule[];
}

export function useAiPage(module: AiModule, needs?: Need[]): AiPage {
  const farm = useFarm();
  const { config } = usePlatform();
  const ai = useAiFarm(farm, needs);
  const findings = useFindings(farm, config, ai);
  const modules = useMemo(() => visibleModules(farm, config), [farm, config]);
  return { farm, cfg: config, ai, findings, allowed: modules.includes(module), modules };
}

/** Wraps a module page: the "not available" screen, loading and errors. */
export function AiGate({ page, children }: { page: AiPage; children: ReactNode }) {
  if (!page.allowed)
    return (
      <AiOff
        reason={
          !farmAiOn(page.farm, page.cfg)
            ? 'AI Intelligence is switched off for this farm. Contact FarmTap support to turn it on.'
            : 'This part of AI Intelligence is not available to your role or has been switched off.'
        }
      />
    );
  return <AiState ai={page.ai}>{children}</AiState>;
}

export function ModuleFindings({ page, module, empty }: { page: AiPage; module: AiModule | AiModule[]; empty: string }) {
  const ms = Array.isArray(module) ? module : [module];
  return <FindingList fs={page.findings.filter((f) => ms.includes(f.module))} empty={empty} />;
}

/**
 * AI inside an existing page (Milk, Feeds, Health, Money, Breeding): the
 * top findings for that area and a link to the full AI page. Hidden when
 * the module is off for this person.
 */
export function AiStrip({ module, also = [], title, needs, extra }: { module: AiModule; also?: AiModule[]; title: string; needs?: Need[]; extra?: (p: AiPage) => ReactNode }) {
  const page = useAiPage(module, needs);
  if (!page.allowed) return null;
  const ms = [module, ...also];
  const fs = page.findings.filter((f) => ms.includes(f.module)).slice(0, 3);
  return (
    <section className="card stack ai-insights no-print" aria-label={`AI: ${title}`}>
      <div className="card-head">
        <h2>
          <Icon name="spark" /> {title}
        </h2>
        <Link className="btn sm ghost" href={moduleHref[module]}>
          More <Icon name="chevron" />
        </Link>
      </div>
      {page.ai.loading ? (
        <SkelCard lines={2} />
      ) : (
        <>
          {extra?.(page)}
          {fs.length ? (
            <ul className="ai-insight-list">
              {fs.map((f) => (
                <li key={f.id}>
                  <SeverityChip severity={f.severity} />
                  <span className="grow">
                    <strong>{f.title}</strong>
                    <span className="small muted"> {f.why}</span>
                  </span>
                  {f.links[0] && (
                    <Link className="icon-btn" href={f.links[0].href} aria-label={`Open ${f.links[0].label}`}>
                      <Icon name="chevron" />
                    </Link>
                  )}
                </li>
              ))}
            </ul>
          ) : (
            <p className="small muted">Nothing needs attention here today.</p>
          )}
        </>
      )}
    </section>
  );
}

// ---------------------------------------------------------------- Per page

export function MilkAi() {
  return (
    <AiStrip
      module="milk"
      also={['quality']}
      title="AI: milk"
      needs={['herd', 'money', 'quality', 'states']}
      extra={(p) => {
        const f = herdForecast(p.ai.data);
        return (
          <p className="small row wrap">
            <MethodBadge method="statistical" />
            {f.ok ? `Next 7 days: about ${fmtL(f.total7)} (${f.confidence} confidence).` : `No forecast yet: ${f.reason}`}
          </p>
        );
      }}
    />
  );
}
export const FeedAi = () => <AiStrip module="feed" also={['inventory']} title="AI: feed" needs={['herd', 'stock', 'money', 'states']} />;
export const HealthAi = () => <AiStrip module="health" title="AI: animal health" needs={['herd', 'stock', 'states']} />;
export const MoneyAi = () => <AiStrip module="finance" title="AI: money" needs={['herd', 'money', 'stock', 'states']} />;
export const BreedingAi = () => <AiStrip module="breeding" title="AI: breeding" needs={['herd', 'states']} />;

/** Home: "Today's AI farm insights". */
export function HomeAi() {
  const page = useAiPage('recommendations');
  if (!page.allowed) return null;
  return <InsightsPanel fs={page.findings} loading={page.ai.loading} n={page.cfg.ai.insightsCount} />;
}

/** Herd → animal: AI health summary, milk trend and forecast, breeding state. */
export function AnimalAi({ animalId }: { animalId: string }) {
  const page = useAiPage('health', ['herd', 'states']);
  if (!page.allowed) return null;
  if (page.ai.loading) return <SkelCard lines={3} />;
  const h = animalHealth(page.ai.data, animalId);
  const f = cowForecast(page.ai.data, animalId);
  const b = h.breeding;
  return (
    <section className="card flat stack ai-insights" aria-label="AI health analysis">
      <div className="card-head">
        <h3>
          <Icon name="spark" /> AI health analysis
        </h3>
        <MethodBadge method="calculated" />
      </div>
      {h.attention.length ? (
        <ul className="small">
          {h.attention.map((x) => (
            <li key={x}>{x}</li>
          ))}
        </ul>
      ) : (
        <p className="small muted">Nothing stands out in her records.</p>
      )}
      <p className="small">
        {h.milkChangePct != null ? `Milk this week: ${h.milkChangePct > 0 ? '+' : ''}${h.milkChangePct}% against the 2 weeks before. ` : ''}
        {f.ok ? `Expected about ${fmtL(f.total7 / 7)} a day next week (${f.confidence} confidence). ` : ''}
        {b.pregnant ? `In calf${b.confirmed ? ' (confirmed)' : ' (not yet checked)'}, due about ${fmtDay(b.due!)}. ` : b.nextHeat ? `Next heat about ${fmtDay(b.nextHeat)} (estimate). ` : ''}
        {h.inWithdrawal && h.safeFrom ? `Milk not for sale until ${fmtDay(h.safeFrom)}.` : ''}
      </p>
      <div className="row wrap">
        <Link className="btn sm outline" href={`/ai/vet/?animal=${encodeURIComponent(animalId)}`}>
          <Icon name="health" /> Check signs
        </Link>
        {page.modules.includes('screening') && (
          <Link className="btn sm ghost" href={`/ai/screening/?animal=${encodeURIComponent(animalId)}`}>
            <Icon name="camera" /> Photo for the vet
          </Link>
        )}
      </div>
    </section>
  );
}
