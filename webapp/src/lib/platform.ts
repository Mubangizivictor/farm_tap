// Platform settings edited in the control panel (decision 0020). Pure
// functions and types only, so they can be tested without Firebase. The
// phone has the same shapes in lib/core/platform/platform_config.dart.

import { parseDate } from './dates.ts';

// ---------------------------------------------------------------- Features

/** Switches the panel can turn on or off: default, then plan, then farm. */
export const featureList = [
  { key: 'milk', label: 'Milk records', hint: 'Daily milk per cow and session' },
  { key: 'herd', label: 'Herd', hint: 'Animals, tags, photos' },
  { key: 'health', label: 'Health', hint: 'Treatments, withdrawal, vaccinations' },
  { key: 'breeding', label: 'Breeding', hint: 'Heat, AI, pregnancy, calving' },
  { key: 'feeding', label: 'Feeding and stock', hint: 'Feeds, stock counts' },
  { key: 'money', label: 'Money', hint: 'Sales, expenses, reports' },
  { key: 'workers', label: 'Workers', hint: 'Staff, attendance, wages' },
  { key: 'centre', label: 'Collection centre', hint: 'Suppliers, deliveries, statements' },
  { key: 'idCards', label: 'ID cards and scan station', hint: 'Printable cards, QR scanning' },
  { key: 'exports', label: 'PDF and Excel exports', hint: 'Download and print reports' },
  { key: 'webApp', label: 'Web app', hint: 'Use FarmTap in Chrome' },
  { key: 'smsAutoSend', label: 'Automatic SMS', hint: 'Sent by the server, uses SMS credits' },
] as const;

export type FeatureKey = (typeof featureList)[number]['key'];
export type FeatureMap = Partial<Record<FeatureKey, boolean>>;

export const defaultFeatures: Record<FeatureKey, boolean> = {
  milk: true,
  herd: true,
  health: true,
  breeding: true,
  feeding: true,
  money: true,
  workers: true,
  centre: true,
  idCards: true,
  exports: true,
  webApp: true,
  smsAutoSend: false,
};

/** The farm's own switch wins, then its plan's, then the default. */
export function featureOn(key: FeatureKey, defaults: FeatureMap, plan?: FeatureMap | null, farm?: FeatureMap | null): boolean {
  if (farm && typeof farm[key] === 'boolean') return farm[key] as boolean;
  if (plan && typeof plan[key] === 'boolean') return plan[key] as boolean;
  if (typeof defaults[key] === 'boolean') return defaults[key] as boolean;
  return defaultFeatures[key];
}

// ---------------------------------------------------------------- Config

export interface Gateway {
  id: string;
  name: string;
  enabled: boolean;
  /** Merchant or pay code shown to farmers (e.g. MoMo Pay code). Not secret. */
  payCode: string;
  /** Account name the farmer should see when paying. */
  accountName: string;
  instructions: string;
}

export interface AppVersion {
  minVersion: string;
  latestVersion: string;
  storeUrl: string;
}

export interface PlatformConfig {
  trialDays: number;
  maintenance: { on: boolean; message: string };
  app: { android: AppVersion; ios: AppVersion; updateMessage: string };
  web: { minBuild: number; message: string };
  support: { phone: string; whatsapp: string; email: string; hours: string };
  signup: { open: boolean; sectors: string[]; closedMessage: string };
  features: FeatureMap;
  payments: { gateways: Gateway[]; manualNote: string };
  maps: { provider: 'none' | 'google' | 'mapbox' | 'openstreetmap'; appKey: string };
  sms: { autoSendAvailable: boolean; pricePerSmsUgx: number };
  legal: { termsUrl: string; privacyUrl: string };
  defaultPlanId: string;
}

export const defaultGateways: Gateway[] = [
  { id: 'mtn', name: 'MTN Mobile Money', enabled: true, payCode: '', accountName: 'Victorbee Technologies', instructions: 'Dial *165*3#, choose MoMoPay, enter the pay code and the amount.' },
  { id: 'airtel', name: 'Airtel Money', enabled: true, payCode: '', accountName: 'Victorbee Technologies', instructions: 'Dial *185*9#, choose Pay Bill, enter the business number and the amount.' },
  { id: 'card', name: 'Visa or Mastercard', enabled: false, payCode: '', accountName: 'Victorbee Technologies', instructions: 'Pay by card through the secure payment page.' },
  { id: 'bank', name: 'Bank transfer', enabled: false, payCode: '', accountName: 'Victorbee Technologies', instructions: 'Send to the account number and use the farm name as the reference.' },
];

/** This web build (yyyymmddhhmm, set in next.config.ts); 0 in development. */
export const WEB_BUILD = Number(process.env.NEXT_PUBLIC_WEB_BUILD ?? 0);

export const SUPPORT_PHONE = '+256 793 128 137';

export const defaultConfig: PlatformConfig = {
  trialDays: 7,
  maintenance: { on: false, message: 'FarmTap is being updated. Please try again in a few minutes.' },
  app: {
    android: { minVersion: '0.0.0', latestVersion: '0.0.0', storeUrl: '' },
    ios: { minVersion: '0.0.0', latestVersion: '0.0.0', storeUrl: '' },
    updateMessage: 'A new FarmTap is ready. Update to keep recording.',
  },
  web: { minBuild: 0, message: 'FarmTap has been updated. Refresh the page to get the new version.' },
  support: { phone: SUPPORT_PHONE, whatsapp: SUPPORT_PHONE, email: '', hours: 'Monday to Saturday, 8 am to 6 pm' },
  signup: { open: true, sectors: ['dairy'], closedMessage: 'New sign-ups are paused. Contact FarmTap support.' },
  features: { ...defaultFeatures },
  payments: { gateways: defaultGateways, manualNote: 'After paying, send the transaction ID to FarmTap support on WhatsApp.' },
  maps: { provider: 'none', appKey: '' },
  sms: { autoSendAvailable: false, pricePerSmsUgx: 35 },
  legal: { termsUrl: '', privacyUrl: '' },
  defaultPlanId: '',
};

const obj = (v: unknown): Record<string, unknown> => (v && typeof v === 'object' && !Array.isArray(v) ? (v as Record<string, unknown>) : {});
const str = (v: unknown, d: string) => (typeof v === 'string' ? v : d);
const numv = (v: unknown, d: number) => (typeof v === 'number' && Number.isFinite(v) ? v : d);
const bool = (v: unknown, d: boolean) => (typeof v === 'boolean' ? v : d);

function version(v: unknown, d: AppVersion): AppVersion {
  const o = obj(v);
  return { minVersion: str(o.minVersion, d.minVersion), latestVersion: str(o.latestVersion, d.latestVersion), storeUrl: str(o.storeUrl, d.storeUrl) };
}

function features(v: unknown): FeatureMap {
  const o = obj(v);
  const out: FeatureMap = {};
  for (const f of featureList) if (typeof o[f.key] === 'boolean') out[f.key] = o[f.key] as boolean;
  return out;
}

/** Reads platform/config; anything missing or wrong falls back to the default. */
export function configFromDoc(data: unknown): PlatformConfig {
  const d = obj(data);
  const D = defaultConfig;
  const m = obj(d.maintenance);
  const app = obj(d.app);
  const web = obj(d.web);
  const sup = obj(d.support);
  const sign = obj(d.signup);
  const pay = obj(d.payments);
  const maps = obj(d.maps);
  const sms = obj(d.sms);
  const legal = obj(d.legal);
  const gws = Array.isArray(pay.gateways) ? pay.gateways.map(obj) : null;
  const provider = str(maps.provider, D.maps.provider);
  return {
    trialDays: Math.max(1, Math.round(numv(d.trialDays, D.trialDays))),
    maintenance: { on: bool(m.on, false), message: str(m.message, D.maintenance.message) },
    app: { android: version(app.android, D.app.android), ios: version(app.ios, D.app.ios), updateMessage: str(app.updateMessage, D.app.updateMessage) },
    web: { minBuild: numv(web.minBuild, 0), message: str(web.message, D.web.message) },
    support: {
      phone: str(sup.phone, D.support.phone) || D.support.phone,
      whatsapp: str(sup.whatsapp, D.support.whatsapp) || D.support.whatsapp,
      email: str(sup.email, ''),
      hours: str(sup.hours, D.support.hours),
    },
    signup: {
      open: bool(sign.open, true),
      sectors: Array.isArray(sign.sectors) ? sign.sectors.filter((s): s is string => typeof s === 'string') : D.signup.sectors,
      closedMessage: str(sign.closedMessage, D.signup.closedMessage),
    },
    features: { ...defaultFeatures, ...features(d.features) },
    payments: {
      gateways: gws
        ? gws.map((g, i) => ({
            id: str(g.id, `gw${i}`),
            name: str(g.name, 'Payment'),
            enabled: bool(g.enabled, false),
            payCode: str(g.payCode, ''),
            accountName: str(g.accountName, ''),
            instructions: str(g.instructions, ''),
          }))
        : D.payments.gateways,
      manualNote: str(pay.manualNote, D.payments.manualNote),
    },
    maps: { provider: (['none', 'google', 'mapbox', 'openstreetmap'].includes(provider) ? provider : 'none') as PlatformConfig['maps']['provider'], appKey: str(maps.appKey, '') },
    sms: { autoSendAvailable: bool(sms.autoSendAvailable, false), pricePerSmsUgx: numv(sms.pricePerSmsUgx, D.sms.pricePerSmsUgx) },
    legal: { termsUrl: str(legal.termsUrl, ''), privacyUrl: str(legal.privacyUrl, '') },
    defaultPlanId: str(d.defaultPlanId, ''),
  };
}

/** "1.2.10" vs "1.2.9": -1, 0 or 1. Missing parts count as 0; "+build" is ignored. */
export function compareVersions(a: string, b: string): number {
  const pa = a.split('+')[0].split('.').map((x) => parseInt(x, 10) || 0);
  const pb = b.split('+')[0].split('.').map((x) => parseInt(x, 10) || 0);
  for (let i = 0; i < Math.max(pa.length, pb.length); i++) {
    const d = (pa[i] ?? 0) - (pb[i] ?? 0);
    if (d) return d < 0 ? -1 : 1;
  }
  return 0;
}

// ---------------------------------------------------------------- Plans

export interface Plan {
  id: string;
  name: string;
  priceUgx: number;
  months: number;
  description: string;
  features: FeatureMap;
  smsCreditsPerMonth: number;
  maxWorkers: number;
  farmLimit: number;
  active: boolean;
  sort: number;
}

export function planFromDoc(id: string, data: unknown): Plan {
  const d = obj(data);
  return {
    id,
    name: str(d.name, 'Plan'),
    priceUgx: Math.max(0, Math.round(numv(d.priceUgx, 0))),
    months: Math.max(1, Math.round(numv(d.months, 1))),
    description: str(d.description, ''),
    features: features(d.features),
    smsCreditsPerMonth: Math.max(0, Math.round(numv(d.smsCreditsPerMonth, 0))),
    maxWorkers: Math.max(0, Math.round(numv(d.maxWorkers, 0))),
    farmLimit: Math.max(1, Math.round(numv(d.farmLimit, 1))),
    active: bool(d.active, true),
    sort: numv(d.sort, 0),
  };
}

/** Monthly value of a plan: a 12-month plan at 600,000 counts 50,000 a month. */
export const monthlyValue = (p: Pick<Plan, 'priceUgx' | 'months'>) => Math.round(p.priceUgx / Math.max(1, p.months));

/** The plan binding rule 3 starts with, until Victor sets his own. */
export const starterPlan: Plan = {
  id: 'standard',
  name: 'Standard',
  priceUgx: 70000,
  months: 1,
  description: 'One farm or centre, all dairy features.',
  features: {},
  smsCreditsPerMonth: 0,
  maxWorkers: 0,
  farmLimit: 1,
  active: true,
  sort: 0,
};

export interface SmsPackage {
  id: string;
  name: string;
  credits: number;
  priceUgx: number;
  active: boolean;
}

export function smsPackageFromDoc(id: string, data: unknown): SmsPackage {
  const d = obj(data);
  return {
    id,
    name: str(d.name, 'SMS package'),
    credits: Math.max(0, Math.round(numv(d.credits, 0))),
    priceUgx: Math.max(0, Math.round(numv(d.priceUgx, 0))),
    active: bool(d.active, true),
  };
}

// ---------------------------------------------------------------- Announcements

export interface Announcement {
  id: string;
  title: string;
  body: string;
  level: 'info' | 'warn';
  audience: { kind: 'all' | 'sector' | 'farm'; sector: string; tenantId: string };
  startsAt: Date | null;
  endsAt: Date | null;
  active: boolean;
  createdAt: Date | null;
}

export function announcementFromDoc(id: string, data: unknown): Announcement {
  const d = obj(data);
  const a = obj(d.audience);
  const kind = str(a.kind, 'all');
  return {
    id,
    title: str(d.title, ''),
    body: str(d.body, ''),
    level: d.level === 'warn' ? 'warn' : 'info',
    audience: { kind: (['all', 'sector', 'farm'].includes(kind) ? kind : 'all') as Announcement['audience']['kind'], sector: str(a.sector, ''), tenantId: str(a.tenantId, '') },
    startsAt: parseDate(d.startsAt),
    endsAt: parseDate(d.endsAt),
    active: bool(d.active, true),
    createdAt: parseDate(d.createdAt),
  };
}

/** Is this announcement for this farm, right now? */
export function announcementFor(a: Announcement, farm: { id: string; sector: string }, now: Date): boolean {
  if (!a.active) return false;
  if (a.startsAt && now < a.startsAt) return false;
  if (a.endsAt && now >= a.endsAt) return false;
  if (a.audience.kind === 'sector') return a.audience.sector === farm.sector;
  if (a.audience.kind === 'farm') return a.audience.tenantId === farm.id;
  return true;
}

// ---------------------------------------------------------------- Admin staff

export const permissionList = [
  { key: 'farms', label: 'Farms', hint: 'Review, suspend, plans, feature switches' },
  { key: 'finance', label: 'Money', hint: 'Payments, plans and prices, SMS packages' },
  { key: 'users', label: 'Users', hint: 'Disable accounts, reset card PINs, revoke cards' },
  { key: 'support', label: 'Support', hint: 'Look up farms and people, support notes' },
  { key: 'messages', label: 'Announcements', hint: 'Send notices to farms' },
  { key: 'settings', label: 'App settings', hint: 'Versions, maintenance, sign-up, feature defaults' },
  { key: 'secrets', label: 'API keys', hint: 'Set SMS, payment and map keys' },
  { key: 'staff', label: 'Staff', hint: 'Invite and turn off admin staff' },
  { key: 'audit', label: 'Audit log', hint: 'See every change made here' },
] as const;

export type Permission = (typeof permissionList)[number]['key'];

export const rolePresets: Record<string, { label: string; perms: Permission[] }> = {
  finance: { label: 'Finance', perms: ['finance', 'support'] },
  support: { label: 'Support', perms: ['support', 'users'] },
  manager: { label: 'Operations manager', perms: ['farms', 'finance', 'users', 'support', 'messages', 'audit'] },
  viewer: { label: 'Viewer', perms: ['support'] },
  custom: { label: 'Custom', perms: [] },
};

export interface AdminMe {
  uid: string;
  role: string;
  perms: Permission[];
  active: boolean;
  name: string;
  email: string;
}

export const adminCan = (me: AdminMe | null | undefined, p: Permission) =>
  !!me && me.active && (me.role === 'owner' || me.perms.includes(p));

// ---------------------------------------------------------------- Secrets

/** API keys the server code reads. Others can be added by name in the panel. */
export const secretList = [
  { key: 'sms_api_key', group: 'SMS', label: "Africa's Talking API key or Twilio auth token" },
  { key: 'mtn_subscription_key', group: 'MTN MoMo', label: 'MoMo API subscription key (Ocp-Apim)' },
  { key: 'mtn_api_user', group: 'MTN MoMo', label: 'MoMo API user (UUID)' },
  { key: 'mtn_api_key', group: 'MTN MoMo', label: 'MoMo API key' },
  { key: 'airtel_client_id', group: 'Airtel Money', label: 'Client ID' },
  { key: 'airtel_client_secret', group: 'Airtel Money', label: 'Client secret' },
  { key: 'flutterwave_secret_key', group: 'Card (Flutterwave)', label: 'Secret key' },
  { key: 'flutterwave_webhook_hash', group: 'Card (Flutterwave)', label: 'Webhook secret hash' },
  { key: 'maps_server_key', group: 'Maps', label: 'Server key (geocoding, district lookup)' },
] as const;

/** "sk_live_abcd1234" -> "••••1234". Never shows more than four characters. */
export function maskSecret(value: string): string {
  const v = value.trim();
  if (!v) return '';
  return `••••${v.slice(-4)}`;
}

export const secretNameOk = (name: string) => /^[a-z][a-z0-9_]{2,48}$/.test(name);
