import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/cloud_sync_service.dart';

const _syncEnabledKey = 'cloud_sync_enabled';

final cloudSyncServiceProvider = Provider<CloudSyncService>((ref) {
  return CloudSyncService();
});

class SyncState {
  final bool enabled;
  final bool busy;
  final bool configured;

  const SyncState({
    this.enabled = false,
    this.busy = true,
    this.configured = false,
  });
}

class SyncController extends StateNotifier<SyncState> {
  final CloudSyncService _service;
  late final Future<void> ready;

  SyncController(this._service) : super(const SyncState()) {
    ready = _restore();
  }

  Future<void> _restore() async {
    final preferences = await SharedPreferences.getInstance();
    final requested = preferences.getBool(_syncEnabledKey) ?? false;

    await _service.init();
    final connected = requested ? await _service.connect() : false;
    if (!requested) {
      await _service.disconnect();
    } else if (!connected) {
      await preferences.setBool(_syncEnabledKey, false);
    }

    state = SyncState(
      enabled: connected,
      busy: false,
      configured: _service.isConfigured,
    );
  }

  Future<void> setEnabled(bool enabled) async {
    if (state.busy || (enabled && !state.configured)) return;

    state = SyncState(
      enabled: state.enabled,
      busy: true,
      configured: state.configured,
    );

    final connected = enabled ? await _service.connect() : false;
    if (!enabled) await _service.disconnect();

    final effectiveValue = enabled && connected;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_syncEnabledKey, effectiveValue);

    state = SyncState(
      enabled: effectiveValue,
      busy: false,
      configured: _service.isConfigured,
    );
  }
}

final syncControllerProvider =
    StateNotifierProvider<SyncController, SyncState>((ref) {
  return SyncController(ref.watch(cloudSyncServiceProvider));
});
