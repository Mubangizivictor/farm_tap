// GENERATED from shared/ by `node shared/sync.mjs`. Edit the file in shared/, not this copy.
// FarmTap AI engine — who sees what, and the platform switches (decision 0025).
// Display only: Firestore rules still decide what can be read at all.

import { aiModules, type AiModule } from './aiCore.ts';
import { assistantConfigFrom, defaultAssistantConfig, type AssistantConfig } from './aiQuota.ts';

export type FarmRole = 'owner' | 'manager' | 'clerk' | 'worker' | string;

/** AI modules each farm role is shown (docs/ai/AI_IMPLEMENTATION_MAP.md §3). */
const byRole: Record<string, AiModule[]> = {
  owner: aiModules.map((m) => m.key),
  manager: aiModules.map((m) => m.key),
  clerk: ['assistant', 'vet', 'screening', 'milk', 'quality', 'predictions', 'feed', 'breeding', 'health', 'inventory', 'risks', 'recommendations', 'alerts'],
  worker: ['assistant', 'vet', 'screening', 'milk', 'quality', 'feed', 'health', 'recommendations', 'alerts'],
};

export function roleModules(role: FarmRole): AiModule[] {
  return byRole[role] ?? byRole.worker;
}

/** Money modules and money findings are for owners and managers only, as Money already is. */
export const seesMoney = (role: FarmRole) => role === 'owner' || role === 'manager';

/** platform/config.ai, edited in the AI Control Centre. */
export interface AiConfig {
  /** Everything AI, for every farm. */
  enabled: boolean;
  modules: Record<AiModule, boolean>;
  /** Experimental modules (screening) are shown only when this is on. */
  experimental: boolean;
  /** Optional self-hosted language model (Ollama) used only to phrase answers. */
  llm: { enabled: boolean; model: string; timeoutMs: number };
  /**
   * Photo analysis with Google Gemini through Firebase AI Logic (decision
   * 0026). Off until the Firebase steps are done and a Super Admin turns it
   * on. [perFarmPerDay] is a soft limit counted from the farm's own saved
   * photo checks; the Google free tier has its own limits as well.
   */
  photo: { enabled: boolean; model: string; perFarmPerDay: number };
  /** The AI chat (layer 3, decision 0028): switch, provider, model, daily allowance and limits. */
  assistant: AssistantConfig;
  /** How many alerts "Today's insights" shows. */
  insightsCount: number;
}

export const defaultAiConfig: AiConfig = {
  enabled: true,
  modules: Object.fromEntries(aiModules.map((m) => [m.key, true])) as Record<AiModule, boolean>,
  experimental: true,
  llm: { enabled: false, model: 'qwen3:4b', timeoutMs: 20000 },
  photo: { enabled: false, model: 'gemini-3.8-flash', perFarmPerDay: 20 },
  assistant: defaultAssistantConfig,
  insightsCount: 5,
};

const obj = (v: unknown): Record<string, unknown> => (v && typeof v === 'object' && !Array.isArray(v) ? (v as Record<string, unknown>) : {});

export function aiConfigFrom(v: unknown): AiConfig {
  const o = obj(v);
  const m = obj(o.modules);
  const l = obj(o.llm);
  const ph = obj(o.photo);
  const D = defaultAiConfig;
  return {
    enabled: typeof o.enabled === 'boolean' ? o.enabled : D.enabled,
    modules: Object.fromEntries(aiModules.map((x) => [x.key, typeof m[x.key] === 'boolean' ? (m[x.key] as boolean) : D.modules[x.key]])) as Record<AiModule, boolean>,
    experimental: typeof o.experimental === 'boolean' ? o.experimental : D.experimental,
    llm: {
      enabled: typeof l.enabled === 'boolean' ? l.enabled : D.llm.enabled,
      model: typeof l.model === 'string' && /^[\w.:\-/]{1,64}$/.test(l.model) ? l.model : D.llm.model,
      timeoutMs: typeof l.timeoutMs === 'number' && l.timeoutMs >= 1000 && l.timeoutMs <= 120000 ? l.timeoutMs : D.llm.timeoutMs,
    },
    photo: {
      enabled: typeof ph.enabled === 'boolean' ? ph.enabled : D.photo.enabled,
      model: typeof ph.model === 'string' && /^[\w.\-]{3,64}$/.test(ph.model) ? ph.model : D.photo.model,
      perFarmPerDay: typeof ph.perFarmPerDay === 'number' && ph.perFarmPerDay >= 1 && ph.perFarmPerDay <= 500 ? Math.round(ph.perFarmPerDay) : D.photo.perFarmPerDay,
    },
    assistant: assistantConfigFrom(o),
    insightsCount: typeof o.insightsCount === 'number' && o.insightsCount >= 1 && o.insightsCount <= 10 ? Math.round(o.insightsCount) : D.insightsCount,
  };
}

export const experimentalModules: AiModule[] = [];

/** Whether a person on a farm sees one module: platform switch, farm switch, role. */
export function moduleOn(key: AiModule, cfg: AiConfig, role: FarmRole, farmAiOn = true): boolean {
  if (!cfg.enabled || !farmAiOn || !cfg.modules[key]) return false;
  if (experimentalModules.includes(key) && !cfg.experimental) return false;
  if ((key === 'finance' || key === 'reports') && !seesMoney(role)) return false;
  return roleModules(role).includes(key);
}
