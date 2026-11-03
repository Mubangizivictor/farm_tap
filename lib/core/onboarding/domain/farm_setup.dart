import 'package:equatable/equatable.dart';
import 'package:farm_tap/core/people/domain/staff_member.dart';

enum Sector { dairy, poultry, piggery, goats, crops, fish }

enum DairyType { farm, centre, both }

/// What the person setting up may do: an owner can do everything, a manager
/// everything except billing and removing the owner.
enum SetupRole { owner, manager }

class FirstWorker extends Equatable {
  const new({
    required this.name,
    required this.role,
    required this.pin,
    this.title,
    this.phone,
    this.monthlyWage,
    this.cardNumber,
  });

  final String name;

  /// What they can do in the app.
  final StaffRole role;

  /// Their job in their words ("Herdsman", "Farmer's daughter").
  final String? title;
  final String? phone;
  final int? monthlyWage;
  final String pin;

  /// Their NFC card, read or typed during setup; null = give one later.
  final String? cardNumber;

  @override
  List<Object?> get props => [name, role, title, phone, monthlyWage, pin, cardNumber];
}

/// Everything the onboarding steps (B02-B09) collect before the farm is
/// created. Phone numbers are the 9 digits after +256 and are not verified
/// by OTP: they show "Not yet confirmed" until the first message arrives.
class FarmSetup extends Equatable {
  const new({
    this.sector = Sector.dairy,
    this.dairyType = DairyType.farm,
    this.farmName = '',
    this.district,
    this.village = '',
    this.cows,
    this.whatsapp = '',
    this.smsSameAsWhatsapp = false,
    this.sms = '',
    this.dailyReport = true,
    this.smsAlerts = true,
    this.role = SetupRole.owner,
    this.roleTitle = '',
    this.firstWorker,
  });

  final Sector sector;
  final DairyType dairyType;
  final String farmName;

  /// Any of Uganda's districts, or what the person typed.
  final String? district;
  final String village;

  /// Head of cattle today (an exact number).
  final int? cows;
  final String whatsapp;
  final bool smsSameAsWhatsapp;

  /// Where SMS alerts go; can differ from [whatsapp].
  final String sms;
  final bool dailyReport;
  final bool smsAlerts;
  final SetupRole role;

  /// Their own word for it: "Owner", "Farmer's son", "Secretary".
  final String roleTitle;
  final FirstWorker? firstWorker;

  FarmSetup copyWith({
    Sector? sector,
    DairyType? dairyType,
    String? farmName,
    String? district,
    String? village,
    int? cows,
    String? whatsapp,
    bool? smsSameAsWhatsapp,
    String? sms,
    bool? dailyReport,
    bool? smsAlerts,
    SetupRole? role,
    String? roleTitle,
    FirstWorker? firstWorker,
  }) => FarmSetup(
    sector: sector ?? this.sector,
    dairyType: dairyType ?? this.dairyType,
    farmName: farmName ?? this.farmName,
    district: district ?? this.district,
    village: village ?? this.village,
    cows: cows ?? this.cows,
    whatsapp: whatsapp ?? this.whatsapp,
    smsSameAsWhatsapp: smsSameAsWhatsapp ?? this.smsSameAsWhatsapp,
    sms: sms ?? this.sms,
    dailyReport: dailyReport ?? this.dailyReport,
    smsAlerts: smsAlerts ?? this.smsAlerts,
    role: role ?? this.role,
    roleTitle: roleTitle ?? this.roleTitle,
    firstWorker: firstWorker ?? this.firstWorker,
  );

  @override
  List<Object?> get props => [
    sector,
    dairyType,
    farmName,
    district,
    village,
    cows,
    whatsapp,
    smsSameAsWhatsapp,
    sms,
    dailyReport,
    smsAlerts,
    role,
    roleTitle,
    firstWorker,
  ];
}
