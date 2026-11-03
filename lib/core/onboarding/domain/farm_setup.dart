import 'package:equatable/equatable.dart';

enum Sector { dairy, poultry, piggery, goats, crops, fish }

enum DairyType { farm, centre, both }

enum HerdSize { upTo10, upTo30, upTo100, over100 }

enum SetupRole { owner, manager }

enum WorkerRole { manager, herdsman, clerk, worker, vet }

class FirstWorker extends Equatable {
  const new({required this.name, required this.role, required this.pin});

  final String name;
  final WorkerRole role;
  final String pin;

  @override
  List<Object?> get props => [name, role, pin];
}

/// Everything the onboarding steps (B01-B09) collect before the farm is
/// created. Phone numbers are the 9 digits after +256 and are not verified
/// by OTP: they show "Not yet confirmed" until the first message arrives.
class FarmSetup extends Equatable {
  const new({
    this.sector = Sector.dairy,
    this.dairyType = DairyType.farm,
    this.farmName = '',
    this.district,
    this.village = '',
    this.herdSize,
    this.whatsapp = '',
    this.smsSameAsWhatsapp = true,
    this.sms = '',
    this.dailyReport = true,
    this.smsAlerts = true,
    this.role = SetupRole.owner,
    this.firstWorker,
  });

  final Sector sector;
  final DairyType dairyType;
  final String farmName;
  final String? district;
  final String village;
  final HerdSize? herdSize;
  final String whatsapp;
  final bool smsSameAsWhatsapp;
  final String sms;
  final bool dailyReport;
  final bool smsAlerts;
  final SetupRole role;
  final FirstWorker? firstWorker;

  FarmSetup copyWith({
    Sector? sector,
    DairyType? dairyType,
    String? farmName,
    String? district,
    String? village,
    HerdSize? herdSize,
    String? whatsapp,
    bool? smsSameAsWhatsapp,
    String? sms,
    bool? dailyReport,
    bool? smsAlerts,
    SetupRole? role,
    FirstWorker? firstWorker,
  }) => FarmSetup(
    sector: sector ?? this.sector,
    dairyType: dairyType ?? this.dairyType,
    farmName: farmName ?? this.farmName,
    district: district ?? this.district,
    village: village ?? this.village,
    herdSize: herdSize ?? this.herdSize,
    whatsapp: whatsapp ?? this.whatsapp,
    smsSameAsWhatsapp: smsSameAsWhatsapp ?? this.smsSameAsWhatsapp,
    sms: sms ?? this.sms,
    dailyReport: dailyReport ?? this.dailyReport,
    smsAlerts: smsAlerts ?? this.smsAlerts,
    role: role ?? this.role,
    firstWorker: firstWorker ?? this.firstWorker,
  );

  @override
  List<Object?> get props => [
    sector,
    dairyType,
    farmName,
    district,
    village,
    herdSize,
    whatsapp,
    smsSameAsWhatsapp,
    sms,
    dailyReport,
    smsAlerts,
    role,
    firstWorker,
  ];
}
