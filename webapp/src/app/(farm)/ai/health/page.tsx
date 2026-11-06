'use client';

// Animal Health Monitoring (decision 0025): repeat illness, vaccinations,
// treatment follow-ups, withdrawal and milk drops, per animal.

import Link from 'next/link';
import { useMemo } from 'react';
import { Fit } from '@/components/fit';
import { Icon } from '@/components/Icon';
import { AiTable, MethodBadge, ModuleHead } from '@/components/ai';
import { AiGate, ModuleFindings, useAiPage } from '@/components/aiPage';
import { CardHead, Empty, Stat } from '@/components/ui';
import { alive, fmtDay } from '@/shared/aiCore';
import { animalHref, isActive } from '@/shared/aiData';
import { animalHealth, vaccinesDue } from '@/shared/aiHerd';

export default function HealthMonitoring() {
  const page = useAiPage('health', ['herd', 'states']);
  const d = page.ai.data;
  const all = useMemo(() => alive(d.animals).filter(isActive).map((a) => animalHealth(d, a.id)), [d]);
  const attention = all.filter((h) => h.attention.length).sort((a, b) => b.attention.length - a.attention.length);
  const vd = useMemo(() => vaccinesDue(d), [d]);
  return (
    <>
      <ModuleHead module="health" title="Animal Health Monitoring" subtitle="Which animals need attention, and why">
        <Link className="btn" href="/ai/vet/">
          <Icon name="health" /> Check an animal
        </Link>
      </ModuleHead>
      <AiGate page={page}>
        <Fit kind="stats">
          <Stat icon="alert" label="Need attention" value={String(attention.length)} tone={attention.length ? 'warn' : undefined} />
          <Stat icon="shield" label="Vaccinations overdue" value={String(vd.filter((v) => v.overdueDays > 0).length)} tone={vd.some((v) => v.overdueDays > 0) ? 'bad' : undefined} />
          <Stat icon="clock" label="In withdrawal" value={String(all.filter((h) => h.inWithdrawal).length)} hint="Milk must not be sold" />
          <Stat icon="health" label="Treated in 90 days" value={String(all.filter((h) => h.treatments90 > 0).length)} />
        </Fit>
        <ModuleFindings page={page} module="health" empty="No health alerts today." />
        <section className="card stack">
          <CardHead title="Animals needing attention">
            <MethodBadge method="calculated" />
          </CardHead>
          {attention.length ? (
            <AiTable
              label="Animals needing attention"
              columns={['Animal', 'Why', 'Treated (90 days)', 'Safe for milk from', '']}
              rows={attention.map((h) => [
                <Link key="n" href={animalHref(h.animalId)}>
                  {h.name}
                </Link>,
                h.attention.join('; '),
                h.treatments90,
                h.safeFrom ? fmtDay(h.safeFrom) : '—',
                <Link key="v" className="btn sm outline" href={`/ai/vet/?animal=${encodeURIComponent(h.animalId)}`}>
                  Check signs
                </Link>,
              ])}
            />
          ) : (
            <Empty icon="health">No animal stands out. Repeat treatments, milk drops, overdue vaccines and calvings are all checked.</Empty>
          )}
        </section>
      </AiGate>
    </>
  );
}
