'use client';

// The web side of AI Intelligence (decision 0025): loads one farm's records
// with the signed-in person's own access, hands them to the shared engine,
// and keeps the AI use log. Nothing here talks to an AI service.

import { useMemo } from 'react';
import { aiModules, kampalaNow, type AiModule, type Method, type Rec } from '../shared/aiCore.ts';
import { moduleOn, type AiConfig } from '../shared/aiAccess.ts';
import { defaultShelfRules, type FarmData, type ShelfRule } from '../shared/aiData.ts';
import { allFindings, type AlertStateIn, type FindingWithState } from '../shared/aiRisk.ts';
import { addRecord, upsertRecord, useRecords, webDeviceId } from './data.ts';
import { hasHerd, isCentre, manages, type Farm, type FarmRecord } from './domain.ts';
import { firebase } from './firebase.ts';
import { featureOn, type FeatureKey, type PlatformConfig } from './platform.ts';

export type Need = 'herd' | 'money' | 'centre' | 'stock' | 'quality' | 'states';

/** Every collection the engine may read, and which "need" it belongs to. */
const sources: { key: keyof FarmData; name: string; need: Need }[] = [
  { key: 'animals', name: 'animals', need: 'herd' },
  { key: 'milk', name: 'milkRecords', need: 'herd' },
  { key: 'treatments', name: 'treatments', need: 'herd' },
  { key: 'vaccinations', name: 'vaccinations', need: 'herd' },
  { key: 'breeding', name: 'breedingEvents', need: 'herd' },
  { key: 'feedUses', name: 'feedUsage', need: 'stock' },
  { key: 'stockMoves', name: 'stockMovements', need: 'stock' },
  { key: 'feedTypes', name: 'feedTypes', need: 'stock' },
  { key: 'stockItems', name: 'stockItems', need: 'stock' },
  { key: 'expenses', name: 'expenses', need: 'money' },
  { key: 'income', name: 'income', need: 'money' },
  { key: 'milkSales', name: 'milkSales', need: 'money' },
  { key: 'deliveries', name: 'deliveries', need: 'centre' },
  { key: 'milkBatches', name: 'milkBatches', need: 'quality' },
  { key: 'storageReadings', name: 'storageReadings', need: 'quality' },
];

const ALL: Need[] = ['herd', 'money', 'centre', 'stock', 'quality', 'states'];

export interface AiFarm {
  data: FarmData;
  loading: boolean;
  error: string | null;
  states: Map<string, AlertStateIn>;
  /** Raw records, for pages that save changes (batches, alert states). */
  records: Record<string, FarmRecord<object>[]>;
  shelfRules: ShelfRule[];
}

/**
 * The farm's records as the AI engine reads them. Money is loaded only for
 * owners and managers (Firestore would refuse nothing, but Money is theirs);
 * the herd only for farms with a herd, deliveries only for centres.
 */
export function useAiFarm(farm: Farm, needs: Need[] = ALL): AiFarm {
  const allowed: Record<Need, boolean> = {
    herd: hasHerd(farm),
    stock: hasHerd(farm),
    money: manages(farm),
    centre: isCentre(farm),
    quality: hasHerd(farm) || isCentre(farm),
    states: true,
  };
  const want = (n: Need) => needs.includes(n) && allowed[n];
  // A fixed list of hooks (same order on every render); unused ones get a null farm id.
  const lives = sources.map((s) => ({ s, live: useRecords<object>(want(s.need) ? farm.id : null, s.name) }));
  const states = useRecords<AlertStateIn>(want('states') ? farm.id : null, 'aiAlertStates');
  const settings = useRecords<{ rules?: unknown }>(want('quality') ? farm.id : null, 'settings');
  const used = lives.filter((l) => want(l.s.need));
  const loading = used.some((l) => l.live.loading) || (want('states') && states.loading);
  const error = used.map((l) => l.live.error).find(Boolean) ?? null;
  const key = used.map((l) => `${l.s.name}:${l.live.data.length}:${l.live.data.reduce((t, r) => t + (r.version ?? 0), 0)}`).join('|') + `|s:${states.data.length}:${states.data.reduce((t, r) => t + r.version, 0)}|c:${settings.data.length}`;
  return useMemo(() => {
    const shelf = shelfRulesFrom(settings.data.find((r) => r.id === 'aiMilk')?.body.rules);
    const data: FarmData = { now: kampalaNow(new Date()).iso, shelfRules: shelf };
    const records: Record<string, FarmRecord<object>[]> = {};
    for (const l of used) {
      (data as unknown as Record<string, Rec<object>[]>)[l.s.key] = l.live.data as Rec<object>[];
      records[l.s.name] = l.live.data;
    }
    records.aiAlertStates = states.data;
    const st = new Map(states.data.map((r) => [r.id, r.body]));
    return { data, loading, error, states: st, records, shelfRules: shelf };
    // `key` changes whenever any record is added or changed.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [key, loading, error]);
}

export function shelfRulesFrom(v: unknown): ShelfRule[] {
  if (!Array.isArray(v)) return defaultShelfRules;
  const ok = v
    .filter((x): x is Record<string, unknown> => !!x && typeof x === 'object')
    .map((x) => ({
      product: String(x.product ?? 'rawMilk'),
      label: String(x.label ?? 'Raw milk'),
      cooledHours: clampNum(x.cooledHours, 1, 24 * 14, 48),
      warmHours: clampNum(x.warmHours, 0.5, 48, 3),
      maxTempC: clampNum(x.maxTempC, -5, 15, 4),
    }));
  return ok.length ? ok : defaultShelfRules;
}
const clampNum = (v: unknown, lo: number, hi: number, d: number) => (typeof v === 'number' && Number.isFinite(v) && v >= lo && v <= hi ? v : d);

/** Whether AI is on for this farm (platform switch, then plan/farm feature switch). */
export function farmAiOn(farm: Farm, cfg: PlatformConfig): boolean {
  return cfg.ai.enabled && featureOn('ai', cfg.features, null, farm.features as Record<FeatureKey, boolean | undefined>);
}

export function visibleModules(farm: Farm, cfg: PlatformConfig): AiModule[] {
  const on = farmAiOn(farm, cfg);
  return aiModules.map((m) => m.key).filter((k) => moduleOn(k, cfg.ai, farm.role, on) && (k !== 'quality' || hasHerd(farm) || isCentre(farm)));
}

export function useFindings(farm: Farm, cfg: PlatformConfig, ai: AiFarm): FindingWithState[] {
  return useMemo(
    () => (ai.loading ? [] : allFindings(ai.data, { role: farm.role, cfg: cfg.ai as AiConfig, farmAiOn: farmAiOn(farm, cfg), states: ai.states })),
    [ai, farm, cfg],
  );
}

// ---------------------------------------------------------------- Writes

const uid = () => firebase().auth.currentUser?.uid ?? '';

/**
 * One line in the farm's AI use log: which feature, whether it worked, how
 * long it took and how the answer was made. Never the question, the answer
 * or any figure (firestore.rules refuse anything else). Fire and forget.
 */
export function logAi(tenantId: string, feature: string, ok: boolean, ms: number, method: Method) {
  if (!uid()) return;
  void addRecord(firebase().db, tenantId, 'aiLog', uid(), { feature: feature.slice(0, 32), ok, ms: Math.round(ms), method, at: kampalaNow(new Date()).iso }).catch(() => {
    /* the log must never stop the farmer */
  });
}

export async function setAlertState(tenantId: string, alertId: string, status: AlertStateIn['status'], byName: string) {
  await upsertRecord(firebase().db, tenantId, 'aiAlertStates', stateKey(alertId), uid(), {
    status,
    byName,
    at: kampalaNow(new Date()).iso,
    note: null,
  });
}

/** Alert ids are used as document ids; Firestore forbids "/" in them. */
export const stateKey = (alertId: string) => alertId.slice(0, 200).replace(/\//g, '_');

// ---------------------------------------------------------------- Cache

const CACHE = 'farmtap.ai.insights';

/** The last insights seen in this browser, for when the internet drops (web is online-only, decision 0017). */
export function cacheInsights(tenantId: string, fs: FindingWithState[]) {
  try {
    window.localStorage.setItem(`${CACHE}.${tenantId}`, JSON.stringify({ at: new Date().toISOString(), fs: fs.slice(0, 20), device: webDeviceId() }));
  } catch {
    /* private window */
  }
}

export function cachedInsights(tenantId: string): { at: Date; fs: FindingWithState[] } | null {
  try {
    const raw = window.localStorage.getItem(`${CACHE}.${tenantId}`);
    if (!raw) return null;
    const v = JSON.parse(raw) as { at: string; fs: FindingWithState[] };
    return { at: new Date(v.at), fs: Array.isArray(v.fs) ? v.fs : [] };
  } catch {
    return null;
  }
}
