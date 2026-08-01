import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lesung/features/reader/domain/reader_settings.dart';
import 'package:lesung/features/reader/presentation/reader_controller.dart';

import '../../app/engine.dart';
import '../../app/router.dart';
import '../../components/section_title.dart';
import '../../design_system/tokens/app_colors.dart';
import '../../design_system/tokens/app_icons.dart';
import '../../design_system/tokens/app_radius.dart';
import '../../design_system/tokens/app_spacing.dart';
import '../../main.dart' show BrandLogo;

/// Mehr — réglages de lecture (persistés par le moteur), statistiques
/// réelles de la bibliothèque et informations sur l'application.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final ReaderController _readerController;

  @override
  void initState() {
    super.initState();
    final engine = ref.read(engineProvider);
    _readerController =
        ReaderController(manager: engine.createReaderManager());
    _readerController.stream.listen((_) {
      if (mounted) setState(() {});
    });
    _readerController.init();
    engine.library.stream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _readerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final engine = ref.read(engineProvider);
    final settings = _readerController.state.settings;
    final stats = engine.library.state.stats;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.screen,
          children: [
            AppSpacing.gapXl,
            Text('Mehr', style: textTheme.displayLarge),
            AppSpacing.gapXxl,

            // -- Raccourcis bibliothèque ------------------------------
            const SectionTitle(title: 'Bibliothek'),
            AppSpacing.gapM,
            _SettingsTile(
              icon: AppIcons.favorite,
              title: 'Favoriten',
              onTap: () => context.push(AppRoutes.favorites),
            ),
            _SettingsTile(
              icon: AppIcons.collection,
              title: 'Sammlungen',
              onTap: () => context.push(AppRoutes.collections),
            ),
            _SettingsTile(
              icon: AppIcons.history,
              title: 'Verlauf',
              onTap: () => context.push(AppRoutes.history),
            ),
            AppSpacing.gapXxl,

            // -- Style de lecture ---------------------------------------
            const SectionTitle(title: 'Lesestil'),
            AppSpacing.gapM,
            Container(
              padding: AppSpacing.card,
              decoration: BoxDecoration(
                color: colors.surfaceAlt,
                borderRadius: AppRadius.card,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Design', style: textTheme.bodySmall),
                  AppSpacing.gapM,
                  Row(
                    children: [
                      for (final preset in ReaderTheme.presets.values)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.xs),
                            child: _ThemeOption(
                              theme: preset,
                              selected:
                                  settings.themeId == preset.id,
                              onTap: () => _readerController
                                  .updateSettings((s) =>
                                      s.copyWith(themeId: preset.id)),
                            ),
                          ),
                        ),
                    ],
                  ),
                  AppSpacing.gapL,
                  _SliderRow(
                    label: 'Schrift',
                    value: settings.fontSize,
                    min: 10,
                    max: 32,
                    onChanged: (v) => _readerController
                        .updateSettings((s) => s.copyWith(fontSize: v)),
                  ),
                  _SliderRow(
                    label: 'Abstand',
                    value: settings.lineHeight,
                    min: 1.0,
                    max: 2.5,
                    onChanged: (v) => _readerController
                        .updateSettings((s) => s.copyWith(lineHeight: v)),
                  ),
                  _SliderRow(
                    label: 'Ränder',
                    value: settings.marginHorizontal,
                    min: 0,
                    max: 64,
                    onChanged: (v) => _readerController.updateSettings(
                        (s) => s.copyWith(marginHorizontal: v)),
                  ),
                ],
              ),
            ),
            AppSpacing.gapXxl,

            // -- Statistiques -------------------------------------------
            if (stats != null) ...[
              const SectionTitle(title: 'Statistik'),
              AppSpacing.gapM,
              Container(
                padding: AppSpacing.card,
                decoration: BoxDecoration(
                  color: colors.surfaceAlt,
                  borderRadius: AppRadius.card,
                ),
                child: Column(
                  children: [
                    _StatRow(label: 'Bücher', value: '${stats.totalBooks}'),
                    _StatRow(
                        label: 'Heruntergeladen',
                        value: '${stats.downloadedBooks}'),
                    _StatRow(
                        label: 'Beendet',
                        value: '${stats.finishedBooks}'),
                    _StatRow(
                        label: 'Favoriten',
                        value: '${stats.favoritesCount}'),
                    _StatRow(
                        label: 'Lesezeit',
                        value: _formatReadingTime(
                            stats.totalReadingSeconds)),
                  ],
                ),
              ),
              AppSpacing.gapXxl,
            ],

            // -- À propos ------------------------------------------------
            Center(
              child: Column(
                children: [
                  const BrandLogo(size: 56),
                  AppSpacing.gapM,
                  Text('Lesung', style: textTheme.titleLarge),
                  AppSpacing.gapXs,
                  Text('Deine Bibliothek. Privat. Lokal.',
                      style: textTheme.bodySmall),
                ],
              ),
            ),
            AppSpacing.gapXxl,
          ],
        ),
      ),
    );
  }

  String _formatReadingTime(int seconds) {
    final duration = Duration(seconds: seconds);
    if (duration.inHours > 0) {
      return '${duration.inHours} Std. ${duration.inMinutes % 60} Min.';
    }
    return '${duration.inMinutes} Min.';
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: colors.accentSubtle,
          borderRadius: AppRadius.cardSmall,
        ),
        child: Icon(icon, color: colors.accent, size: 20),
      ),
      title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
      trailing: Icon(AppIcons.chapterNext,
          color: colors.inkTertiary, size: 20),
      onTap: onTap,
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final ReaderTheme theme;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.theme,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
        decoration: BoxDecoration(
          color: Color(theme.backgroundColor),
          borderRadius: AppRadius.cardSmall,
          border: Border.all(
            color: selected ? colors.accent : colors.divider,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text('Aa',
                style: TextStyle(
                    color: Color(theme.textColor),
                    fontWeight: FontWeight.w600)),
            AppSpacing.gapXs,
            Text(theme.name,
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _SliderRow({
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
          width: 72,
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

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: textTheme.bodyMedium),
          Text(value,
              style: textTheme.bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
