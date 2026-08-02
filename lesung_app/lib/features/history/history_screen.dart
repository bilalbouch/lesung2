import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lesung/features/library/domain/entities/library_book.dart';
import 'package:lesung/features/library/domain/entities/reading_history.dart';

import '../../app/engine.dart';
import '../../app/router.dart';
import '../../components/app_states.dart';
import '../../components/book_cover.dart';
import '../../components/section_title.dart';
import '../../design_system/tokens/lumina_radius.dart';
import '../../l10n/generated/app_localizations.dart';

/// Verlauf — sessions de lecture groupées par jour.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  /// Titres des livres résolus (bookId -> livre).
  final Map<String, LibraryBook?> _books = {};
  late final StreamSubscription<dynamic> _librarySubscription;

  @override
  void initState() {
    super.initState();
    final engine = ref.read(engineProvider);
    unawaited(_resolveBooks(engine));
    _librarySubscription =
        engine.library.stream.listen((_) => _resolveBooks(engine));
  }

  @override
  void dispose() {
    unawaited(_librarySubscription.cancel());
    super.dispose();
  }

  Future<void> _resolveBooks(Engine engine) async {
    for (final entry in engine.library.state.history) {
      if (_books.containsKey(entry.bookId)) continue;
      _books[entry.bookId] =
          await engine.libraryManager.bookById(entry.bookId);
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.read(engineProvider).library.state;
    final entries = state.history;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.historyTitle)),
      body: state.loaded && entries.isEmpty
          ? AppEmptyState.noHistory(context: context)
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(top: 16),
              children: [
                for (final group in _groupByDay(entries)) ...[
                  SectionTitle(title: group.$1),
                  const SizedBox(height: 16),
                  for (final entry in group.$2)
                    _HistoryTile(
                      entry: entry,
                      book: _books[entry.bookId],
                      onTap: () => _open(entry.bookId),
                    ),
                  const SizedBox(height: 32),
                ],
              ],
            ),
    );
  }

  /// Groupe les sessions par jour (plus récent en premier).
  List<(String, List<ReadingHistoryEntry>)> _groupByDay(
      List<ReadingHistoryEntry> entries) {
    final sorted = [...entries]
      ..sort((a, b) => b.openedAt.compareTo(a.openedAt));
    final groups = <String, List<ReadingHistoryEntry>>{};
    final order = <String>[];
    final locale = Localizations.localeOf(context).languageCode;
    final dayFormat = DateFormat.yMMMEd(locale);
    for (final entry in sorted) {
      final label = dayFormat.format(entry.openedAt);
      if (!groups.containsKey(label)) {
        groups[label] = [];
        order.add(label);
      }
      groups[label]!.add(entry);
    }
    return [for (final label in order) (label, groups[label]!)];
  }

  Future<void> _open(String bookId) async {
    final book =
        await ref.read(engineProvider).libraryManager.bookById(bookId);
    if (book == null || !book.isReadable || !mounted) return;
    context.push(AppRoutes.reader,
        extra: ReaderBookArgs(
            bookId: book.id,
            filePath: book.filePath!,
            title: book.title));
  }
}

class _HistoryTile extends StatelessWidget {
  final ReadingHistoryEntry entry;
  final LibraryBook? book;
  final VoidCallback onTap;

  const _HistoryTile({
    required this.entry,
    required this.book,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final duration = entry.durationSeconds;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(LuminaRadius.m),
        child: Row(
          children: [
            BookCover(
              title: book?.title ?? '?',
              coverUrl: book?.coverUrl,
              width: 44,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(book?.title ?? entry.bookId,
                      style: textTheme.bodyLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text(
                    [
                      DateFormat.Hm(locale).format(entry.openedAt),
                      if (duration != null && duration > 0)
                        _formatDuration(duration, l10n),
                    ].join(' · '),
                    style: textTheme.bodySmall
                        ?.copyWith(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int seconds, AppLocalizations l10n) {
    final duration = Duration(seconds: seconds);
    if (duration.inHours > 0) {
      return l10n.settingsHoursMinutes(
        duration.inHours,
        duration.inMinutes % 60,
      );
    }
    return l10n.settingsMinutesOnly(duration.inMinutes);
  }
}
