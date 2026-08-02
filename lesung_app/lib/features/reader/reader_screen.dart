import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lesung/features/reader/domain/reader_bookmarks.dart';
import 'package:lesung/features/reader/domain/reader_settings.dart';
import 'package:lesung/features/reader/presentation/reader_controller.dart';

import '../../app/engine.dart';
import '../../app/router.dart';
import '../../components/app_bottom_sheet.dart';
import '../../components/app_progress_indicator.dart';
import '../../components/reader_toolbar.dart';
import '../../design_system/tokens/app_icons.dart';
import '../../design_system/tokens/app_motion.dart';
import '../../features/reader/reader_text_provider.dart';
import '../../features/sync/sync_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../services/cloud_sync_service.dart';
import 'reader_page_content.dart';

/// Reader premium — surface de lecture épurée : le texte est l'élément
/// principal, les chrome (barres) n'apparaissent qu'au tap central.
///
/// Pagination v1 par unité (chapitre EPUB / page PDF), défilement
/// vertical continu dans l'unité. Sauvegarde automatique de la position
/// assurée par le ReaderManager (toutes les 15 s + à la fermeture).
class ReaderScreen extends ConsumerStatefulWidget {
  final ReaderBookArgs book;

  const ReaderScreen({super.key, required this.book});

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen>
    with WidgetsBindingObserver {
  late final ReaderController _controller;
  late final StreamSubscription<ReaderViewState> _readerSubscription;
  bool _chromeVisible = false;
  bool _savingLifecycleState = false;

  /// Texte de l'unité courante (chargé à chaque changement d'unité).
  String? _unitText;
  int? _loadedUnit;
  bool _cloudRestorePending = true;
  bool _cloudBookmarksReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final engine = ref.read(engineProvider);
    _controller = ReaderController(manager: engine.createReaderManager());
    _readerSubscription = _controller.stream.listen((state) {
      if (!mounted) return;
      final unit = state.position?.unitIndex;
      if (state.status == ReaderStatus.ready && unit != _loadedUnit) {
        _loadUnitText(unit ?? 0);
        if (!_cloudRestorePending) _saveCloudProgress();
      }
      setState(() {});
    });
    _open();
  }

  Future<void> _open() async {
    final engine = ref.read(engineProvider);
    await _controller.init();
    // La bibliothèque est informée via callback — le Reader n'émet
    // jamais d'événement lui-même (single-writer).
    await engine.libraryManager.openReading(widget.book.bookId);
    await _controller.openBook(widget.book.filePath);

    final syncController = ref.read(syncControllerProvider.notifier);
    await syncController.ready;
    if (!mounted) return;

    final syncState = ref.read(syncControllerProvider);
    if (syncState.enabled && _controller.state.status == ReaderStatus.ready) {
      final cloud = await ref
          .read(cloudSyncServiceProvider)
          .getProgress(widget.book.bookId);
      if (!mounted) return;
      if (!ref.read(syncControllerProvider).enabled) {
        _cloudRestorePending = false;
        return;
      }

      final local = _controller.state.position;
      final unitCount = _controller.manager.reader?.unitCount ?? 0;
      if (cloud != null &&
          local != null &&
          cloud.canRestore(
            localProgress: local.progress,
            unitCount: unitCount,
          )) {
        _controller.goToUnit(cloud.unitIndex);
        await _controller.manager.saveNow();
        if (!mounted) return;
      }

      await _restoreCloudBookmarks();
      if (!mounted) return;
    }

    _cloudRestorePending = false;
    await _saveCloudProgress();
  }

  Future<void> _restoreCloudBookmarks() async {
    final service = ref.read(cloudSyncServiceProvider);
    final cloudBookmarks = await service.getBookmarks(widget.book.bookId);
    if (!mounted || cloudBookmarks == null) return;
    if (!ref.read(syncControllerProvider).enabled) return;

    final unitCount = _controller.manager.reader?.unitCount ?? 0;
    final localBookmarks = _controller.state.bookmarks
        .map(_toCloudBookmark)
        .toList();
    final merged = CloudBookmark.merge(
      local: localBookmarks,
      cloud: cloudBookmarks,
      unitCount: unitCount,
    );
    final localLocators = localBookmarks
        .map((bookmark) => bookmark.locator)
        .toSet();
    final imported = merged
        .where((bookmark) => !localLocators.contains(bookmark.locator))
        .map(
          (bookmark) => ReaderBookmark(
            id: bookmark.id,
            bookId: _controller.manager.bookId ?? widget.book.filePath,
            locator: bookmark.locator,
            unitIndex: bookmark.unitIndex,
            label: bookmark.label,
            chapterTitle: bookmark.chapterTitle,
            createdAt: DateTime.now(),
          ),
        );
    await _controller.mergeBookmarks(imported);
    if (!mounted || !ref.read(syncControllerProvider).enabled) return;

    _cloudBookmarksReady = true;
    await service.saveBookmarks(widget.book.bookId, merged);
  }

  CloudBookmark _toCloudBookmark(ReaderBookmark bookmark) => CloudBookmark(
        id: bookmark.id,
        locator: bookmark.locator,
        unitIndex: bookmark.unitIndex,
        label: bookmark.label,
        chapterTitle: bookmark.chapterTitle,
      );

  Future<void> _saveCloudBookmarks() async {
    if (!_cloudBookmarksReady || !ref.read(syncControllerProvider).enabled) {
      return;
    }
    final bookmarks = _controller.state.bookmarks
        .map(_toCloudBookmark)
        .toList();
    await ref
        .read(cloudSyncServiceProvider)
        .saveBookmarks(widget.book.bookId, bookmarks);
  }

  Future<void> _saveCloudProgress() async {
    final syncState = ref.read(syncControllerProvider);
    final position = _controller.state.position;
    if (!syncState.enabled || position == null) return;

    await ref.read(cloudSyncServiceProvider).saveProgress(
          bookId: widget.book.bookId,
          unitIndex: position.unitIndex,
          progress: position.progress,
          chapterTitle: position.chapterTitle,
        );
  }

  Future<void> _loadUnitText(int unitIndex) async {
    _loadedUnit = unitIndex;
    final text =
        await _controller.manager.reader?.unitText(unitIndex);
    if (mounted && _loadedUnit == unitIndex) {
      setState(() => _unitText = text ?? '');
      ref.read(readerTextProvider.notifier).state = text ?? '';
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      unawaited(_saveForLifecycleChange());
    }
  }

  Future<void> _saveForLifecycleChange() async {
    if (_savingLifecycleState) return;
    _savingLifecycleState = true;
    try {
      await Future.wait([
        _controller.saveNow(),
        _saveCloudProgress(),
        _saveCloudBookmarks(),
      ]);
    } catch (_) {
      // Le prochain auto-save réessaiera sans interrompre le cycle de vie.
    } finally {
      _savingLifecycleState = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_readerSubscription.cancel());
    final engine = ref.read(engineProvider);
    unawaited(engine.libraryManager.closeReading(widget.book.bookId));
    unawaited(_saveCloudProgress());
    unawaited(_saveCloudBookmarks());
    unawaited(_controller.dispose());
    super.dispose();
  }

  // ---------------------------------------------------------------
  // Thème actif (fond / encre issus des presets du moteur)
  // ---------------------------------------------------------------

  ReaderTheme get _theme =>
      ReaderTheme.byId(_controller.state.settings.themeId);

  @override
  Widget build(BuildContext context) {
    final state = _controller.state;
    final theme = _theme;
    final settings = state.settings;

    return Scaffold(
      backgroundColor: Color(theme.backgroundColor),
      body: Stack(
        children: [
          // -- Surface de lecture -------------------------------------
          GestureDetector(
            onTapUp: (details) {
              final width = MediaQuery.sizeOf(context).width;
              final dx = details.localPosition.dx;
              if (dx < width * 0.25) {
                _controller.previousChapter();
              } else if (dx > width * 0.75) {
                _controller.nextChapter();
              } else {
                setState(() => _chromeVisible = !_chromeVisible);
              }
            },
            child: SafeArea(
              child: _buildBody(state, settings),
            ),
          ),

          // -- Chrome ---------------------------------------------------
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ReaderToolbar(
              visible: _chromeVisible,
              chapterTitle: state.position?.chapterTitle ?? state.title,
              progress: state.position?.progress ?? 0,
              bookmarked: _isBookmarked(state),
              onBack: () => Navigator.of(context).maybePop(),
              onSearch: _openSearch,
              onToc: _openToc,
              onBookmark: () async {
                await _controller.toggleBookmarkAtCurrentPosition();
                if (mounted) {
                  setState(() {});
                  unawaited(_saveCloudBookmarks());
                }
              },
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ReaderBottomBar(
              visible: _chromeVisible,
              progress: state.position?.progress ?? 0,
              onPreviousChapter: _controller.previousChapter,
              onNextChapter: _controller.nextChapter,
              onSettings: _openSettings,
            ),
          ),
        ],
      ),
    );
  }

  bool _isBookmarked(ReaderViewState state) {
    final unit = state.position?.unitIndex;
    if (unit == null) return false;
    return state.bookmarks.any((b) => b.unitIndex == unit);
  }

  Widget _buildBody(ReaderViewState state, ReaderSettings settings) {
    final l10n = AppLocalizations.of(context)!;
    if (state.status == ReaderStatus.loading ||
        state.status == ReaderStatus.idle) {
      return const Center(child: AppLoadingSpinner());
    }
    if (state.status == ReaderStatus.error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            '${l10n.errorInvalidFile}\n${state.errorMessage ?? ''}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }

    final text = _unitText;
    if (text == null) return const Center(child: AppLoadingSpinner());

    return ReaderPageContent(
      text: text,
      settings: settings,
      theme: _theme,
      loadedUnit: _loadedUnit ?? 0,
    );
  }

  // ---------------------------------------------------------------
  // Feuilles : sommaire, recherche, réglages
  // ---------------------------------------------------------------

  void _openToc() {
    final state = _controller.state;
    final l10n = AppLocalizations.of(context)!;
    final entries = state.tableOfContents.expand((e) => e.flatten()).toList();
    AppBottomSheet.show<void>(
      context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppBottomSheet.header(context, title: l10n.readerTocTitle),
          if (entries.isEmpty)
            Text(l10n.readerTocEmpty,
                style: Theme.of(context).textTheme.bodyMedium)
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.5),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(entry.title,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    onTap: () {
                      Navigator.of(context).pop();
                      _controller.goToTocEntry(entry);
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void _openSearch() {
    final controller = TextEditingController();
    final l10n = AppLocalizations.of(context)!;
    AppBottomSheet.show<void>(
      context,
      child: StatefulBuilder(
        builder: (context, setSheetState) {
          final state = _controller.state;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppBottomSheet.header(context, title: l10n.searchInBookTitle),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                    hintText: l10n.searchInBookHint,
                    prefixIcon: const Icon(AppIcons.searchInBook)),
                onSubmitted: (query) {
                  _controller.searchInBook(query);
                  setSheetState(() {});
                },
              ),
              const SizedBox(height: 16),
              if (state.searching)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 16),
                  child: AppProgressIndicator(
                    value: state.searchTotalUnits == 0
                        ? null
                        : state.searchDoneUnits / state.searchTotalUnits,
                  ),
                )
              else if (controller.text.isNotEmpty &&
                  state.searchResults.isEmpty)
                Text(l10n.searchInBookNoHits,
                    style: Theme.of(context).textTheme.bodyMedium),
              ConstrainedBox(
                constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.4),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: state.searchResults.length,
                  itemBuilder: (context, index) {
                    final hit = state.searchResults[index];
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(hit.snippet,
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                      subtitle: hit.chapterTitle == null
                          ? null
                          : Text(hit.chapterTitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                      onTap: () {
                        Navigator.of(context).pop();
                        _controller.goToSearchHit(hit);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openSettings() {
    final l10n = AppLocalizations.of(context)!;
    AppBottomSheet.show<void>(
      context,
      child: StatefulBuilder(
        builder: (context, setSheetState) {
          final settings = _controller.state.settings;
          void update(ReaderSettings Function(ReaderSettings) fn) {
            _controller.updateSettings(fn);
            setSheetState(() {});
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppBottomSheet.header(context, title: l10n.readerSettingsTitle),
              // -- Thèmes ------------------------------------------------
              Row(
                children: [
                  for (final preset in ReaderTheme.presets.values)
                    Padding(
                      padding:
                          const EdgeInsets.only(right: 12),
                      child: _ThemeChip(
                        theme: preset,
                        label: _themeLabel(l10n, preset.id),
                        selected: settings.themeId == preset.id,
                        onTap: () =>
                            update((s) => s.copyWith(themeId: preset.id)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 32),
              _SettingSlider(
                label: l10n.readerSettingsFontSize,
                value: settings.fontSize,
                min: 10,
                max: 32,
                onChanged: (v) =>
                    update((s) => s.copyWith(fontSize: v)),
              ),
              _SettingSlider(
                label: l10n.readerSettingsLineHeight,
                value: settings.lineHeight,
                min: 1.0,
                max: 2.5,
                onChanged: (v) =>
                    update((s) => s.copyWith(lineHeight: v)),
              ),
              _SettingSlider(
                label: l10n.readerSettingsMargins,
                value: settings.marginHorizontal,
                min: 0,
                max: 64,
                onChanged: (v) =>
                    update((s) => s.copyWith(marginHorizontal: v)),
              ),
              const SizedBox(height: 24),
              // -- Police -------------------------------------------------
              Text(l10n.readerSettingsFontFamily,
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final entry
                      in ReaderSettings.availableFonts.entries)
                    ChoiceChip(
                      label: Text(entry.value),
                      selected: settings.fontFamily == entry.key,
                      onSelected: (_) => update(
                          (s) => s.copyWith(fontFamily: entry.key)),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  String _themeLabel(AppLocalizations l10n, String themeId) => switch (themeId) {
        'dark' => l10n.readerThemeDark,
        'sepia' => l10n.readerThemeSepia,
        'night' => l10n.readerThemeBlack,
        _ => l10n.readerThemeLight,
      };
}

class _ThemeChip extends StatelessWidget {
  final ReaderTheme theme;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeChip({
    required this.theme,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Color(theme.backgroundColor),
            shape: BoxShape.circle,
            border: Border.all(
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Color(theme.textColor).withValues(alpha: 0.2),
              width: selected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text('Aa',
                style: TextStyle(
                    color: Color(theme.textColor),
                    fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }
}

class _SettingSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _SettingSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(label,
              style: Theme.of(context).textTheme.bodySmall),
        ),
        Expanded(
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
