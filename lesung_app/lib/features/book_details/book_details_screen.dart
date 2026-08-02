import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lesung/features/downloads/domain/entities/download_task.dart';
import 'package:lesung/features/library/domain/entities/library_book.dart';
import 'package:lesung/features/search/domain/entities/download_link.dart';
import 'package:lesung/features/search/domain/entities/search_result.dart';

import '../../app/engine.dart';
import '../../components/action_button.dart';
import '../../components/app_snackbars.dart';
import '../../components/book_cover.dart';
import '../../components/favorite_button.dart';
import '../../design_system/tokens/app_icons.dart';
import '../../l10n/generated/app_localizations.dart';

/// Détails du livre — couverture en héros, métadonnées discrètes,
/// action principale : Télécharger.
class BookDetailsScreen extends ConsumerStatefulWidget {
  final SearchResultItem item;

  const BookDetailsScreen({super.key, required this.item});

  @override
  ConsumerState<BookDetailsScreen> createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends ConsumerState<BookDetailsScreen> {
  bool _downloading = false;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadFavoriteState();
  }

  Future<void> _loadFavoriteState() async {
    final engine = ref.read(engineProvider);
    final isFav = await engine.libraryManager.favorites
        .isFavorite(widget.item.book.dedupKey);
    if (mounted) setState(() => _isFavorite = isFav);
  }

  /// Favori réel : le livre rejoint la bibliothèque si besoin
  /// (état « non téléchargé »), puis le favori est basculé.
  Future<void> _toggleFavorite() async {
    final engine = ref.read(engineProvider);
    final manager = engine.libraryManager;
    final book = widget.item.book;
    final existing = await manager.bookById(book.dedupKey);
    if (existing == null) {
      final now = DateTime.now();
      await manager.addBook(LibraryBook(
        id: book.dedupKey,
        title: book.title,
        author: book.author,
        coverUrl: book.coverUrl,
        language: book.language,
        format: book.format.name,
        publisher: book.publisher,
        year: book.year,
        description: book.description,
        isbn: book.isbn,
        addedAt: now,
        updatedAt: now,
      ));
    }
    final isFav = await manager.favorites.toggle(book.dedupKey);
    if (!mounted) return;
    setState(() => _isFavorite = isFav);
    final l10n = AppLocalizations.of(context)!;
    AppSnackbars.info(context,
        isFav ? l10n.bookDetailsAddedToFavorites : l10n.bookDetailsRemovedFromFavorites);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final book = widget.item.book;

    final meta = [
      if (book.format.name != 'unknown') book.format.name.toUpperCase(),
      if (book.language != null && book.language!.isNotEmpty)
        book.language!.toUpperCase(),
      if (book.year != null) '${book.year}',
      if (book.fileSizeBytes != null) _formatSize(book.fileSizeBytes!),
      if (book.publisher != null && book.publisher!.isNotEmpty)
        book.publisher!,
    ];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(AppIcons.back),
            onPressed: () => context.pop()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Hero(
              tag: 'cover-${book.dedupKey}',
              child: BookCover(
                  title: book.title, coverUrl: book.coverUrl, width: 180,
                  heroTag: book.dedupKey,),
            ),
          ),
          const SizedBox(height: 32),
          Text(book.title,
              style: textTheme.headlineLarge, textAlign: TextAlign.center),
          if (book.author != null && book.author!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(book.author!,
                style: textTheme.titleMedium
                    ?.copyWith(color: colors.onSurfaceVariant),
                textAlign: TextAlign.center),
          ],
          const SizedBox(height: 32),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final chip in meta)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(chip, style: textTheme.bodySmall),
                ),
            ],
          ),
          const SizedBox(height: 48),
          ActionButton(
            label: _downloading ? l10n.bookDetailsDownloading : l10n.bookDetailsDownload,
            icon: AppIcons.download,
            expanded: true,
            onPressed: _downloading ? null : _startDownload,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FavoriteButton(
                isFavorite: _isFavorite,
                onToggle: _toggleFavorite,
              ),
            ],
          ),
          if (book.description != null && book.description!.isNotEmpty) ...[
            const SizedBox(height: 48),
            Text(l10n.bookDetailsDescription, style: textTheme.titleLarge),
            const SizedBox(height: 16),
            Text(book.description!,
                style: textTheme.bodyLarge?.copyWith(height: 1.6)),
          ],
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Future<void> _startDownload() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _downloading = true);
    final engine = ref.read(engineProvider);
    final book = widget.item.book;
    try {
      if (book.refs.isEmpty) {
        throw StateError('Keine Quelle für dieses Buch.');
      }
      final ref0 = book.refs.first;
      final source = engine.registry.byId(ref0.sourceId);
      if (source == null) {
        throw StateError('Quelle unbekannt: ${ref0.sourceId}');
      }
      final links = await source.resolveDownloadLinks(ref0.sourceBookId);
      if (links.isEmpty) {
        throw StateError('Keine Download-Links gefunden.');
      }
      await engine.downloadManager.enqueue(DownloadTask(
        id: book.dedupKey,
        title: book.title,
        author: book.author,
        coverUrl: book.coverUrl,
        format: book.format,
        links: links
            .map((l) => DownloadLink(
                url: l.url,
                kind: l.kind,
                format: l.format,
                md5: l.md5,
                fileSizeBytes: l.fileSizeBytes))
            .toList(),
        expectedMd5: links
            .map((l) => l.md5)
            .firstWhere((m) => m != null && m.isNotEmpty, orElse: () => null),
        expectedSizeBytes: book.fileSizeBytes,
      ));
      if (mounted) {
        AppSnackbars.success(context, l10n.bookDetailsDownloadStarted);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbars.error(context, l10n.bookDetailsDownloadFailed(e.toString()));
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  String _formatSize(int bytes) {
    if (bytes >= 1 << 20) {
      return '${(bytes / (1 << 20)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024).toStringAsFixed(0)} KB';
  }
}