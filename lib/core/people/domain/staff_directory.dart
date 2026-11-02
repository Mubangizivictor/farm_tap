import 'package:farm_tap/core/error/result.dart';
import 'package:farm_tap/core/people/domain/staff_member.dart';

/// The farm's staff and their NFC cards (K01-K03). The unlock screens read
/// the same people, so a card assigned here unlocks the phone at once.
abstract interface class StaffDirectory {
  Future<Result<List<StaffMember>>> staff();

  /// The next blank printed card in stock ("0207").
  Future<Result<String?>> nextBlankCard();

  /// K03: gives [staffId] the card; their old card (if any) stops working.
  /// Fails when another person already has the card.
  Future<Result<StaffMember>> assignCard(String staffId, String cardNumber);

  /// K02: the worker chooses a new PIN at their next unlock.
  Future<Result<void>> resetPin(String staffId);
}
