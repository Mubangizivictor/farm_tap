import 'package:equatable/equatable.dart';

/// The owner / manager dashboard numbers (D01).
class HomeSummary extends Equatable {
  const new({
    required this.milkToday,
    required this.milkTrendPercent,
    required this.cows,
    required this.milking,
    required this.dry,
    required this.underTreatment,
    required this.notForSale,
    required this.workersIn,
    required this.workersTotal,
    required this.week,
  });

  final double milkToday;

  /// Versus the same day last week: +6.
  final int milkTrendPercent;
  final int cows;
  final int milking;
  final int dry;
  final int underTreatment;
  final int notForSale;
  final int workersIn;
  final int workersTotal;

  /// Litres per day, oldest first, ending today.
  final List<DayLitres> week;

  @override
  List<Object?> get props => [
    milkToday,
    milkTrendPercent,
    cows,
    milking,
    dry,
    underTreatment,
    notForSale,
    workersIn,
    workersTotal,
    week,
  ];
}

class DayLitres extends Equatable {
  const new(this.day, this.litres);

  final DateTime day;
  final double litres;

  @override
  List<Object?> get props => [day, litres];
}

enum AlertCategory { health, milk, stock, money, other }

/// Something that needs attention, most urgent first (D01, D03). Holds data
/// only; the page words it in the user's language.
sealed class Attention extends Equatable {
  const new();

  AlertCategory get category;
  bool get urgent => false;
}

class MilkNotForSale extends Attention {
  const new({required this.animal, required this.drug, required this.safeFrom});

  final String animal;
  final String drug;
  final DateTime safeFrom;

  @override
  AlertCategory get category => AlertCategory.health;

  @override
  bool get urgent => true;

  @override
  List<Object?> get props => [animal, drug, safeFrom];
}

class MilkDropped extends Attention {
  const new({required this.animal, required this.percent, required this.today, required this.average});

  final String animal;
  final int percent;
  final double today;
  final double average;

  @override
  AlertCategory get category => AlertCategory.milk;

  @override
  List<Object?> get props => [animal, percent, today, average];
}

class CalvingDue extends Attention {
  const new({required this.animal, required this.due});

  final String animal;
  final DateTime due;

  @override
  AlertCategory get category => AlertCategory.health;

  @override
  List<Object?> get props => [animal, due];
}

class StockLow extends Attention {
  const new({required this.item, required this.bagsLeft, required this.daysLeft});

  final String item;
  final int bagsLeft;
  final int daysLeft;

  @override
  AlertCategory get category => AlertCategory.stock;

  @override
  List<Object?> get props => [item, bagsLeft, daysLeft];
}

class RecordEdited extends Attention {
  const new({required this.person, required this.morning, required this.at});

  final String person;
  final bool morning;
  final DateTime at;

  @override
  AlertCategory get category => AlertCategory.stock;

  @override
  List<Object?> get props => [person, morning, at];
}

class TrialEnding extends Attention {
  const new({required this.daysLeft});

  final int daysLeft;

  @override
  AlertCategory get category => AlertCategory.money;

  @override
  List<Object?> get props => [daysLeft];
}

/// A worker's day (D02).
class WorkerDay extends Equatable {
  const new({
    required this.clockedInAt,
    required this.morningSession,
    required this.feedingGroupsLeft,
    required this.treatmentsDue,
    required this.dippingDue,
    required this.tasks,
  });

  /// Null when they have not clocked in today.
  final DateTime? clockedInAt;
  final bool morningSession;
  final int feedingGroupsLeft;
  final int treatmentsDue;
  final DateTime dippingDue;
  final List<WorkerTask> tasks;

  @override
  List<Object?> get props => [clockedInAt, morningSession, feedingGroupsLeft, treatmentsDue, dippingDue, tasks];
}

class WorkerTask extends Equatable {
  const new({required this.id, required this.title, required this.when, this.done = false});

  final String id;
  final String title;

  /// "Before 10:00", "After evening milking" (already worded by the farm).
  final String when;
  final bool done;

  WorkerTask copyWith({bool? done}) => WorkerTask(id: id, title: title, when: when, done: done ?? this.done);

  @override
  List<Object?> get props => [id, title, when, done];
}
