import 'package:flutter/material.dart' hide SearchController;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lesung/features/search/domain/entities/search_query.dart';
import 'package:lesung/features/search/domain/entities/search_result.dart';

import 'search_providers.dart';
import '../../app/router.dart';
import '../../components/app_animations.dart';
import '../../components/app_progress_indicator.dart';
import '../../components/app_search_bar.dart';
import '../../components/app_states.dart';
import '../../components/book_cover.dart';
import '../../design_system/tokens/app_colors.dart';
import '../../design_system/tokens/app_icons.dart';
import '../../design_system/tokens/app_spacing.dart';

/// Recherche — la fonctionnalité la plus importante de l'app.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  BookFormat? _formatFilter;

  SearchController get _search =>
      ref.read(searchControllerProvider.notifier);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppSpacing.gapL,
            FloatingSearchBar(
              controller: _controller,
              onChanged: _search.onQueryChanged,
              onSubmitted: () =>
                  _search.search(_controller.text, format: _formatFilter),
            ),
            AppSpacing.gapM,
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: AppSpacing.screen,
                children: [
                  _FormatChip(
                    label: 'Alle',
                    selected: _formatFilter == null,
                    onTap: () => _applyFilter(null),
                  ),
                  AppSpacing.hGapS,
                  _FormatChip(
                    label: 'EPUB',
                    selected: _formatFilter == BookFormat.epub,
                    onTap: () => _applyFilter(BookFormat.epub),
                  ),
                  AppSpacing.hGapS,
                  _FormatChip(
                    label: 'PDF',
                    selected: _formatFilter == BookFormat.pdf,
                    onTap: () => _applyFilter(BookFormat.pdf),
                  ),
                ],
              ),
            ),
            AppSpacing.gapS,
            Expanded(
                child: AppAnimations.crossFade(
                    child: _body(ref.watch(searchControllerProvider).valueOrNull))),
          ],
        ),
      ),
    );
  }

  void _applyFilter(BookFormat? format) {
    setState(() => _formatFilter = format);
    if (_controller.text.trim().isNotEmpty) {
      _search.search(_controller.text, format: format);
    }
  }

  Widget _body(SearchUiState? ui) {
    final state = ui ?? const SearchUiState(status: SearchUiStatus.idle);
    switch (state.status) {
      case SearchUiStatus.idle:
        return const _SearchPrompt(key: ValueKey('prompt'));
      case SearchUiStatus.loading:
        return const AppLoadingState(
            key: ValueKey('loading'), label: 'Suche läuft…');
      case SearchUiStatus.empty:
        return AppEmptyState.noResults(
            key: const ValueKey('empty'), query: _controller.text);
      case SearchUiStatus.error:
        return AppEmptyState.errorNetwork(
          key: const ValueKey('error'),
          onRetry: () =>
              _search.search(_controller.text, format: _formatFilter),
        );
      case SearchUiStatus.success:
        return _ResultsList(
          key: const ValueKey('results'),
          items: state.items,
          hasMore: state.hasMore,
          onLoadMore: _search.loadMore,
          onTap: (item) => context.push(AppRoutes.bookDetails, extra: item),
        );
    }
  }
}

class _SearchPrompt extends StatelessWidget {
  const _SearchPrompt({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppIcons.search, size: 44, color: colors.inkTertiary),
          AppSpacing.gapL,
          Text(
            'Wonach suchst du?',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          AppSpacing.gapS,
          Text(
            'Titel, Autor oder ISBN eingeben.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _FormatChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FormatChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
    );
  }
}

class _ResultsList extends StatelessWidget {
  final List<SearchResultItem> items;
  final bool hasMore;
  final VoidCallback onLoadMore;
  final void Function(SearchResultItem) onTap;

  const _ResultsList({
    super.key,
    required this.items,
    required this.hasMore,
    required this.onLoadMore,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
      itemCount: items.length + (hasMore ? 1 : 0),
      separatorBuilder: (_, __) =>
          Divider(indent: AppSpacing.l, endIndent: AppSpacing.l),
      itemBuilder: (context, index) {
        if (index >= items.length) {
          onLoadMore();
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: AppLoadingSpinner(),
          );
        }
        final item = items[index];
        final book = item.book;
        return ListTile(
          contentPadding: AppSpacing.listItem,
          leading:
              BookCover(title: book.title, coverUrl: book.coverUrl, width: 44),
          title: Text(book.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w600)),
          subtitle: Text(
            [book.author, book.year?.toString(), book.language]
                .whereType<String>()
                .where((e) => e.isNotEmpty)
                .join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s, vertical: AppSpacing.xxs),
            decoration: BoxDecoration(
              color: colors.surfaceAlt,
              borderRadius: BorderRadius.circular(AppSpacing.xs),
            ),
            child: Text(
              book.format.name.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
          onTap: () => onTap(item),
        );
      },
    );
  }
}
