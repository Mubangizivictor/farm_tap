// FarmTap AI engine: Veterinary Assistant (decision 0025). Hand port of
// shared/aiVet.ts.
//
// A fixed, reviewable guide, not a model and not a diagnosis. It matches
// what the farmer saw against the common signs of common cattle problems in
// East Africa (normal adult temperature about 38.0-39.3 °C) and lists urgent
// warning signs. It never names a drug or a dose, and every result says to
// call the vet. Any change to this table must be checked by a vet before it
// is released.
import 'package:farm_tap/core/ai/ai_core.dart';

class VetSign {
  const new(this.key, this.label, this.group);
  final String key;
  final String label;
  final String group;
}

const signs = <VetSign>[
  VetSign('downCannotRise', 'Lying down, cannot get up', 'Body'),
  VetSign('leftSideSwollen', 'Left side swollen like a drum', 'Body'),
  VetSign('breathingHard', 'Breathing fast or with difficulty', 'Breathing'),
  VetSign('cough', 'Coughing', 'Breathing'),
  VetSign('noseDischarge', 'Discharge or froth from the nose', 'Breathing'),
  VetSign('notEating', 'Not eating', 'Feeding'),
  VetSign('eatingLess', 'Eating less than usual', 'Feeding'),
  VetSign('milkDrop', 'Sudden drop in milk', 'Milk'),
  VetSign('udderSwollen', 'Udder quarter swollen, hot or hard', 'Milk'),
  VetSign('milkClots', 'Clots, flakes, blood or water in the milk', 'Milk'),
  VetSign('drooling', 'Drooling a lot', 'Mouth'),
  VetSign('mouthBlisters', 'Blisters or sores in the mouth, feet or teats', 'Mouth'),
  VetSign('skinLumps', 'Firm round lumps on the skin', 'Skin'),
  VetSign('woundBleeding', 'Wound that is bleeding a lot', 'Skin'),
  VetSign('wound', 'Wound or injury', 'Skin'),
  VetSign('ticksMany', 'Many ticks', 'Skin'),
  VetSign('lymphSwollen', 'Swellings below the ear or in front of the shoulder', 'Skin'),
  VetSign('paleGums', 'Pale or yellow gums and eyes', 'Body'),
  VetSign('redUrine', 'Red or dark brown urine', 'Body'),
  VetSign('diarrhoea', 'Diarrhoea', 'Dung'),
  VetSign('bloodDung', 'Blood in the dung', 'Dung'),
  VetSign('lame', 'Limping', 'Legs'),
  VetSign('footSmell', 'Swelling or bad smell between the claws', 'Legs'),
  VetSign('legMuscleSwollen', 'Swollen leg muscle that crackles when pressed', 'Legs'),
  VetSign('eyeWatery', 'Watery, cloudy or closed eye', 'Eyes'),
  VetSign('weightLoss', 'Losing weight', 'Body'),
  VetSign('jawSwelling', 'Soft swelling under the jaw', 'Body'),
  VetSign('strangeBehaviour', 'Strange or aggressive behaviour, shaking or fits', 'Body'),
  VetSign('bloodOpenings', 'Blood from the nose, mouth or anus', 'Body'),
  VetSign('calvingStraining', 'Straining to calve for more than 1 hour', 'Calving'),
  VetSign('afterbirthStuck', 'Afterbirth not out a day after calving', 'Calving'),
  VetSign('badDischarge', 'Bad-smelling discharge after calving', 'Calving'),
  VetSign('coldEars', 'Cold ears, wobbly, soon after calving', 'Calving'),
  VetSign('otherDied', 'Another animal died suddenly', 'Herd'),
  VetSign('abortion', 'Aborted (lost a calf before time)', 'Calving'),
  VetSign('prolapse', 'Womb or vagina pushed out', 'Calving'),
  VetSign('hairLoss', 'Patches of hair loss or scabs', 'Skin'),
  VetSign('itching', 'Rubbing and scratching a lot', 'Skin'),
  VetSign('ringLesions', 'Round grey-white crusty patches on the skin', 'Skin'),
  VetSign('staggering', 'Staggering or trembling, often on lush green grass', 'Body'),
  VetSign('weakRough', 'Weak, thin, rough coat, fever that comes and goes', 'Body'),
  VetSign('swollenBrisket', 'Swelling of the brisket or under the belly or throat', 'Body'),
  VetSign('sunkenEyes', 'Sunken eyes, skin stays up when pinched (dehydration)', 'Body'),
  VetSign('grainOverload', 'Ate a lot of grain, maize or bran, now dull with loose dung', 'Feeding'),
  VetSign('eatingStrange', 'Chewing wood, bones or soil', 'Feeding'),
  VetSign('swollenJoint', 'Swollen, hot or painful joint', 'Legs'),
  VetSign('dungWorms', 'Worms or white segments seen in the dung', 'Dung'),
  VetSign('navelSwollen', 'Calf: swollen, wet or smelly navel', 'Calves'),
  VetSign('calfScours', 'Calf: watery dung and weak', 'Calves'),
  VetSign('calfNotSuckling', 'Calf: not suckling, cold or cannot stand', 'Calves'),
];

class _Condition {
  const new(
    this.key,
    this.name,
    this.main,
    this.other,
    this.urgency,
    this.advice, {
    this.fever = false,
    this.afterCalving,
    this.notifiable = false,
  });
  final String key;
  final String name;
  final List<String> main;
  final List<String> other;
  final bool fever;
  final (int, int)? afterCalving;
  final bool notifiable;
  final Severity urgency;
  final String advice;
}

const _conditions = <_Condition>[
  _Condition(
    'mastitis',
    'Mastitis (udder infection)',
    ['udderSwollen', 'milkClots'],
    ['milkDrop', 'eatingLess'],
    Severity.high,
    'Milk her last, into a separate container, and do not sell that milk. Keep her bedding clean and dry.',
    fever: true,
  ),
  _Condition(
    'ecf',
    'East Coast Fever or another tick fever',
    ['lymphSwollen', 'ticksMany'],
    ['breathingHard', 'noseDischarge', 'cough', 'notEating', 'weightLoss', 'milkDrop'],
    Severity.high,
    'Treatment works best early. Keep her in shade with water, and check the rest of the herd for ticks.',
    fever: true,
  ),
  _Condition(
    'redwater',
    'Redwater or gall sickness (tick-borne blood disease)',
    ['paleGums', 'redUrine'],
    ['ticksMany', 'notEating', 'milkDrop', 'weightLoss'],
    Severity.high,
    'Keep her calm and in shade with water; do not drive or chase her.',
    fever: true,
  ),
  _Condition(
    'fmd',
    'Foot and mouth disease',
    ['mouthBlisters', 'drooling'],
    ['lame', 'milkDrop', 'notEating'],
    Severity.high,
    'Keep the herd in, stop moving or selling animals and milk to other farms, and report to the District Veterinary Officer.',
    fever: true,
    notifiable: true,
  ),
  _Condition(
    'lsd',
    'Lumpy skin disease',
    ['skinLumps'],
    ['lymphSwollen', 'milkDrop', 'noseDischarge', 'notEating'],
    Severity.high,
    'Keep her apart from the herd, control flies and ticks, and report to the District Veterinary Officer.',
    fever: true,
    notifiable: true,
  ),
  _Condition(
    'bloat',
    'Bloat',
    ['leftSideSwollen'],
    ['breathingHard', 'notEating'],
    Severity.critical,
    'Emergency. Stand her up and walk her slowly; keep her off lush legumes. Call the vet now.',
  ),
  _Condition(
    'milkFever',
    'Milk fever (low calcium after calving)',
    ['coldEars', 'downCannotRise'],
    ['notEating'],
    Severity.critical,
    'Emergency. Prop her up on her chest so she does not lie flat on her side. Call the vet now.',
    afterCalving: (0, 3),
  ),
  _Condition(
    'pneumonia',
    'Pneumonia or a chest infection',
    ['cough', 'breathingHard'],
    ['noseDischarge', 'notEating', 'eatingLess'],
    Severity.high,
    'Move her to a sheltered place with fresh air and water.',
    fever: true,
  ),
  _Condition(
    'footRot',
    'Foot rot or a hoof problem',
    ['lame', 'footSmell'],
    ['milkDrop', 'eatingLess'],
    Severity.medium,
    'Clean and look at the foot. Keep her on dry ground.',
  ),
  _Condition(
    'worms',
    'Worms or another gut problem',
    ['diarrhoea', 'weightLoss'],
    ['jawSwelling', 'eatingLess', 'paleGums'],
    Severity.medium,
    'Keep her drinking. A dung test tells the vet which worms, if any.',
  ),
  _Condition(
    'gutBleed',
    'Gut infection with bleeding',
    ['bloodDung', 'diarrhoea'],
    ['notEating', 'weightLoss'],
    Severity.high,
    'Keep her apart and drinking. Young animals weaken fast.',
    fever: true,
  ),
  _Condition(
    'retained',
    'Retained afterbirth or womb infection',
    ['afterbirthStuck', 'badDischarge'],
    ['notEating', 'milkDrop'],
    Severity.high,
    'Do not pull the afterbirth out. Keep her clean.',
    afterCalving: (0, 21),
    fever: true,
  ),
  _Condition(
    'ketosis',
    'Ketosis (energy shortage in early lactation)',
    ['eatingLess', 'milkDrop'],
    ['weightLoss', 'notEating'],
    Severity.medium,
    'Make sure she has good feed and water, and ask the vet to test her.',
    afterCalving: (5, 60),
  ),
  _Condition(
    'pinkeye',
    'Pinkeye (eye infection)',
    ['eyeWatery'],
    [],
    Severity.medium,
    'Keep her out of the sun and dust, and control flies.',
  ),
  _Condition(
    'blackquarter',
    'Blackquarter',
    ['legMuscleSwollen'],
    ['lame', 'otherDied', 'notEating'],
    Severity.critical,
    'Emergency, often fatal in young cattle. Call the vet now about the rest of the herd.',
    fever: true,
  ),
  _Condition(
    'anthrax',
    'Anthrax (sudden death disease)',
    ['bloodOpenings', 'otherDied'],
    ['breathingHard'],
    Severity.critical,
    'Do not open, skin or eat a dead animal, and keep people and dogs away. Report to the District Veterinary Officer at once.',
    fever: true,
    notifiable: true,
  ),
  _Condition(
    'rabies',
    'Rabies or another brain disease',
    ['strangeBehaviour'],
    ['drooling', 'notEating'],
    Severity.critical,
    'Do not put a hand in her mouth. Keep people away and report to the District Veterinary Officer.',
    notifiable: true,
  ),
  _Condition(
    'brucellosis',
    'Brucellosis (can cause abortion, can spread to people)',
    ['abortion'],
    ['afterbirthStuck', 'swollenJoint', 'badDischarge'],
    Severity.high,
    'Keep the aborted calf and afterbirth away from people and dogs, wear gloves, do not drink raw milk from her, and report to the District Veterinary Officer.',
    notifiable: true,
  ),
  _Condition(
    'trypano',
    'Trypanosomiasis (nagana, spread by tsetse flies)',
    ['weakRough'],
    ['paleGums', 'weightLoss', 'eatingLess', 'lymphSwollen', 'milkDrop'],
    Severity.high,
    'Keep her in shade with water. Tell the vet if you have seen tsetse flies in the area.',
    fever: true,
  ),
  _Condition(
    'heartwater',
    'Heartwater (tick-borne, affects the nerves and chest)',
    ['swollenBrisket', 'strangeBehaviour'],
    ['breathingHard', 'ticksMany', 'diarrhoea', 'notEating'],
    Severity.high,
    'Keep her calm and in shade, and check the herd for ticks. Treatment works only if given early.',
    fever: true,
  ),
  _Condition(
    'tetany',
    'Grass tetany (low magnesium)',
    ['staggering'],
    ['strangeBehaviour', 'downCannotRise', 'notEating'],
    Severity.critical,
    'Emergency. Keep her calm, do not chase her, and call the vet now. Tell the vet what pasture she was on.',
  ),
  _Condition(
    'acidosis',
    'Grain overload (rumen acidosis)',
    ['grainOverload'],
    ['diarrhoea', 'eatingLess', 'lame', 'breathingHard', 'notEating'],
    Severity.high,
    'Stop all grain and concentrate feed, give hay or dry grass and clean water, and call the vet today.',
  ),
  _Condition(
    'ringworm',
    'Ringworm (a skin fungus)',
    ['ringLesions'],
    ['hairLoss', 'itching'],
    Severity.low,
    'Keep her apart from calves and from people with skin problems, and wash your hands after touching her.',
  ),
  _Condition(
    'mange',
    'Mange or lice (skin parasites)',
    ['itching'],
    ['hairLoss', 'ticksMany', 'weightLoss'],
    Severity.medium,
    'Keep her apart from the herd, and ask the vet which parasite it is before using any product.',
  ),
  _Condition(
    'calfScours',
    'Calf scours (diarrhoea in a young calf)',
    ['calfScours'],
    ['sunkenEyes', 'calfNotSuckling', 'notEating'],
    Severity.high,
    'Calves lose water fast. Keep her warm, dry and clean, keep her drinking, and call the vet today.',
  ),
  _Condition(
    'navelIll',
    'Navel or joint ill in a calf',
    ['navelSwollen'],
    ['swollenJoint', 'calfNotSuckling', 'lame'],
    Severity.high,
    'Keep the calf clean and dry and away from others, and call the vet today.',
    fever: true,
  ),
  _Condition(
    'prolapse',
    'Prolapse (womb or vagina pushed out)',
    ['prolapse'],
    ['calvingStraining'],
    Severity.critical,
    'Emergency. Keep the tissue clean and moist, stop her lying on it, and call the vet now. Do not try to push it back yourself.',
  ),
  _Condition(
    'mineral',
    'Mineral shortage',
    ['eatingStrange'],
    ['weightLoss', 'milkDrop', 'eatingLess'],
    Severity.low,
    'Ask the vet or your extension officer about a mineral lick and the quality of her feed.',
  ),
  _Condition(
    'jointInfection',
    'Joint infection or injury',
    ['swollenJoint'],
    ['lame', 'woundBleeding'],
    Severity.medium,
    'Keep her on soft, dry ground and rest her. See the vet if the joint stays swollen.',
  ),
  _Condition(
    'dehydration',
    'Dehydration (needs water urgently)',
    ['sunkenEyes'],
    ['diarrhoea', 'notEating', 'weightLoss'],
    Severity.high,
    'Give her clean water to drink slowly, keep her in shade, and call the vet today.',
  ),
  _Condition(
    'wound',
    'Wound or injury',
    ['wound'],
    ['lame', 'woundBleeding'],
    Severity.medium,
    'Clean it with clean water and keep flies off.',
  ),
];

class VetInput {
  const new({required this.signs, this.tempC, this.daysSinceCalving, this.days});

  final List<String> signs;

  /// Rectal temperature, °C, if taken.
  final double? tempC;

  /// Days since she calved, if she calved recently.
  final int? daysSinceCalving;

  /// How many days the signs have been seen.
  final int? days;
}

class _Flag {
  const new(this.text, {this.sign, this.test});
  final String text;
  final String? sign;
  final bool Function(VetInput)? test;
}

final _redFlags = <_Flag>[
  const _Flag('Cannot get up', sign: 'downCannotRise'),
  const _Flag('Swollen left side (bloat can kill within hours)', sign: 'leftSideSwollen'),
  const _Flag('Straining to calve for over an hour', sign: 'calvingStraining'),
  const _Flag('Heavy bleeding', sign: 'woundBleeding'),
  const _Flag('Blood from the nose, mouth or anus', sign: 'bloodOpenings'),
  const _Flag('Strange behaviour or fits', sign: 'strangeBehaviour'),
  const _Flag('Another animal died suddenly', sign: 'otherDied'),
  const _Flag('Crackling swollen muscle', sign: 'legMuscleSwollen'),
  const _Flag('Womb or vagina pushed out', sign: 'prolapse'),
  const _Flag('Staggering or trembling', sign: 'staggering'),
  const _Flag('Sunken eyes (dehydration)', sign: 'sunkenEyes'),
  const _Flag('Calf cold, not suckling or cannot stand', sign: 'calfNotSuckling'),
  _Flag('Very high temperature (41 °C or more)', test: (i) => i.tempC != null && i.tempC! >= 41),
  _Flag('Low temperature (below 37.5 °C)', test: (i) => i.tempC != null && i.tempC! < 37.5),
  _Flag(
    'Hard breathing and not eating',
    test: (i) => i.signs.contains('breathingHard') && i.signs.contains('notEating'),
  ),
];

class PossibleCondition {
  const new({
    required this.key,
    required this.name,
    required this.matched,
    required this.notifiable,
    required this.advice,
  });
  final String key;
  final String name;
  final List<String> matched;
  final bool notifiable;
  final String advice;
}

class VetResult {
  const new({
    required this.risk,
    required this.fever,
    required this.redFlags,
    required this.possible,
    required this.callVet,
    required this.steps,
    required this.disclaimer,
  });
  final Severity risk;

  /// none, fever, high, low or notTaken
  final String fever;
  final List<String> redFlags;
  final List<PossibleCondition> possible;

  /// now, today or soon
  final String callVet;
  final List<String> steps;
  final String disclaimer;
}

const vetDisclaimer =
    'This is a guide to possible causes, not a diagnosis. Only a vet can examine and diagnose your animal. FarmTap never suggests drugs or doses.';

String _labelOf(String k) {
  for (final s in signs) {
    if (s.key == k) return s.label;
  }
  return k;
}

VetResult assess(VetInput input) {
  final set = input.signs.toSet();
  final t = input.tempC;
  final fever = t == null
      ? 'notTaken'
      : t < 37.5
      ? 'low'
      : t >= 40.5
      ? 'high'
      : t >= 39.5
      ? 'fever'
      : 'none';
  final flags = _redFlags
      .where((f) => f.sign != null ? set.contains(f.sign) : f.test!(input))
      .map((f) => f.text)
      .toList();
  final all = <({_Condition c, List<String> main, List<String> other, int score})>[];
  for (final c in _conditions) {
    final main = c.main.where(set.contains).toList();
    final other = c.other.where(set.contains).toList();
    var score = main.length * 2 + other.length;
    if (c.fever && (fever == 'fever' || fever == 'high')) score += 1;
    if (c.afterCalving != null) {
      final dsc = input.daysSinceCalving;
      if (dsc != null && dsc >= c.afterCalving!.$1 && dsc <= c.afterCalving!.$2) {
        score += 2;
      } else if (c.key == 'milkFever' || c.key == 'ketosis' || c.key == 'retained') {
        score -= 2;
      }
    }
    all.add((c: c, main: main, other: other, score: score));
  }
  // A condition needs at least one of its main signs to be listed at all.
  final scored = stableSort(
    all.where((x) => x.main.isNotEmpty && x.score >= 2),
    (a, b) => b.score != a.score ? b.score - a.score : severityRank(a.c.urgency) - severityRank(b.c.urgency),
  ).take(3).toList();
  var risk = flags.isNotEmpty ? Severity.critical : Severity.low;
  for (final x in scored) {
    if (severityRank(x.c.urgency) < severityRank(risk)) risk = x.c.urgency;
  }
  if (fever == 'high' && severityRank(risk) > severityRank(Severity.high)) risk = Severity.high;
  if (fever == 'fever' && severityRank(risk) > severityRank(Severity.medium)) risk = Severity.medium;
  if (set.contains('notEating') && (input.days ?? 0) >= 1 && severityRank(risk) > severityRank(Severity.high)) {
    risk = Severity.high;
  }
  if (scored.isEmpty && set.isNotEmpty && severityRank(risk) > severityRank(Severity.medium)) risk = Severity.medium;
  final callVet = risk == Severity.critical
      ? 'now'
      : risk == Severity.high
      ? 'today'
      : 'soon';
  final steps = <String>[
    if (risk == Severity.critical)
      'Call your vet now.'
    else if (risk == Severity.high)
      'Call your vet today.'
    else
      'Ask your vet at the next visit, sooner if she gets worse.',
    if (fever == 'notTaken') 'Take her temperature with a thermometer if you can. Normal is about 38.0 to 39.3 °C.',
    'Keep her apart from the herd until she has been seen, with shade, clean water and feed.',
    ...scored.map((x) => x.c.advice),
    if (scored.any((x) => x.c.notifiable))
      'This could be a disease the law says must be reported. Tell the District Veterinary Officer.',
    'Do not sell her milk or meat until the vet says it is safe.',
  ];
  return VetResult(
    risk: risk,
    fever: fever,
    redFlags: flags,
    possible: [
      for (final x in scored)
        PossibleCondition(
          key: x.c.key,
          name: x.c.name,
          matched: [...x.main, ...x.other].map(_labelOf).toList(),
          notifiable: x.c.notifiable,
          advice: x.c.advice,
        ),
    ],
    callVet: callVet,
    steps: steps.toSet().toList(),
    disclaimer: vetDisclaimer,
  );
}

const vetEngine = 'vet-guide-2';
