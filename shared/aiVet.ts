// FarmTap AI engine — Veterinary Assistant (decision 0025, ROADMAP AI-03).
//
// A fixed, reviewable guide, not a model and not a diagnosis. It matches
// what the farmer saw against the common signs of common cattle problems in
// East Africa (standard veterinary teaching: normal adult temperature about
// 38.0–39.3 °C) and lists urgent warning signs. It never names a drug or a
// dose, and every result says to call the vet. Any change to this table
// should be checked by a vet before it is released.

import type { Severity } from './aiCore.ts';

export const signs = [
  { key: 'downCannotRise', label: 'Lying down, cannot get up', group: 'Body' },
  { key: 'leftSideSwollen', label: 'Left side swollen like a drum', group: 'Body' },
  { key: 'breathingHard', label: 'Breathing fast or with difficulty', group: 'Breathing' },
  { key: 'cough', label: 'Coughing', group: 'Breathing' },
  { key: 'noseDischarge', label: 'Discharge or froth from the nose', group: 'Breathing' },
  { key: 'notEating', label: 'Not eating', group: 'Feeding' },
  { key: 'eatingLess', label: 'Eating less than usual', group: 'Feeding' },
  { key: 'milkDrop', label: 'Sudden drop in milk', group: 'Milk' },
  { key: 'udderSwollen', label: 'Udder quarter swollen, hot or hard', group: 'Milk' },
  { key: 'milkClots', label: 'Clots, flakes, blood or water in the milk', group: 'Milk' },
  { key: 'drooling', label: 'Drooling a lot', group: 'Mouth' },
  { key: 'mouthBlisters', label: 'Blisters or sores in the mouth, feet or teats', group: 'Mouth' },
  { key: 'skinLumps', label: 'Firm round lumps on the skin', group: 'Skin' },
  { key: 'woundBleeding', label: 'Wound that is bleeding a lot', group: 'Skin' },
  { key: 'wound', label: 'Wound or injury', group: 'Skin' },
  { key: 'ticksMany', label: 'Many ticks', group: 'Skin' },
  { key: 'lymphSwollen', label: 'Swellings below the ear or in front of the shoulder', group: 'Skin' },
  { key: 'paleGums', label: 'Pale or yellow gums and eyes', group: 'Body' },
  { key: 'redUrine', label: 'Red or dark brown urine', group: 'Body' },
  { key: 'diarrhoea', label: 'Diarrhoea', group: 'Dung' },
  { key: 'bloodDung', label: 'Blood in the dung', group: 'Dung' },
  { key: 'lame', label: 'Limping', group: 'Legs' },
  { key: 'footSmell', label: 'Swelling or bad smell between the claws', group: 'Legs' },
  { key: 'legMuscleSwollen', label: 'Swollen leg muscle that crackles when pressed', group: 'Legs' },
  { key: 'eyeWatery', label: 'Watery, cloudy or closed eye', group: 'Eyes' },
  { key: 'weightLoss', label: 'Losing weight', group: 'Body' },
  { key: 'jawSwelling', label: 'Soft swelling under the jaw', group: 'Body' },
  { key: 'strangeBehaviour', label: 'Strange or aggressive behaviour, shaking or fits', group: 'Body' },
  { key: 'bloodOpenings', label: 'Blood from the nose, mouth or anus', group: 'Body' },
  { key: 'calvingStraining', label: 'Straining to calve for more than 1 hour', group: 'Calving' },
  { key: 'afterbirthStuck', label: 'Afterbirth not out a day after calving', group: 'Calving' },
  { key: 'badDischarge', label: 'Bad-smelling discharge after calving', group: 'Calving' },
  { key: 'coldEars', label: 'Cold ears, wobbly, soon after calving', group: 'Calving' },
  { key: 'otherDied', label: 'Another animal died suddenly', group: 'Herd' },
] as const;
export type SignKey = (typeof signs)[number]['key'];

interface Condition {
  key: string;
  name: string;
  /** Signs that point to it; [main] signs weigh double. */
  main: SignKey[];
  other: SignKey[];
  fever?: boolean;
  /** Days after calving when it is likely (inclusive). */
  afterCalving?: [number, number];
  notifiable?: boolean;
  urgency: Severity;
  advice: string;
}

/** Common problems. Advice is what to do before the vet comes; never a drug or dose. */
const conditions: Condition[] = [
  { key: 'mastitis', name: 'Mastitis (udder infection)', main: ['udderSwollen', 'milkClots'], other: ['milkDrop', 'eatingLess'], fever: true, urgency: 'high', advice: 'Milk her last, into a separate container, and do not sell that milk. Keep her bedding clean and dry.' },
  { key: 'ecf', name: 'East Coast Fever or another tick fever', main: ['lymphSwollen', 'ticksMany'], other: ['breathingHard', 'noseDischarge', 'cough', 'notEating', 'weightLoss', 'milkDrop'], fever: true, urgency: 'high', advice: 'Treatment works best early. Keep her in shade with water, and check the rest of the herd for ticks.' },
  { key: 'redwater', name: 'Redwater or gall sickness (tick-borne blood disease)', main: ['paleGums', 'redUrine'], other: ['ticksMany', 'notEating', 'milkDrop', 'weightLoss'], fever: true, urgency: 'high', advice: 'Keep her calm and in shade with water; do not drive or chase her.' },
  { key: 'fmd', name: 'Foot and mouth disease', main: ['mouthBlisters', 'drooling'], other: ['lame', 'milkDrop', 'notEating'], fever: true, notifiable: true, urgency: 'high', advice: 'Keep the herd in, stop moving or selling animals and milk to other farms, and report to the District Veterinary Officer.' },
  { key: 'lsd', name: 'Lumpy skin disease', main: ['skinLumps'], other: ['lymphSwollen', 'milkDrop', 'noseDischarge', 'notEating'], fever: true, notifiable: true, urgency: 'high', advice: 'Keep her apart from the herd, control flies and ticks, and report to the District Veterinary Officer.' },
  { key: 'bloat', name: 'Bloat', main: ['leftSideSwollen'], other: ['breathingHard', 'notEating'], urgency: 'critical', advice: 'Emergency. Stand her up and walk her slowly; keep her off lush legumes. Call the vet now.' },
  { key: 'milkFever', name: 'Milk fever (low calcium after calving)', main: ['coldEars', 'downCannotRise'], other: ['notEating'], afterCalving: [0, 3], urgency: 'critical', advice: 'Emergency. Prop her up on her chest so she does not lie flat on her side. Call the vet now.' },
  { key: 'pneumonia', name: 'Pneumonia or a chest infection', main: ['cough', 'breathingHard'], other: ['noseDischarge', 'notEating', 'eatingLess'], fever: true, urgency: 'high', advice: 'Move her to a sheltered place with fresh air and water.' },
  { key: 'footRot', name: 'Foot rot or a hoof problem', main: ['lame', 'footSmell'], other: ['milkDrop', 'eatingLess'], urgency: 'medium', advice: 'Clean and look at the foot. Keep her on dry ground.' },
  { key: 'worms', name: 'Worms or another gut problem', main: ['diarrhoea', 'weightLoss'], other: ['jawSwelling', 'eatingLess', 'paleGums'], urgency: 'medium', advice: 'Keep her drinking. A dung test tells the vet which worms, if any.' },
  { key: 'gutBleed', name: 'Gut infection with bleeding', main: ['bloodDung', 'diarrhoea'], other: ['notEating', 'weightLoss'], fever: true, urgency: 'high', advice: 'Keep her apart and drinking. Young animals weaken fast.' },
  { key: 'retained', name: 'Retained afterbirth or womb infection', main: ['afterbirthStuck', 'badDischarge'], other: ['notEating', 'milkDrop'], afterCalving: [0, 21], fever: true, urgency: 'high', advice: 'Do not pull the afterbirth out. Keep her clean.' },
  { key: 'ketosis', name: 'Ketosis (energy shortage in early lactation)', main: ['eatingLess', 'milkDrop'], other: ['weightLoss', 'notEating'], afterCalving: [5, 60], urgency: 'medium', advice: 'Make sure she has good feed and water, and ask the vet to test her.' },
  { key: 'pinkeye', name: 'Pinkeye (eye infection)', main: ['eyeWatery'], other: [], urgency: 'medium', advice: 'Keep her out of the sun and dust, and control flies.' },
  { key: 'blackquarter', name: 'Blackquarter', main: ['legMuscleSwollen'], other: ['lame', 'otherDied', 'notEating'], fever: true, urgency: 'critical', advice: 'Emergency, often fatal in young cattle. Call the vet now about the rest of the herd.' },
  { key: 'anthrax', name: 'Anthrax (sudden death disease)', main: ['bloodOpenings', 'otherDied'], other: ['breathingHard'], fever: true, notifiable: true, urgency: 'critical', advice: 'Do not open, skin or eat a dead animal, and keep people and dogs away. Report to the District Veterinary Officer at once.' },
  { key: 'rabies', name: 'Rabies or another brain disease', main: ['strangeBehaviour'], other: ['drooling', 'notEating'], notifiable: true, urgency: 'critical', advice: 'Do not put a hand in her mouth. Keep people away and report to the District Veterinary Officer.' },
  { key: 'wound', name: 'Wound or injury', main: ['wound'], other: ['lame', 'woundBleeding'], urgency: 'medium', advice: 'Clean it with clean water and keep flies off.' },
];

/** Signs that need a vet now, whatever the cause. */
const redFlags: { sign?: SignKey; test?: (i: VetInput) => boolean; text: string }[] = [
  { sign: 'downCannotRise', text: 'Cannot get up' },
  { sign: 'leftSideSwollen', text: 'Swollen left side (bloat can kill within hours)' },
  { sign: 'calvingStraining', text: 'Straining to calve for over an hour' },
  { sign: 'woundBleeding', text: 'Heavy bleeding' },
  { sign: 'bloodOpenings', text: 'Blood from the nose, mouth or anus' },
  { sign: 'strangeBehaviour', text: 'Strange behaviour or fits' },
  { sign: 'otherDied', text: 'Another animal died suddenly' },
  { sign: 'legMuscleSwollen', text: 'Crackling swollen muscle' },
  { test: (i) => i.tempC != null && i.tempC >= 41, text: 'Very high temperature (41 °C or more)' },
  { test: (i) => i.tempC != null && i.tempC < 37.5, text: 'Low temperature (below 37.5 °C)' },
  { test: (i) => i.signs.includes('breathingHard') && i.signs.includes('notEating'), text: 'Hard breathing and not eating' },
];

export interface VetInput {
  signs: SignKey[];
  /** Rectal temperature, °C, if taken. */
  tempC?: number | null;
  /** Days since she calved, if she calved recently. */
  daysSinceCalving?: number | null;
  /** How many days the signs have been seen. */
  days?: number | null;
}

export interface VetResult {
  risk: Severity;
  fever: 'none' | 'fever' | 'high' | 'low' | 'notTaken';
  redFlags: string[];
  possible: { key: string; name: string; matched: string[]; notifiable: boolean; advice: string }[];
  callVet: 'now' | 'today' | 'soon';
  steps: string[];
  /** Always shown with every result. */
  disclaimer: string;
}

export const vetDisclaimer =
  'This is a guide to possible causes, not a diagnosis. Only a vet can examine and diagnose your animal. FarmTap never suggests drugs or doses.';

const labelOf = (k: SignKey) => signs.find((s) => s.key === k)?.label ?? k;
const rank: Record<Severity, number> = { critical: 0, high: 1, medium: 2, low: 3 };

export function assess(input: VetInput): VetResult {
  const set = new Set(input.signs);
  const t = input.tempC ?? null;
  const fever: VetResult['fever'] = t == null ? 'notTaken' : t < 37.5 ? 'low' : t >= 40.5 ? 'high' : t >= 39.5 ? 'fever' : 'none';
  const flags = redFlags.filter((f) => (f.sign ? set.has(f.sign) : f.test!(input))).map((f) => f.text);
  const scored = conditions
    .map((c) => {
      const main = c.main.filter((s) => set.has(s));
      const other = c.other.filter((s) => set.has(s));
      let score = main.length * 2 + other.length;
      if (c.fever && (fever === 'fever' || fever === 'high')) score += 1;
      if (c.afterCalving) {
        const dsc = input.daysSinceCalving;
        if (dsc != null && dsc >= c.afterCalving[0] && dsc <= c.afterCalving[1]) score += 2;
        else if (c.key === 'milkFever' || c.key === 'ketosis' || c.key === 'retained') score -= 2;
      }
      return { c, main, other, score };
    })
    // A condition needs at least one of its main signs to be listed at all.
    .filter((x) => x.main.length > 0 && x.score >= 2)
    .sort((a, b) => b.score - a.score || rank[a.c.urgency] - rank[b.c.urgency])
    .slice(0, 3);
  let risk: Severity = flags.length ? 'critical' : 'low';
  for (const x of scored) if (rank[x.c.urgency] < rank[risk]) risk = x.c.urgency;
  if (fever === 'high' && rank[risk] > rank.high) risk = 'high';
  if (fever === 'fever' && rank[risk] > rank.medium) risk = 'medium';
  if (set.has('notEating') && (input.days ?? 0) >= 1 && rank[risk] > rank.high) risk = 'high';
  if (!scored.length && set.size && rank[risk] > rank.medium) risk = 'medium';
  const callVet: VetResult['callVet'] = risk === 'critical' ? 'now' : risk === 'high' ? 'today' : 'soon';
  const steps = [
    ...(risk === 'critical' ? ['Call your vet now.'] : risk === 'high' ? ['Call your vet today.'] : ['Ask your vet at the next visit, sooner if she gets worse.']),
    ...(fever === 'notTaken' ? ['Take her temperature with a thermometer if you can. Normal is about 38.0 to 39.3 °C.'] : []),
    'Keep her apart from the herd until she has been seen, with shade, clean water and feed.',
    ...scored.map((x) => x.c.advice),
    ...(scored.some((x) => x.c.notifiable) ? ['This could be a disease the law says must be reported. Tell the District Veterinary Officer.'] : []),
    'Do not sell her milk or meat until the vet says it is safe.',
  ];
  return {
    risk,
    fever,
    redFlags: flags,
    possible: scored.map((x) => ({ key: x.c.key, name: x.c.name, matched: [...x.main, ...x.other].map(labelOf), notifiable: !!x.c.notifiable, advice: x.c.advice })),
    callVet,
    steps: [...new Set(steps)],
    disclaimer: vetDisclaimer,
  };
}

/** healthAssessments body (append-only, decision 0025). */
export interface HealthAssessmentBody {
  animalId: string;
  kind: 'vet' | 'screening';
  signs: SignKey[];
  tempC: number | null;
  daysSinceCalving: number | null;
  days: number | null;
  note: string | null;
  photo: string | null;
  risk: Severity;
  possible: string[];
  redFlags: string[];
  callVet: VetResult['callVet'];
  /** The engine version that made it, so old results can be re-read later. */
  engine: string;
  /** Screening only: the model used, or null when none is installed. */
  model: string | null;
  at: string;
}

export const VET_ENGINE = 'vet-guide-1';
