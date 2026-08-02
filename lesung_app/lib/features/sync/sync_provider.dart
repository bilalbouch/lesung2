import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/cloud_sync_service.dart';

final cloudSyncServiceProvider = Provider<CloudSyncService>((ref) {
  return CloudSyncService();
});

final syncEnabledProvider =
    StateNotifierProvider<SyncController, AsyncValue<bool>>((ref) {
  final controller = SyncController(ref.read(cloudSyncServiceProvider));
  unawaited(controller.restore());
  return controller;
});

class SyncController extends StateNotifier<AsyncValue<bool>> {
  final CloudSyncService _service;

  SyncController(this._service) : super(const AsyncValue.loading());

  Future<void> restore() async {
    await _service.init();
    state = AsyncValue.data(_service.isAvailable);
  }

  Future<void> setEnabled(bool enabled) async {
    state = const AsyncValue.loading();
    try {
      if (enabled) {
        await _service.connectAnonymously();
      } else {
        await _service.disconnect();
      }
      state = AsyncValue.data(_service.isAvailable);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
