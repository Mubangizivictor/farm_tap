'use client';

// Farm Risk Detection (decision 0025): every finding, by how serious it is.

import { useEffect, useState } from 'react';
import { Fit } from '@/components/fit';
import { FindingList, ModuleHead } from '@/components/ai';
import { AiGate, useAiPage } from '@/components/aiPage';
import { aiModules, type Severity } from '@/shared/aiCore';
import { countBySeverity } from '@/shared/aiRisk';

const levels: Severity[] = ['critical', 'high', 'medium', 'low'];

export default function Risks() {
  const page = useAiPage('risks');
  const [level, setLevel] = useState<Severity | 'all'>('all');
  const [mod, setMod] = useState<string>('all');
  useEffect(() => {
    const l = new URL(window.location.href).searchParams.get('level');
    if (l && (levels as string[]).includes(l)) setLevel(l as Severity);
  }, []);
  const c = countBySeverity(page.findings);
  const shown = page.findings.filter((f) => (level === 'all' || f.severity === level) && (mod === 'all' || f.module === mod));
  const mods = aiModules.filter((m) => page.findings.some((f) => f.module === m.key));
  const tile = (l: Severity, label: string, tone?: 'bad' | 'warn') => (
    <button type="button" className={`card stat link ${c[l] && tone ? tone : ''}`} aria-pressed={level === l} onClick={() => setLevel(level === l ? 'all' : l)}>
      <span className="label">{label}</span>
      <span className="value">{c[l]}</span>
    </button>
  );
  return (
    <>
      <ModuleHead module="risks" title="Farm Risk Detection" subtitle="Everything FarmTap found in your records, most serious first. Tap a level to filter." />
      <AiGate page={page}>
        <Fit kind="stats">
          {tile('critical', 'Critical', 'bad')}
          {tile('high', 'High', 'bad')}
          {tile('medium', 'Medium', 'warn')}
          {tile('low', 'Low')}
        </Fit>
        {mods.length > 1 && (
          <div className="chips" role="group" aria-label="Area">
            <button type="button" className={`chip ${mod === 'all' ? 'brand' : ''}`} aria-pressed={mod === 'all'} onClick={() => setMod('all')}>
              All areas
            </button>
            {mods.map((m) => (
              <button key={m.key} type="button" className={`chip ${mod === m.key ? 'brand' : ''}`} aria-pressed={mod === m.key} onClick={() => setMod(m.key)}>
                {m.label}
              </button>
            ))}
          </div>
        )}
        <FindingList fs={shown} empty={level === 'all' ? 'No risks found in your records today.' : 'Nothing at this level.'} />
      </AiGate>
    </>
  );
}
