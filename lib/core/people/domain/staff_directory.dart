import 'package:farm_tap/core/error/result.dart';
import 'package:farm_tap/core/people/domain/card_registry.dart';
import 'package:farm_tap/core/people/domain/photo_store.dart';
import 'package:farm_tap/core/people/domain/staff_member.dart';

/// The farm's staff and their NFC cards (K01-K03). The unlock screens read
/// the same people, so a card assigned here unlocks the phone at once.
abstract interface class StaffDirectory {
  Future<Result<List<StaffMember>>> staff();

  Future<Result<StaffMember?>> staffById(String staffId);

  /// K01 Add worker (B09 too): [pin] unlocks; a card can be given at once
  /// with [assignCard]. The PIN is temporary: the worker chooses their own
  /// at their first unlock or sign-in (decision 0016 §5).
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
  });

  /// K02 Edit worker.
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
  });

  /// The next blank printed card in stock ("0207"), else a free number.
  Future<Result<String?>> nextBlankCard();

  /// K03: gives [staffId] the card that was read or typed ([cardNumber]: a
  /// number, chip id or QR); null gives a new number for a printed card.
  /// Fails when another person holds the card, when it was lost, or when
  /// the worker already has a card and [replace] is false (decision 0016).
  Future<Result<StaffMember>> assignCard(String staffId, String? cardNumber, {bool replace = false});

  /// Ends the worker's card: lost (never works again) or returned.
  Future<Result<StaffMember>> revokeCard(String staffId, CardStatus why);

  /// Card history of a worker, newest first.
  Future<Result<List<IdCardRecord>>> cardHistory(String staffId);

  Future<Result<StaffMember>> setPhoto(String staffId, PersonPhoto photo);

  /// P04: true when [pin] is a manager's (or the owner's) PIN.
  Future<Result<bool>> verifyManagerPin(String pin);

  /// K02: a manager sets a temporary PIN; the worker must choose their own
  /// at the next unlock or sign-in.
  Future<Result<void>> resetPin(String staffId, String temporaryPin);

  /// The worker chose their own PIN (first unlock or sign-in).
  Future<Result<void>> setOwnPin(String staffId, String pin);

  /// Phone sign-in set up (or failed) for this worker.
  Future<Result<StaffMember>> setLoginStatus(String staffId, StaffLoginStatus status);
}
