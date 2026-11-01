import 'package:equatable/equatable.dart';

enum AnimalSex { male, female }

enum AnimalStatus { active, sold, deceased, transferred }

enum SyncStatus { pending, synced, failed }

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
      ];
}
