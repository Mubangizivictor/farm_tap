// Cattle breeding (J01-J03). Breeding events are the single source: who is
// pregnant, when she calves, when to check and when to dry her off are all
// calculated from heat, service and pregnancy-check records.

enum ServiceKind { heat, natural, ai }

/// The rules every breeding date comes from.
abstract final class BreedingRules {
  /// Service to expected calving (J02: 7 Nov -> 14 Aug 2027).
  static const gestationDays = 280;

  /// Service to pregnancy check (J02: 7 Nov -> 2 Jan).
  static const checkAfterDays = 56;

  /// Stop milking this many days before calving.
  static const dryOffDays = 60;

  /// "Calving in 30 days" on J01.
  static const calvingSoonDays = 30;

  /// A heat older than this is no longer worth serving.
  static const heatValidDays = 2;
}

/// An animal that can be served (a cow or heifer).
class BreedingAnimal {
  const new({required this.id, required this.name, required this.tag, required this.avatarIndex, this.heifer = false});

  final String id;
  final String name;
  final String tag;
  final int avatarIndex;
  final bool heifer;
}

/// J02: heat seen, natural service or AI.
class ServiceRecord {
  const new({
    required this.id,
    required this.animal,
    required this.kind,
    required this.at,
    this.straw,
    this.bull,
    this.technician,
    this.cost,
  });

  final String id;
  final BreedingAnimal animal;
  final ServiceKind kind;
  final DateTime at;

  /// AI semen straw ("Friesian 4421").
  final String? straw;
  final String? bull;
  final String? technician;

  /// UGX; recorded as an expense in the money repository.
  final int? cost;

  bool get isService => kind != ServiceKind.heat;

  DateTime get checkFrom => _day(at).add(const Duration(days: BreedingRules.checkAfterDays));
  DateTime get expectedCalving => _day(at).add(const Duration(days: BreedingRules.gestationDays));
}

/// A vet's pregnancy check after a service.
class PregnancyCheck {
  const new({required this.id, required this.serviceId, required this.pregnant, required this.at, this.by});

  final String id;
  final String serviceId;
  final bool pregnant;
  final DateTime at;
  final String? by;
}

/// The cow's calf was born (closes the pregnancy).
class CalvingRecord {
  const new({required this.animalId, required this.at});

  final String animalId;
  final DateTime at;
}

/// A confirmed pregnancy (J01 expected calvings, J03).
class Pregnancy {
  const new({required this.service, required this.check});

  final ServiceRecord service;
  final PregnancyCheck check;

  BreedingAnimal get animal => service.animal;
  DateTime get due => service.expectedCalving;
  DateTime get dryOffFrom => due.subtract(const Duration(days: BreedingRules.dryOffDays));
  int daysToCalving(DateTime now) => due.difference(_day(now)).inDays;
}

enum BreedingTaskKind { check, serve }

/// J01 "To do": a pregnancy check that is due, or a heat to serve.
class BreedingTask {
  const new({required this.kind, required this.record});

  final BreedingTaskKind kind;

  /// The service to check, or the heat to serve.
  final ServiceRecord record;
}

/// J01, calculated from the records at one moment.
class BreedingSummary {
  const new({required this.pregnancies, required this.calvingSoon, required this.tasks});

  /// Confirmed and not yet calved, soonest first.
  final List<Pregnancy> pregnancies;

  /// Due within [BreedingRules.calvingSoonDays].
  final List<Pregnancy> calvingSoon;
  final List<BreedingTask> tasks;

  int get checksDue => tasks.where((t) => t.kind == BreedingTaskKind.check).length;
}

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);
