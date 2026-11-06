'use client';

// Inventory Intelligence (decision 0025): feed and drug stock, run-out
// dates from actual use, and what to reorder.

import { useMemo } from 'react';
import { AiTable, MethodBadge, ModuleHead } from '@/components/ai';
import { AiGate, ModuleFindings, useAiPage } from '@/components/aiPage';
import { CardHead, Empty } from '@/components/ui';
import { fmtDay } from '@/shared/aiCore';
import { drugViews, feedViews } from '@/shared/aiStock';

export default function InventoryIntelligence() {
  const page = useAiPage('inventory', ['herd', 'stock', 'states']);
  const d = page.ai.data;
  const feeds = useMemo(() => feedViews(d), [d]);
  const drugs = useMemo(() => drugViews(d), [d]);
  const reorder = [
    ...feeds.filter((f) => (f.daysLeft != null && f.daysLeft <= 14) || (f.lowAt != null && f.left <= f.lowAt)).map((f) => [f.name, 'Feed', `${f.left} ${f.unit}`, f.runsOut ? `Runs out about ${fmtDay(f.runsOut)}` : 'Below your level', `About ${Math.ceil(f.perDay * 14)} ${f.unit} for 2 weeks`]),
    ...drugs.filter((x) => x.stock != null && x.reorderAt != null && x.stock <= x.reorderAt).map((x) => [x.name, 'Drug', `${x.stock} ${x.unit}`.trim(), `Reorder level ${x.reorderAt}`, x.used30 ? `Used ${x.used30} times in 30 days` : 'Top up']),
  ];
  return (
    <>
      <ModuleHead module="inventory" title="Inventory Intelligence" subtitle="Stock of feed and drugs, from what you buy, count and use" />
      <AiGate page={page}>
        <ModuleFindings page={page} module={['inventory', 'feed']} empty="Nothing is running out." />
        <section className="card stack">
          <CardHead title="Reorder soon">
            <MethodBadge method="calculated" />
          </CardHead>
          {reorder.length ? <AiTable label="Reorder" columns={['Item', 'Kind', 'Left', 'Why', 'Suggestion']} rows={reorder} /> : <p className="small muted">Nothing needs reordering in the next 2 weeks.</p>}
        </section>
        <section className="card stack">
          <CardHead title="Drugs">
            <MethodBadge method="calculated" />
          </CardHead>
          {drugs.length ? (
            <AiTable
              label="Drugs"
              columns={['Drug', 'In stock', 'Reorder at', 'Used (30 days)']}
              right={[1, 2, 3]}
              rows={drugs.map((x) => [x.name, x.stock == null ? 'Not counted' : `${x.stock} ${x.unit}`.trim(), x.reorderAt ?? '—', x.used30])}
            />
          ) : (
            <Empty icon="health">No drugs in the store list yet. Add them in Health.</Empty>
          )}
        </section>
      </AiGate>
    </>
  );
}
