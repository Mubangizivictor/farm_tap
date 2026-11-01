import 'package:equatable/equatable.dart';
import 'package:farm_tap/sectors/cattle/herd/domain/entities/animal.dart';

/// One row of the herd list (E01).
class HerdRow extends Equatable {
  const new({required this.animal, this.milkToday});

  final Animal animal;

  /// Litres today; null when not milked (heifer, dry).
  final double? milkToday;

  bool get notForSale => animal.dairyStatus == DairyStatus.treated;

  @override
  List<Object?> get props => [animal, milkToday];
}

/// Head count (E01 chips, E09).
class HerdCounts extends Equatable {
  const new({
    required this.total,
    required this.milking,
    required this.dry,
    required this.treated,
    required this.pregnant,
    required this.heifers,
    required this.calves,
    required this.bulls,
    required this.bornThisMonth,
    required this.boughtThisMonth,
    required this.soldThisMonth,
    required this.diedThisMonth,
  });

  final int total;
  final int milking;
  final int dry;
  final int treated;
  final int pregnant;
  final int heifers;
  final int calves;
  final int bulls;
  final int bornThisMonth;
  final int boughtThisMonth;
  final int soldThisMonth;
  final int diedThisMonth;

  @override
  List<Object?> get props => [
    total,
    milking,
    dry,
    treated,
    pregnant,
    heifers,
    calves,
    bulls,
    bornThisMonth,
    boughtThisMonth,
    soldThisMonth,
    diedThisMonth,
  ];
}

enum HerdSort { name, tag, milk }

/// E02 filter: statuses (empty = all), group (null = all), sort.
class HerdFilter extends Equatable {
  const new({this.statuses = const {}, this.group, this.sort = HerdSort.name});

  final Set<DairyStatus> statuses;
  final String? group;
  final HerdSort sort;

  bool get isEmpty => statuses.isEmpty && group == null;

  HerdFilter copyWith({Set<DairyStatus>? statuses, String? group, bool clearGroup = false, HerdSort? sort}) =>
      HerdFilter(
        statuses: statuses ?? this.statuses,
        group: clearGroup ? null : group ?? this.group,
        sort: sort ?? this.sort,
      );

  List<HerdRow> apply(List<HerdRow> rows) {
    final out = rows
        .where((r) => statuses.isEmpty || statuses.contains(r.animal.dairyStatus))
        .where((r) => group == null || r.animal.group == group)
        .toList();
    switch (sort) {
      case HerdSort.name:
        out.sort((a, b) => a.animal.name.compareTo(b.animal.name));
      case HerdSort.tag:
        out.sort((a, b) => a.animal.tagNumber.compareTo(b.animal.tagNumber));
      case HerdSort.milk:
        out.sort((a, b) => (b.milkToday ?? -1).compareTo(a.milkToday ?? -1));
    }
    return out;
  }

  @override
  List<Object?> get props => [statuses, group, sort];
}

/// Milk withdrawal after a treatment: milk is not for sale until [until].
class Withdrawal extends Equatable {
  const new({required this.drug, required this.until});

  final String drug;
  final DateTime until;

  @override
  List<Object?> get props => [drug, until];
}

/// One entry on the animal timeline (E03).
sealed class AnimalEvent extends Equatable {
  const new(this.at);

  final DateTime at;
}

class TreatmentEvent extends AnimalEvent {
  const new({required DateTime at, required this.drug, required this.reason, required this.vet, required this.safeFrom})
    : super(at);

  final String drug;
  final String reason;
  final String vet;
  final DateTime safeFrom;

  @override
  List<Object?> get props => [at, drug, reason, vet, safeFrom];
}

class MilkEvent extends AnimalEvent {
  const new({required DateTime at, required this.morning, required this.evening}) : super(at);

  final double morning;
  final double evening;

  double get total => morning + evening;

  @override
  List<Object?> get props => [at, morning, evening];
}

class ServiceEvent extends AnimalEvent {
  const new({required DateTime at, required this.method, required this.straw, required this.by}) : super(at);

  /// "AI" or "Bull".
  final String method;
  final String straw;
  final String by;

  @override
  List<Object?> get props => [at, method, straw, by];
}

class VaccinationEvent extends AnimalEvent {
  const new({required DateTime at, required this.name, required this.batch}) : super(at);

  final String name;
  final String batch;

  @override
  List<Object?> get props => [at, name, batch];
}

/// Animal detail (E03).
class AnimalDetail extends Equatable {
  const new({
    required this.animal,
    required this.avgMilk,
    required this.daysInMilk,
    required this.timeline,
    this.pregnancyCheckDue,
    this.withdrawal,
  });

  final Animal animal;
  final double avgMilk;
  final int daysInMilk;
  final DateTime? pregnancyCheckDue;
  final Withdrawal? withdrawal;

  /// Newest first.
  final List<AnimalEvent> timeline;

  @override
  List<Object?> get props => [animal, avgMilk, daysInMilk, pregnancyCheckDue, withdrawal, timeline];
}

enum HerdEventKind { milk, treatment, heat, calving, sold, died }
