import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lesung_app/features/sync/sync_provider.dart';
import 'package:lesung_app/main.dart';

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
}
