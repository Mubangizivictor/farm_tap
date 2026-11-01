import 'package:farm_tap/core/error/result.dart';
import 'package:farm_tap/core/people/domain/staff_access_repository.dart';
import 'package:farm_tap/core/people/domain/staff_member.dart';

/// Sample staff from the mockups. Every PIN is 1234 in the UI phase.
class FakeStaffAccessRepository implements StaffAccessRepository {
  new({this.nfc = true});

  /// The simulator and web have no NFC; set false to show C05.
  final bool nfc;
  final _wrongTries = <String, int>{};

  static const staff = [
    StaffMember(id: 'staff-mt', name: 'Mugisha Tom', role: StaffRole.manager, cardNumber: '0101', shortName: 'Tom'),
    StaffMember(id: 'staff-ta', name: 'Twinomujuni Amos', role: StaffRole.herdsman, cardNumber: '0142'),
    StaffMember(id: 'staff-aj', name: 'Ahimbisibwe Joy', role: StaffRole.clerk, cardNumber: '0155', shortName: 'Joy'),
    StaffMember(id: 'staff-np', name: 'Nuwagaba Peter', role: StaffRole.worker, cardNumber: '0207'),
    StaffMember(id: 'staff-kr', name: 'Katusiime Rita', role: StaffRole.worker, cardNumber: '0168'),
    StaffMember(id: 'staff-ki', name: 'Dr. Kamugisha Ivan', role: StaffRole.vet, cardNumber: '0190', shortName: 'Ivan'),
  ];

  static const pin = '1234';
  static const maxTries = 5;

  @override
  Future<bool> nfcAvailable() async => nfc;

  @override
  Future<Result<StaffMember?>> findByCard(String cardNumber) async {
    for (final s in staff) {
      if (s.cardNumber == cardNumber.padLeft(4, '0')) return Result.success(s);
    }
    return const Result.success(null);
  }

  @override
  Future<Result<PinCheck>> verifyPin(String staffId, String entered) async {
    if (entered == pin) {
      _wrongTries.remove(staffId);
      return const Result.success(PinAccepted());
    }
    final wrong = (_wrongTries[staffId] ?? 0) + 1;
    _wrongTries[staffId] = wrong;
    if (wrong >= maxTries) return const Result.success(PinLocked());
    return Result.success(PinRejected(maxTries - wrong));
  }
}
