import 'dart:async';

import 'app_events.dart';

/// Bus d'événements typé — noyau de communication inter-features.
///
/// Chaque feature ne dépend QUE de ce noyau : la bibliothèque ne
/// connaît ni le DownloadManager, ni les providers, ni le Reader.
/// Les émetteurs publient, les abonnés écoutent, par TYPE d'événement.
class EventBus {
  final Map<Type, StreamController<Object>> _controllers = {};

  /// Flux des événements de type [T].
  Stream<T> on<T>() {
    final controller = _controllers.putIfAbsent(
        T, () => StreamController<Object>.broadcast());
    return controller.stream.cast<T>();
  }

  /// Publie un événement. Synchrone : les abonnés broadcast sont
  /// notifiés en micro-tâche.
  ///
  /// Un événement est livré aux abonnés de son type exact ET aux
  /// abonnés du type de base [AppEvent] (vue « tous événements »,
  /// utile pour les observateurs comme les contrôleurs de présentation).
  void emit<T extends Object>(T event) {
    final exact = _controllers[T];
    if (exact != null && !exact.isClosed) {
      exact.add(event);
    }
    if (event is AppEvent && T != AppEvent) {
      final base = _controllers[AppEvent];
      if (base != null && !base.isClosed) {
        base.add(event);
      }
    }
  }

  Future<void> dispose() async {
    for (final controller in _controllers.values) {
      await controller.close();
    }
    _controllers.clear();
  }
}
