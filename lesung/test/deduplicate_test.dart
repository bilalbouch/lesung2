import 'package:test/test.dart';
import 'package:lesung/features/search/domain/entities/book.dart';
import 'package:lesung/features/search/domain/pipeline/deduplicate.dart';
import 'package:lesung/features/search/domain/pipeline/normalize.dart';

Book book({
  required String title,
  String? author,
  String? isbn,
  String sourceId = 's1',
  String? sourceBookId,
  String? coverUrl,
}) =>
    normalizeBook(Book(
      title: title,
      author: author,
      isbn: isbn,
      coverUrl: coverUrl,
      refs: [
        SourceBookRef(
            sourceId: sourceId,
            sourceBookId: sourceBookId ?? 'id-$title')
      ],
    ));

void main() {
  group('deduplicateBooks', () {
    test('fusionne par clé floue titre+auteur normalisés', () {
      final result = deduplicateBooks([
        book(title: 'Les Misérables', author: 'Victor Hugo', sourceId: 's1'),
        book(title: 'les miserables!', author: 'VICTOR HUGO', sourceId: 's2'),
      ]);

      expect(result, hasLength(1));
      expect(result.single.refs, hasLength(2),
          reason: 'les deux sources sont conservées');
      expect(result.single.refs.map((r) => r.sourceId),
          containsAll(['s1', 's2']));
    });

    test('fusionne par ISBN même si titres différents', () {
      final result = deduplicateBooks([
        book(
            title: 'Der Prozess',
            author: 'Kafka',
            isbn: '978-3-15-009814-8',
            sourceId: 's1'),
        book(
            title: 'Der Prozeß',
            author: 'Kafka',
            isbn: '9783150098148',
            sourceId: 's2'),
      ]);
      expect(result, hasLength(1));
    });

    test('ne fusionne pas des livres différents', () {
      final result = deduplicateBooks([
        book(title: 'Faust I', author: 'Goethe'),
        book(title: 'Faust II', author: 'Goethe'),
      ]);
      expect(result, hasLength(2));
    });

    test('le doublon complète les métadonnées manquantes', () {
      final result = deduplicateBooks([
        book(title: 'Dune', author: 'Frank Herbert'),
        book(
            title: 'Dune',
            author: 'Frank Herbert',
            sourceId: 's2',
            coverUrl: 'https://img/cover.jpg'),
      ]);
      expect(result.single.coverUrl, 'https://img/cover.jpg');
    });

    test('fusionne par MD5 même sans ISBN et avec titres différents', () {
      const md5 = '0123456789abcdef0123456789abcdef';
      final result = deduplicateBooks([
        book(title: 'Die Verwandlung', author: 'Franz Kafka',
            sourceId: 's1', sourceBookId: md5),
        book(title: 'The Metamorphosis', author: 'F. Kafka',
            sourceId: 's2', sourceBookId: md5.toUpperCase()),
      ]);

      expect(result, hasLength(1),
          reason: 'même fichier exact (MD5), casse insensible');
      expect(result.single.refs.map((r) => r.sourceId),
          containsAll(['s1', 's2']));
    });

    test('MD5 différents : la clé floue fusionne quand même '
        '(le MD5 est une clé additionnelle, pas un veto)', () {
      // Deux fichiers distincts pour deux éditions différentes.
      final result = deduplicateBooks([
        book(title: 'Faust I', author: 'Goethe', sourceId: 's1',
            sourceBookId: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'),
        book(title: 'Faust I', author: 'Goethe', sourceId: 's1',
            sourceBookId: 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb'),
      ]);

      // La clé floue (titre+auteur) les fusionne tout de même :
      // le MD5 est une clé forte ADDITIONNELLE, pas un veto.
      expect(result, hasLength(1));
      expect(result.single.refs, hasLength(2));
    });

    test('un identifiant non-MD5 ne crée pas de clé forte', () {
      final result = deduplicateBooks([
        book(title: 'Emile', author: 'Rousseau', sourceId: 's1',
            sourceBookId: 'gutenberg-1234'),
        book(title: 'Emile', author: 'Rousseau', sourceId: 's2',
            sourceBookId: 'openlibrary-OL1M'),
      ]);

      // Fusion uniquement via la clé floue titre+auteur.
      expect(result, hasLength(1));
      expect(result.single.refs, hasLength(2));
    });

    test('la fusion par MD5 ré-indexe le MD5 gagné', () {
      const md5 = 'ffffffffffffffffffffffffffffffff';
      final result = deduplicateBooks([
        // D'abord un livre sans MD5...
        book(title: 'Sans MD5', author: 'Auteur', sourceId: 's1'),
        // ...fusionné par clé floue avec un livre qui a un MD5...
        book(title: 'sans md5', author: 'AUTEUR', sourceId: 's2',
            sourceBookId: md5),
        // ...puis un troisième avec le même MD5 mais un titre différent.
        book(title: 'Titre different', author: 'Autre', sourceId: 's3',
            sourceBookId: md5),
      ]);

      expect(result, hasLength(1),
          reason: 'le MD5 acquis par fusion sert de clé pour la suite');
      expect(result.single.refs, hasLength(3));
    });

    test('ignore les livres sans titre normalisable', () {
      final result = deduplicateBooks([
        book(title: '!!!', author: 'x'),
        book(title: 'Valide', author: 'y'),
      ]);
      expect(result, hasLength(1));
      expect(result.single.title, 'Valide');
    });
  });
}
