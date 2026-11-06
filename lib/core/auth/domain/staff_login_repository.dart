import 'package:farm_tap/core/error/result.dart';
import 'package:farm_tap/core/people/domain/staff_member.dart';

/// After a worker signs in with phone + PIN.
class StaffSignIn {
  const new({required this.mustChangePin, required this.tenantId, required this.staffId});

  /// The PIN was set by a manager: the worker must choose their own now.
  final bool mustChangePin;
  final String tenantId;
  final String staffId;
}

/// Why a staff login could not be made or used.
abstract final class StaffLoginError {
  /// Phone number or PIN wrong (never says which).
  static const wrong = 'staff-login-wrong';

  /// The number signs in to another farm already.
  static const otherFarm = 'staff-login-other-farm';

  /// Too many wrong tries: wait and try again.
  static const tooMany = 'staff-login-too-many';
  static const offline = 'staff-login-offline';
}

/// Workers sign in on their own phone with their phone number and a
/// 4-digit PIN (decision 0016 §5). No SMS, no OTP, nothing to pay.
abstract interface class StaffLoginRepository {
  /// On the manager's phone: makes (or renews, after a PIN reset) the
  /// worker's login with a temporary [pin] the worker must change.
  Future<Result<void>> createLogin({
    required String tenantId,
    required String staffId,
    required String name,
    required String phone,
    required String pin,
    required StaffRole role,
  });

  /// On the worker's phone.
  Future<Result<StaffSignIn>> signIn({required String phone, required String pin});

  /// The signed-in worker chooses their own PIN (first sign-in or after a
  /// reset).
  Future<Result<void>> changePin(String newPin);
}

/// "0772 451 908", "+256 772451908", "772451908" -> "772451908" (9 digits),
/// else null.
String? ugPhoneDigits(String input) {
  var d = input.replaceAll(RegExp(r'\D'), '');
  if (d.startsWith('256')) d = d.substring(3);
  if (d.startsWith('0')) d = d.substring(1);
  return RegExp(r'^\d{9}$').hasMatch(d) ? d : null;
}
