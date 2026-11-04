// Farm operations on the phone (decision 0024): contacts, the duty roster
// with stand-ins and time away, the feeds store and vaccinations. The record
// bodies are the same ones the web app writes (webapp/src/lib/domain.ts), so
// both see the same farm through the same records.

import 'package:equatable/equatable.dart';

String? _s(Object? v) => v is String && v.trim().isNotEmpty ? v : null;
num? _n(Object? v) => v is num ? v : (v is String ? num.tryParse(v) : null);
DateTime? _d(Object? v) => v is String ? DateTime.tryParse(v) : null;

/// yyyy-mm-dd of a local date.
String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

enum ContactKind { vet, aiTechnician, feedSupplier, agrovet, buyer, transporter, emergency, other }

ContactKind contactKindOf(String? v) =>
    ContactKind.values.firstWhere((k) => k.name == v, orElse: () => ContactKind.other);

class FarmContact extends Equatable {
  const new({
    required this.id,
    required this.name,
    required this.kind,
    required this.phone,
    this.phone2,
    this.org,
    this.place,
    this.note,
    this.showWorkers = true,
  });

  factory fromBody(String id, Map<String, Object?> b) => FarmContact(
    id: id,
    name: _s(b['name']) ?? '',
    kind: contactKindOf(b['kind'] as String?),
    phone: _s(b['phone']) ?? '',
    phone2: _s(b['phone2']),
    org: _s(b['org']),
    place: _s(b['place']),
    note: _s(b['note']),
    showWorkers: b['showWorkers'] != false,
  );

  final String id;
  final String name;
  final ContactKind kind;
  final String phone;
  final String? phone2;
  final String? org;
  final String? place;
  final String? note;

  /// Workers see this contact.
  final bool showWorkers;

  Map<String, Object?> toBody() => {
    'name': name,
    'kind': kind.name,
    'phone': phone,
    'phone2': phone2,
    'org': org,
    'place': place,
    'note': note,
    'showWorkers': showWorkers,
  };

  @override
  List<Object?> get props => [id, name, kind, phone, phone2, org, place, note, showWorkers];
}

/// The jobs on the roster (web: dutyActivities).
enum DutyActivity { milking, feeding, health, cleaning, grazing, security, collection, manager, other }

DutyActivity dutyActivityOf(String? v) =>
    DutyActivity.values.firstWhere((k) => k.name == v, orElse: () => DutyActivity.other);

enum DutyShift { morning, afternoon, evening, night, allDay }

DutyShift dutyShiftOf(String? v) => DutyShift.values.firstWhere((k) => k.name == v, orElse: () => DutyShift.allDay);

class Duty extends Equatable {
  const new({
    required this.id,
    required this.activity,
    required this.staffId,
    this.label,
    this.standInId,
    this.days = const [],
    this.shift = DutyShift.allDay,
    this.note,
    this.contactId,
  });

  factory fromBody(String id, Map<String, Object?> b) => Duty(
    id: id,
    activity: dutyActivityOf(b['activity'] as String?),
    label: _s(b['label']),
    staffId: _s(b['staffId']) ?? '',
    standInId: _s(b['standInId']),
    days: [
      for (final d in (b['days'] as List?) ?? const [])
        if (d is num && d >= 0 && d <= 6) d.toInt(),
    ],
    shift: dutyShiftOf(b['shift'] as String?),
    note: _s(b['note']),
    contactId: _s(b['contactId']),
  );

  final String id;
  final DutyActivity activity;

  /// Free text when [activity] is other.
  final String? label;
  final String staffId;

  /// Who covers when [staffId] is away.
  final String? standInId;

  /// 0 = Sunday ... 6 = Saturday; empty = every day.
  final List<int> days;
  final DutyShift shift;
  final String? note;
  final String? contactId;

  /// Dart weekday (1 = Monday ... 7 = Sunday) to the web's 0 = Sunday.
  static int webDay(DateTime d) => d.weekday % 7;

  bool on(DateTime day) => days.isEmpty || days.contains(webDay(day));

  Map<String, Object?> toBody() => {
    'activity': activity.name,
    'label': label,
    'staffId': staffId,
    'standInId': standInId,
    'days': days,
    'shift': shift.name,
    'note': note,
    'contactId': contactId,
  };

  @override
  List<Object?> get props => [id, activity, label, staffId, standInId, days, shift, note, contactId];
}

class Absence extends Equatable {
  const new({required this.id, required this.staffId, required this.from, required this.to, this.reason});

  factory fromBody(String id, Map<String, Object?> b) {
    final from = _d(b['from']) ?? DateTime(2000);
    return Absence(
      id: id,
      staffId: _s(b['staffId']) ?? '',
      from: from,
      to: _d(b['to']) ?? from,
      reason: _s(b['reason']),
    );
  }

  final String id;
  final String staffId;
  final DateTime from;
  final DateTime to;
  final String? reason;

  bool covers(DateTime day) {
    final k = dayKey(day);
    return dayKey(from).compareTo(k) <= 0 && k.compareTo(dayKey(to)) <= 0;
  }

  Map<String, Object?> toBody() => {'staffId': staffId, 'from': dayKey(from), 'to': dayKey(to), 'reason': reason};

  @override
  List<Object?> get props => [id, staffId, from, to, reason];
}

/// Who actually works a duty on [day]: the person, their stand-in when they
/// are away, or nobody.
({String? staffId, bool covering}) whoWorks(Duty d, DateTime day, List<Absence> absences) {
  bool away(String id) => absences.any((a) => a.staffId == id && a.covers(day));
  if (!away(d.staffId)) return (staffId: d.staffId, covering: false);
  final s = d.standInId;
  if (s != null && !away(s)) return (staffId: s, covering: true);
  return (staffId: null, covering: false);
}

/// A feed the farm buys and counts (web: feedTypes).
class FeedType extends Equatable {
  const new({required this.id, required this.name, required this.unit, this.lowAt});

  factory fromBody(String id, Map<String, Object?> b) =>
      FeedType(id: id, name: _s(b['name']) ?? '', unit: _s(b['unit']) ?? 'kg', lowAt: _n(b['lowAt'])?.toDouble());

  final String id;
  final String name;
  final String unit;

  /// Warn when stock falls to this or below.
  final double? lowAt;

  Map<String, Object?> toBody() => {'name': name, 'unit': unit, 'lowAt': lowAt};

  @override
  List<Object?> get props => [id, name, unit, lowAt];
}

/// One feed's stock: the last count, then purchases in and feedings out.
class FeedStock extends Equatable {
  const new({required this.type, required this.amount, this.lastBought, this.dailyUse = 0});

  final FeedType type;
  final double amount;
  final DateTime? lastBought;

  /// Average used per day over the last 7 days.
  final double dailyUse;

  bool get low => type.lowAt != null && amount <= type.lowAt!;

  /// Days the stock lasts at [dailyUse]; null when nothing is used.
  int? get daysLeft => dailyUse > 0 ? (amount / dailyUse).floor() : null;

  @override
  List<Object?> get props => [type, amount, lastBought, dailyUse];
}

class Vaccination extends Equatable {
  const new({
    required this.id,
    required this.vaccine,
    required this.given,
    this.animalIds = const [],
    this.nextDue,
    this.cost,
    this.vetId,
    this.note,
  });

  factory fromBody(String id, Map<String, Object?> b) => Vaccination(
    id: id,
    vaccine: _s(b['vaccine']) ?? '',
    animalIds: [for (final a in (b['animalIds'] as List?) ?? const []) '$a'],
    given: _d(b['given']) ?? DateTime(2000),
    nextDue: _d(b['nextDue']),
    cost: _n(b['cost'])?.toInt(),
    vetId: _s(b['vetId']),
    note: _s(b['note']),
  );

  final String id;
  final String vaccine;

  /// Whole herd when empty.
  final List<String> animalIds;
  final DateTime given;
  final DateTime? nextDue;
  final int? cost;
  final String? vetId;
  final String? note;

  Map<String, Object?> toBody() => {
    'vaccine': vaccine,
    'animalIds': animalIds,
    'given': dayKey(given),
    'nextDue': nextDue == null ? null : dayKey(nextDue!),
    'cost': cost,
    'vetId': vetId,
    'note': note,
  };

  @override
  List<Object?> get props => [id, vaccine, animalIds, given, nextDue, cost, vetId, note];
}

/// Common vaccines in Uganda, offered first when recording.
const commonVaccines = [
  'Foot and mouth (FMD)',
  'Lumpy skin',
  'Anthrax',
  'Blackquarter',
  'Brucellosis (S19)',
  'East Coast Fever (ITM)',
  'Rabies',
];
