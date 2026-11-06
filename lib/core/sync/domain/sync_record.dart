import 'package:equatable/equatable.dart';

/// Where a record is on its way to the cloud (ROADMAP 5.1 base fields).
enum SyncStatus { pending, synced, failed }

/// One saved record: base fields (ROADMAP 5.1) plus the feature's own data in
/// [body]. Every feature stores its records through this shape, so one outbox
/// and one sync engine serve Sections A–L.
class SyncRecord extends Equatable {
  const new({
    required this.collection,
    required this.id,
    required this.tenantId,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.updatedBy,
    required this.deviceId,
    this.version = 1,
    this.isDeleted = false,
    this.syncStatus = SyncStatus.pending,
  });

  factory fromJson(Map<String, Object?> json, {SyncStatus syncStatus = SyncStatus.synced}) => SyncRecord(
    collection: json['collection']! as String,
    id: json['id']! as String,
    tenantId: json['tenantId']! as String,
    body: Map<String, Object?>.from(json['body']! as Map),
    createdAt: DateTime.parse(json['createdAt']! as String),
    updatedAt: DateTime.parse(json['updatedAt']! as String),
    createdBy: json['createdBy']! as String,
    updatedBy: json['updatedBy']! as String,
    deviceId: json['deviceId']! as String,
    version: json['version']! as int,
    isDeleted: json['isDeleted']! as bool,
    syncStatus: syncStatus,
  );

  /// Firestore collection under `tenants/{tenantId}` (e.g. `milkRecords`).
  final String collection;

  /// UUID v4 made on the phone, so a retried push never makes a duplicate.
  final String id;
  final String tenantId;
  final Map<String, Object?> body;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String updatedBy;
  final String deviceId;

  /// Goes up by one on every local edit. A push only clears the outbox when
  /// the version it sent is still the newest.
  final int version;
  final bool isDeleted;
  final SyncStatus syncStatus;

  String get key => recordKey(collection, id);

  SyncRecord copyWith({
    Map<String, Object?>? body,
    DateTime? updatedAt,
    String? updatedBy,
    String? deviceId,
    int? version,
    bool? isDeleted,
    SyncStatus? syncStatus,
  }) => SyncRecord(
    collection: collection,
    id: id,
    tenantId: tenantId,
    body: body ?? this.body,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    createdBy: createdBy,
    updatedBy: updatedBy ?? this.updatedBy,
    deviceId: deviceId ?? this.deviceId,
    version: version ?? this.version,
    isDeleted: isDeleted ?? this.isDeleted,
    syncStatus: syncStatus ?? this.syncStatus,
  );

  Map<String, Object?> toJson() => {
    'collection': collection,
    'id': id,
    'tenantId': tenantId,
    'body': body,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'createdBy': createdBy,
    'updatedBy': updatedBy,
    'deviceId': deviceId,
    'version': version,
    'isDeleted': isDeleted,
  };

  @override
  List<Object?> get props => [
    collection,
    id,
    tenantId,
    body,
    createdAt,
    updatedAt,
    createdBy,
    updatedBy,
    deviceId,
    version,
    isDeleted,
    syncStatus,
  ];
}

String recordKey(String collection, String id) => '$collection/$id';

/// A record waiting to be sent. Kept until the cloud confirms it; never
/// dropped, even after many failed tries.
class OutboxEntry extends Equatable {
  const new({
    required this.collection,
    required this.id,
    required this.version,
    this.attempts = 0,
    this.nextAttemptAt,
    this.lastError,
    this.failed = false,
  });

  final String collection;
  final String id;
  final int version;
  final int attempts;

  /// Null means "send as soon as possible".
  final DateTime? nextAttemptAt;
  final String? lastError;

  /// Shown as "Failed" in D04 (too many tries, or the cloud refused it).
  final bool failed;

  String get key => recordKey(collection, id);

  bool isDue(DateTime now) => !failed && (nextAttemptAt == null || !nextAttemptAt!.isAfter(now));

  OutboxEntry copyWith({int? attempts, DateTime? nextAttemptAt, String? lastError, bool? failed}) => OutboxEntry(
    collection: collection,
    id: id,
    version: version,
    attempts: attempts ?? this.attempts,
    nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
    lastError: lastError ?? this.lastError,
    failed: failed ?? this.failed,
  );

  @override
  List<Object?> get props => [collection, id, version, attempts, nextAttemptAt, lastError, failed];
}

/// A local edit that lost to a newer edit from another phone, kept for the
/// owner when it changed money or litres.
class SyncConflict extends Equatable {
  const new({required this.local, required this.remote, required this.needsReview});

  final SyncRecord local;
  final SyncRecord remote;
  final bool needsReview;

  @override
  List<Object?> get props => [local, remote, needsReview];
}
