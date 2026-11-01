import 'package:farm_tap/core/error/result.dart';
import 'package:farm_tap/core/people/domain/staff_member.dart';

abstract interface class StaffAccessRepository {
  /// Whether the phone can read NFC cards now (C05 when not).
  Future<bool> nfcAvailable();

  Future<Result<StaffMember?>> findByCard(String cardNumber);

  Future<Result<PinCheck>> verifyPin(String staffId, String pin);
}
