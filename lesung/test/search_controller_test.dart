import 'dart:async';

import 'package:test/test.dart';
import 'package:lesung/features/search/domain/entities/book.dart';
import 'package:lesung/features/search/domain/entities/search_query.dart';
import 'package:lesung/features/search/domain/entities/search_result.dart';
import 'package:lesung/features/search/domain/search_repository.dart';
import 'package:lesung/features/search/presentation/search_controller.dart';

import 'pipeline_test.dart' show book;

/// Repository factice à réponses pilotables (Completer par requête).
class _PilotedRepository implements SearchRepository {
  final calls = <SearchQuery>[];
  final _pending = <SearchQuery, Completer<SearchResult>>{};

  @override
  Future<SearchResult> search(SearchQuery query) {
    calls.add(query);
    final completer = Completer<SearchResult>();
    _pending[query] = completer;
    return completer.future;
  }

  void complete(SearchQuery query, List<Book> books,
      {bool hasMore = false}) {
    _pending[query]!.complete(SearchResult(
      query: query,
      items: [
        for (final b in books)
          SearchResultItem(book: b, score: 50, scoreBreakdown: const {}),
      ],
      sourceReports: const [],
      hasMore: hasMore,
    ));
  }

  void fail(SearchQuery query, Object error) {
    _pending[query]!.completeError(error);
  }
}

void main() {
  group('annulation des recherches', () {
    test('une ancienne réponse ne peut pas écraser une recherche '
        'plus récente', () async {
      final repo = _PilotedRepository();
      final controller = SearchController(repo);
      var notifications = 0;
      controller.onChanged = () => notifications++;

      const qA = SearchQuery(text: 'anciennerequete');
      const qB = SearchQuery(text: 'nouvellerequete');

      final searchA = controller.search(qA.text);
      final searchB = controller.search(qB.text);

      // La réponse A arrive APRÈS le lancement de B : ignorée.
      repo.complete(qA, [book('Livre A', 'Auteur', 's1')]);
      await searchA;
      expect(controller.result, isNull,
          reason: 'la réponse obsolète est rejetée');
      expect(controller.status, SearchStatus.loading,
          reason: 'la recherche B est toujours en cours');

      repo.complete(qB, [book('Livre B', 'Auteur', 's1')]);
      await searchB;
      expect(controller.status, SearchStatus.success);
      expect(controller.items.single.book.title, 'Livre B');
      expect(notifications, greaterThan(0));

      controller.dispose();
    });

    test('debounce : une seule requête émise après la dernière frappe',
        () async {
      final repo = _PilotedRepository();
      final controller =
          SearchController(repo, debounceDuration: const Duration(milliseconds: 60));

      controller.onQueryChanged('k');
      controller.onQueryChanged('ka');
      controller.onQueryChanged('kafka');
      expect(repo.calls, isEmpty,
          reason: 'aucune requête avant la fin du debounce');

      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(repo.calls, hasLength(1));
      expect(repo.calls.single.text, 'kafka');

      controller.dispose();
    });

    test('nouvelle recherche pendant loadMore : la page suivante '
        'obsolète est ignorée', () async {
      final repo = _PilotedRepository();
      final controller = SearchController(repo);

      const q1 = SearchQuery(text: 'kafka');
      const q2 = SearchQuery(text: 'kafka', page: 2);
      const qNew = SearchQuery(text: 'mann');

      final first = controller.search('kafka');
      repo.complete(q1, [book('Procès', 'Kafka', 's1')], hasMore: true);
      await first;

      final more = controller.loadMore();
      final renewed = controller.search('mann');

      // La page 2 arrive après le démarrage de la nouvelle recherche.
      repo.complete(q2, [book('Château', 'Kafka', 's1')]);
      await more;

      repo.complete(qNew, [book('Buddenbrooks', 'Mann', 's1')]);
      await renewed;

      expect(controller.items, hasLength(1));
      expect(controller.items.single.book.author, 'Mann',
          reason: 'la page 2 obsolète n a pas pollué la nouvelle recherche');

      controller.dispose();
    });

    test('erreur : statut error sans écraser les recherches suivantes',
        () async {
      final repo = _PilotedRepository();
      final controller = SearchController(repo);

      const q1 = SearchQuery(text: 'crash');
      final failing = controller.search('crash');
      repo.fail(q1, StateError('réseau coupé'));
      await failing;

      expect(controller.status, SearchStatus.error);
      expect(controller.error, isNotNull);

      controller.dispose();
    });
  });
}
