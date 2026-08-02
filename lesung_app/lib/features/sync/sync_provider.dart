import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/cloud_sync_service.dart';

final cloudSyncServiceProvider = Provider<CloudSyncService>((ref) {
  return CloudSyncService();
});

final syncEnabledProvider = StateProvider<bool>((ref) => true);
