import 'dart:async';

import 'package:farm_tap/core/sync/connectivity_monitor.dart';
import 'package:farm_tap/core/sync/domain/local_record_store.dart';
import 'package:farm_tap/core/sync/domain/merge_policy.dart';
import 'package:farm_tap/core/sync/domain/remote_store.dart';
import 'package:farm_tap/core/sync/domain/retry_backoff.dart';
import 'package:farm_tap/core/sync/domain/sync_record.dart';
import 'package:farm_tap/core/sync/sync_service.dart';
import 'package:farm_tap/core/utils/clock.dart';

/// Sends the outbox and pulls other phones' changes (decision 0014 §3).
///
/// Triggers: [debounce] after a write, when the network returns, on app
/// resume ([onResume]), every [periodic] while open, and "Sync now".
/// Only one run at a time; a trigger during a run queues one more run.
class SyncEngine implements SyncService {
  new({
    required this.store,
    required this.remote,
    required this.connectivity,
    required this.clock,
    required this.tenants,
    required this.collections,
    this.policy = const MergePolicy(),
    this.backoff = const RetryBackoff(),
    this.batchSize = 20,
    this.pullPageSize = 100,
    this.debounce = const Duration(seconds: 5), // theme-guard: ignore (network timing, not UI)
    this.periodic = const Duration(minutes: 15),
    this.liveDelay = const Duration(seconds: 3), // theme-guard: ignore (network timing, not UI)
    this.onConflicts,
  });

  final LocalRecordStore store;
  final RemoteStore remote;
  final ConnectivityMonitor connectivity;
  final Clock clock;

  /// Farms whose changes this phone pulls (the open farm).
  final List<String> Function() tenants;

  /// Collections to pull.
  final List<String> collections;
  final MergePolicy policy;
  final RetryBackoff backoff;
  final int batchSize;
  final int pullPageSize;
  final Duration debounce;
  final Duration periodic;

  /// Wait after a cloud change before pulling, so a burst of edits (the web
  /// saving a form, a batch from another phone) is one pull.
  final Duration liveDelay;
  final void Function(List<SyncConflict>)? onConflicts;

  SyncSnapshot _current = const SyncSnapshot(online: false);
  final _controller = StreamController<SyncSnapshot>.broadcast();
  final _subs = <StreamSubscription<Object?>>[];
  Timer? _debounceTimer;
  Timer? _retryTimer;
  Timer? _periodicTimer;
  Timer? _liveTimer;
  StreamSubscription<void>? _live;
  String _liveKey = '';
  Future<void>? _running;
  bool _again = false;
  bool _againPull = false;

  @override
  SyncSnapshot get current => _current;

  @override
  Stream<SyncSnapshot> watch() => _controller.stream;

  Future<void> start() async {
    _current = _current.copyWith(online: connectivity.online);
    _subs
      ..add(
        connectivity.watch().listen((online) {
          _emit(_current.copyWith(online: online));
          if (online) unawaited(_trigger(pull: true, retryFailed: true));
        }),
      )
      ..add(store.changes().listen((_) => unawaited(_onStoreChange())));
    _periodicTimer = Timer.periodic(periodic, (_) => unawaited(_trigger(pull: true)));
    _listenLive();
    await _refreshCounts();
    if (connectivity.online) await _trigger(pull: true);
  }

  /// App came back to the front.
  Future<void> onResume() => _trigger(pull: true);

  @override
  Future<void> sync() async {
    if (!connectivity.online) await connectivity.recheck();
    await _trigger(pull: true, retryFailed: true);
  }

  /// Waits for the current run (tests).
  Future<void> idle() async {
    while (_running != null) {
      await _running;
    }
  }

  void dispose() {
    _debounceTimer?.cancel();
    _retryTimer?.cancel();
    _periodicTimer?.cancel();
    _liveTimer?.cancel();
    unawaited(_live?.cancel());
    for (final s in _subs) {
      unawaited(s.cancel());
    }
    unawaited(_controller.close());
  }

  Future<void> _onStoreChange() async {
    await _refreshCounts();
    if (_running != null || !connectivity.online) return;
    final due = await store.due(clock.now(), limit: 1);
    if (due.isEmpty) return;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounce, () => unawaited(_trigger(pull: false)));
  }

  Future<void> _trigger({required bool pull, bool retryFailed = false}) async {
    if (retryFailed) await store.retryFailed();
    if (_running != null) {
      _again = true;
      _againPull = _againPull || pull;
      return await _running;
    }
    final run = _run(pull: pull);
    _running = run;
    try {
      await run;
    } finally {
      _running = null;
    }
    if (_again) {
      final p = _againPull;
      _again = false;
      _againPull = false;
      await _trigger(pull: p);
    }
  }

  /// Listens for cloud changes on the open farm(s); again when they change.
  void _listenLive() {
    final open = tenants().where((t) => t.isNotEmpty).toList();
    final key = open.join(',');
    if (key == _liveKey && _live != null) return;
    _liveKey = key;
    unawaited(_live?.cancel());
    _live = null;
    if (open.isEmpty) return;
    final streams = [for (final t in open) remote.changes(t, collections)];
    final merged = StreamController<void>();
    final subs = [
      for (final s in streams)
        s.listen(merged.add, onError: (Object _) {}, onDone: () {}),
    ];
    merged.onCancel = () async {
      for (final s in subs) {
        await s.cancel();
      }
    };
    _live = merged.stream.listen((_) {
      if (!connectivity.online) return;
      _liveTimer?.cancel();
      _liveTimer = Timer(liveDelay, () => unawaited(_trigger(pull: true)));
    });
  }

  Future<void> _run({required bool pull}) async {
    _listenLive();
    if (!connectivity.online) {
      await _refreshCounts();
      return;
    }
    _emit(_current.copyWith(syncing: true));
    try {
      final pushed = await _push();
      if (pushed && pull) await _pull();
      if (pushed) _emit(_current.copyWith(lastSyncedAt: clock.now()));
    } finally {
      _emit(_current.copyWith(syncing: false));
      await _refreshCounts();
      await _scheduleRetry();
    }
  }

  /// Sends due entries in batches. False when the network failed.
  Future<bool> _push() async {
    while (true) {
      final entries = await store.due(clock.now(), limit: batchSize);
      if (entries.isEmpty) return true;
      final byTenant = <String, List<(OutboxEntry, SyncRecord)>>{};
      for (final e in entries) {
        final r = await store.get(e.collection, e.id);
        if (r == null) {
          await store.markSent(e.collection, e.id, e.version);
          continue;
        }
        (byTenant[r.tenantId] ??= []).add((e, r));
      }
      for (final MapEntry(key: tenant, value: batch) in byTenant.entries) {
        final PushResult result;
        try {
          result = await remote.push(tenant, [for (final (_, r) in batch) r]);
        } on Object catch (error) {
          for (final (e, _) in batch) {
            await _retryLater(e, '$error');
          }
          await connectivity.recheck();
          return false;
        }
        for (final (e, r) in batch) {
          switch (result.acks[r.key]) {
            case PushAck.accepted:
              await store.markSent(r.collection, r.id, r.version);
            case PushAck.rejected:
              await store.markRetry(
                e.copyWith(attempts: e.attempts + 1, failed: true, lastError: result.reasons[r.key] ?? 'rejected'),
              );
            case null:
              await _retryLater(e, 'no reply');
          }
        }
      }
    }
  }

  Future<void> _retryLater(OutboxEntry e, String error) async {
    final attempts = e.attempts + 1;
    await store.markRetry(
      e.copyWith(
        attempts: attempts,
        nextAttemptAt: clock.now().add(backoff.delay(attempts)),
        lastError: error,
        failed: backoff.exhausted(attempts),
      ),
    );
  }

  Future<void> _pull() async {
    final conflicts = <SyncConflict>[];
    try {
      for (final tenant in tenants()) {
        for (final collection in collections) {
          var cursor = await store.cursor(tenant, collection);
          while (true) {
            final page = await remote.pull(tenant, collection, cursor: cursor, limit: pullPageSize);
            conflicts.addAll(await store.applyRemote(page.records, policy));
            cursor = page.cursor;
            await store.setCursor(tenant, collection, cursor);
            if (!page.hasMore) break;
          }
        }
      }
    } on Object {
      // Network dropped mid-pull: the cursor is saved page by page, so the
      // next run continues where this one stopped.
      await connectivity.recheck();
    }
    if (conflicts.isNotEmpty) onConflicts?.call(conflicts);
  }

  /// Wakes up when the earliest waiting record is due again.
  Future<void> _scheduleRetry() async {
    _retryTimer?.cancel();
    final now = clock.now();
    DateTime? next;
    for (final e in await store.outbox()) {
      final at = e.nextAttemptAt;
      if (e.failed || at == null || !at.isAfter(now)) continue;
      if (next == null || at.isBefore(next)) next = at;
    }
    if (next == null) return;
    _retryTimer = Timer(next.difference(now), () => unawaited(_trigger(pull: false)));
  }

  Future<void> _refreshCounts() async {
    final c = await store.counts();
    _emit(_current.copyWith(online: connectivity.online, synced: c.synced, waiting: c.waiting, failed: c.failed));
  }

  void _emit(SyncSnapshot s) {
    if (s == _current) return;
    _current = s;
    if (!_controller.isClosed) _controller.add(s);
  }
}
