'use client';

// Production Predictions (decision 0025): a statistical forecast of the
// herd and of each cow, only when there are enough recorded days.

import Link from 'next/link';
import { useMemo } from 'react';
import { Fit } from '@/components/fit';
import { AiTable, ForecastBars, MethodBadge, ModuleHead } from '@/components/ai';
import { AiGate, useAiPage } from '@/components/aiPage';
import { CardHead, Empty, Stat } from '@/components/ui';
import { fmtDay, fmtL } from '@/shared/aiCore';
import { animalHref, animalMap, animalName, breedingState, cowDays, milkDays } from '@/shared/aiData';
import { cowForecast, herdForecast, MIN_FORECAST_DAYS } from '@/shared/aiMilk';

const confText = { low: 'Low', medium: 'Medium', high: 'High' } as const;

function stage(dim: number | null) {
  if (dim == null) return 'Not known';
  if (dim <= 60) return `Early (${dim} days): milk still rising to its peak`;
  if (dim <= 200) return `Mid (${dim} days): slow natural fall`;
  return `Late (${dim} days): milk falls; plan drying off`;
}

export default function Predictions() {
  const page = useAiPage('predictions', ['herd', 'states']);
  const d = page.ai.data;
  const f = useMemo(() => herdForecast(d), [d]);
  const past = useMemo(() => milkDays(d, 21).slice(0, -1), [d]);
  const cows = useMemo(() => {
    const animals = animalMap(d);
    return [...cowDays(d, 29).keys()].map((id) => ({ id, name: animalName(animals.get(id)), f: cowForecast(d, id), dim: breedingState(id, d.breeding ?? [], d.now.slice(0, 10)).daysInMilk }));
  }, [d]);
  return (
    <>
      <ModuleHead module="predictions" title="Production Predictions" subtitle="How much milk to expect, worked out from your own records" />
      <AiGate page={page}>
        {f.ok ? (
          <>
            <Fit kind="stats">
              <Stat icon="trend" label="Next 7 days" value={fmtL(f.total7)} hint={`About ${fmtL(f.total7 / 7)} a day`} />
              <Stat icon="calendar" label="Next 30 days" value={f.total30 != null ? fmtL(f.total30) : '—'} hint={f.total30 == null ? 'Needs 21 recorded days' : undefined} />
              <Stat icon="chart" label="Trend" value={f.trendPerDay === 0 ? 'Steady' : `${f.trendPerDay > 0 ? '+' : '−'}${fmtL(Math.abs(f.trendPerDay))}`} hint={f.trendPerDay === 0 ? undefined : 'a day, each day'} tone={f.trendPerDay < 0 ? 'warn' : undefined} />
              <Stat icon="check" label="Confidence" value={confText[f.confidence]} hint={`${f.daysUsed} recorded days used`} tone={f.confidence === 'low' ? 'warn' : undefined} />
            </Fit>
            <section className="card stack">
              <CardHead title="Recorded and expected milk">
                <MethodBadge method="statistical" detail={f.method} />
              </CardHead>
              <ForecastBars past={past} next={f.next7} label="Recorded milk for 20 days and the forecast for 7 days" />
              <AiTable
                label="Forecast"
                columns={['Day', 'Expected', 'Likely between']}
                right={[1, 2]}
                rows={f.next7.map((x) => [fmtDay(x.day), fmtL(x.litres), `${fmtL(x.low)} – ${fmtL(x.high)}`])}
              />
              <p className="small muted">
                {f.method}. Recent days count more. “Likely between” covers about 8 in 10 days. Sickness, a change of feed, rain or a cow calving or drying off can change milk
                quickly; the forecast only knows what is recorded.
              </p>
            </section>
          </>
        ) : (
          <Empty icon="trend">
            <strong>No forecast yet</strong>
            <p className="muted">{f.reason} FarmTap does not guess without enough records.</p>
          </Empty>
        )}
        <section className="card stack">
          <CardHead title="Each cow (next 7 days)">
            <MethodBadge method="statistical" />
          </CardHead>
          {cows.length ? (
            <AiTable
              label="Cow forecasts"
              columns={['Cow', 'Expected a day', 'Confidence', 'Lactation stage']}
              right={[1]}
              rows={cows.map((c) => [
                <Link key="n" href={animalHref(c.id)}>
                  {c.name}
                </Link>,
                c.f.ok ? fmtL(c.f.total7 / 7) : `Needs ${MIN_FORECAST_DAYS} days (has ${c.f.daysUsed})`,
                c.f.ok ? confText[c.f.confidence] : '—',
                stage(c.dim),
              ])}
            />
          ) : (
            <Empty icon="cow">Record milk per cow to get a forecast for each cow.</Empty>
          )}
        </section>
      </AiGate>
    </>
  );
}
