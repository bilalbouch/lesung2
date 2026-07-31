import 'package:lesung/features/reader/domain/reader_contract.dart';
import 'package:lesung/features/reader/domain/reader_navigation.dart';
import 'package:test/test.dart';

ReaderTocEntry toc() => const ReaderTocEntry(title: 'Racine', children: [
      ReaderTocEntry(title: 'Ch1', unitIndex: 0, children: [
        ReaderTocEntry(title: 'Ch1.1', unitIndex: 2),
      ]),
      ReaderTocEntry(title: 'Ch2', unitIndex: 5),
      ReaderTocEntry(title: 'Ch3', unitIndex: 8),
    ]);

void main() {
  group('historique de navigation', () {
    test('visites enregistrées, doublons ignorés, retour navigateur', () {
      final nav = ReaderNavigation(tableOfContents: [toc()]);
      nav.recordVisit('epub:u0');
      nav.recordVisit('epub:u0'); // doublon ignoré
      nav.recordVisit('epub:u2');
      nav.recordVisit('epub:u5');

      expect(nav.history, ['epub:u0', 'epub:u2', 'epub:u5']);
      expect(nav.canGoBack, isTrue);

      expect(nav.goBack(), 'epub:u2');
      expect(nav.history, ['epub:u0', 'epub:u2']);
      expect(nav.goBack(), 'epub:u0');
      expect(nav.goBack(), isNull); // plus rien
    });

    test('historique restauré à l\'ouverture et borné', () {
      final restored =
          List.generate(60, (i) => 'epub:u$i'); // > maxHistoryLength
      final nav = ReaderNavigation(
          tableOfContents: [toc()], restoredHistory: restored);
      nav.recordVisit('epub:u999');
      expect(nav.history.length, ReaderNavigation.maxHistoryLength);
      expect(nav.history.last, 'epub:u999');
    });
  });

  group('navigation par chapitre', () {
    test('suivant / précédent / chapitre actif', () {
      final nav = ReaderNavigation(tableOfContents: [toc()]);

      expect(nav.flatToc.map((e) => e.title),
          ['Racine', 'Ch1', 'Ch1.1', 'Ch2', 'Ch3']);

      expect(nav.nextChapter(0)?.title, 'Ch1.1');
      expect(nav.nextChapter(2)?.title, 'Ch2');
      expect(nav.nextChapter(8), isNull);

      // Au milieu d'un chapitre : revenir à son début.
      expect(nav.previousChapter(6)?.title, 'Ch2');
      // Au début exact d'un chapitre : passer au précédent.
      expect(nav.previousChapter(5)?.title, 'Ch1.1');
      expect(nav.previousChapter(0), isNull);

      expect(nav.activeEntryFor(6)?.title, 'Ch2');
      expect(nav.activeEntryFor(3)?.title, 'Ch1.1');
      expect(nav.activeEntryFor(0)?.title, 'Ch1');
    });
  });
}
