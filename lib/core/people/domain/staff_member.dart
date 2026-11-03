import 'package:equatable/equatable.dart';

enum StaffRole { manager, herdsman, clerk, worker, vet }

/// A farm worker who unlocks the farm phone with an NFC card + 4-digit PIN.
/// Workers have no email account (ROADMAP binding rule 12).
class StaffMember extends Equatable {
  const new({
    required this.id,
    required this.name,
    required this.role,
    this.cardNumber,
    this.shortName,
    this.since,
    this.title,
    this.phone,
    this.monthlyWage,
  });

  final String id;

  /// "Twinomujuni Amos".
  final String name;

  /// What the app calls them: "Amos".
  final String? shortName;

  /// What they may do in the app (access level).
  final StaffRole role;

  /// Their job as the farm calls it: "Secretary", "Farmer's daughter";
  /// null shows the [role] name.
  final String? title;

  /// The 9 digits after +256.
  final String? phone;

  /// UGX a month (K05 wages); null when not on the wage sheet.
  final int? monthlyWage;

  /// Printed on the card: "0142"; null until a card is assigned (K03).
  final String? cardNumber;

  /// Started working on the farm (K02 "since Mar 2024").
  final DateTime? since;

  bool get hasCard => cardNumber != null;

  StaffMember copyWith({String? name, StaffRole? role, String? title, String? phone, int? monthlyWage}) => StaffMember(
    id: id,
    name: name ?? this.name,
    role: role ?? this.role,
    cardNumber: cardNumber,
    shortName: name == null ? shortName : null,
    since: since,
    title: title ?? this.title,
    phone: phone ?? this.phone,
    monthlyWage: monthlyWage ?? this.monthlyWage,
  );

  StaffMember withCard(String? card) => StaffMember(
    id: id,
    name: name,
    role: role,
    cardNumber: card,
    shortName: shortName,
    since: since,
    title: title,
    phone: phone,
    monthlyWage: monthlyWage,
  );

  String get greetingName => shortName ?? name.split(' ').last;

  @override
  List<Object?> get props => [id, name, shortName, role, cardNumber, since, title, phone, monthlyWage];
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
