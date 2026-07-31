/// Jeton d'annulation partagé (core) : utilisé par le provider réseau
/// et par le moteur de téléchargement.
///
/// Léger par design : le consommateur vérifie le jeton entre chaque
/// étape de travail. Une annulation lève [RequestCancelledException].
library;

class CancellationToken {
  bool _cancelled = false;

  bool get isCancelled => _cancelled;

  void cancel() => _cancelled = true;

  void throwIfCancelled() {
    if (_cancelled) throw const RequestCancelledException();
  }
}

class RequestCancelledException implements Exception {
  const RequestCancelledException();
  @override
  String toString() => 'RequestCancelledException';
}
