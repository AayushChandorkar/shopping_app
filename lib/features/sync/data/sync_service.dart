import '../domain/sync_status.dart';

class SyncService {
  Stream<SyncStatus> syncStream() async* {
    while (true) {
      yield SyncStatus.syncing;
      await Future.delayed(const Duration(seconds: 2));

      final isError = DateTime.now().second % 10 == 0;
      yield isError ? SyncStatus.error : SyncStatus.synced;

      await Future.delayed(const Duration(seconds: 5));
    }
  }
}
