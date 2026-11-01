import 'package:equatable/equatable.dart';

enum AnimalSex { male, female }

enum AnimalStatus { active, sold, deceased, transferred }

enum SyncStatus { pending, synced, failed }

/// What the animal is doing in the dairy (badge colour: Milking success,
/// Treated danger, Pregnant info, Heifer neutral, Dry warning).
enum DairyStatus { milking, dry, treated, pregnant, heifer, calf, bull }

class Animal extends Equatable {
  const new({
    required this.id,
    required this.tenantId,
    required this.tagNumber,
    required this.name,
    required this.sex,
    required this.breed,
    required this.dateOfBirth,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.updatedBy,
    required this.deviceId,
    required this.syncStatus,
    this.govIdTag,
    this.isDeleted = false,
    this.dairyStatus = DairyStatus.milking,
    this.avatarIndex = 1,
    this.group,
    this.motherTag,
  });

  final String id;
  final String tenantId;
  final String tagNumber;
  final String name;
  final AnimalSex sex;
  final String breed;
  final DateTime dateOfBirth;
  final AnimalStatus status;
  final String? govIdTag;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String updatedBy;
  final String deviceId;
  final SyncStatus syncStatus;
  final bool isDeleted;

  final DairyStatus dairyStatus;

  /// Cartoon avatar 1-6 when the farm has no photo.
  final int avatarIndex;

  /// Paddock or pen: "Paddock 1", "Calf pen".
  final String? group;
  final String? motherTag;

  /// Whole years old on [today].
  int ageYears(DateTime today) {
    var years = today.year - dateOfBirth.year;
    if (today.month < dateOfBirth.month || (today.month == dateOfBirth.month && today.day < dateOfBirth.day)) {
      years--;
    }
    return years < 0 ? 0 : years;
  }

  @override
  List<Object?> get props => [
    id,
    tenantId,
    tagNumber,
    name,
    sex,
    breed,
    dateOfBirth,
    status,
    govIdTag,
    createdAt,
    updatedAt,
    createdBy,
    updatedBy,
    deviceId,
    syncStatus,
    isDeleted,
    dairyStatus,
    avatarIndex,
    group,
    motherTag,
  ];
}
