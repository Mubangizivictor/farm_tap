'use client';

// AI Control Centre (decision 0025). Platform-wide AI switches, the engines
// and models, use and failures, and which farms have AI on. It reads the AI
// use log (feature, ok, time, method — never farm figures) and farm switches,
// never farm records. Every change goes through adminChange (audit log).

import { collectionGroup, doc, getDocs, limit, query, where } from 'firebase/firestore';
import Link from 'next/link';
import { useEffect, useMemo, useState } from 'react';
import { Fit } from '@/components/fit';
import { Icon } from '@/components/Icon';
import { AiTable } from '@/components/ai';
import { Anchor, JumpNav, MsgBanner, Need, Toggle, useAction, useLoad } from '@/components/admin';
import { PageHead, Stat } from '@/components/ui';
import { aiModules, methodLabel, type Method } from '@/shared/aiCore';
import { defaultAiConfig, experimentalModules, type AiConfig } from '@/shared/aiAccess';
import { screeningTargets, SCREENING_ENGINE } from '@/shared/aiScreening';
import { VET_ENGINE } from '@/shared/aiVet';
import { adminChange, loadAllFarms, loadConfig, setOp, updateOp, type AdminFarm } from '@/lib/admin';
import { useAdmin } from '@/lib/adminSession';
import { localIso } from '@/lib/dates';
import { firebase } from '@/lib/firebase';
import { featureOn } from '@/lib/platform';

interface LogRow {
  tenantId: string;
  feature: string;
  ok: boolean;
  ms: number;
  method: string;
  day: string;
}

const DAYS = 30;

/** The farm's feature switches with AI set, or removed to follow the default (Firestore refuses undefined). */
function withAi(features: AdminFarm['features'], on: boolean | undefined) {
  const rest = Object.fromEntries(Object.entries(features).filter(([k, v]) => k !== 'ai' && v !== undefined));
  return on === undefined ? rest : { ...rest, ai: on };
}

async function loadLog(): Promise<LogRow[]> {
  const since = localIso(new Date(Date.now() - DAYS * 86_400_000));
  const snap = await getDocs(query(collectionGroup(firebase().db, 'aiLog'), where('createdAt', '>=', since), limit(20000)));
  return snap.docs.map((d) => {
    const v = d.data() as { tenantId?: string; createdAt?: string; body?: Record<string, unknown> };
    const b = v.body ?? {};
    return {
      tenantId: v.tenantId ?? d.ref.parent.parent?.id ?? '',
      feature: String(b.feature ?? ''),
      ok: b.ok === true,
      ms: typeof b.ms === 'number' ? b.ms : 0,
      method: String(b.method ?? ''),
      day: (v.createdAt ?? '').slice(0, 10),
    };
  });
}

const sections = [
  ['overview', 'Overview'],
  ['models', 'Engines and models'],
  ['features', 'Features'],
  ['farms', 'Farms'],
] as const;

export default function AiControlCentre() {
  const { actor, can } = useAdmin();
  const cfg = useLoad(loadConfig);
  const farms = useLoad(loadAllFarms);
  const log = useLoad(loadLog);
  const act = useAction();
  const [ai, setAi] = useState<AiConfig>(defaultAiConfig);
  useEffect(() => {
    if (cfg.data) setAi(cfg.data.config.ai);
  }, [cfg.data]);
  const saved = cfg.data?.config.ai;
  const changed = !!saved && JSON.stringify(saved) !== JSON.stringify(ai);
  const rows = log.data ?? [];
  const defaults = cfg.data?.config.features ?? {};
  const aiOn = (f: AdminFarm) => !!saved?.enabled && featureOn('ai', defaults, null, f.features);

  const stats = useMemo(() => {
    const by = new Map<string, { n: number; fail: number; ms: number }>();
    const byFarm = new Map<string, { n: number; last: string }>();
    const byMethod = new Map<string, number>();
    for (const r of rows) {
      const f = by.get(r.feature) ?? { n: 0, fail: 0, ms: 0 };
      by.set(r.feature, { n: f.n + 1, fail: f.fail + (r.ok ? 0 : 1), ms: f.ms + r.ms });
      const fm = byFarm.get(r.tenantId) ?? { n: 0, last: '' };
      byFarm.set(r.tenantId, { n: fm.n + 1, last: r.day > fm.last ? r.day : fm.last });
      byMethod.set(r.method, (byMethod.get(r.method) ?? 0) + 1);
    }
    return { by, byFarm, byMethod, ok: rows.filter((r) => r.ok).length, fail: rows.filter((r) => !r.ok).length, avgMs: rows.length ? Math.round(rows.reduce((t, r) => t + r.ms, 0) / rows.length) : 0 };
  }, [rows]);

  const save = () =>
    act
      .run(
        () =>
          adminChange(actor, { action: 'config.ai', target: 'platform/config', details: { ai } }, [
            setOp(doc(firebase().db, 'platform', 'config'), { ai } as unknown as Record<string, unknown>, true),
          ]),
        'Saved. Farms get the change the next time a page opens.',
      )
      .then(cfg.reload);

  const setFarm = (f: AdminFarm, on: boolean | undefined) =>
    act
      .run(
        () =>
          adminChange(actor, { action: 'farm.features', target: `tenants/${f.id}`, tenantId: f.id, details: { ai: on ?? 'default' } }, [
            updateOp(doc(firebase().db, 'tenants', f.id), { features: withAi(f.features, on) }),
          ]),
        on === false ? `AI switched off for ${f.name}.` : `AI follows the default for ${f.name}.`,
      )
      .then(farms.reload);

  const disabled = !can('settings');
  const allFarms = farms.data ?? [];

  return (
    <Need perm={['settings', 'farms', 'support']}>
      <PageHead title="AI Control Centre" subtitle="AI Intelligence across every farm. Free, self-hosted engines only (decision 0025).">
        {can('settings') && (
          <button className="btn sm" disabled={!changed || act.busy} onClick={() => void save()}>
            <Icon name="check" /> Save changes
          </button>
        )}
      </PageHead>
      <MsgBanner msg={act.msg} />
      <div className="banner info small">
        <Icon name="shield" />
        <span className="grow">
          This page counts AI use from each farm’s AI log, which holds only the feature, whether it worked, the time taken and how the answer was made. It never shows a farm’s
          questions, animals or money. To look at a farm’s records, use Farms → Open, which is logged.
        </span>
      </div>
      <JumpNav items={sections} />

      <Anchor id="overview" title="Overview" hint={`Last ${DAYS} days`}>
        {log.error && <div className="banner bad small">Could not load the AI log ({log.error}). The index in firestore.indexes.json may still be building.</div>}
        <Fit kind="stats">
          <Stat icon="home" label="Farms with AI on" value={farms.data ? `${allFarms.filter(aiOn).length} of ${allFarms.length}` : '…'} />
          <Stat icon="spark" label="Farms using AI" value={log.data ? String(stats.byFarm.size) : '…'} />
          <Stat icon="chart" label="AI requests" value={log.data ? String(rows.length) : '…'} />
          <Stat icon="check" label="Worked" value={log.data ? String(stats.ok) : '…'} />
          <Stat icon="alert" label="Failed" value={log.data ? String(stats.fail) : '…'} tone={stats.fail ? 'warn' : undefined} />
          <Stat icon="clock" label="Average time" value={log.data ? `${stats.avgMs} ms` : '…'} hint="Worked out on the farm’s own device" />
        </Fit>
        <Fit kind="cards" cols={[1, 2, 2, 2]}>
          <section className="card stack">
            <h2>By feature</h2>
            {stats.by.size ? (
              <AiTable
                label="Use by feature"
                columns={['Feature', 'Requests', 'Failed', 'Average time']}
                right={[1, 2, 3]}
                rows={[...stats.by.entries()].sort((a, b) => b[1].n - a[1].n).map(([k, v]) => [aiModules.find((m) => m.key === k)?.label ?? k, v.n, v.fail, `${Math.round(v.ms / v.n)} ms`])}
              />
            ) : (
              <p className="small muted">No AI use logged yet.</p>
            )}
          </section>
          <section className="card stack">
            <h2>How answers were made</h2>
            {stats.byMethod.size ? (
              <AiTable label="Use by method" columns={['Method', 'Requests']} right={[1]} rows={[...stats.byMethod.entries()].map(([k, n]) => [methodLabel[k as Method] ?? k, n])} />
            ) : (
              <p className="small muted">No AI use logged yet.</p>
            )}
          </section>
        </Fit>
      </Anchor>

      <Anchor id="models" title="Engines and models" hint="What runs, its version and status">
        <AiTable
          label="Engines and models"
          columns={['Engine', 'Version', 'Licence', 'Status']}
          rows={[
            ['Farm calculations (milk, health, breeding, feed, money, risks)', 'engine-1', 'FarmTap code', 'Active in the browser'],
            ['Milk forecast (weighted trend + weekday pattern)', 'forecast-1', 'FarmTap code', 'Active in the browser'],
            ['Vet guide (signs and warning signs table)', VET_ENGINE, 'FarmTap code (vet review due)', 'Active in the browser'],
            ['Photo quality check', SCREENING_ENGINE, 'FarmTap code', ai.experimental ? 'Active (experimental)' : 'Off'],
            [`Language model (Ollama, ${ai.llm.model})`, '—', 'Qwen3: Apache-2.0', 'Not connected (no server)'],
            ...screeningTargets.map((t) => [`Screening: ${t.label}`, '—', '—', 'No validated model']),
          ]}
        />
        <p className="small muted">
          A photo-screening model can be installed only after it passes the evaluation in <code>tools/ai_eval/</code> on labelled photos, with the sensitivity and specificity
          shown on the farm’s Disease Screening page. Evaluation results: none yet.
        </p>
      </Anchor>

      <Anchor id="features" title="Features" hint="For every farm">
        <Fit kind="cards" cols={[1, 2, 2, 2]}>
          <section className="card stack">
            <Toggle label={ai.enabled ? 'AI Intelligence is on' : 'AI Intelligence is off'} hint="Off hides the AI menu, insights and AI cards on every farm." checked={ai.enabled} disabled={disabled} onChange={(enabled) => setAi({ ...ai, enabled })} />
            <Toggle
              label="Experimental features"
              hint={`Shows ${experimentalModules.map((k) => aiModules.find((m) => m.key === k)?.label).join(', ')}, clearly marked experimental.`}
              checked={ai.experimental}
              disabled={disabled}
              onChange={(experimental) => setAi({ ...ai, experimental })}
            />
            <label className="field">
              <span>Insights on Home</span>
              <input className="input" type="number" min={1} max={10} value={ai.insightsCount} disabled={disabled} onChange={(e) => setAi({ ...ai, insightsCount: Math.min(10, Math.max(1, Number(e.target.value) || 5)) })} />
            </label>
          </section>
          <section className="card stack">
            <h2>Language model (optional)</h2>
            <p className="small muted">
              Needs a self-hosted Ollama server (docs/ai/OLLAMA_SERVER.md). With none, the assistant answers from calculations only, which is how it works today. FarmTap never uses
              a paid AI service.
            </p>
            <Toggle label="Use the language model to phrase answers" hint="Stays off until a server is set up and tested." checked={ai.llm.enabled} disabled onChange={() => undefined} />
            <label className="field">
              <span>Model name</span>
              <input className="input" value={ai.llm.model} disabled={disabled} onChange={(e) => setAi({ ...ai, llm: { ...ai.llm, model: e.target.value.trim() } })} />
            </label>
          </section>
        </Fit>
        <section className="card stack">
          <h2>Modules</h2>
          <Fit kind="cards">
            {aiModules.map((m) => (
              <Toggle
                key={m.key}
                label={m.label}
                hint={`${m.hint}${experimentalModules.includes(m.key) ? ' · experimental' : ''}`}
                checked={ai.modules[m.key]}
                disabled={disabled}
                onChange={(on) => setAi({ ...ai, modules: { ...ai.modules, [m.key]: on } })}
              />
            ))}
          </Fit>
        </section>
      </Anchor>

      <Anchor id="farms" title="Farms" hint="Who has AI on, and who uses it">
        <AiTable
          label="Farms and AI"
          columns={['Farm', 'AI', 'Requests (30 days)', 'Last used', '']}
          rows={allFarms.map((f) => {
            const u = stats.byFarm.get(f.id);
            const override = f.features.ai;
            return [
              <Link key="n" href={`/admin/farm/?id=${encodeURIComponent(f.id)}`}>
                {f.name}
              </Link>,
              aiOn(f) ? 'On' : override === false ? 'Off for this farm' : 'Off',
              u?.n ?? 0,
              u?.last ?? '—',
              can('farms') ? (
                override === false ? (
                  <button key="b" className="btn sm outline" disabled={act.busy} onClick={() => void setFarm(f, undefined)}>
                    Turn back on
                  </button>
                ) : (
                  <button key="b" className="btn sm ghost" disabled={act.busy} onClick={() => void setFarm(f, false)}>
                    Turn off
                  </button>
                )
              ) : (
                ''
              ),
            ];
          })}
        />
        <p className="small muted">
          Every change here is in the <Link href="/admin/audit/">audit log</Link>.
        </p>
      </Anchor>
    </Need>
  );
}
