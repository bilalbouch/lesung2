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
import '../../design_system/tokens/app_colors.dart';
import '../../design_system/tokens/app_icons.dart';
import '../../design_system/tokens/app_spacing.dart';

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
    AppSnackbars.info(context,
        isFav ? 'Zu Favoriten hinzugefügt' : 'Aus Favoriten entfernt');
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final book = widget.item.book;

    final meta = <String>[
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
        padding: AppSpacing.screen,
        children: [
          Center(
            child: Hero(
              tag: 'cover-${book.dedupKey}',
              child: BookCover(
                  title: book.title, coverUrl: book.coverUrl, width: 180),
            ),
          ),
          AppSpacing.gapXl,
          Text(book.title,
              style: textTheme.headlineLarge, textAlign: TextAlign.center),
          if (book.author != null && book.author!.isNotEmpty) ...[
            AppSpacing.gapS,
            Text(book.author!,
                style: textTheme.titleMedium
                    ?.copyWith(color: colors.inkSecondary),
                textAlign: TextAlign.center),
          ],
          AppSpacing.gapXl,
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.s,
            runSpacing: AppSpacing.s,
            children: [
              for (final chip in meta)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.m, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: colors.surfaceAlt,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(chip, style: textTheme.bodySmall),
                ),
            ],
          ),
          AppSpacing.gapXxl,
          ActionButton(
            label: _downloading ? 'Wird geladen…' : 'Herunterladen',
            icon: AppIcons.download,
            expanded: true,
            onPressed: _downloading ? null : _startDownload,
          ),
          AppSpacing.gapM,
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
            AppSpacing.gapXxl,
            Text('Beschreibung', style: textTheme.titleLarge),
            AppSpacing.gapM,
            Text(book.description!,
                style:
                    textTheme.bodyLarge?.copyWith(height: 1.6)),
          ],
          AppSpacing.gapXxl,
        ],
      ),
    );
  }

  Future<void> _startDownload() async {
    setState(() => _downloading = true);
    final engine = ref.read(engineProvider);
    final book = widget.item.book;
    try {
      // Résolution des liens via la source d'origine du livre.
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
        AppSnackbars.success(context, 'Download gestartet.');
      }
    } catch (e) {
      if (mounted) {
        AppSnackbars.error(context, 'Download fehlgeschlagen: $e');
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
