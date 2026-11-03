import 'dart:async';

import 'package:equatable/equatable.dart';

/// What the sync icon and the sync sheet (D04) show.
class SyncSnapshot extends Equatable {
  const new({
    this.online = true,
    this.synced = 0,
    this.waiting = 0,
    this.failed = 0,
    this.syncing = false,
    this.lastSyncedAt,
  });

  final bool online;
  final int synced;
  final int waiting;
  final int failed;
  final bool syncing;
  final DateTime? lastSyncedAt;

  SyncSnapshot copyWith({
    bool? online,
    int? synced,
    int? waiting,
    int? failed,
    bool? syncing,
    DateTime? lastSyncedAt,
  }) => SyncSnapshot(
    online: online ?? this.online,
    synced: synced ?? this.synced,
    waiting: waiting ?? this.waiting,
    failed: failed ?? this.failed,
    syncing: syncing ?? this.syncing,
    lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
  );

  @override
  List<Object?> get props => [online, synced, waiting, failed, syncing, lastSyncedAt];
}

/// Records are saved on the phone first, then sent to the cloud.
abstract class SyncService {
  SyncSnapshot get current;
  Stream<SyncSnapshot> watch();

  /// "Sync now" (D04): also retries records that failed.
  Future<void> sync();
}

/// UI phase: sample numbers from the mockups; "Sync now" moves waiting
/// records to synced.
class FakeSyncService implements SyncService {
  new([SyncSnapshot initial = const SyncSnapshot(synced: 1284)]) : _current = initial;

  SyncSnapshot _current;
  final _controller = StreamController<SyncSnapshot>.broadcast();

  @override
  SyncSnapshot get current => _current;

  @override
  Stream<SyncSnapshot> watch() => _controller.stream;

  /// Simulates losing or regaining the network.
  void setOnline({required bool online}) => _emit(_current.copyWith(online: online));

  @override
  Future<void> sync() async {
    if (!_current.online) return;
    _emit(_current.copyWith(synced: _current.synced + _current.waiting, waiting: 0, failed: 0));
  }

  void _emit(SyncSnapshot s) {
    _current = s;
    _controller.add(s);
  }
}
