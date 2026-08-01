import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lesung/features/reader/domain/reader_settings.dart';
import 'package:lesung/features/reader/presentation/reader_controller.dart';

import '../../app/engine.dart';
import '../../app/router.dart';
import '../../components/app_animations.dart';
import '../../components/app_bottom_sheet.dart';
import '../../components/app_progress_indicator.dart';
import '../../components/reader_toolbar.dart';
import '../../design_system/tokens/app_colors.dart';
import '../../design_system/tokens/app_icons.dart';
import '../../design_system/tokens/app_motion.dart';
import '../../design_system/tokens/app_spacing.dart';
import '../../l10n/generated/app_localizations.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  final ReaderBookArgs book;
  const ReaderScreen({super.key, required this.book});
  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  late final ReaderController _controller;
  bool _chromeVisible = false;
  String? _unitText;
  int? _loadedUnit;

  @override
  void initState() {
    super.initState();
    final engine = ref.read(engineProvider);
    _controller = ReaderController(manager: engine.createReaderManager());
    _controller.stream.listen((state) {
      if (!mounted) return;
      final unit = state.position?.unitIndex;
      if (state.status == ReaderStatus.ready && unit != _loadedUnit) {
        _loadUnitText(unit ?? 0);
      }
      setState(() {});
    });
    _open();
  }

  Future<void> _open() async {
    final engine = ref.read(engineProvider);
    await _controller.init();
    await engine.libraryManager.openReading(widget.book.bookId);
    await _controller.openBook(widget.book.filePath);
  }

  Future<void> _loadUnitText(int unitIndex) async {
    _loadedUnit = unitIndex;
    final text = await _controller.manager.reader?.unitText(unitIndex);
    if (mounted && _loadedUnit == unitIndex) {
      setState(() => _unitText = text ?? '');
    }
  }

  @override
  void dispose() {
    final engine = ref.read(engineProvider);
    engine.libraryManager.closeReading(widget.book.bookId);
    _controller.dispose();
    super.dispose();
  }

  ReaderTheme get _theme => ReaderTheme.byId(_controller.state.settings.themeId);

  TextStyle _readingTextStyle(ReaderSettings settings) {
    final base = switch (settings.fontFamily) {
      'lora' => GoogleFonts.lora(),
      'inter' => GoogleFonts.inter(),
      'system_serif' => const TextStyle(fontFamily: 'serif'),
      'mono' => const TextStyle(fontFamily: 'monospace'),
      _ => const TextStyle(),
    };
    return base.copyWith(
      fontSize: settings.fontSize,
      height: settings.lineHeight,
      color: Color(_theme.textColor),
    );
  }

  TextAlign _flutterAlign(ReaderTextAlign align) => switch (align) {
    ReaderTextAlign.left => TextAlign.left,
    ReaderTextAlign.justify => TextAlign.justify,
    ReaderTextAlign.right => TextAlign.right,
  };

  @override
  Widget build(BuildContext context) {
    final state = _controller.state;
    final theme = _theme;
    final settings = state.settings;

    return Scaffold(
      backgroundColor: Color(theme.backgroundColor),
      body: Stack(
        children: [
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
            child: SafeArea(child: _buildBody(state, settings)),
          ),
          Positioned(
            top: 0, left: 0, right: 0,
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
                if (mounted) setState(() {});
              },
            ),
          ),
          Positioned(
            bottom: 0, left: 0, right: 0,
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
    if (state.status == ReaderStatus.loading || state.status == ReaderStatus.idle) {
      return const Center(child: AppLoadingSpinner());
    }
    if (state.status == ReaderStatus.error) {
      return Center(
        child: Padding(
          padding: AppSpacing.screen,
          child: Text(
            'Das Buch konnte nicht geoeffnet werden.\n${state.errorMessage ?? ''}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }
    final text = _unitText;
    if (text == null) return const Center(child: AppLoadingSpinner());
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.l + settings.marginHorizontal,
        vertical: AppSpacing.xl + settings.marginVertical,
      ),
      child: AppAnimations.fadeIn(
        key: ValueKey(_loadedUnit),
        child: SelectableText(
          text.isEmpty ? '-' : text,
          style: _readingTextStyle(settings),
          textAlign: _flutterAlign(settings.textAlign),
        ),
      ),
    );
  }
  void _openToc() {
    final l10n = AppLocalizations.of(context)!;
    final state = _controller.state;
    final entries = state.tableOfContents.expand((e) => e.flatten()).toList();
    AppBottomSheet.show(
      context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppBottomSheet.header(context, title: l10n.readerTocTitle),
          if (entries.isEmpty)
            Text(l10n.readerTocEmpty, style: Theme.of(context).textTheme.bodyMedium)
          else
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.5),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(entry.title, maxLines: 1, overflow: TextOverflow.ellipsis),
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
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    AppBottomSheet.show(
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
              AppSpacing.gapM,
              if (state.searching)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
                  child: AppProgressIndicator(
                    value: state.searchTotalUnits == 0
                        ? null
                        : state.searchDoneUnits / state.searchTotalUnits,
                  ),
                )
              else if (controller.text.isNotEmpty && state.searchResults.isEmpty)
                Text(l10n.searchInBookNoHits, style: Theme.of(context).textTheme.bodyMedium),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.4),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: state.searchResults.length,
                  itemBuilder: (context, index) {
                    final hit = state.searchResults[index];
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(hit.snippet, maxLines: 2, overflow: TextOverflow.ellipsis),
                      subtitle: hit.chapterTitle == null
                          ? null
                          : Text(hit.chapterTitle!, maxLines: 1, overflow: TextOverflow.ellipsis),
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
    AppBottomSheet.show(
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
              Row(
                children: [
                  for (final preset in ReaderTheme.presets.values)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.s),
                      child: _ThemeChip(
                        theme: preset,
                        selected: settings.themeId == preset.id,
                        onTap: () => update((s) => s.copyWith(themeId: preset.id)),
                      ),
                    ),
                ],
              ),
              AppSpacing.gapXl,
              _SettingSlider(
                label: l10n.readerSettingsFontSize,
                value: settings.fontSize,
                min: 10, max: 32,
                onChanged: (v) => update((s) => s.copyWith(fontSize: v)),
              ),
              _SettingSlider(
                label: l10n.readerSettingsLineHeight,
                value: settings.lineHeight,
                min: 1.0, max: 2.5,
                onChanged: (v) => update((s) => s.copyWith(lineHeight: v)),
              ),
              _SettingSlider(
                label: l10n.readerSettingsMargins,
                value: settings.marginHorizontal,
                min: 0, max: 64,
                onChanged: (v) => update((s) => s.copyWith(marginHorizontal: v)),
              ),
              AppSpacing.gapL,
              Text(l10n.readerSettingsFontFamily, style: Theme.of(context).textTheme.bodySmall),
              AppSpacing.gapS,
              Wrap(
                spacing: AppSpacing.s,
                runSpacing: AppSpacing.s,
                children: [
                  for (final entry in ReaderSettings.availableFonts.entries)
                    ChoiceChip(
                      label: Text(entry.value),
                      selected: settings.fontFamily == entry.key,
                      onSelected: (_) => update((s) => s.copyWith(fontFamily: entry.key)),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
class _ThemeChip extends StatelessWidget {
  final ReaderTheme theme;
  final bool selected;
  final VoidCallback onTap;
  const _ThemeChip({required this.theme, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        width: 52, height: 52,
        decoration: BoxDecoration(
          color: Color(theme.backgroundColor),
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? AppColors.of(context).accent : Color(theme.textColor).withValues(alpha: 0.2),
            width: selected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text('Aa', style: TextStyle(color: Color(theme.textColor), fontWeight: FontWeight.w600)),
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
  const _SettingSlider({required this.label, required this.value, required this.min, required this.max, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 110, child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
        Expanded(child: Slider(value: value.clamp(min, max), min: min, max: max, onChanged: onChanged)),
      ],
    );
  }
}