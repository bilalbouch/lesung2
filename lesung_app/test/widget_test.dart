import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lesung_app/features/sync/sync_provider.dart';
import 'package:lesung_app/main.dart';
import 'package:lesung_app/services/cloud_sync_service.dart';

void main() {
  testWidgets('affiche l’identité Lesung au démarrage', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SplashScreen()),
    );
    await tester.pump(const Duration(milliseconds: 1200));

    expect(find.text('Lesung'), findsOneWidget);
    expect(find.text('Deine Bibliothek.'), findsOneWidget);
  });

  test('la synchronisation est désactivée par défaut', () {
    const state = SyncState();

    expect(state.enabled, isFalse);
    expect(state.busy, isTrue);
    expect(state.configured, isFalse);
  });

  test('fusionne les favoris cloud connus sans perdre les favoris distants', () {
    final plan = FavoriteSyncPlan.create(
      localBookIds: const ['local-a', 'local-b'],
      localFavoriteIds: const ['local-a'],
      cloudFavoriteIds: const ['local-b', 'remote-only'],
      restoreCloud: true,
    );

    expect(plan.localFavoriteIds, ['local-a', 'local-b']);
    expect(
      plan.cloudFavoriteIds,
      ['local-a', 'local-b', 'remote-only'],
    );
  });

  test('respecte une suppression locale et conserve les favoris inconnus', () {
    final plan = FavoriteSyncPlan.create(
      localBookIds: const ['local-a', 'local-b'],
      localFavoriteIds: const ['local-a'],
      cloudFavoriteIds: const ['local-a', 'local-b', 'remote-only'],
      restoreCloud: false,
    );

    expect(plan.localFavoriteIds, ['local-a']);
    expect(plan.cloudFavoriteIds, ['local-a', 'remote-only']);
  });

  test('valide une progression cloud bien formée', () {
    final progress = CloudReadingProgress.fromMap({
      'unitIndex': 4,
      'progress': 0.75,
      'chapterTitle': 'Chapitre 5',
    });

    expect(progress?.unitIndex, 4);
    expect(progress?.progress, 0.75);
    expect(progress?.chapterTitle, 'Chapitre 5');
    expect(
      progress?.canRestore(localProgress: 0.5, unitCount: 8),
      isTrue,
    );
    expect(
      progress?.canRestore(localProgress: 0.8, unitCount: 8),
      isFalse,
    );
    expect(
      progress?.canRestore(localProgress: 0.5, unitCount: 4),
      isFalse,
    );
  });

  test('rejette une progression cloud invalide', () {
    expect(
      CloudReadingProgress.fromMap({'unitIndex': -1, 'progress': 0.5}),
      isNull,
    );
    expect(
      CloudReadingProgress.fromMap({'unitIndex': 2, 'progress': 1.2}),
      isNull,
    );
    expect(
      CloudReadingProgress.fromMap({'unitIndex': 2.5, 'progress': 0.5}),
      isNull,
    );
    expect(
      CloudReadingProgress.fromMap({
        'unitIndex': 2,
        'progress': 0.5,
        'chapterTitle': 3,
      }),
      isNull,
    );
    expect(CloudReadingProgress.fromMap({'progress': 0.5}), isNull);
  });
}
