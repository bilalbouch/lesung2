import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class CloudReadingProgress {
  final int unitIndex;
  final double progress;
  final String? chapterTitle;

  const CloudReadingProgress({
    required this.unitIndex,
    required this.progress,
    this.chapterTitle,
  });

  bool canRestore({required double localProgress, required int unitCount}) {
    return unitIndex < unitCount && progress > localProgress;
  }

  static CloudReadingProgress? fromMap(Map<String, dynamic>? data) {
    final unitIndex = data?['unitIndex'];
    final progress = data?['progress'];
    final chapterTitle = data?['chapterTitle'];
    if (unitIndex is! num ||
        progress is! num ||
        (chapterTitle != null && chapterTitle is! String)) {
      return null;
    }

    final parsedUnit = unitIndex.toInt();
    final parsedProgress = progress.toDouble();
    if (unitIndex != parsedUnit ||
        parsedUnit < 0 ||
        !parsedProgress.isFinite ||
        parsedProgress < 0 ||
        parsedProgress > 1) {
      return null;
    }

    return CloudReadingProgress(
      unitIndex: parsedUnit,
      progress: parsedProgress,
      chapterTitle: chapterTitle as String?,
    );
  }
}

/// Synchronisation Firebase explicitement activée par l'utilisateur.
/// L'application reste entièrement locale lorsque Firebase est absent ou
/// lorsque la sauvegarde cloud n'a pas été autorisée.
class CloudSyncService {
  FirebaseAuth? _auth;
  FirebaseFirestore? _firestore;
  bool _available = false;

  String? get _uid => _available ? _auth?.currentUser?.uid : null;
  bool get isConfigured => _auth != null && _firestore != null;
  bool get isAvailable => _available;

  /// Prépare Firebase sans créer de session ni envoyer de données.
  Future<void> init() async {
    if (Firebase.apps.isEmpty) return;
    try {
      _auth = FirebaseAuth.instance;
      _firestore = FirebaseFirestore.instance;
    } catch (_) {
      _auth = null;
      _firestore = null;
      _available = false;
    }
  }

  /// Ouvre la session anonyme uniquement après consentement explicite.
  Future<bool> connect() async {
    final auth = _auth;
    if (auth == null || _firestore == null) return false;
    try {
      if (auth.currentUser == null) {
        await auth.signInAnonymously();
      }
      _available = auth.currentUser != null;
      return _available;
    } catch (_) {
      _available = false;
      return false;
    }
  }

  /// Ferme la session cloud et arrête immédiatement la synchronisation.
  Future<void> disconnect() async {
    try {
      await _auth?.signOut();
    } finally {
      _available = false;
    }
  }

  Future<void> saveProgress({
    required String bookId,
    required int unitIndex,
    required double progress,
    String? chapterTitle,
  }) async {
    final firestore = _firestore;
    final uid = _uid;
    if (firestore == null || uid == null) return;
    try {
      await firestore
          .collection('users')
          .doc(uid)
          .collection('progress')
          .doc(bookId)
          .set({
        'unitIndex': unitIndex,
        'progress': progress,
        'chapterTitle': chapterTitle,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<CloudReadingProgress?> getProgress(String bookId) async {
    final firestore = _firestore;
    final uid = _uid;
    if (firestore == null || uid == null) return null;
    try {
      final doc = await firestore
          .collection('users')
          .doc(uid)
          .collection('progress')
          .doc(bookId)
          .get();
      return CloudReadingProgress.fromMap(doc.data());
    } catch (_) {
      return null;
    }
  }

  Future<void> saveFavorites(List<String> bookIds) async {
    final firestore = _firestore;
    final uid = _uid;
    if (firestore == null || uid == null) return;
    try {
      await firestore.collection('users').doc(uid).set({
        'favorites': bookIds,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<List<String>?> getFavorites() async {
    final firestore = _firestore;
    final uid = _uid;
    if (firestore == null || uid == null) return null;
    try {
      final doc = await firestore.collection('users').doc(uid).get();
      final data = doc.data();
      final rawFavorites = data?['favorites'];
      if (rawFavorites == null) return [];
      if (rawFavorites is! List || rawFavorites.any((item) => item is! String)) {
        return null;
      }
      return rawFavorites.cast<String>();
    } catch (_) {
      return null;
    }
  }

  Future<void> saveBookmarks(
    String bookId,
    List<Map<String, dynamic>> bookmarks,
  ) async {
    final firestore = _firestore;
    final uid = _uid;
    if (firestore == null || uid == null) return;
    try {
      await firestore
          .collection('users')
          .doc(uid)
          .collection('bookmarks')
          .doc(bookId)
          .set({
        'items': bookmarks,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> getBookmarks(String bookId) async {
    final firestore = _firestore;
    final uid = _uid;
    if (firestore == null || uid == null) return [];
    try {
      final doc = await firestore
          .collection('users')
          .doc(uid)
          .collection('bookmarks')
          .doc(bookId)
          .get();
      final data = doc.data();
      if (data == null || data['items'] == null) return [];
      return List<Map<String, dynamic>>.from(data['items']);
    } catch (_) {
      return [];
    }
  }
}
