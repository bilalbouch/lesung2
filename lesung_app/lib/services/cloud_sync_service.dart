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

    final parsedUnitNumber = unitIndex.toDouble();
    final parsedProgress = progress.toDouble();
    if (!parsedUnitNumber.isFinite || !parsedProgress.isFinite) return null;
    final parsedUnit = unitIndex.toInt();
    if (unitIndex != parsedUnit ||
        parsedUnit < 0 ||
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

class CloudBookmark {
  final String id;
  final String locator;
  final int unitIndex;
  final String? label;
  final String? chapterTitle;

  const CloudBookmark({
    required this.id,
    required this.locator,
    required this.unitIndex,
    this.label,
    this.chapterTitle,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'locator': locator,
        'unitIndex': unitIndex,
        'label': label,
        'chapterTitle': chapterTitle,
      };

  static CloudBookmark? fromMap(Map<String, dynamic>? data) {
    final id = data?['id'];
    final locator = data?['locator'];
    final unitIndex = data?['unitIndex'];
    final label = data?['label'];
    final chapterTitle = data?['chapterTitle'];
    if (id is! String ||
        id.trim().isEmpty ||
        locator is! String ||
        locator.trim().isEmpty ||
        unitIndex is! num ||
        (label != null && label is! String) ||
        (chapterTitle != null && chapterTitle is! String)) {
      return null;
    }
    final parsedUnitNumber = unitIndex.toDouble();
    if (!parsedUnitNumber.isFinite ||
        unitIndex != unitIndex.toInt() ||
        unitIndex < 0) {
      return null;
    }

    return CloudBookmark(
      id: id,
      locator: locator,
      unitIndex: unitIndex.toInt(),
      label: label as String?,
      chapterTitle: chapterTitle as String?,
    );
  }

  static List<CloudBookmark> merge({
    required Iterable<CloudBookmark> local,
    required Iterable<CloudBookmark> cloud,
    required int unitCount,
  }) {
    final validLocal = local
        .where((bookmark) => bookmark.unitIndex < unitCount)
        .toList();
    final localIds = validLocal.map((bookmark) => bookmark.id).toSet();
    final byLocator = <String, CloudBookmark>{};
    for (final bookmark in cloud) {
      if (bookmark.unitIndex < unitCount && !localIds.contains(bookmark.id)) {
        byLocator[bookmark.locator] = bookmark;
      }
    }
    for (final bookmark in validLocal) {
      byLocator[bookmark.locator] = bookmark;
    }
    return byLocator.values.toList()
      ..sort((a, b) {
        final byUnit = a.unitIndex.compareTo(b.unitIndex);
        return byUnit != 0 ? byUnit : a.locator.compareTo(b.locator);
      });
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
    List<CloudBookmark> bookmarks,
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
        'items': bookmarks.map((bookmark) => bookmark.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  Future<List<CloudBookmark>?> getBookmarks(String bookId) async {
    final firestore = _firestore;
    final uid = _uid;
    if (firestore == null || uid == null) return null;
    try {
      final doc = await firestore
          .collection('users')
          .doc(uid)
          .collection('bookmarks')
          .doc(bookId)
          .get();
      final rawItems = doc.data()?['items'];
      if (rawItems == null) return [];
      if (rawItems is! List) return null;

      final bookmarks = <CloudBookmark>[];
      final ids = <String>{};
      final locators = <String>{};
      for (final item in rawItems) {
        if (item is! Map) return null;
        final parsed = CloudBookmark.fromMap(Map<String, dynamic>.from(item));
        if (parsed == null ||
            !ids.add(parsed.id) ||
            !locators.add(parsed.locator)) {
          return null;
        }
        bookmarks.add(parsed);
      }
      return bookmarks;
    } catch (_) {
      return null;
    }
  }
}
