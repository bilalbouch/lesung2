import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lesung/features/reader/domain/reader_settings.dart';
import '../../components/app_animations.dart';
import '../../design_system/tokens/app_spacing.dart';

class ReaderPageContent extends StatelessWidget {
  final String text;
  final ReaderSettings settings;
  final ReaderTheme theme;
  final int loadedUnit;

  const ReaderPageContent({
    super.key,
    required this.text,
    required this.settings,
    required this.theme,
    required this.loadedUnit,
  });

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.orientationOf(context) == Orientation.landscape;
    final isTablet = MediaQuery.sizeOf(context).width > 600;
    final useTwoColumns = isLandscape && isTablet && text.length > 200;

    final style = _readingTextStyle(settings, theme);
    final align = _flutterAlign(settings.textAlign);

    if (useTwoColumns) {
      final mid = text.length ~/ 2;
      final splitAt = text.lastIndexOf(' ', mid);
      final part1 = text.substring(0, splitAt > 0 ? splitAt : mid);
      final part2 = text.substring(splitAt > 0 ? splitAt + 1 : mid);

      return SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.l + settings.marginHorizontal,
          vertical: AppSpacing.xl + settings.marginVertical,
        ),
        child: AppAnimations.fadeIn(
          key: ValueKey(loadedUnit),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SelectableText(
                  part1,
                  style: style,
                  textAlign: align,
                ),
              ),
              const SizedBox(width: 32),
              Expanded(
                child: SelectableText(
                  part2,
                  style: style,
                  textAlign: align,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.l + settings.marginHorizontal,
        vertical: AppSpacing.xl + settings.marginVertical,
      ),
      child: AppAnimations.fadeIn(
        key: ValueKey(loadedUnit),
        child: SelectableText(
          text.isEmpty ? '-' : text,
          style: style,
          textAlign: align,
        ),
      ),
    );
  }

  TextStyle _readingTextStyle(ReaderSettings settings, ReaderTheme theme) {
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
      color: Color(theme.textColor),
    );
  }

  TextAlign _flutterAlign(ReaderTextAlign align) => switch (align) {
    ReaderTextAlign.left => TextAlign.left,
    ReaderTextAlign.justify => TextAlign.justify,
    ReaderTextAlign.right => TextAlign.right,
  };
}
