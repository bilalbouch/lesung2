import 'package:test/test.dart';
import 'package:lesung/features/search/domain/entities/book.dart';
import 'package:lesung/features/search/domain/pipeline/normalize.dart';

Book book({required String title, String? author, String? language}) => Book(
      title: title,
      author: author,
      language: language,
      refs: const [
        SourceBookRef(sourceId: 'test', sourceBookId: 'x'),
      ],
    );

void main() {
  group('normalizeText', () {
    test('minuscules et ponctuation supprimée', () {
      expect(normalizeText('Der Zauberberg: Ein Roman!'),
          'der zauberberg ein roman');
    });

    test('diacritiques supprimés (DE + FR)', () {
      expect(normalizeText('Müller à cœur über ß'), 'muller a coeur uber ss');
    });

    test('espaces multiples compactés', () {
      expect(normalizeText('  Les   Misérables  '), 'les miserables');
    });
  });

  group('normalizeLanguageCode', () {
    test('codes ISO déjà valides', () {
      expect(normalizeLanguageCode('de'), 'de');
      expect(normalizeLanguageCode(' FR '), 'fr');
    });

    test('codes régionaux', () {
      expect(normalizeLanguageCode('fr-FR'), 'fr');
      expect(normalizeLanguageCode('de_DE'), 'de');
    });

    test('noms de langues complets', () {
      expect(normalizeLanguageCode('german'), 'de');
      expect(normalizeLanguageCode('Deutsch'), 'de');
      expect(normalizeLanguageCode('french'), 'fr');
      expect(normalizeLanguageCode('english'), 'en');
    });

    test('indéterminable -> null', () {
      expect(normalizeLanguageCode(null), isNull);
      expect(normalizeLanguageCode(''), isNull);
      expect(normalizeLanguageCode('klingon'), isNull);
    });
  });

  group('normalizeBook', () {
    test('champs dérivés remplis, entrée non mutée', () {
      final raw = book(title: 'Die Verwandlung', author: 'Franz Kafka');
      final normalized = normalizeBook(raw);

      expect(normalized.normalizedTitle, 'die verwandlung');
      expect(normalized.normalizedAuthor, 'franz kafka');
      expect(raw.normalizedTitle, isEmpty, reason: 'entrée immuable');
      expect(normalized.dedupKey, 'die verwandlung|franz kafka');
    });

    test('livres équivalents multilingues partagent la même clé', () {
      final a = normalizeBook(
          book(title: 'Les Misérables', author: 'Victor Hugo'));
      final b = normalizeBook(
          book(title: 'les miserables', author: 'VICTOR HUGO'));
      expect(a.dedupKey, b.dedupKey);
    });
  });
}
