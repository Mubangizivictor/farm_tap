import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:farm_tap/core/sync/data/reachability.dart' as reach;

/// Online or not, as the offline banner and the sync engine see it.
abstract class ConnectivityMonitor {
  bool get online;
  Stream<bool> watch();

  /// Checks again now (after a failed push, or on "Sync now").
  Future<bool> recheck();
  void dispose();
}

/// Tests and the demo build: online until told otherwise.
class ManualConnectivity implements ConnectivityMonitor {
  new({this._online = true});

  bool _online;
  final _controller = StreamController<bool>.broadcast();

  @override
  bool get online => _online;

  void set({required bool online}) {
    if (online == _online) return;
    _online = online;
    _controller.add(online);
  }

  @override
  Stream<bool> watch() => _controller.stream;

  @override
  Future<bool> recheck() async => _online;

  @override
  void dispose() => unawaited(_controller.close());
}

/// The real phone: `connectivity_plus` says whether there is a link, a DNS
/// lookup says whether the internet is behind it. While there is a link but
/// no internet (weak signal, bundle finished), it checks again every
/// [probeEvery].
class DeviceConnectivity implements ConnectivityMonitor {
  new({
    Connectivity? connectivity,
    Future<bool> Function()? probe,
    this.probeEvery = const Duration(seconds: 30), // theme-guard: ignore (network timing, not UI)
  }) : _connectivity = connectivity ?? Connectivity(),
       _probe = probe ?? reach.internetReachable;

  final Connectivity _connectivity;
  final Future<bool> Function() _probe;
  final Duration probeEvery;
  final _controller = StreamController<bool>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _sub;
  Timer? _timer;
  bool _online = false;
  bool _hasLink = false;

  Future<void> start() async {
    try {
      _sub = _connectivity.onConnectivityChanged.listen(_onLink);
      _onLink(await _connectivity.checkConnectivity());
    } on Object {
      // No plugin (host tests): assume online; a failed push re-checks.
      _hasLink = true;
      _set(true);
    }
  }

  void _onLink(List<ConnectivityResult> results) {
    _hasLink = results.any((r) => r != ConnectivityResult.none);
    if (!_hasLink) {
      _timer?.cancel();
      _set(false);
      return;
    }
    unawaited(recheck());
  }

  @override
  bool get online => _online;

  @override
  Stream<bool> watch() => _controller.stream;

  @override
  Future<bool> recheck() async {
    final ok = _hasLink && await _probe();
    _set(ok);
    _timer?.cancel();
    if (_hasLink && !ok) _timer = Timer(probeEvery, () => unawaited(recheck()));
    return ok;
  }

  void _set(bool value) {
    if (value == _online) return;
    _online = value;
    _controller.add(value);
  }

  @override
  void dispose() {
    _timer?.cancel();
    unawaited(_sub?.cancel());
    unawaited(_controller.close());
  }
}
