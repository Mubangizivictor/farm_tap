import 'package:farm_tap/sectors/cattle/herd/domain/entities/animal.dart';
import 'package:isar/isar.dart';

part 'animal_model.g.dart';

@collection
class AnimalModel {

  new();

  new fromEntity(Animal animal) {
    id = animal.id;
    tenantId = animal.tenantId;
    tagNumber = animal.tagNumber;
    name = animal.name;
    sex = animal.sex;
    breed = animal.breed;
    dateOfBirth = animal.dateOfBirth;
    status = animal.status;
    govIdTag = animal.govIdTag;
    createdAt = animal.createdAt;
    updatedAt = animal.updatedAt;
    createdBy = animal.createdBy;
    updatedBy = animal.updatedBy;
    deviceId = animal.deviceId;
    syncStatus = animal.syncStatus;
    isDeleted = animal.isDeleted;
  }
  Id? isarId; // Isar internal id

  @Index(unique: true, replace: true)
  late String id;

  late String tenantId;
  late String tagNumber;
  late String name;

  @enumerated
  late AnimalSex sex;

  late String breed;
  late DateTime dateOfBirth;

  @enumerated
  late AnimalStatus status;

  String? govIdTag;
  late DateTime createdAt;
  late DateTime updatedAt;
  late String createdBy;
  late String updatedBy;
  late String deviceId;

  @enumerated
  late SyncStatus syncStatus;

  late bool isDeleted;

  Animal toEntity() {
    return Animal(
      id: id,
      tenantId: tenantId,
      tagNumber: tagNumber,
      name: name,
      sex: sex,
      breed: breed,
      dateOfBirth: dateOfBirth,
      status: status,
      govIdTag: govIdTag,
      createdAt: createdAt,
      updatedAt: updatedAt,
      createdBy: createdBy,
      updatedBy: updatedBy,
      deviceId: deviceId,
      syncStatus: syncStatus,
      isDeleted: isDeleted,
    );
  }
}
