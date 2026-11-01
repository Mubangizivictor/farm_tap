abstract class SyncService {
  Future<void> sync();
}

class NoOpSyncService implements SyncService {
  @override
  Future<void> sync() async {}
}
