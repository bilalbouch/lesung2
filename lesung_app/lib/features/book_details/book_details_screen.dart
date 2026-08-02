import 'dart:async';

import 'package:flutter/foundation.dart';
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
import '../../features/sync/sync_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../services/browser_download.dart';

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
    unawaited(ref.read(syncControllerProvider.notifier).syncFavorites());
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
    final supportsDownloads =
        kIsWeb || ref.read(engineProvider).supportsManagedDownloads;

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
            onPressed:
                _downloading || !supportsDownloads ? null : _startDownload,
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
      if (kIsWeb) {
        Uri? directUrl;
        for (final bookRef in book.refs) {
          if (bookRef.sourceId == 'gutendex' && bookRef.url != null) {
            directUrl = bookRef.url;
            break;
          }
        }
        if (directUrl != null) {
          startBrowserDownload(directUrl, _downloadFileName(book.format.name));
          if (mounted) {
            AppSnackbars.success(context, l10n.bookDetailsDownloadStarted);
          }
          return;
        }
      }

      final links = <DownloadLink>[];
      for (final bookRef in book.refs) {
        final source = engine.registry.byId(bookRef.sourceId);
        if (source == null) continue;
        try {
          links.addAll(await source.resolveDownloadLinks(bookRef.sourceBookId));
        } catch (_) {
          // Une source indisponible ne doit pas empêcher d'essayer les autres.
        }
      }
      if (links.isEmpty) throw StateError(l10n.errorFileNotFound);

      if (kIsWeb) {
        final link = links.firstWhere(
          (candidate) => candidate.kind == DownloadLinkKind.direct,
          orElse: () => links.first,
        );
        startBrowserDownload(link.url, _downloadFileName(link.format.name));
      } else {
        final downloadManager = engine.downloadManager;
        if (downloadManager == null) {
          throw StateError(l10n.errorUnknown);
        }
        await downloadManager.enqueue(DownloadTask(
          id: book.dedupKey,
          title: book.title,
          author: book.author,
          coverUrl: book.coverUrl,
          format: book.format,
          links: links,
          expectedMd5: links
              .map((link) => link.md5)
              .firstWhere((md5) => md5 != null && md5.isNotEmpty,
                  orElse: () => null),
          expectedSizeBytes: book.fileSizeBytes,
        ));
      }

      if (mounted) {
        AppSnackbars.success(context, l10n.bookDetailsDownloadStarted);
      }
    } catch (error) {
      if (mounted) {
        AppSnackbars.error(
            context, l10n.bookDetailsDownloadFailed(error.toString()));
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  String _downloadFileName(String formatName) {
    final safeTitle = widget.item.book.title
        .replaceAll(RegExp(r'[^a-zA-Z0-9À-ÿ._ -]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '_');
    final extension = formatName == 'pdf' ? 'pdf' : 'epub';
    return '${safeTitle.isEmpty ? 'book' : safeTitle}.$extension';
  }

  String _formatSize(int bytes) {
    if (bytes >= 1 << 20) {
      return '${(bytes / (1 << 20)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024).toStringAsFixed(0)} KB';
  }
}