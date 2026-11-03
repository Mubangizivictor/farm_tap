import 'package:farm_tap/core/error/failure.dart';
import 'package:farm_tap/core/error/result.dart';
import 'package:farm_tap/core/people/data/local_card_registry.dart';
import 'package:farm_tap/core/people/data/pin_security.dart';
import 'package:farm_tap/core/people/domain/card_registry.dart';
import 'package:farm_tap/core/people/domain/photo_store.dart';
import 'package:farm_tap/core/people/domain/staff_access_repository.dart';
import 'package:farm_tap/core/people/domain/staff_directory.dart';
import 'package:farm_tap/core/people/domain/staff_member.dart';
import 'package:farm_tap/core/sync/record_journal.dart';

/// The farm's staff, saved as `staff` records with PIN hashes in
/// `staffPins` (decision 0015 §5); cards come from the shared
/// [CardRegistry], so a card has one holder (staff or farmer).
///
/// Sample staff from the mockups use PIN 1234. Peter has no card yet (K01
/// "No card"); blank cards 0207-0215 are in stock. With [withSamples] false
/// (real data) the farm starts with no staff, no blank cards and no PIN.
class FakeStaffAccessRepository implements StaffAccessRepository, StaffDirectory, Restorable {
  new({
    this.nfc = true,
    this.today,
    DateTime Function()? now,
    this._hasher = const PinHasher(iterations: 2000),
    this.journal,
    this.withSamples = true,
    LocalCardRegistry? cards,
  }) : _lockout = PinLockout(now: now ?? _never),
       _staff = withSamples ? [...sample] : [],
       cards =
           cards ??
           LocalCardRegistry(
             now: now ?? _never,
             journal: journal,
             seed: withSamples ? sampleCards : const [],
             blankStock: withSamples ? [for (var n = 207; n <= 215; n++) n.toString().padLeft(4, '0')] : const [],
           );

  /// False in real-data mode.
  final bool withSamples;

  /// The simulator and web have no NFC; set false to show C05.
  final bool nfc;

  /// Saves records on the phone for sync (decision 0014); null in tests.
  final RecordJournal? journal;

  /// Every card on the farm (staff and farmers).
  final LocalCardRegistry cards;

  /// Start date for new staff ("since").
  final DateTime Function()? today;

  /// PIN hashes by staff id (decision 0014 §6); never the typed PIN.
  final _pinHashes = <String, String>{};

  /// Staff whose PIN was set by a manager: they choose their own next.
  final _mustChange = <String>{};
  final PinHasher _hasher;
  final PinLockout _lockout;
  var _nextId = 1;

  /// Without a clock a lock never ends (tests that only count tries).
  static DateTime _never() => DateTime(2000);
  String? _sampleHash;

  /// Only the demo staff share PIN 1234; a real person without a saved
  /// hash cannot unlock until a manager sets their PIN.
  String? _hashFor(String staffId) => _pinHashes[staffId] ?? (withSamples ? (_sampleHash ??= _hasher.hash(pin)) : null);
  final List<StaffMember> _staff;

  bool _matches(String staffId, String entered) {
    final hash = _hashFor(staffId);
    return hash != null && _hasher.verify(entered, hash);
  }

  static Map<String, Object?> _staffBody(StaffMember s) => {
    'name': s.name,
    'role': s.role.name,
    'title': s.title,
    'phone': s.phone,
    'monthlyWage': s.monthlyWage,
    'cardNumber': s.cardNumber,
    'since': s.since?.toIso8601String(),
    'department': s.department,
    'nationalId': s.nationalId,
    'village': s.village,
    'emergencyName': s.emergencyName,
    'emergencyPhone': s.emergencyPhone,
    'photo': s.photo,
    'photoUrl': s.photoUrl,
    'login': s.login.name,
    'active': true,
  };

  static StaffMember _fromBody(String id, Map<String, Object?> b) {
    final since = b['since'] as String?;
    return StaffMember(
      id: id,
      name: b['name']! as String,
      role: StaffRole.values.byName(b['role']! as String),
      since: since == null ? null : DateTime.parse(since),
      title: b['title'] as String?,
      phone: b['phone'] as String?,
      monthlyWage: b['monthlyWage'] as int?,
      department: b['department'] as String?,
      nationalId: b['nationalId'] as String?,
      village: b['village'] as String?,
      emergencyName: b['emergencyName'] as String?,
      emergencyPhone: b['emergencyPhone'] as String?,
      photo: b['photo'] as String?,
      photoUrl: b['photoUrl'] as String?,
      login: StaffLoginStatus.values.asNameMap()[b['login']] ?? StaffLoginStatus.none,
    );
  }

  static final sample = [
    StaffMember(
      id: 'staff-mt',
      name: 'Mugisha Tom',
      role: StaffRole.manager,
      cardNumber: '0101',
      shortName: 'Tom',
      since: DateTime(2022, 6),
      department: 'Management',
      phone: '772 104 551',
    ),
    StaffMember(
      id: 'staff-ta',
      name: 'Twinomujuni Amos',
      role: StaffRole.herdsman,
      cardNumber: '0142',
      since: DateTime(2024, 3),
      department: 'Milking',
      phone: '701 220 318',
      emergencyName: 'Kyomuhendo Sarah',
      emergencyPhone: '772 118 090',
      village: 'Kashari',
    ),
    StaffMember(
      id: 'staff-aj',
      name: 'Ahimbisibwe Joy',
      role: StaffRole.clerk,
      cardNumber: '0155',
      shortName: 'Joy',
      since: DateTime(2023, 9),
      department: 'Office',
    ),
    StaffMember(id: 'staff-np', name: 'Nuwagaba Peter', role: StaffRole.worker, since: DateTime(2026, 10)),
    StaffMember(
      id: 'staff-kr',
      name: 'Katusiime Rita',
      role: StaffRole.worker,
      cardNumber: '0168',
      since: DateTime(2025),
      department: 'Field',
    ),
    StaffMember(
      id: 'staff-ki',
      name: 'Dr. Kamugisha Ivan',
      role: StaffRole.vet,
      cardNumber: '0190',
      shortName: 'Ivan',
      since: DateTime(2023, 2),
      department: 'Animal health',
    ),
  ];

  /// The sample staff's cards in the register.
  static final sampleCards = [
    for (final s in sample)
      if (s.cardNumber != null)
        IdCardRecord(
          number: s.cardNumber!,
          holderId: s.id,
          holderKind: CardHolderKind.staff,
          holderName: s.name,
          status: CardStatus.active,
          issuedAt: s.since,
        ),
  ];

  static const pin = '1234';
  static const maxTries = 5;

  /// Staff, their PIN hashes and cards: unlock works offline after a restart.
  @override
  Future<void> restore() async {
    final j = journal;
    if (j == null) return;
    for (final r in await j.load('staff')) {
      final s = _fromBody(r.id, r.body);
      final i = _staff.indexWhere((x) => x.id == r.id);
      if (i >= 0) {
        _staff[i] = s;
      } else {
        _staff.add(s);
      }
      if (r.body['pinHash'] case final String hash) _pinHashes[r.id] = hash;
    }
    // A PIN the worker chose (or a manager reset) is newer than the one in
    // the staff record.
    for (final r in await j.load('staffPins')) {
      if (r.body['pinHash'] case final String hash) _pinHashes[r.id] = hash;
      if (r.body['mustChange'] == true) {
        _mustChange.add(r.id);
      } else {
        _mustChange.remove(r.id);
      }
    }
    await cards.restore();
    await _syncCards();
  }

  /// Each worker's card number is their active card in the register.
  Future<void> _syncCards() async {
    for (var i = 0; i < _staff.length; i++) {
      final card = (await cards.activeCardOf(_staff[i].id)).data;
      if (card?.number != _staff[i].cardNumber) _staff[i] = _staff[i].withCard(card?.number);
    }
  }

  @override
  Future<bool> nfcAvailable() async => nfc;

  @override
  Future<Result<StaffMember?>> findByCard(String cardNumber) async {
    final card = (await cards.lookup(cardNumber)).data;
    if (card == null || !card.active || card.holderKind != CardHolderKind.staff) return const Result.success(null);
    return Result.success(_staff.where((s) => s.id == card.holderId).firstOrNull);
  }

  @override
  Future<Result<PinCheck>> verifyPin(String staffId, String entered) async {
    if (_lockout.isLocked(staffId)) return const Result.success(PinLocked());
    if (_matches(staffId, entered)) {
      _lockout.reset(staffId);
      return Result.success(PinAccepted(mustChange: _mustChange.contains(staffId)));
    }
    final left = _lockout.recordWrong(staffId);
    if (left == 0) return const Result.success(PinLocked());
    return Result.success(PinRejected(left));
  }

  @override
  Future<Result<List<StaffMember>>> staff() async => Result.success(List.unmodifiable(_staff));

  @override
  Future<Result<StaffMember?>> staffById(String staffId) async =>
      Result.success(_staff.where((s) => s.id == staffId).firstOrNull);

  Future<void> _save(StaffMember s) async =>
      journal?.put('staff', s.id, {..._staffBody(s), 'pinHash': _pinHashes[s.id]});

  Future<void> _savePin(String staffId) async => journal?.put('staffPins', staffId, {
    'pinHash': _pinHashes[staffId],
    'mustChange': _mustChange.contains(staffId),
  });

  @override
  Future<Result<StaffMember>> addStaff({
    required String name,
    required StaffRole role,
    required String pin,
    String? title,
    String? phone,
    int? monthlyWage,
    String? department,
    String? nationalId,
    String? village,
    String? emergencyName,
    String? emergencyPhone,
  }) async {
    final s = StaffMember(
      id: journal?.newId() ?? 'staff-new-${_nextId++}',
      name: name,
      role: role,
      since: today?.call(),
      title: title,
      phone: phone,
      monthlyWage: monthlyWage,
      department: department,
      nationalId: nationalId,
      village: village,
      emergencyName: emergencyName,
      emergencyPhone: emergencyPhone,
    );
    _staff.add(s);
    _pinHashes[s.id] = _hasher.hash(pin);
    // The manager chose this PIN: the worker picks their own at first use.
    _mustChange.add(s.id);
    // Only the PIN hash leaves the phone, so unlock works on every farm phone.
    await journal?.add('staff', {..._staffBody(s), 'pinHash': _pinHashes[s.id]}, id: s.id);
    await _savePin(s.id);
    return Result.success(s);
  }

  @override
  Future<Result<StaffMember>> updateStaff(
    String staffId, {
    required String name,
    required StaffRole role,
    String? title,
    String? phone,
    int? monthlyWage,
    String? department,
    String? nationalId,
    String? village,
    String? emergencyName,
    String? emergencyPhone,
  }) async {
    final i = _staff.indexWhere((s) => s.id == staffId);
    if (i < 0) return const Result.failure(ValidationFailure('staff-unknown'));
    final old = _staff[i];
    _staff[i] = StaffMember(
      id: staffId,
      name: name,
      role: role,
      cardNumber: old.cardNumber,
      since: old.since,
      title: title,
      phone: phone,
      monthlyWage: monthlyWage,
      department: department,
      nationalId: nationalId,
      village: village,
      emergencyName: emergencyName,
      emergencyPhone: emergencyPhone,
      photo: old.photo,
      photoUrl: old.photoUrl,
      login: old.login,
    );
    await _save(_staff[i]);
    if (old.name != name) await cards.renameHolder(staffId, name);
    return Result.success(_staff[i]);
  }

  @override
  Future<Result<String?>> nextBlankCard() async => Result.success(cards.nextNumber());

  @override
  Future<Result<StaffMember>> assignCard(String staffId, String? cardNumber, {bool replace = false}) async {
    final i = _staff.indexWhere((s) => s.id == staffId);
    if (i < 0) return const Result.failure(ValidationFailure('staff-unknown'));
    final issued = await cards.issue(
      holderId: staffId,
      kind: CardHolderKind.staff,
      holderName: _staff[i].name,
      scanned: cardNumber,
      replace: replace,
    );
    switch (issued) {
      case FailureResult(:final failure):
        return Result.failure(failure);
      case Success(:final data):
        _staff[i] = _staff[i].withCard(data.number);
        await _save(_staff[i]);
        return Result.success(_staff[i]);
    }
  }

  @override
  Future<Result<StaffMember>> revokeCard(String staffId, CardStatus why) async {
    final i = _staff.indexWhere((s) => s.id == staffId);
    if (i < 0) return const Result.failure(ValidationFailure('staff-unknown'));
    final card = (await cards.activeCardOf(staffId)).data;
    if (card != null) await cards.revoke(card.number, why);
    _staff[i] = _staff[i].withCard(null);
    await _save(_staff[i]);
    return Result.success(_staff[i]);
  }

  @override
  Future<Result<List<IdCardRecord>>> cardHistory(String staffId) => cards.historyOf(staffId);

  @override
  Future<Result<StaffMember>> setPhoto(String staffId, PersonPhoto photo) async {
    final i = _staff.indexWhere((s) => s.id == staffId);
    if (i < 0) return const Result.failure(ValidationFailure('staff-unknown'));
    _staff[i] = _staff[i].copyWith(photo: photo.thumb, photoUrl: photo.url);
    await _save(_staff[i]);
    return Result.success(_staff[i]);
  }

  @override
  Future<Result<bool>> verifyManagerPin(String entered) async =>
      Result.success(_staff.any((s) => s.role == StaffRole.manager && _matches(s.id, entered)));

  @override
  Future<Result<void>> resetPin(String staffId, String temporaryPin) async {
    _lockout.reset(staffId);
    _pinHashes[staffId] = _hasher.hash(temporaryPin);
    _mustChange.add(staffId);
    await _savePin(staffId);
    return const Result.success(null);
  }

  @override
  Future<Result<void>> setOwnPin(String staffId, String pin) async {
    _lockout.reset(staffId);
    _pinHashes[staffId] = _hasher.hash(pin);
    _mustChange.remove(staffId);
    await _savePin(staffId);
    return const Result.success(null);
  }

  @override
  Future<Result<StaffMember>> setLoginStatus(String staffId, StaffLoginStatus status) async {
    final i = _staff.indexWhere((s) => s.id == staffId);
    if (i < 0) return const Result.failure(ValidationFailure('staff-unknown'));
    _staff[i] = _staff[i].copyWith(login: status);
    await _save(_staff[i]);
    return Result.success(_staff[i]);
  }
}
