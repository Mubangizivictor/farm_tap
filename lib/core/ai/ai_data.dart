// FarmTap AI engine: the farm's records as the engine reads them
// (decision 0025). Hand port of shared/aiData.ts. Records are the same bodies
// the phone and web write; everything is optional so older or half-filled
// records never break an analysis.
import 'package:farm_tap/core/ai/ai_core.dart';

/// Shelf-life rule for a product, set by the farm (settings/aiMilk).
class ShelfRule {
  const new({
    required this.product,
    required this.label,
    required this.cooledHours,
    required this.warmHours,
    required this.maxTempC,
  });

  factory fromJson(Map<String, Object?> j) => ShelfRule(
    product: '${j['product']}',
    label: '${j['label']}',
    cooledHours: num0(j['cooledHours']),
    warmHours: num0(j['warmHours']),
    maxTempC: num0(j['maxTempC']),
  );

  final String product;
  final String label;

  /// Hours the milk keeps when cooled and every reading is at or below [maxTempC].
  final double cooledHours;

  /// Hours it keeps when not cooled, or after a reading above [maxTempC].
  final double warmHours;
  final double maxTempC;
}

/// Starting rules, to be checked and changed by each farm: raw milk keeps
/// about 2 days at 4 °C or colder and must be cooled or sold within a few
/// hours when warm. FarmTap defaults, not a safety certificate.
const defaultShelfRules = <ShelfRule>[
  ShelfRule(product: 'rawMilk', label: 'Raw milk', cooledHours: 48, warmHours: 3, maxTempC: 4),
];

class FarmData {
  const new({
    required this.now,
    this.animals = const [],
    this.milk = const [],
    this.treatments = const [],
    this.vaccinations = const [],
    this.breeding = const [],
    this.expenses = const [],
    this.income = const [],
    this.milkSales = const [],
    this.feedUses = const [],
    this.stockMoves = const [],
    this.feedTypes = const [],
    this.stockItems = const [],
    this.deliveries = const [],
    this.milkBatches = const [],
    this.storageReadings = const [],
    this.shelfRules,
  });

  factory fromJson(Map<String, Object?> j) {
    List<Rec> recs(String k) =>
        ((j[k] as List?) ?? const []).map((e) => Rec.fromJson((e as Map).cast<String, Object?>())).toList();
    return FarmData(
      now: j['now']! as String,
      animals: recs('animals'),
      milk: recs('milk'),
      treatments: recs('treatments'),
      vaccinations: recs('vaccinations'),
      breeding: recs('breeding'),
      expenses: recs('expenses'),
      income: recs('income'),
      milkSales: recs('milkSales'),
      feedUses: recs('feedUses'),
      stockMoves: recs('stockMoves'),
      feedTypes: recs('feedTypes'),
      stockItems: recs('stockItems'),
      deliveries: recs('deliveries'),
      milkBatches: recs('milkBatches'),
      storageReadings: recs('storageReadings'),
      shelfRules: j['shelfRules'] == null
          ? null
          : ((j['shelfRules']! as List).map((e) => ShelfRule.fromJson((e as Map).cast<String, Object?>())).toList()),
    );
  }

  /// Kampala local now, ISO without zone (kampalaNow(clock.now()).iso).
  final String now;
  final List<Rec> animals;
  final List<Rec> milk;
  final List<Rec> treatments;
  final List<Rec> vaccinations;
  final List<Rec> breeding;
  final List<Rec> expenses;
  final List<Rec> income;
  final List<Rec> milkSales;
  final List<Rec> feedUses;
  final List<Rec> stockMoves;
  final List<Rec> feedTypes;
  final List<Rec> stockItems;
  final List<Rec> deliveries;
  final List<Rec> milkBatches;
  final List<Rec> storageReadings;
  final List<ShelfRule>? shelfRules;
}

String today(FarmData d) => d.now.substring(0, 10);

// ---------------------------------------------------------------- Animals

bool isActive(Rec a) => a.str('status') == null || a.str('status')!.isEmpty || a.str('status') == 'active';

String animalName(Rec? a) {
  if (a == null) return 'Unknown animal';
  final n = a.str('name')?.trim();
  if (n != null && n.isNotEmpty) return n;
  final t = a.str('tagNumber');
  return t != null && t.isNotEmpty ? t : 'No tag';
}

String animalHref(String id) => '/herd/?animal=${Uri.encodeComponent(id)}';

Map<String, Rec> animalMap(FarmData d) => {for (final a in alive(d.animals)) a.id: a};

bool isMilkingCow(Rec a) => isActive(a) && (a.str('dairyStatus') == 'milking' || a.str('dairyStatus') == 'treated');

// ---------------------------------------------------------------- Milk days

class MilkDay {
  new(this.day);
  final String day;
  double litres = 0;
  bool recorded = false;
}

/// Litres per day for the [days] days ending today (oldest first). A day with
/// no record is "not recorded", never "zero milk".
List<MilkDay> milkDays(FarmData d, int days) {
  final end = today(d);
  final out = <String, MilkDay>{};
  for (var i = days - 1; i >= 0; i--) {
    final day = addDays(end, -i);
    out[day] = MilkDay(day);
  }
  for (final r in alive(d.milk)) {
    final day = recDay(r);
    final slot = day == null ? null : out[day];
    if (slot == null) continue;
    slot
      ..litres += num0(r.body['litres'])
      ..recorded = true;
  }
  return out.values.toList();
}

/// Litres per cow per day for the last [days] days (only cows with per-cow records).
Map<String, Map<String, double>> cowDays(FarmData d, int days) {
  final from = addDays(today(d), -(days - 1));
  final out = <String, Map<String, double>>{};
  for (final r in alive(d.milk)) {
    final id = r.str('animalId');
    final day = recDay(r);
    if (id == null || id.isEmpty || day == null || day.compareTo(from) < 0 || day.compareTo(today(d)) > 0) continue;
    final m = out.putIfAbsent(id, () => <String, double>{});
    m[day] = (m[day] ?? 0) + num0(r.body['litres']);
  }
  return out;
}

// ---------------------------------------------------------------- Breeding

const gestationDays = 283;
const heatCycleDays = 21;
const pregnancyCheckDays = 60;

bool _isService(Rec b) => (b.str('type') == 'ai' || b.str('type') == 'service') && b.str('kind') != 'heat';
bool _isHeat(Rec b) => b.str('type') == 'service' && b.str('kind') == 'heat';

class BreedingState {
  const new({
    required this.servedDay,
    required this.confirmed,
    required this.pregnant,
    required this.due,
    required this.checkDue,
    required this.lastHeat,
    required this.nextHeat,
    required this.calvedDay,
    required this.daysInMilk,
    required this.servicesSinceCalving,
    required this.failedServices,
  });
  final String? servedDay;
  final bool confirmed;
  final bool pregnant;
  final String? due;
  final String? checkDue;
  final String? lastHeat;
  final String? nextHeat;
  final String? calvedDay;
  final int? daysInMilk;
  final int servicesSinceCalving;
  final int failedServices;
}

/// The same reading of breeding events as the phone and web.
BreedingState breedingState(String animalId, List<Rec> events, String day) {
  final all = alive(events).where((e) => dayOf(e.body['at']) != null).toList()
    ..sort((a, b) => (b.str('at') ?? '').compareTo(a.str('at') ?? ''));
  final mine = all.where((e) => e.str('animalId') == animalId).toList();
  final services = mine.where(_isService).toList();
  final served = services.isEmpty ? null : services.first;
  Rec? firstWhere(Iterable<Rec> xs, bool Function(Rec) f) {
    for (final x in xs) {
      if (f(x)) return x;
    }
    return null;
  }

  final calved = firstWhere(mine, (e) => e.str('type') == 'calving');
  final heat = firstWhere(mine, _isHeat);
  final servedDay = served == null ? null : dayOf(served.body['at']);
  final calvedDay = calved == null ? null : dayOf(calved.body['at']);
  final open = served != null && servedDay != null && (calvedDay == null || calvedDay.compareTo(servedDay) < 0)
      ? served
      : null;
  final check = open == null
      ? null
      : firstWhere(all, (e) => e.str('type') == 'pregnancyCheck' && e.str('serviceId') == open.id);
  final result = check == null ? null : check.flag('pregnant') == true;
  final pregnant = open != null && result != false;
  final due = pregnant && servedDay != null ? addDays(servedDay, gestationDays) : null;
  final signs = <String>[
    if (heat != null && dayOf(heat.body['at']) != null) dayOf(heat.body['at'])!,
    if (result == false && servedDay != null) servedDay,
    ?calvedDay,
  ]..sort();
  final lastSign = signs.isEmpty ? null : signs.last;
  String? nextHeat;
  if (!pregnant && lastSign != null) {
    nextHeat = addDays(lastSign, heatCycleDays);
    while (nextHeat!.compareTo(day) < 0) {
      nextHeat = addDays(nextHeat, heatCycleDays);
    }
  }
  final sinceCalving = services
      .where((s) => calvedDay == null || dayOf(s.body['at'])!.compareTo(calvedDay) > 0)
      .toList();
  final failed = sinceCalving.where((s) {
    final c = firstWhere(all, (e) => e.str('type') == 'pregnancyCheck' && e.str('serviceId') == s.id);
    return c != null ? c.flag('pregnant') == false : !identical(s, open);
  }).length;
  return BreedingState(
    servedDay: open != null ? servedDay : null,
    confirmed: result == true,
    pregnant: pregnant,
    due: due,
    checkDue: open != null && result == null && servedDay != null ? addDays(servedDay, pregnancyCheckDays) : null,
    lastHeat: heat == null ? null : dayOf(heat.body['at']),
    nextHeat: nextHeat,
    calvedDay: calvedDay,
    daysInMilk: calvedDay != null ? daysBetween(calvedDay, day) : null,
    servicesSinceCalving: sinceCalving.length,
    failedServices: failed,
  );
}
