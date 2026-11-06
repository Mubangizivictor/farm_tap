import 'package:farm_tap/core/sync/domain/sync_record.dart';

/// Which copy wins when the cloud sends a record this phone also has.
enum MergeWinner { local, remote }

class MergeOutcome {
  const new(this.winner, {this.conflict = false, this.needsReview = false});

  final MergeWinner winner;

  /// The losing copy had an unsent local edit.
  final bool conflict;

  /// The lost edit changed money or litres: show it to the owner.
  final bool needsReview;
}

/// Decision 0014 §4.
///
/// * Append-only collections (milk, deliveries, treatments, attendance,
///   payments, expenses): a record never changes after it is saved; a
///   correction is a new record. Two phones can never edit the same one, so
///   there is nothing to merge.
/// * Everything else: last write wins by `updatedAt`, ties broken by
///   `deviceId` so every phone picks the same winner.
/// * A lost local edit in a money or litres collection is kept for review.
class MergePolicy {
  const new({this.appendOnly = defaultAppendOnly, this.sensitive = defaultSensitive});

  final Set<String> appendOnly;
  final Set<String> sensitive;

  static const defaultAppendOnly = {
    'milkRecords',
    'milkSales',
    'deliveries',
    'qualityTests',
    'treatments',
    'vaccinations',
    'attendance',
    'payments',
    'payouts',
    'expenses',
    'income',
    'wages',
    'feedUsage',
    'stockMovements',
    'animalEvents',
    'breedingEvents',
    'auditLog',
  };

  static const defaultSensitive = {
    'milkRecords',
    'milkSales',
    'deliveries',
    'paymentPeriods',
    'farmerStatements',
    'deductions',
    'payouts',
    'payments',
    'expenses',
    'income',
    'wages',
    'settings',
  };

  /// [hasUnsentEdit]: the local copy is still in the outbox.
  MergeOutcome resolve(SyncRecord? local, SyncRecord remote, {required bool hasUnsentEdit}) {
    if (local == null) return const MergeOutcome(MergeWinner.remote);
    if (!hasUnsentEdit) return const MergeOutcome(MergeWinner.remote);
    if (appendOnly.contains(remote.collection)) {
      // Same id means the same record (our own push coming back). Keep ours
      // until the push is confirmed.
      return const MergeOutcome(MergeWinner.local);
    }
    final remoteWins = _newer(remote, local);
    if (!remoteWins) return const MergeOutcome(MergeWinner.local);
    return MergeOutcome(MergeWinner.remote, conflict: true, needsReview: sensitive.contains(remote.collection));
  }

  static bool _newer(SyncRecord a, SyncRecord b) {
    final byTime = a.updatedAt.compareTo(b.updatedAt);
    if (byTime != 0) return byTime > 0;
    if (a.version != b.version) return a.version > b.version;
    return a.deviceId.compareTo(b.deviceId) > 0;
  }
}
