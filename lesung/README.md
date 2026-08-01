# Lesung — Moteur de recherche

Package **Dart pur** : le moteur est entièrement indépendant de l'application
Flutter (aucune dépendance Flutter). Il sera consommé par l'app via Riverpod.

## Architecture

```
lib/features/
├── search/
│   ├── domain/
│   │   ├── entities/       SearchQuery, Book, BookDetails, DownloadLink, SearchResult
│   │   ├── pipeline/       fanout.dart, normalize.dart, deduplicate.dart, score.dart
│   │   └── search_repository.dart   (contrat)
│   ├── data/
│   │   ├── search_service.dart      (orchestrateur du pipeline)
│   │   └── search_repository_impl.dart
│   └── presentation/
│       └── search_controller.dart   (état + pagination, sans Flutter)
└── sources/
    ├── domain/
    │   ├── book_source.dart         BookSource, PagedResult, SourceMeta, SourceHealth
    │   └── source_registry.dart     SourceRegistry (enregistrement/activation dynamique)
    └── data/annas_archive/          1er provider (endpoints réels uniquement)
        ├── annas_archive_source.dart       Orchestrateur (BookSource)
        ├── annas_archive_client.dart       Transport pur : failover par score,
        │                                   retry backoff, timeout, CancellationToken
        ├── annas_archive_parser.dart       HTML -> DTO (SEUL fichier couplé au markup,
        │                                   repères structurels, pas de classes CSS)
        ├── annas_archive_mapper.dart       DTO -> Book/BookDetails/DownloadLink
        ├── annas_archive_health_check.dart Santé fonctionnelle + scoring instances
        ├── annas_archive_cache.dart        Cache mémoire LRU + disque TTL, purge auto
        ├── annas_archive_dto.dart          Modèles bruts du HTML
        └── annas_archive_instances.dart    Miroirs + score

lib/core/network/
└── cloudflare_guard.dart            Détection -> bypass (session cachée) ->
                                     solver (WebView) en dernier recours.
                                     Le provider ne connaît jamais la WebView.
lib/core/cancellation/
└── cancellation_token.dart          Jeton d'annulation partagé.

features/downloads/                  Moteur de téléchargement — indépendant
├── domain/                          des sources : il ne reçoit QUE des
│   ├── entities/                    DownloadLink normalisés.
│   │   ├── download_task.dart       DownloadTask, DownloadStatus, DownloadProgress
│   │   └── download_history.dart    DownloadHistoryEntry
│   ├── download_repository.dart     Contrat persistance (tâches + historique)
│   ├── download_notification_service.dart  Contrat notifications (impl. app)
│   └── download_link_resolver.dart  Contrat résolution liens intermédiaires
├── data/
│   ├── download_manager.dart        Chef d'orchestre (API publique)
│   ├── download_queue.dart          FIFO + concurrence bornée
│   ├── download_worker.dart         Exécution : failover miroirs, HTTP Range,
│   │                                pause/reprise, annulation, progression temps réel
│   ├── download_verifier.dart       MD5 streaming + signature magique + taille
│   ├── download_storage.dart        Fichiers partiels .partial/, finalisation
│   └── download_repository_impl.dart  Persistance JSON
└── presentation/
    └── downloads_controller.dart    État consolidé + actions (sans Flutter)
```

## Pipeline

```
SearchQuery -> fanOutToSources() -> normalizeBooks() -> deduplicateBooks() -> scoreAndSortBooks()
```

- **Fan-out** : toutes les sources actives en parallèle, timeout individuel,
  une source en panne ne casse rien (rapport par source).
- **Normalisation** : titre/auteur normalisés (sans accents ni casse),
  langue ISO 639-1.
- **Déduplication** : ISBN identique, sinon titre+auteur normalisés ;
  les doublons cumulent leurs sources.
- **Scoring** : 0..100, pondérations dans `ScoringConfig`.
  Priorité langue : **DE +35 / FR +30 / autres +10**.

## Ajouter une source (WeLib, Open Library, Gutenberg…)

1. Créer `lib/features/sources/data/<nouvelle_source>/`.
2. Implémenter `BookSource` (search / details / resolveDownloadLinks / healthCheck).
3. Enregistrer : `registry.register(NouvelleSource())`.

Aucune ligne du moteur n'est à modifier.

## Tests

```
dart pub get
dart test        # 96 tests : pipeline, parser, client, health-check, cache,
                 # guard, source, worker, verifier, storage, queue, manager
dart analyze     # 0 problème
```

## Feature : library (Étape 6)

Bibliothèque intelligente, totalement découplée : elle ne connaît ni les
sources, ni le DownloadManager, ni le Reader — tout passe par le bus
d'événements (`core/events`). Un livre peut être téléchargé, favori, dans
une collection, commencé ou terminé : états indépendants.

- `domain/` : LibraryManager (orchestrateur + écoute du bus), FavoritesManager,
  CollectionsManager, HistoryManager, ReadingProgressManager,
  StatisticsManager, LibrarySyncBackend (contrat cloud, sans implémentation),
  LibraryRepository (contrat de persistance), entities (LibraryBook, Favorite,
  Collection, ReadingProgress, ReadingHistory, ReadingStats).
- `data/` : JsonLibraryRepository (pur Dart, écritures sérialisées et
  atomiques), LibrarySync (sync disque au démarrage : fichiers disparus,
  revenus, orphelins), schema/library_schema.dart (DDL SQL de référence,
  8 tables : books, favorites, collections, collection_books,
  reading_progress, history, downloads, statistics).
- `presentation/` : LibraryController (pur Dart, état immuable LibraryState,
  rafraîchi par les événements).

Le DownloadManager publie `DownloadFinishedEvent` / `DownloadRemovedEvent`
(il n'écrit jamais dans la bibliothèque) ; le futur Reader utilisera les
mêmes événements de lecture. La future synchro Cloud implémentera
`LibrarySyncBackend` sans modifier aucun composant.

## Feature : reader (Étape 7)

Reader premium indépendant : il ne connaît ni les sources, ni le
DownloadManager, ni la Library — il reçoit uniquement un fichier local.
Tout lecteur implémente `ReaderContract` (modèle d'« unités » :
chapitres EPUB / pages PDF, progression dérivée de l'index d'unité).

- `domain/` : reader_contract (ReaderContract, ReaderPosition,
  ReaderTocEntry, ReaderContent, ReaderFormat — CBZ/CBR/MOBI/AZW3/FB2
  prévus, enregistrables via `ReaderManager.registerReader` sans rien
  modifier d'autre), reader_manager (orchestre : détection de format
  par extension + magic bytes, auto-save périodique, restauration de la
  dernière position, callbacks onPositionChanged/onSessionClosed),
  reader_settings (réglages bornés : police, interligne, marges,
  alignement, luminosité, orientation + ReaderTheme Light/Dark/Sepia/
  Night), reader_bookmarks, reader_annotations, reader_search
  (insensible casse/diacritiques, annulable, en flux), reader_navigation
  (chapitres, historique borné, retour navigateur), reader_statistics
  (temps, sessions, progression max), reader_repository (contrat).
- `data/` : epub/epub_reader (ZIP -> OPF -> spine -> NCX/NAV, HTML
  brut pour l'UI, texte brut pour la recherche), pdf/pdf_reader +
  pdf_document (arbre /Pages, ordre /Kids, flux FlateDecode, extraction
  Tj/TJ, /Outlines ; limites documentées : pas de rendu graphique, texte
  des scans non extractible), json_reader_repository (écritures
  atomiques sérialisées).
- `presentation/` : reader_controller (pur Dart, ReaderViewState
  immuable, recherches périmées annulées).

La mémorisation est automatique : position, progression, temps de
lecture, date d'ouverture — auto-save périodique + sauvegarde à la
fermeture. La reconnexion avec la Library se fera côté application via
les callbacks (jamais par dépendance directe).
