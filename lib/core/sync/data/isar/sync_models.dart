import 'package:farm_tap/core/sync/domain/sync_record.dart';
import 'package:isar_community/isar.dart';

part 'sync_models.g.dart';

/// FNV-1a 64-bit: a stable Isar id from a string key (Android/iOS only;
/// Isar does not run on the web).
int fastHash(String string) {
  // The 64-bit FNV offset basis; exact on the Dart VM (Isar is VM-only).
  // ignore: avoid_js_rounded_ints
  var hash = 0xcbf29ce484222325;
  var i = 0;
  while (i < string.length) {
    final codeUnit = string.codeUnitAt(i++);
    hash ^= codeUnit >> 8;
    hash *= 0x100000001b3;
    hash ^= codeUnit & 0xFF;
    hash *= 0x100000001b3;
  }
  return hash;
}

/// One saved record of any feature (decision 0014 §1).
@collection
class LocalRecordModel {
  Id get isarId => fastHash(key);

  @Index(unique: true, replace: true)
  late String key;

  @Index(composite: [CompositeIndex('collection')])
  late String tenantId;
  late String collection;
  late String recordId;

  /// The feature's own fields, as JSON.
  late String bodyJson;
  late DateTime createdAt;
  late DateTime updatedAt;
  late String createdBy;
  late String updatedBy;
  late String deviceId;
  late int version;
  late bool isDeleted;

  @enumerated
  late SyncStatus syncStatus;
}

/// One record waiting to be sent.
@collection
class OutboxModel {
  Id get isarId => fastHash(key);

  @Index(unique: true, replace: true)
  late String key;
  late String collection;
  late String recordId;
  late int version;
  late int attempts;
  DateTime? nextAttemptAt;
  String? lastError;
  late bool failed;

  /// Send order: oldest first.
  @Index()
  late int seq;
}

/// Where the last pull of a collection stopped.
@collection
class SyncCursorModel {
  Id get isarId => fastHash(key);

  @Index(unique: true, replace: true)
  late String key;
  String? cursor;
}
