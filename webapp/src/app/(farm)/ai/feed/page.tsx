'use client';

// Feed Intelligence (decision 0025): feed left, run-out dates, unusual
// feeding days and feed cost against milk. No feed formulas are invented:
// rations need a nutritionist or extension officer with your own feeds.

import { useMemo } from 'react';
import { Fit } from '@/components/fit';
import { Icon } from '@/components/Icon';
import { AiTable, MethodBadge, ModuleHead } from '@/components/ai';
import { AiGate, ModuleFindings, useAiPage } from '@/components/aiPage';
import { CardHead, Empty, Stat } from '@/components/ui';
import { fmtDay, fmtL, fmtUgx } from '@/shared/aiCore';
import { seesMoney } from '@/shared/aiAccess';
import { feedEconomics, feedViews } from '@/shared/aiStock';

export default function FeedIntelligence() {
  const page = useAiPage('feed', ['herd', 'stock', 'money', 'states']);
  const d = page.ai.data;
  const feeds = useMemo(() => feedViews(d), [d]);
  const e = useMemo(() => feedEconomics(d), [d]);
  const money = seesMoney(page.farm.role);
  return (
    <>
      <ModuleHead module="feed" title="Feed Intelligence" subtitle="What is in the store, when it runs out, and what feed costs for each litre" />
      <AiGate page={page}>
        {money && (
          <Fit kind="stats">
            <Stat icon="money" label="Feed spend (30 days)" value={fmtUgx(e.feedSpend30)} />
            <Stat icon="drop" label="Feed cost a litre" value={e.costPerLitre != null ? fmtUgx(e.costPerLitre) : '—'} hint={`${fmtL(e.litres30)} in 30 days`} />
            <Stat icon="cow" label="Feed cost per animal a day" value={e.costPerAnimalDay != null ? fmtUgx(e.costPerAnimalDay) : '—'} hint={`${e.animals} animals`} />
            <Stat icon="trend" label="Milk for UGX 1,000 of feed" value={e.litresPer1000 != null ? fmtL(e.litresPer1000) : '—'} />
          </Fit>
        )}
        <ModuleFindings page={page} module={['feed']} empty="No feed is running low and no feeding day looks unusual." />
        <section className="card stack">
          <CardHead title="Feed in store">
            <MethodBadge method="calculated" />
          </CardHead>
          {feeds.length ? (
            <AiTable
              label="Feeds"
              columns={['Feed', 'Left', 'Used a day (14 days)', 'Lasts', 'Runs out']}
              right={[1, 2, 3]}
              rows={feeds.map((f) => [
                f.name,
                `${f.left} ${f.unit}${f.hasCount ? '' : ' *'}`,
                `${f.perDay} ${f.unit}`,
                f.daysLeft != null ? `${f.daysLeft} days` : 'Not used lately',
                f.runsOut ? fmtDay(f.runsOut) : '—',
              ])}
            />
          ) : (
            <Empty icon="feed">Record feed purchases and feedings to see what is left and when it runs out.</Empty>
          )}
          {feeds.some((f) => !f.hasCount) && <p className="small muted">* No stock count yet: worked out from purchases and feedings only. Count the store to make it exact.</p>}
        </section>
        <section className="card stack small">
          <h2>
            <Icon name="feed" /> About rations
          </h2>
          <p>
            FarmTap compares feed with milk from your records, but it does not write feed formulas: a good ration depends on your own feeds, their quality and each cow’s
            weight and milk. Ask your extension officer or a nutritionist, and record what you feed so FarmTap can show whether milk follows.
          </p>
        </section>
      </AiGate>
    </>
  );
}
