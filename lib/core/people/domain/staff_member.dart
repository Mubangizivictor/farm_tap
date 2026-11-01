import 'package:equatable/equatable.dart';

enum StaffRole { manager, herdsman, clerk, worker, vet }

/// A farm worker who unlocks the farm phone with an NFC card + 4-digit PIN.
/// Workers have no email account (ROADMAP binding rule 12).
class StaffMember extends Equatable {
  const new({required this.id, required this.name, required this.role, required this.cardNumber, this.shortName});

  final String id;

  /// "Twinomujuni Amos".
  final String name;

  /// What the app calls them: "Amos".
  final String? shortName;
  final StaffRole role;

  /// Printed on the card: "0142".
  final String cardNumber;

  String get greetingName => shortName ?? name.split(' ').last;

  @override
  List<Object?> get props => [id, name, shortName, role, cardNumber];
}

/// Result of a PIN check.
sealed class PinCheck {
  const new();
}

class PinAccepted extends PinCheck {
  const new();
}

class PinRejected extends PinCheck {
  const new(this.triesLeft);

  final int triesLeft;
}

/// After 5 wrong tries the card locks for 5 minutes (UX_SPEC C04).
class PinLocked extends PinCheck {
  const new();
}
