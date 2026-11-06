import 'package:equatable/equatable.dart';
import 'package:farm_tap/core/error/result.dart';

/// Who carries a card.
enum CardHolderKind { staff, farmer }

/// A card's life (decision 0016 §1).
enum CardStatus {
  /// Works: the holder can tap it.
  active,

  /// Given back (worker left, farmer stopped): can go to someone new.
  returned,

  /// Lost or stolen: never works again and is never given again.
  lost,
}

/// One FarmTap card: staff or milk-supplier ID with NFC chip, QR code and a
/// printed 4-digit number.
class IdCardRecord extends Equatable {
  const new({
    required this.number,
    required this.holderId,
    required this.holderKind,
    required this.holderName,
    required this.status,
    this.chipId,
    this.issuedAt,
    this.endedAt,
  });

  /// "0142": printed on the card and typed when a phone has no NFC.
  final String number;

  /// The NFC chip's id when the chip carries no number ("04A2B3C4D5E680").
  final String? chipId;
  final String holderId;
  final CardHolderKind holderKind;

  /// Kept on the card record for "belongs to Amos" messages.
  final String holderName;
  final CardStatus status;
  final DateTime? issuedAt;

  /// When it was returned or reported lost.
  final DateTime? endedAt;

  bool get active => status == CardStatus.active;

  IdCardRecord ended(CardStatus why, DateTime at) => IdCardRecord(
    number: number,
    chipId: chipId,
    holderId: holderId,
    holderKind: holderKind,
    holderName: holderName,
    status: why,
    issuedAt: issuedAt,
    endedAt: at,
  );

  @override
  List<Object?> get props => [number, chipId, holderId, holderKind, holderName, status, issuedAt, endedAt];
}

/// Why a card could not be issued.
abstract final class CardIssueError {
  /// `card-taken:<holder name>`: active and held by someone else.
  static const taken = 'card-taken';

  /// Reported lost: never reissued.
  static const lost = 'card-lost';

  /// The person already has an active card (replace it instead).
  static const hasCard = 'has-card';

  /// A QR code from another farm.
  static const otherFarm = 'other-farm';
}

/// Every card on the farm, for staff and farmers alike: a card has one
/// holder until it is revoked (decision 0016 §1).
abstract interface class CardRegistry {
  /// The card for what was read: a typed number ("142"), an NFC chip id or
  /// a scanned QR payload. Returns lost and returned cards too.
  Future<Result<IdCardRecord?>> lookup(String scanned);

  /// The person's working card, if any.
  Future<Result<IdCardRecord?>> activeCardOf(String holderId);

  /// The person's cards, newest first (card history).
  Future<Result<List<IdCardRecord>>> historyOf(String holderId);

  /// Every card, newest first.
  Future<Result<List<IdCardRecord>>> cards();

  /// Gives a card to a person. [scanned] is what was read or typed; null
  /// gives a new number (a printed QR-only card). With [replace] the
  /// person's current card is marked lost in the same step.
  ///
  /// Fails with a [CardIssueError] message.
  Future<Result<IdCardRecord>> issue({
    required String holderId,
    required CardHolderKind kind,
    required String holderName,
    String? scanned,
    bool replace = false,
  });

  /// Ends a card: [CardStatus.lost] or [CardStatus.returned].
  Future<Result<IdCardRecord>> revoke(String number, CardStatus why);
}

/// The QR code printed on a FarmTap card: `FTID:<tenantId>:<number>`.
abstract final class CardQr {
  static const prefix = 'FTID';

  static String encode(String tenantId, String number) => '$prefix:$tenantId:$number';

  /// (tenantId, number) or null when it is not a FarmTap card QR.
  static (String, String)? decode(String text) {
    final parts = text.trim().split(':');
    if (parts.length != 3 || parts[0] != prefix) return null;
    final n = parts[2].replaceAll(RegExp(r'\D'), '');
    if (n.isEmpty || n.length > 4) return null;
    return (parts[1], n.padLeft(4, '0'));
  }
}
