enum SyncStatus {
  syncing,
  synced,
  error;

  String get label {
    switch (this) {
      case SyncStatus.syncing:
        return 'Syncing...';
      case SyncStatus.synced:
        return 'Up to date';
      case SyncStatus.error:
        return 'Sync failed';
    }
  }
}