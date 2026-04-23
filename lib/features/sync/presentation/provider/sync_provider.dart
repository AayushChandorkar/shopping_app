import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/sync_status.dart';
import '../../data/sync_service.dart';

final syncProvider = StreamProvider<SyncStatus>((ref) {
  final service = SyncService();
  return service.syncStream();
});