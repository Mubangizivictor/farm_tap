// Cattle health (H01-H06). Treatment records are the single source for
// withdrawal: the "safe from" date, the Treated badge and the milk
// "not for sale" block are all calculated from them.

enum Condition { mastitis, lame, fever, wound, eye, diarrhoea, other }

enum DrugRoute { injection, oral, spray, pourOn }

enum DrugUnit { bottles, litres }

/// A drug the farm uses. [withdrawalDays] is how long milk stays unsafe.
class Drug {
  const new({
    required this.id,
    required this.name,
    required this.shortName,
    required this.withdrawalDays,
    required this.stock,
    this.unit = DrugUnit.bottles,
    this.reorderAt,
    this.inStockList = true,
  });

  final String id;

  /// "Penicillin-Streptomycin".
  final String name;

  /// "Penicillin" in lists.
  final String shortName;
  final int withdrawalDays;
  final double stock;
  final DrugUnit unit;
  final double? reorderAt;

  /// False for one-off drugs the vet brought (not on H04).
  final bool inStockList;

  bool get low => reorderAt != null && stock < reorderAt!;
}

/// One course of treatment for one animal.
class TreatmentRecord {
  const new({
    required this.id,
    required this.animalId,
    required this.animalName,
    required this.tag,
    required this.avatarIndex,
    required this.condition,
    required this.drug,
    required this.given,
    this.note,
    this.courseDays = 1,
    this.animalDry = false,
    this.dose,
    this.route = DrugRoute.injection,
    this.givenBy,
    this.photo,
  });

  final String id;
  final String animalId;
  final String animalName;
  final String tag;
  final int avatarIndex;
  final Condition condition;

  /// "hoof treatment" after the condition on H01.
  final String? note;
  final Drug drug;
  final DateTime given;
  final int courseDays;

  /// A dry cow is not milked: her withdrawal shows on H06 but blocks no sale.
  final bool animalDry;
  final String? dose;
  final DrugRoute route;
  final String? givenBy;

  /// Photo of the wound or sick part (PhotoStore key).
  final String? photo;

  DateTime get _givenDay => DateTime(given.year, given.month, given.day);

  /// First day the milk may be sold again: treatment day + withdrawal days.
  DateTime get safeFrom => _givenDay.add(Duration(days: drug.withdrawalDays));

  /// Milk from this animal must not be sold before [safeFrom].
  bool inWithdrawal(DateTime now) => drug.withdrawalDays > 0 && now.isBefore(safeFrom);

  /// Days of withdrawal left (at least 0).
  int withdrawalDaysLeft(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final left = safeFrom.difference(today).inDays;
    return left < 0 ? 0 : left;
  }

  /// "day 2 of 3" (1-based, clamped to the course).
  int courseDay(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final d = today.difference(_givenDay).inDays + 1;
    return d.clamp(1, courseDays);
  }

  bool active(DateTime now) => inWithdrawal(now) || courseDay(now) < courseDays || now.isBefore(_givenDay);
}

/// Input for H02.
class NewTreatment {
  const new({
    required this.animalId,
    required this.condition,
    required this.drugId,
    required this.given,
    this.dose,
    this.route = DrugRoute.injection,
    this.givenBy,
    this.photo,
    this.note,
  });

  final String animalId;
  final Condition condition;
  final String drugId;
  final DateTime given;
  final String? dose;
  final DrugRoute route;
  final String? givenBy;
  final String? photo;

  /// What was seen ("swollen left hind leg"), or the disease name for Other.
  final String? note;
}

enum HealthTaskKind { dipping, deworming, vaccination }

/// H05 — a planned herd health job.
class HealthTask {
  const new({
    required this.kind,
    required this.title,
    required this.detail,
    required this.due,
    this.id = '',
    this.done = false,
  });

  /// Record id (empty until saved).
  final String id;

  /// Done jobs drop off the calendar.
  final bool done;
  final HealthTaskKind kind;
  final String title;
  final String detail;
  final DateTime due;
}

/// An animal that can be treated (H02 picker).
class TreatableAnimal {
  const new({required this.id, required this.name, required this.tag, required this.avatarIndex, this.dry = false});

  final String id;
  final String name;
  final String tag;
  final int avatarIndex;
  final bool dry;
}
