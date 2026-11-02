import 'package:farm_tap/core/error/failure.dart';
import 'package:farm_tap/core/error/result.dart';
import 'package:farm_tap/core/people/domain/staff_access_repository.dart';
import 'package:farm_tap/core/people/domain/staff_directory.dart';
import 'package:farm_tap/core/people/domain/staff_member.dart';

/// Sample staff from the mockups. Every PIN is 1234 in the UI phase.
/// Peter has no card yet (K01 "No card"); blank cards 0207-0215 are in stock.
class FakeStaffAccessRepository implements StaffAccessRepository, StaffDirectory {
  new({this.nfc = true, this.today});

  /// The simulator and web have no NFC; set false to show C05.
  final bool nfc;

  /// Start date for new staff ("since").
  final DateTime Function()? today;
  final _pins = <String, String>{};
  var _nextId = 1;
  final _wrongTries = <String, int>{};
  final List<StaffMember> _staff = [...sample];
  final List<String> _blankCards = [for (var n = 207; n <= 215; n++) n.toString().padLeft(4, '0')];

  static final sample = [
    StaffMember(
      id: 'staff-mt',
      name: 'Mugisha Tom',
      role: StaffRole.manager,
      cardNumber: '0101',
      shortName: 'Tom',
      since: DateTime(2022, 6),
    ),
    StaffMember(
      id: 'staff-ta',
      name: 'Twinomujuni Amos',
      role: StaffRole.herdsman,
      cardNumber: '0142',
      since: DateTime(2024, 3),
    ),
    StaffMember(
      id: 'staff-aj',
      name: 'Ahimbisibwe Joy',
      role: StaffRole.clerk,
      cardNumber: '0155',
      shortName: 'Joy',
      since: DateTime(2023, 9),
    ),
    StaffMember(id: 'staff-np', name: 'Nuwagaba Peter', role: StaffRole.worker, since: DateTime(2026, 10)),
    StaffMember(
      id: 'staff-kr',
      name: 'Katusiime Rita',
      role: StaffRole.worker,
      cardNumber: '0168',
      since: DateTime(2025),
    ),
    StaffMember(
      id: 'staff-ki',
      name: 'Dr. Kamugisha Ivan',
      role: StaffRole.vet,
      cardNumber: '0190',
      shortName: 'Ivan',
      since: DateTime(2023, 2),
    ),
  ];

  static const pin = '1234';
  static const maxTries = 5;

  @override
  Future<bool> nfcAvailable() async => nfc;

  @override
  Future<Result<StaffMember?>> findByCard(String cardNumber) async {
    for (final s in _staff) {
      if (s.cardNumber != null && s.cardNumber == cardNumber.padLeft(4, '0')) return Result.success(s);
    }
    return const Result.success(null);
  }

  @override
  Future<Result<PinCheck>> verifyPin(String staffId, String entered) async {
    if (entered == (_pins[staffId] ?? pin)) {
      _wrongTries.remove(staffId);
      return const Result.success(PinAccepted());
    }
    final wrong = (_wrongTries[staffId] ?? 0) + 1;
    _wrongTries[staffId] = wrong;
    if (wrong >= maxTries) return const Result.success(PinLocked());
    return Result.success(PinRejected(maxTries - wrong));
  }

  @override
  Future<Result<List<StaffMember>>> staff() async => Result.success(List.unmodifiable(_staff));

  @override
  Future<Result<StaffMember>> addStaff({required String name, required StaffRole role, required String pin}) async {
    final s = StaffMember(id: 'staff-new-${_nextId++}', name: name, role: role, since: today?.call());
    _staff.add(s);
    _pins[s.id] = pin;
    return Result.success(s);
  }

  @override
  Future<Result<StaffMember>> updateStaff(String staffId, {required String name, required StaffRole role}) async {
    final i = _staff.indexWhere((s) => s.id == staffId);
    _staff[i] = _staff[i].copyWith(name: name, role: role);
    return Result.success(_staff[i]);
  }

  @override
  Future<Result<String?>> nextBlankCard() async => Result.success(_blankCards.firstOrNull);

  @override
  Future<Result<StaffMember>> assignCard(String staffId, String cardNumber) async {
    final card = cardNumber.padLeft(4, '0');
    final owner = _staff.where((s) => s.cardNumber == card && s.id != staffId).firstOrNull;
    if (owner != null) return Result.failure(ValidationFailure('card-taken:${owner.name}'));
    final i = _staff.indexWhere((s) => s.id == staffId);
    _staff[i] = _staff[i].withCard(card);
    _blankCards.remove(card);
    return Result.success(_staff[i]);
  }

  @override
  Future<Result<bool>> verifyManagerPin(String entered) async =>
      Result.success(entered == pin && _staff.any((s) => s.role == StaffRole.manager));

  @override
  Future<Result<void>> resetPin(String staffId) async {
    _wrongTries.remove(staffId);
    return const Result.success(null);
  }
}
