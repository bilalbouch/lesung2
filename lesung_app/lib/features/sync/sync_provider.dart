import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/cloud_sync_service.dart';

final cloudSyncServiceProvider = Provider<CloudSyncService>((ref) {
  final service = CloudSyncService();
  unawaited(service.init());
  return service;
});

final syncEnabledProvider = StateProvider<bool>((ref) => true);
