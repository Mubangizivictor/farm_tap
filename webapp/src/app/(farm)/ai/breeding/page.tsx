'use client';

// Breeding Intelligence (decision 0025): every cow's breeding state, open
// cows, repeat breeders and calvings. Dates are estimates unless a vet check
// confirmed them, and the page says which.

import Link from 'next/link';
import { useMemo } from 'react';
import { Fit } from '@/components/fit';
import { AiTable, MethodBadge, ModuleHead } from '@/components/ai';
import { AiGate, ModuleFindings, useAiPage } from '@/components/aiPage';
import { CardHead, Empty, Stat } from '@/components/ui';
import { addDays, alive, fmtDay } from '@/shared/aiCore';
import { animalHref, animalName, breedingState, isActive } from '@/shared/aiData';
import { calvingInterval } from '@/shared/aiHerd';

export default function BreedingIntelligence() {
  const page = useAiPage('breeding', ['herd', 'states']);
  const d = page.ai.data;
  const day = d.now.slice(0, 10);
  const cows = useMemo(
    () =>
      alive(d.animals)
        .filter((a) => isActive(a) && a.body.sex !== 'male' && !['calf', 'bull'].includes(a.body.dairyStatus ?? ''))
        .map((a) => ({ a, b: breedingState(a.id, d.breeding ?? [], day) })),
    [d, day],
  );
  const ci = useMemo(() => calvingInterval(d), [d]);
  const inCalf = cows.filter((c) => c.b.pregnant);
  return (
    <>
      <ModuleHead module="breeding" title="Breeding Intelligence" subtitle="Heats, services, checks and calvings for every cow" />
      <AiGate page={page}>
        <Fit kind="stats">
          <Stat icon="cow" label="Cows and heifers" value={String(cows.length)} />
          <Stat icon="check" label="In calf (confirmed)" value={String(inCalf.filter((c) => c.b.confirmed).length)} hint={`${inCalf.filter((c) => !c.b.confirmed).length} served, not yet checked`} />
          <Stat icon="calendar" label="Calving in 30 days" value={String(inCalf.filter((c) => c.b.due && c.b.due <= addDays(day, 30)).length)} />
          <Stat icon="clock" label="Calving interval" value={ci.avgDays != null ? `${ci.avgDays} days` : '—'} hint={ci.avgDays != null ? 'Aim: about 365' : 'Needs 2 recorded intervals'} tone={ci.avgDays != null && ci.avgDays > 420 ? 'warn' : undefined} />
        </Fit>
        <ModuleFindings page={page} module="breeding" empty="No breeding reminders today." />
        <section className="card stack">
          <CardHead title="Every cow">
            <MethodBadge method="calculated" detail="Due date = service + 283 days; next heat = last sign + 21 days. Estimates, not vet findings." />
          </CardHead>
          {cows.length ? (
            <AiTable
              label="Breeding state"
              columns={['Cow', 'State', 'Served', 'Due (estimate)', 'Next heat (estimate)', 'Days since calving']}
              rows={cows.map(({ a, b }) => [
                <Link key="n" href={animalHref(a.id)}>
                  {animalName(a)}
                </Link>,
                b.pregnant ? (b.confirmed ? 'In calf, confirmed' : 'Served, not checked') : b.failedServices >= 3 ? `Open, ${b.failedServices} failed services` : 'Open',
                b.servedDay ? fmtDay(b.servedDay) : '—',
                b.due ? fmtDay(b.due) : '—',
                b.nextHeat ? fmtDay(b.nextHeat) : '—',
                b.daysInMilk ?? '—',
              ])}
            />
          ) : (
            <Empty icon="cow">No cows or heifers in the herd yet.</Empty>
          )}
        </section>
      </AiGate>
    </>
  );
}

