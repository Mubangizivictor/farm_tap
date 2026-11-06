'use client';

// Milk Intelligence (decision 0025): the day, the week, cows dropping,
// unusual days and milk not accounted for, all from milk records.

import { useMemo } from 'react';
import { Fit } from '@/components/fit';
import { AiTable, MethodBadge, ModuleHead } from '@/components/ai';
import { AiGate, ModuleFindings, useAiPage } from '@/components/aiPage';
import { CardHead, Change, Empty, Stat } from '@/components/ui';
import { fmtDay, fmtL } from '@/shared/aiCore';
import { cowTrends, milkAnomalies, milkBalance, milkSummary } from '@/shared/aiMilk';
import { animalHref } from '@/shared/aiData';
import { ForecastBars } from '@/components/ai';
import Link from 'next/link';

export default function MilkIntelligence() {
  const page = useAiPage('milk', ['herd', 'money', 'quality', 'states']);
  const d = page.ai.data;
  const s = useMemo(() => milkSummary(d), [d]);
  const trends = useMemo(() => cowTrends(d), [d]);
  const odd = useMemo(() => milkAnomalies(d), [d]);
  const bal = useMemo(() => milkBalance(d), [d]);
  return (
    <>
      <ModuleHead module="milk" title="Milk Intelligence" subtitle="How milk is going, which cows are dropping and where milk goes" />
      <AiGate page={page}>
        <Fit kind="stats">
          <Stat icon="drop" label="Today" value={fmtL(s.today)} hint={s.todayRecorded ? 'So far today' : 'Nothing recorded yet'} />
          <Stat icon="drop" label="Yesterday" value={fmtL(s.yesterday)} />
          <Stat icon="chart" label="7-day average" value={s.avg7 != null ? fmtL(s.avg7) : '—'} hint={<Change pct={s.weekChangePct} />} />
          <Stat icon="calendar" label="This month" value={fmtL(s.monthToDate)} hint={s.lastMonthSameDays ? `Same days last month: ${fmtL(s.lastMonthSameDays)}` : undefined} />
        </Fit>
        <section className="card">
          <CardHead title="Last 30 days">
            <MethodBadge method="calculated" />
          </CardHead>
          {s.recordedDays30 ? <ForecastBars past={s.last30} next={[]} label="Milk per day for 30 days" /> : <Empty icon="drop">No milk recorded in the last 30 days.</Empty>}
        </section>
        <ModuleFindings page={page} module="milk" empty="No milk problems found in your records." />
        <section className="card stack">
          <CardHead title="Each cow: this week against the 2 weeks before">
            <MethodBadge method="calculated" />
          </CardHead>
          {trends.length ? (
            <AiTable
              label="Cow milk trends"
              columns={['Cow', 'This week (a day)', 'Before (a day)', 'Change', 'Days in milk']}
              right={[1, 2, 3, 4]}
              rows={trends.map((t) => [
                <Link key="n" href={animalHref(t.animalId)}>
                  {t.name}
                </Link>,
                fmtL(t.recent),
                fmtL(t.before),
                <Change key="c" pct={t.changePct} />,
                t.daysInMilk ?? '—',
              ])}
            />
          ) : (
            <Empty icon="cow">Record milk per cow (not only the herd total) on at least 3 days a week to see each cow’s trend.</Empty>
          )}
        </section>
        <Fit kind="cards" cols={[1, 2, 2, 2]}>
          <section className="card stack">
            <CardHead title="Unusual days (last 14)">
              <MethodBadge method="statistical" />
            </CardHead>
            {odd.length ? (
              <ul className="ai-insight-list">
                {odd.map((a) => (
                  <li key={a.day}>
                    <span className="grow">
                      <strong>{fmtDay(a.day)}</strong> {fmtL(a.litres)} <span className="small muted">usual {fmtL(a.usual)}</span>
                    </span>
                  </li>
                ))}
              </ul>
            ) : (
              <p className="small muted">No day stood out. Days are compared with the 30 recorded days before them; at least 10 are needed.</p>
            )}
          </section>
          <section className="card stack">
            <CardHead title="Where the milk went (last 7 days)">
              <MethodBadge method="calculated" />
            </CardHead>
            <AiTable
              label="Milk balance"
              columns={['', 'Litres']}
              right={[1]}
              rows={[
                ['Produced', fmtL(bal.produced)],
                ['Sold', fmtL(bal.sold)],
                ['For the home', fmtL(bal.homeUse)],
                ['Thrown away', fmtL(bal.discarded)],
                ['Not accounted for', bal.unaccounted == null ? 'Record sales to see' : fmtL(bal.unaccounted)],
              ]}
            />
          </section>
        </Fit>
      </AiGate>
    </>
  );
}
