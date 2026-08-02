import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lesung/features/library/domain/entities/collection.dart';
import 'package:lesung/features/library/domain/entities/library_book.dart';

import '../../app/engine.dart';
import '../../app/router.dart';
import '../../components/app_dialogs.dart';
import '../../components/app_states.dart';
import '../../components/book_grid.dart';
import '../../components/collection_card.dart';
import '../../design_system/tokens/app_colors.dart';
import '../../design_system/tokens/app_icons.dart';
import '../../design_system/tokens/app_spacing.dart';
import '../../l10n/generated/app_localizations.dart';

/// Sammlungen — étagères thématiques créées par l'utilisateur.
/// Création via dialogue, détail au tap, renommage/suppression au
/// long-press.
class CollectionsScreen extends ConsumerStatefulWidget {
  const CollectionsScreen({super.key});

  @override
  ConsumerState<CollectionsScreen> createState() =>
      _CollectionsScreenState();
}

class _CollectionsScreenState extends ConsumerState<CollectionsScreen> {
  /// Nombre de livres et couvertures par collection (chargés une fois,
  /// rafraîchis à chaque événement de bibliothèque).
  final Map<String, List<LibraryBook>> _booksByCollection = {};
  late final StreamSubscription<dynamic> _librarySubscription;

  @override
  void initState() {
    super.initState();
    final engine = ref.read(engineProvider);
    unawaited(_reload(engine));
    _librarySubscription =
        engine.library.stream.listen((_) => _reload(engine));
  }

  @override
  void dispose() {
    unawaited(_librarySubscription.cancel());
    super.dispose();
  }

  Future<void> _reload(Engine engine) async {
    final state = engine.library.state;
    final map = <String, List<LibraryBook>>{};
    for (final collection in state.collections) {
      map[collection.id] =
          await engine.libraryManager.collections.booksIn(collection.id);
    }
    if (mounted) {
      setState(() {
        _booksByCollection
          ..clear()
          ..addAll(map);
      });
    }
  }

  Future<void> _create() async {
    final l10n = AppLocalizations.of(context)!;
    final name = await AppDialogs.prompt(
      context,
      title: l10n.collectionCreateTitle,
      hint: l10n.collectionNameHint,
      confirmLabel: l10n.actionCreate,
    );
    if (name == null) return;
    await ref.read(engineProvider).libraryManager.collections.create(name);
  }

  Future<void> _editCollection(Collection collection) async {
    final engine = ref.read(engineProvider);
    final l10n = AppLocalizations.of(context)!;
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.of(context).surface,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(AppIcons.settings),
              title: Text(l10n.actionRename),
              onTap: () => Navigator.of(context).pop('rename'),
            ),
            ListTile(
              leading: Icon(AppIcons.delete,
                  color: AppColors.of(context).error),
              title: Text(l10n.actionDelete,
                  style:
                      TextStyle(color: AppColors.of(context).error)),
              onTap: () => Navigator.of(context).pop('delete'),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (action == 'rename') {
      final newName = await AppDialogs.prompt(
        context,
        title: l10n.collectionRenameTitle,
        initialValue: collection.name,
      );
      if (newName != null) {
        await engine.libraryManager.collections
            .rename(collection.id, newName);
      }
    } else if (action == 'delete') {
      final confirmed = await AppDialogs.confirm(
        context,
        title: l10n.collectionDeleteTitle,
        message: '“${collection.name}” ${l10n.collectionDeleteMessage}',
        confirmLabel: l10n.actionDelete,
        destructive: true,
      );
      if (confirmed) {
        await engine.libraryManager.collections.delete(collection.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.read(engineProvider).library.state;
    final collections = state.collections;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.collectionsTitle)),
      floatingActionButton: FloatingActionButton(
        onPressed: _create,
        child: const Icon(AppIcons.add),
      ),
      body: state.loaded && collections.isEmpty
          ? AppEmptyState.emptyCollection(context: context)
          : ListView.separated(
              padding: AppSpacing.screen.copyWith(top: AppSpacing.l),
              itemCount: collections.length,
              separatorBuilder: (_, __) => AppSpacing.gapM,
              itemBuilder: (context, index) {
                final collection = collections[index];
                final books =
                    _booksByCollection[collection.id] ?? const [];
                return CollectionCard(
                  name: collection.name,
                  bookCount: books.length,
                  coverUrls: books
                      .map((b) => b.coverUrl)
                      .whereType<String>()
                      .take(4)
                      .toList(),
                  onTap: () => _openCollection(collection),
                  onLongPress: () => _editCollection(collection),
                );
              },
            ),
    );
  }

  void _openCollection(Collection collection) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => CollectionDetailScreen(collection: collection),
    ));
  }
}

/// Détail d'une collection — grille de livres, retrait au long-press.
class CollectionDetailScreen extends ConsumerStatefulWidget {
  final Collection collection;

  const CollectionDetailScreen({super.key, required this.collection});

  @override
  ConsumerState<CollectionDetailScreen> createState() =>
      _CollectionDetailScreenState();
}

class _CollectionDetailScreenState
    extends ConsumerState<CollectionDetailScreen> {
  List<LibraryBook> _books = const [];
  late final StreamSubscription<dynamic> _librarySubscription;

  @override
  void initState() {
    super.initState();
    final engine = ref.read(engineProvider);
    unawaited(_reload(engine));
    _librarySubscription =
        engine.library.stream.listen((_) => _reload(engine));
  }

  @override
  void dispose() {
    unawaited(_librarySubscription.cancel());
    super.dispose();
  }

  Future<void> _reload(Engine engine) async {
    final books = await engine.libraryManager.collections
        .booksIn(widget.collection.id);
    if (mounted) setState(() => _books = books);
  }

  Future<void> _removeBook(LibraryBook book) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await AppDialogs.confirm(
      context,
      title: l10n.collectionRemoveBookTitle,
      message: '“${book.title}” ${l10n.collectionRemoveBookMessage}',
      confirmLabel: l10n.actionRemove,
    );
    if (!confirmed) return;
    await ref
        .read(engineProvider)
        .libraryManager
        .collections
        .removeBook(widget.collection.id, book.id);
  }

  @override
  Widget build(BuildContext context) {
    final items = _books
        .map((book) => BookItem(
              id: book.id,
              title: book.title,
              author: book.author,
              coverUrl: book.coverUrl,
              badge: book.format?.toUpperCase(),
            ))
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(widget.collection.name)),
      body: _books.isEmpty
          ? AppEmptyState.emptyCollection(context: context)
          : GridView.builder(
              padding: AppSpacing.screen.copyWith(top: AppSpacing.l),
              gridDelegate:
                  const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 200,
                childAspectRatio: 0.62,
                crossAxisSpacing: AppSpacing.l,
                mainAxisSpacing: AppSpacing.xl,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final book = _books[index];
                return GestureDetector(
                  onLongPress: () => _removeBook(book),
                  child: BookGrid(
                    books: [items[index]],
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    onBookTap: (_) => _open(book),
                  ),
                );
              },
            ),
    );
  }

  void _open(LibraryBook book) {
    if (book.isReadable) {
      context.push(AppRoutes.reader,
          extra: ReaderBookArgs(
              bookId: book.id,
              filePath: book.filePath!,
              title: book.title));
    }
  }
}
