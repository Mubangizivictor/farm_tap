import 'package:farm_tap/core/sync/domain/local_record_store.dart';
import 'package:farm_tap/core/sync/domain/sync_record.dart';
import 'package:farm_tap/core/utils/clock.dart';
import 'package:farm_tap/core/utils/id_generator.dart';

/// How a feature saves a record (decision 0014 §1–2): onto the phone first
/// (record + outbox + audit in one transaction), with the base fields filled
/// in. The sync engine sends it when it can.
class RecordJournal {
  new({
    required this.store,
    required this.clock,
    required this.ids,
    required this.deviceId,
    required this.tenantId,
    required this.actor,
  });

  final LocalRecordStore store;
  final Clock clock;
  final IdGenerator ids;
  final String deviceId;
  final String Function() tenantId;

  /// Staff person who unlocked the phone, else the signed-in account.
  final String Function() actor;

  /// A new UUID v4 for a record made on this phone.
  String newId() => ids.generate();

  /// Saves a new record. Returns its id.
  Future<String> add(String collection, Map<String, Object?> body, {String? id}) async {
    final now = clock.now();
    final by = actor();
    final record = SyncRecord(
      collection: collection,
      id: id ?? newId(),
      tenantId: tenantId(),
      body: body,
      createdAt: now,
      updatedAt: now,
      createdBy: by,
      updatedBy: by,
      deviceId: deviceId,
    );
    await store.write(record, auditAction: 'create');
    return record.id;
  }

  /// Saves a new version of a record (creates it if missing).
  Future<void> put(String collection, String id, Map<String, Object?> body) async {
    final old = await store.get(collection, id);
    if (old == null) {
      await add(collection, body, id: id);
      return;
    }
    await store.write(
      old.copyWith(
        body: body,
        updatedAt: clock.now(),
        updatedBy: actor(),
        deviceId: deviceId,
        version: old.version + 1,
      ),
      auditAction: 'update',
    );
  }

  /// Soft delete: the record stays, marked deleted (never removed).
  Future<void> remove(String collection, String id) async {
    final old = await store.get(collection, id);
    if (old == null || old.isDeleted) return;
    await store.write(
      old.copyWith(
        isDeleted: true,
        updatedAt: clock.now(),
        updatedBy: actor(),
        deviceId: deviceId,
        version: old.version + 1,
      ),
      auditAction: 'delete',
    );
  }

  /// This farm's saved records of [collection] (not deleted).
  Future<List<SyncRecord>> load(String collection) => store.all(tenantId(), collection);
}
