import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lesung/features/library/domain/library_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/engine.dart';
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

class FavoriteSyncPlan {
  final List<String> localFavoriteIds;
  final List<String> cloudFavoriteIds;

  const FavoriteSyncPlan({
    required this.localFavoriteIds,
    required this.cloudFavoriteIds,
  });

  factory FavoriteSyncPlan.create({
    required Iterable<String> localBookIds,
    required Iterable<String> localFavoriteIds,
    required Iterable<String> cloudFavoriteIds,
    required bool restoreCloud,
  }) {
    final knownBooks = localBookIds.toSet();
    final currentLocal = localFavoriteIds.toSet();
    final currentCloud = cloudFavoriteIds.toSet();
    final mergedLocal = restoreCloud
        ? {
            ...currentLocal,
            ...currentCloud.where(knownBooks.contains),
          }
        : currentLocal;
    final mergedCloud = {
      ...currentCloud.where((id) => !knownBooks.contains(id)),
      ...mergedLocal,
    };

    return FavoriteSyncPlan(
      localFavoriteIds: mergedLocal.toList()..sort(),
      cloudFavoriteIds: mergedCloud.toList()..sort(),
    );
  }
}

class SyncController extends StateNotifier<SyncState> {
  final CloudSyncService _service;
  final LibraryManager _libraryManager;
  late final Future<void> ready;

  SyncController(this._service, this._libraryManager)
      : super(const SyncState()) {
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
    } else {
      await _synchronizeFavorites(restoreCloud: true);
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
    if (effectiveValue) {
      await _synchronizeFavorites(restoreCloud: true);
    }

    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_syncEnabledKey, effectiveValue);

    state = SyncState(
      enabled: effectiveValue,
      busy: false,
      configured: _service.isConfigured,
    );
  }

  Future<void> syncFavorites() async {
    await ready;
    if (!state.enabled) return;
    await _synchronizeFavorites(restoreCloud: false);
  }

  Future<void> _synchronizeFavorites({required bool restoreCloud}) async {
    final cloudFavoriteIds = await _service.getFavorites();
    if (cloudFavoriteIds == null) return;

    final localFavoriteIds =
        await _libraryManager.repository.favoriteBookIds();
    final localBooks = await _libraryManager.allBooks();
    final plan = FavoriteSyncPlan.create(
      localBookIds: localBooks.map((book) => book.id),
      localFavoriteIds: localFavoriteIds,
      cloudFavoriteIds: cloudFavoriteIds,
      restoreCloud: restoreCloud,
    );

    final currentLocal = localFavoriteIds.toSet();
    for (final bookId in plan.localFavoriteIds) {
      if (!currentLocal.contains(bookId)) {
        await _libraryManager.favorites.add(bookId);
      }
    }
    await _service.saveFavorites(plan.cloudFavoriteIds);
  }
}

final syncControllerProvider =
    StateNotifierProvider<SyncController, SyncState>((ref) {
  return SyncController(
    ref.watch(cloudSyncServiceProvider),
    ref.watch(engineProvider).libraryManager,
  );
});
