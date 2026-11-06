'use client';

// AI Alerts Centre (decision 0025): new, seen and resolved alerts. Seen
// stays on the list; resolved is hidden until the situation changes (a new
// day, month or batch makes a new alert).

import { useMemo, useState } from 'react';
import { FindingList, ModuleHead } from '@/components/ai';
import { AiGate, useAiPage } from '@/components/aiPage';
import { Empty, Tabs } from '@/components/ui';
import { allFindings } from '@/shared/aiRisk';
import { farmAiOn } from '@/lib/ai';

type Tab = 'new' | 'seen' | 'resolved';

export default function AlertsCentre() {
  const page = useAiPage('alerts');
  const { farm, cfg, ai, findings } = page;
  const [tab, setTab] = useState<Tab>('new');
  // Resolved ones: the same findings worked out without hiding resolved alerts.
  const resolved = useMemo(() => {
    if (ai.loading) return [];
    const ids = new Set([...ai.states.entries()].filter(([, s]) => s.status === 'resolved').map(([id]) => id));
    return allFindings(ai.data, { role: farm.role, cfg: cfg.ai, farmAiOn: farmAiOn(farm, cfg) })
      .filter((f) => ids.has(f.id))
      .map((f) => ({ ...f, state: 'acknowledged' as const }));
  }, [ai, farm, cfg]);
  const fresh = findings.filter((f) => f.state === 'new');
  const seen = findings.filter((f) => f.state === 'acknowledged');
  return (
    <>
      <ModuleHead module="alerts" title="AI Alerts Centre" subtitle="Mark an alert as seen to keep it on the list, or resolved when it is dealt with" />
      <AiGate page={page}>
        <Tabs
          label="Alerts"
          value={tab}
          onChange={setTab}
          items={[
            ['new', 'New', fresh.length],
            ['seen', 'Seen', seen.length],
            ['resolved', 'Resolved', resolved.length],
          ]}
        />
        {tab === 'new' && <FindingList fs={fresh} empty="No new alerts." />}
        {tab === 'seen' && <FindingList fs={seen} empty="No alerts marked as seen." />}
        {tab === 'resolved' &&
          (resolved.length ? (
            <FindingList fs={resolved} empty="" actions={false} />
          ) : (
            <Empty icon="check">Nothing resolved that still applies. Alerts you resolved for problems that have gone are not listed.</Empty>
          ))}
      </AiGate>
    </>
  );
}
