import 'package:equatable/equatable.dart';

/// A short, stable number for a person's record ("ST-04217", "MS-55120"),
/// printed on ID cards. FNV-1a over the id, so every phone gets the same.
String personCode(String prefix, String id) {
  var h = 0x811c9dc5;
  for (final c in id.codeUnits) {
    h = ((h ^ c) * 0x01000193) & 0xffffffff;
  }
  return '$prefix-${(h % 100000).toString().padLeft(5, '0')}';
}

enum StaffRole { manager, herdsman, clerk, worker, vet }

/// Whether a worker can sign in on their own phone with phone + PIN
/// (decision 0015).
enum StaffLoginStatus {
  /// No phone number, or never set up.
  none,

  /// The login exists; the worker still has to choose their own PIN.
  mustChangePin,

  /// The worker has signed in and chosen their PIN.
  active,

  /// The phone was offline when the worker was added: set it up again.
  failed,
}

/// A farm worker who unlocks the farm phone with an NFC card + 4-digit PIN,
/// or signs in on their own phone with phone + PIN (decision 0015).
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
    this.department,
    this.nationalId,
    this.village,
    this.emergencyName,
    this.emergencyPhone,
    this.photo,
    this.photoUrl,
    this.login = StaffLoginStatus.none,
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

  /// "Milking", "Field", "Office" (printed on the ID card).
  final String? department;

  /// National ID number (NIN), optional.
  final String? nationalId;

  /// Where they live.
  final String? village;

  /// Who to call in an emergency (back of the ID card).
  final String? emergencyName;
  final String? emergencyPhone;

  /// Small JPEG (base64) kept in the record so it prints and syncs on the
  /// free plan (decision 0015 §2).
  final String? photo;

  /// Full photo in Firebase Storage, once Storage is on.
  final String? photoUrl;

  final StaffLoginStatus login;

  bool get hasCard => cardNumber != null;
  bool get hasPhoto => (photo ?? '').isNotEmpty;

  /// "ST-04217": the staff number printed on the ID card (stable, from the id).
  String get staffCode => personCode('ST', id);

  StaffMember copyWith({
    String? name,
    StaffRole? role,
    String? title,
    String? phone,
    int? monthlyWage,
    String? department,
    String? nationalId,
    String? village,
    String? emergencyName,
    String? emergencyPhone,
    String? photo,
    String? photoUrl,
    StaffLoginStatus? login,
  }) => StaffMember(
    id: id,
    name: name ?? this.name,
    role: role ?? this.role,
    cardNumber: cardNumber,
    shortName: name == null ? shortName : null,
    since: since,
    title: title ?? this.title,
    phone: phone ?? this.phone,
    monthlyWage: monthlyWage ?? this.monthlyWage,
    department: department ?? this.department,
    nationalId: nationalId ?? this.nationalId,
    village: village ?? this.village,
    emergencyName: emergencyName ?? this.emergencyName,
    emergencyPhone: emergencyPhone ?? this.emergencyPhone,
    photo: photo ?? this.photo,
    photoUrl: photoUrl ?? this.photoUrl,
    login: login ?? this.login,
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
    department: department,
    nationalId: nationalId,
    village: village,
    emergencyName: emergencyName,
    emergencyPhone: emergencyPhone,
    photo: photo,
    photoUrl: photoUrl,
    login: login,
  );

  String get greetingName => shortName ?? name.split(' ').last;

  @override
  List<Object?> get props => [
    id,
    name,
    shortName,
    role,
    cardNumber,
    since,
    title,
    phone,
    monthlyWage,
    department,
    nationalId,
    village,
    emergencyName,
    emergencyPhone,
    photo,
    photoUrl,
    login,
  ];
}

/// The optional details of the add / edit worker form (decision 0015).
class StaffDetails extends Equatable {
  const new({
    this.title,
    this.phone,
    this.monthlyWage,
    this.department,
    this.nationalId,
    this.village,
    this.emergencyName,
    this.emergencyPhone,
  });

  final String? title;
  final String? phone;
  final int? monthlyWage;
  final String? department;
  final String? nationalId;
  final String? village;
  final String? emergencyName;
  final String? emergencyPhone;

  @override
  List<Object?> get props => [title, phone, monthlyWage, department, nationalId, village, emergencyName, emergencyPhone];
}

/// Result of a PIN check.
sealed class PinCheck {
  const new();
}

class PinAccepted extends PinCheck {
  const new({this.mustChange = false});

  /// A manager set (or reset) this PIN: the worker chooses their own now.
  final bool mustChange;
}

class PinRejected extends PinCheck {
  const new(this.triesLeft);

  final int triesLeft;
}

/// After 5 wrong tries the card locks for 5 minutes (UX_SPEC C04).
class PinLocked extends PinCheck {
  const new();
}
