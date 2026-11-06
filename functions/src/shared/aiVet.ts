// GENERATED from shared/ by `node shared/sync.mjs`. Edit the file in shared/, not this copy.
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
  { key: 'abortion', label: 'Aborted (lost a calf before time)', group: 'Calving' },
  { key: 'prolapse', label: 'Womb or vagina pushed out', group: 'Calving' },
  { key: 'hairLoss', label: 'Patches of hair loss or scabs', group: 'Skin' },
  { key: 'itching', label: 'Rubbing and scratching a lot', group: 'Skin' },
  { key: 'ringLesions', label: 'Round grey-white crusty patches on the skin', group: 'Skin' },
  { key: 'staggering', label: 'Staggering or trembling, often on lush green grass', group: 'Body' },
  { key: 'weakRough', label: 'Weak, thin, rough coat, fever that comes and goes', group: 'Body' },
  { key: 'swollenBrisket', label: 'Swelling of the brisket or under the belly or throat', group: 'Body' },
  { key: 'sunkenEyes', label: 'Sunken eyes, skin stays up when pinched (dehydration)', group: 'Body' },
  { key: 'grainOverload', label: 'Ate a lot of grain, maize or bran, now dull with loose dung', group: 'Feeding' },
  { key: 'eatingStrange', label: 'Chewing wood, bones or soil', group: 'Feeding' },
  { key: 'swollenJoint', label: 'Swollen, hot or painful joint', group: 'Legs' },
  { key: 'dungWorms', label: 'Worms or white segments seen in the dung', group: 'Dung' },
  { key: 'navelSwollen', label: 'Calf: swollen, wet or smelly navel', group: 'Calves' },
  { key: 'calfScours', label: 'Calf: watery dung and weak', group: 'Calves' },
  { key: 'calfNotSuckling', label: 'Calf: not suckling, cold or cannot stand', group: 'Calves' },
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
  { key: 'brucellosis', name: 'Brucellosis (can cause abortion, can spread to people)', main: ['abortion'], other: ['afterbirthStuck', 'swollenJoint', 'badDischarge'], notifiable: true, urgency: 'high', advice: 'Keep the aborted calf and afterbirth away from people and dogs, wear gloves, do not drink raw milk from her, and report to the District Veterinary Officer.' },
  { key: 'trypano', name: 'Trypanosomiasis (nagana, spread by tsetse flies)', main: ['weakRough'], other: ['paleGums', 'weightLoss', 'eatingLess', 'lymphSwollen', 'milkDrop'], fever: true, urgency: 'high', advice: 'Keep her in shade with water. Tell the vet if you have seen tsetse flies in the area.' },
  { key: 'heartwater', name: 'Heartwater (tick-borne, affects the nerves and chest)', main: ['swollenBrisket', 'strangeBehaviour'], other: ['breathingHard', 'ticksMany', 'diarrhoea', 'notEating'], fever: true, urgency: 'high', advice: 'Keep her calm and in shade, and check the herd for ticks. Treatment works only if given early.' },
  { key: 'tetany', name: 'Grass tetany (low magnesium)', main: ['staggering'], other: ['strangeBehaviour', 'downCannotRise', 'notEating'], urgency: 'critical', advice: 'Emergency. Keep her calm, do not chase her, and call the vet now. Tell the vet what pasture she was on.' },
  { key: 'acidosis', name: 'Grain overload (rumen acidosis)', main: ['grainOverload'], other: ['diarrhoea', 'eatingLess', 'lame', 'breathingHard', 'notEating'], urgency: 'high', advice: 'Stop all grain and concentrate feed, give hay or dry grass and clean water, and call the vet today.' },
  { key: 'ringworm', name: 'Ringworm (a skin fungus)', main: ['ringLesions'], other: ['hairLoss', 'itching'], urgency: 'low', advice: 'Keep her apart from calves and from people with skin problems, and wash your hands after touching her.' },
  { key: 'mange', name: 'Mange or lice (skin parasites)', main: ['itching'], other: ['hairLoss', 'ticksMany', 'weightLoss'], urgency: 'medium', advice: 'Keep her apart from the herd, and ask the vet which parasite it is before using any product.' },
  { key: 'calfScours', name: 'Calf scours (diarrhoea in a young calf)', main: ['calfScours'], other: ['sunkenEyes', 'calfNotSuckling', 'notEating'], urgency: 'high', advice: 'Calves lose water fast. Keep her warm, dry and clean, keep her drinking, and call the vet today.' },
  { key: 'navelIll', name: 'Navel or joint ill in a calf', main: ['navelSwollen'], other: ['swollenJoint', 'calfNotSuckling', 'lame'], fever: true, urgency: 'high', advice: 'Keep the calf clean and dry and away from others, and call the vet today.' },
  { key: 'prolapse', name: 'Prolapse (womb or vagina pushed out)', main: ['prolapse'], other: ['calvingStraining'], urgency: 'critical', advice: 'Emergency. Keep the tissue clean and moist, stop her lying on it, and call the vet now. Do not try to push it back yourself.' },
  { key: 'mineral', name: 'Mineral shortage', main: ['eatingStrange'], other: ['weightLoss', 'milkDrop', 'eatingLess'], urgency: 'low', advice: 'Ask the vet or your extension officer about a mineral lick and the quality of her feed.' },
  { key: 'jointInfection', name: 'Joint infection or injury', main: ['swollenJoint'], other: ['lame', 'woundBleeding'], urgency: 'medium', advice: 'Keep her on soft, dry ground and rest her. See the vet if the joint stays swollen.' },
  { key: 'dehydration', name: 'Dehydration (needs water urgently)', main: ['sunkenEyes'], other: ['diarrhoea', 'notEating', 'weightLoss'], urgency: 'high', advice: 'Give her clean water to drink slowly, keep her in shade, and call the vet today.' },
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
  { sign: 'prolapse', text: 'Womb or vagina pushed out' },
  { sign: 'staggering', text: 'Staggering or trembling' },
  { sign: 'sunkenEyes', text: 'Sunken eyes (dehydration)' },
  { sign: 'calfNotSuckling', text: 'Calf cold, not suckling or cannot stand' },
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
  kind: 'vet' | 'screening' | 'chat';
  signs: SignKey[];
  tempC: number | null;
  daysSinceCalving: number | null;
  days: number | null;
  note: string | null;
  photo: string | null;
  /** Chat only: what the farmer asked, and the start of the answer. */
  question?: string;
  summary?: string;
  risk: Severity;
  possible: string[];
  redFlags: string[];
  callVet: VetResult['callVet'] | null;
  /** The engine version that made it, so old results can be re-read later. */
  engine: string;
  /** Screening only: the model used, or null when none is installed. */
  model: string | null;
  at: string;
}

export const VET_ENGINE = 'vet-guide-2';
