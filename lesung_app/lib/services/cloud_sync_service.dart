import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service de synchronisation cloud via Firebase.
/// Auth anonyme + Firestore pour backup progression/favoris/bookmarks.
/// Mode degrade : fonctionne offline si Firebase non configure.
class CloudSyncService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _available = false;

  String? get _uid => _auth.currentUser?.uid;

  /// Initialise l'authentification anonyme si necessaire.
  /// Silencieux si Firebase n'est pas configure (mode offline).
  Future<void> init() async {
    try {
      if (_auth.currentUser == null) {
        await _auth.signInAnonymously();
      }
      _available = true;
    } catch (_) {
      _available = false;
    }
  }

  bool get isAvailable => _available;

  /// Sauvegarde la progression de lecture d'un livre.
  Future<void> saveProgress({
    required String bookId,
    required int unitIndex,
    required double progress,
    String? chapterTitle,
  }) async {
    if (!_available) return;
    try {
      final uid = _uid;
      if (uid == null) return;
      await _firestore
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

  /// Recupere la progression d'un livre.
  Future<Map<String, dynamic>?> getProgress(String bookId) async {
    if (!_available) return null;
    try {
      final uid = _uid;
      if (uid == null) return null;
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('progress')
          .doc(bookId)
          .get();
      return doc.data();
    } catch (_) {
      return null;
    }
  }

  /// Sauvegarde les favoris.
  Future<void> saveFavorites(List<String> bookIds) async {
    if (!_available) return;
    try {
      final uid = _uid;
      if (uid == null) return;
      await _firestore.collection('users').doc(uid).set({
        'favorites': bookIds,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  /// Recupere les favoris.
  Future<List<String>> getFavorites() async {
    if (!_available) return [];
    try {
      final uid = _uid;
      if (uid == null) return [];
      final doc = await _firestore.collection('users').doc(uid).get();
      final data = doc.data();
      if (data == null || data['favorites'] == null) return [];
      return List<String>.from(data['favorites']);
    } catch (_) {
      return [];
    }
  }

  /// Sauvegarde les bookmarks d'un livre.
  Future<void> saveBookmarks(String bookId, List<Map<String, dynamic>> bookmarks) async {
    if (!_available) return;
    try {
      final uid = _uid;
      if (uid == null) return;
      await _firestore
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

  /// Recupere les bookmarks d'un livre.
  Future<List<Map<String, dynamic>>> getBookmarks(String bookId) async {
    if (!_available) return [];
    try {
      final uid = _uid;
      if (uid == null) return [];
      final doc = await _firestore
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
