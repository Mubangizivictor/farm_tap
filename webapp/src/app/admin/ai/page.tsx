'use client';

// AI Control Centre (decision 0025). Platform-wide AI switches, the engines
// and models, use and failures, and which farms have AI on. It reads the AI
// use log (feature, ok, time, method — never farm figures) and farm switches,
// never farm records. Every change goes through adminChange (audit log).

import { collection, collectionGroup, doc, getDocs, limit, orderBy, query, where } from 'firebase/firestore';
import Link from 'next/link';
import { useEffect, useMemo, useState } from 'react';
import { Fit } from '@/components/fit';
import { Icon } from '@/components/Icon';
import { AiTable } from '@/components/ai';
import { Anchor, JumpNav, MsgBanner, Need, Toggle, useAction, useLoad } from '@/components/admin';
import { PageHead, PrintButton, Stat } from '@/components/ui';
import { aiModules, methodLabel, type Method } from '@/shared/aiCore';
import { defaultAiConfig, experimentalModules, type AiConfig } from '@/shared/aiAccess';
import { screeningTargets, SCREENING_ENGINE } from '@/shared/aiScreening';
import { CHAT_ENGINE } from '@/shared/aiChat';
import { PHOTO_ENGINE } from '@/shared/aiPhoto';
import { VET_ENGINE } from '@/shared/aiVet';
import { adminChange, loadAllFarms, loadConfig, setOp, updateOp, type AdminFarm } from '@/lib/admin';
import { useAdmin } from '@/lib/adminSession';
import { localIso } from '@/lib/dates';
import { firebase } from '@/lib/firebase';
import { featureOn } from '@/lib/platform';
import { AI_PROVIDERS, quotaDay, validTimezone, type AssistantConfig } from '@/shared/aiQuota';

interface DayStat {
  day: string;
  total: number;
  ok: number;
  failed: number;
  cached: number;
  limit: number;
  tooFast: number;
  disabled: number;
  msOk: number;
  tokensIn: number;
  tokensOut: number;
  costUsd: number;
  byKind: Record<string, number>;
  lastOkAt: Date | null;
  lastFailAt: Date | null;
  lastFailKind: string;
}
interface FarmStat {
  tenantId: string;
  ok: number;
  failed: number;
  limit: number;
  cached: number;
  tokensIn: number;
  tokensOut: number;
}
interface ErrorRow {
  at: Date | null;
  tenantId: string;
  kind: string;
  status: number;
  model: string;
  detail: string;
}

const n0 = (v: unknown) => (typeof v === 'number' && Number.isFinite(v) ? v : 0);
const when = (v: unknown) => (v && typeof (v as { toDate?: () => Date }).toDate === 'function' ? (v as { toDate: () => Date }).toDate() : null);

/** Server AI totals (decision 0028): aiStats/{day}, the farms of the latest day, and recent provider errors. */
async function loadServerStats(): Promise<{ days: DayStat[]; farms: FarmStat[]; errors: ErrorRow[] }> {
  const db = firebase().db;
  const since = quotaDay(Date.now() - DAYS * 86_400_000);
  const today = quotaDay(Date.now());
  const [d, f, e] = await Promise.all([
    getDocs(query(collection(db, 'aiStats'), where('day', '>=', since), limit(DAYS + 1))),
    getDocs(collection(db, 'aiStats', today, 'farms')),
    getDocs(query(collection(db, 'aiErrors'), orderBy('at', 'desc'), limit(20))).catch(() => null),
  ]);
  const days = d.docs.map((x) => {
    const v = x.data();
    return {
      day: x.id,
      total: n0(v.total),
      ok: n0(v.ok),
      failed: n0(v.failed),
      cached: n0(v.cached),
      limit: n0(v.limit),
      tooFast: n0(v.tooFast),
      disabled: n0(v.disabled),
      msOk: n0(v.msOk),
      tokensIn: n0(v.tokensIn),
      tokensOut: n0(v.tokensOut),
      costUsd: n0(v.costUsd),
      byKind: (v.byKind ?? {}) as Record<string, number>,
      lastOkAt: when(v.lastOkAt),
      lastFailAt: when(v.lastFailAt),
      lastFailKind: String(v.lastFailKind ?? ''),
    };
  });
  const farms = f.docs.map((x) => {
    const v = x.data();
    return { tenantId: x.id, ok: n0(v.ok), failed: n0(v.failed), limit: n0(v.limit), cached: n0(v.cached), tokensIn: n0(v.tokensIn), tokensOut: n0(v.tokensOut) };
  });
  const errors = (e?.docs ?? []).map((x) => {
    const v = x.data();
    return { at: when(v.at), tenantId: String(v.tenantId ?? ''), kind: String(v.kind ?? ''), status: n0(v.status), model: String(v.model ?? ''), detail: String(v.detail ?? '') };
  });
  return { days, farms, errors };
}

/** A number box for the assistant settings, kept inside its range. */
function NumberField({ label, hint, value, min, max, step = 1, disabled, onChange }: { label: string; hint?: string; value: number; min: number; max: number; step?: number; disabled: boolean; onChange: (v: number) => void }) {
  return (
    <label className="field">
      <span>{label}</span>
      <input className="input" type="number" min={min} max={max} step={step} value={value} disabled={disabled} onChange={(e) => onChange(Math.min(max, Math.max(min, Number(e.target.value) || min)))} />
      {hint && <small className="muted">{hint}</small>}
    </label>
  );
}

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
  ['assistant', 'AI assistant'],
  ['models', 'Engines and models'],
  ['features', 'Features'],
  ['farms', 'Farms'],
] as const;

export default function AiControlCentre() {
  const { actor, can } = useAdmin();
  const cfg = useLoad(loadConfig);
  const farms = useLoad(loadAllFarms);
  const log = useLoad(loadLog);
  const server = useLoad(loadServerStats);
  const act = useAction();
  const allFarmsById = useMemo(() => new Map((farms.data ?? []).map((f) => [f.id, f.name])), [farms.data]);
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
  const a = ai.assistant;
  const setA = (patch: Partial<AssistantConfig>) => setAi({ ...ai, assistant: { ...a, ...patch } });
  const srv = useMemo(() => {
    const ds = server.data?.days ?? [];
    const sum = (k: keyof DayStat) => ds.reduce((t, d) => t + (typeof d[k] === 'number' ? (d[k] as number) : 0), 0);
    const kinds = new Map<string, number>();
    for (const d of ds) for (const [k, v] of Object.entries(d.byKind)) kinds.set(k, (kinds.get(k) ?? 0) + n0(v));
    const lastOk = ds.map((d) => d.lastOkAt).filter((x): x is Date => !!x).sort((x, y) => +y - +x)[0] ?? null;
    const lastFail = ds.map((d) => d.lastFailAt).filter((x): x is Date => !!x).sort((x, y) => +y - +x)[0] ?? null;
    const ok = sum('ok');
    return { total: sum('total'), ok, failed: sum('failed'), cached: sum('cached'), limit: sum('limit'), tooFast: sum('tooFast'), avgMs: ok ? Math.round(sum('msOk') / ok) : 0, tokensIn: sum('tokensIn'), tokensOut: sum('tokensOut'), cost: sum('costUsd'), kinds, lastOk, lastFail, lastFailKind: ds.find((d) => d.lastFailAt && +d.lastFailAt === +(lastFail ?? 0))?.lastFailKind ?? '' };
  }, [server.data]);
  const providerState = !srv.lastOk && !srv.lastFail ? 'No server answers yet' : srv.lastFail && (!srv.lastOk || srv.lastFail > srv.lastOk) ? `Failing since ${srv.lastFail.toLocaleString()} (${srv.lastFailKind})` : `Working (last answer ${srv.lastOk!.toLocaleString()})`;
  const farmName = (id: string) => allFarmsById.get(id) ?? id;
  const allFarms = farms.data ?? [];

  return (
    <Need perm={['settings', 'farms', 'support']}>
      <PageHead title="AI Control Centre" subtitle="AI Intelligence across every farm: built-in engines (free, unlimited) and the AI assistant (decisions 0025, 0028).">
        {can('settings') && (
          <button className="btn sm" disabled={!changed || act.busy} onClick={() => void save()}>
            <Icon name="check" /> Save changes
          </button>
        )}
        <PrintButton />
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

      <Anchor id="assistant" title="AI assistant" hint="Answers written by an AI model (layer 3). Built-in answers are unlimited and not counted here.">
        <div className={`banner small ${a.route === 'server' ? 'ok' : 'warn'}`}>
          <Icon name="shield" />
          <span className="grow">
            {a.route === 'server'
              ? 'Secure server route: every AI answer goes through the FarmTap server, which checks the farm and enforces the daily allowance. Needs the aiAssistant function deployed (Blaze plan) and the Gemini key saved as gemini_api_key in APIs and keys.'
              : 'Pilot route: the apps call Gemini themselves and count the allowance on the device. Anyone determined could go past the limit. Switch to the server route once Blaze is on and aiAssistant is deployed (decision 0028).'}
          </span>
        </div>
        <Fit kind="stats">
          <Stat icon="chart" label="AI requests (server)" value={server.data ? String(srv.total) : '…'} hint={`Last ${DAYS} days`} />
          <Stat icon="check" label="Answered" value={server.data ? String(srv.ok) : '…'} />
          <Stat icon="alert" label="Failed (not charged)" value={server.data ? String(srv.failed) : '…'} tone={srv.failed ? 'warn' : undefined} />
          <Stat icon="flag" label="Limit reached" value={server.data ? String(srv.limit) : '…'} hint="Times a farm was told its daily allowance was used" />
          <Stat icon="copy" label="From cache (free)" value={server.data ? String(srv.cached) : '…'} />
          <Stat icon="clock" label="Average answer time" value={server.data ? `${(srv.avgMs / 1000).toFixed(1)} s` : '…'} />
          <Stat icon="list" label="Tokens in / out" value={server.data ? `${srv.tokensIn.toLocaleString('en-US')} / ${srv.tokensOut.toLocaleString('en-US')}` : '…'} />
          <Stat icon="spark" label="Estimated cost" value={server.data ? `USD ${srv.cost.toFixed(2)}` : '…'} hint={a.priceInPerM || a.priceOutPerM ? 'From the prices set below' : 'Set prices below for an estimate (0 on the free tier)'} />
        </Fit>
        {server.error && <p className="small muted">Server totals are not available yet ({server.error}). They appear once the server route is in use.</p>}
        <p className="small">
          <strong>Provider:</strong> {AI_PROVIDERS.find((p) => p.id === a.provider)?.label ?? a.provider}. {providerState}.
          {srv.kinds.size > 0 && ` Failures: ${[...srv.kinds.entries()].map(([k, v]) => `${k} ${v}`).join(', ')}.`}
        </p>
        <Fit kind="cards" cols={[1, 2, 2, 2]}>
          <section className="card stack">
            <h2>Settings</h2>
            <Toggle label={a.enabled ? 'AI answers are on' : 'AI answers are off'} hint="Off: the chat keeps answering from the records (built-in intelligence). Nothing else in FarmTap changes." checked={a.enabled} disabled={disabled} onChange={(enabled) => setA({ enabled })} />
            <label className="field">
              <span>Route</span>
              <select className="input" value={a.route} disabled={disabled} onChange={(e) => setA({ route: e.target.value === 'server' ? 'server' : 'client' })}>
                <option value="client">Pilot: apps call Gemini (limit counted on the device)</option>
                <option value="server">Secure server (limit enforced by FarmTap)</option>
              </select>
            </label>
            <label className="field">
              <span>Provider</span>
              <select className="input" value={a.provider} disabled={disabled} onChange={(e) => setA({ provider: e.target.value as AssistantConfig['provider'] })}>
                {AI_PROVIDERS.map((p) => (
                  <option key={p.id} value={p.id}>
                    {p.label}
                  </option>
                ))}
              </select>
            </label>
            <label className="field">
              <span>Model</span>
              <input className="input" value={a.model} disabled={disabled} onChange={(e) => setA({ model: e.target.value.trim() })} />
              <small className="muted">If it fails, the next Gemini model is tried. A retired name is fixed here without an app update.</small>
            </label>
          </section>
          <section className="card stack">
            <h2>Daily allowance</h2>
            <NumberField label="AI answers per farm per day" hint="Shared by everyone on the farm. Failed requests are not counted. 0 turns AI answers off." value={a.dailyLimit} min={0} max={1000} disabled={disabled} onChange={(dailyLimit) => setA({ dailyLimit })} />
            <NumberField label="Warn at (% of the allowance)" value={a.warnPct} min={50} max={100} disabled={disabled} onChange={(warnPct) => setA({ warnPct })} />
            <label className="field">
              <span>Day resets at midnight in</span>
              <input className="input" value={a.timezone} disabled={disabled} onChange={(e) => setA({ timezone: validTimezone(e.target.value.trim()) ? e.target.value.trim() : a.timezone })} />
              <small className="muted">An IANA time zone, e.g. Africa/Kampala. Worked out on the server, never the phone’s clock.</small>
            </label>
            <NumberField label="AI questions per person per minute" value={a.perUserPerMinute} min={1} max={60} disabled={disabled} onChange={(perUserPerMinute) => setA({ perUserPerMinute })} />
          </section>
          <section className="card stack">
            <h2>Request limits</h2>
            <NumberField label="Longest question (characters)" value={a.maxChars} min={100} max={8000} disabled={disabled} onChange={(maxChars) => setA({ maxChars })} />
            <NumberField label="Wait for the model (seconds)" value={Math.round(a.timeoutMs / 1000)} min={5} max={120} disabled={disabled} onChange={(s) => setA({ timeoutMs: s * 1000 })} />
            <NumberField label="Longest answer (tokens)" value={a.maxOutputTokens} min={128} max={8192} disabled={disabled} onChange={(maxOutputTokens) => setA({ maxOutputTokens })} />
            <NumberField label="Most sent per question (tokens)" hint="Question, farm facts and earlier messages. Oldest messages are dropped first." value={a.maxInputTokens} min={500} max={100000} disabled={disabled} onChange={(maxInputTokens) => setA({ maxInputTokens })} />
            <NumberField label="Keep answers for repeat questions (hours)" hint="Same farm, same question, same facts. 0 = off." value={a.cacheHours} min={0} max={72} disabled={disabled} onChange={(cacheHours) => setA({ cacheHours })} />
          </section>
          <section className="card stack">
            <h2>Cost estimate</h2>
            <p className="small muted">Prices from the provider’s pricing page, in USD per million tokens. Leave 0 while on the free tier.</p>
            <NumberField label="Input price (USD per million tokens)" value={a.priceInPerM} min={0} max={1000} step={0.01} disabled={disabled} onChange={(priceInPerM) => setA({ priceInPerM })} />
            <NumberField label="Output price (USD per million tokens)" value={a.priceOutPerM} min={0} max={1000} step={0.01} disabled={disabled} onChange={(priceOutPerM) => setA({ priceOutPerM })} />
            {server.data && srv.ok > 0 && (
              <p className="small">
                About USD {(srv.cost / srv.ok).toFixed(4)} an answer. At {a.dailyLimit} answers a day for 10,000 farms, at most USD {((srv.cost / srv.ok) * a.dailyLimit * 10000 * 30).toLocaleString('en-US', { maximumFractionDigits: 0 })} a month.
              </p>
            )}
          </section>
        </Fit>
        <Fit kind="cards" cols={[1, 2, 2, 2]}>
          <section className="card stack">
            <h2>Farms today</h2>
            {server.data?.farms.length ? (
              <AiTable
                label="AI answers per farm today"
                columns={['Farm', 'Answered', 'Failed', 'Limit reached', 'Tokens']}
                right={[1, 2, 3, 4]}
                rows={[...server.data.farms].sort((x, y) => y.ok - x.ok).slice(0, 50).map((f) => [farmName(f.tenantId), f.ok, f.failed, f.limit, (f.tokensIn + f.tokensOut).toLocaleString('en-US')])}
              />
            ) : (
              <p className="small muted">No server AI answers today.</p>
            )}
          </section>
          {can('settings') && (
            <section className="card stack">
              <h2>Latest provider errors</h2>
              {server.data?.errors.length ? (
                <AiTable
                  label="Latest provider errors"
                  columns={['When', 'Kind', 'Model', 'Details']}
                  rows={server.data.errors.map((e) => [e.at?.toLocaleString() ?? '—', e.kind, e.model, <code key="d" className="small">{`${e.status || ''} ${e.detail}`.trim().slice(0, 200)}</code>])}
                />
              ) : (
                <p className="small muted">None. Farmers never see these details; they get a plain message.</p>
              )}
            </section>
          )}
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
            ['Photo quality check', SCREENING_ENGINE, 'FarmTap code', 'Active in the browser'],
            [`Photo Check (Google Gemini, ${ai.photo.model})`, PHOTO_ENGINE, 'Google service, free tier; photo leaves the farm', ai.photo.enabled ? 'On' : 'Off'],
            [`AI assistant (${a.provider}, ${a.model})`, CHAT_ENGINE, 'Google service; names replaced before sending', a.enabled ? (a.route === 'server' ? 'On, server route' : 'On, pilot route') : 'Off'],
            ['Request classifier (records / insight / AI)', 'route-1', 'FarmTap code', 'Active in the browser'],
            [`Language model (Ollama, ${ai.llm.model})`, '—', 'Qwen3: Apache-2.0', 'Not connected (no server)'],
            ...screeningTargets.map((t) => [`Screening: ${t.label}`, '—', '—', 'No validated model']),
          ]}
        />
        <p className="small muted">
          Photo Check describes what Google Gemini can see and lists possible causes. It never diagnoses, never names a drug or dose, and always says to call the vet (decision 0026).
          It has not been tested on labelled East African photos: treat it as a helper, not a result. Vet review of the wording is still due.
        </p>
      </Anchor>

      <Anchor id="features" title="Features" hint="For every farm">
        <Fit kind="cards" cols={[1, 2, 2, 2]}>
          <section className="card stack">
            <Toggle label={ai.enabled ? 'AI Intelligence is on' : 'AI Intelligence is off'} hint="Off hides the AI menu, insights and AI cards on every farm." checked={ai.enabled} disabled={disabled} onChange={(enabled) => setAi({ ...ai, enabled })} />
            <label className="field">
              <span>Insights on Home</span>
              <input className="input" type="number" min={1} max={10} value={ai.insightsCount} disabled={disabled} onChange={(e) => setAi({ ...ai, insightsCount: Math.min(10, Math.max(1, Number(e.target.value) || 5)) })} />
            </label>
          </section>
          <section className="card stack">
            <h2>Photo Check (Google Gemini)</h2>
            <p className="small muted">
              Sends the farmer’s question, and any photo, PDF, file or video they attach, to Google through Firebase AI Logic. Names are replaced before sending; photos and files leave the farm. Turn it on only after App Check is enforced in the Firebase console and the billing plan is checked
              (decision 0026). The photo leaves the farm; farmers are told before each check.
            </p>
            <Toggle
              label={ai.photo.enabled ? 'Photo Check is on' : 'Photo Check is off'}
              hint="The Photo Check screen under Insights and tools. The chat has its own switch under AI assistant."
              checked={ai.photo.enabled}
              disabled={disabled}
              onChange={(enabled) => setAi({ ...ai, photo: { ...ai.photo, enabled } })}
            />
            <label className="field">
              <span>Model name</span>
              <input className="input" value={ai.photo.model} disabled={disabled} onChange={(e) => setAi({ ...ai, photo: { ...ai.photo, model: e.target.value.trim() } })} />
            </label>
            <label className="field">
              <span>Photo checks per farm per day</span>
              <input
                className="input"
                type="number"
                min={1}
                max={500}
                value={ai.photo.perFarmPerDay}
                disabled={disabled}
                onChange={(e) => setAi({ ...ai, photo: { ...ai.photo, perFarmPerDay: Math.min(500, Math.max(1, Math.round(Number(e.target.value)) || 20)) } })}
              />
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
