import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tokens/app_colors.dart';
import 'tokens/app_motion.dart';
import 'tokens/app_radius.dart';
import 'tokens/app_typography.dart';

/// Construction des thèmes clair et sombre à partir des tokens.
/// Seul endroit où les tokens sont « matérialisés » en ThemeData.
class AppTheme {
  const AppTheme._();

  static ThemeData light() => _build(AppColors.light, Brightness.light);

  static ThemeData dark() => _build(AppColors.dark, Brightness.dark);

  static ThemeData _build(AppColorScheme colors, Brightness brightness) {
    final serif = GoogleFonts.lora();
    final sans = GoogleFonts.inter();

    TextStyle apply(TextStyle style, {bool serifFont = false, Color? color}) =>
        (serifFont ? serif : sans)
            .merge(style)
            .copyWith(color: color ?? colors.ink);

    final textTheme = TextTheme(
      displayLarge: apply(AppTypography.display, serifFont: true),
      headlineLarge: apply(AppTypography.headline, serifFont: true),
      titleLarge: apply(AppTypography.title, serifFont: true),
      titleMedium: apply(AppTypography.subtitle, serifFont: true),
      bodyLarge: apply(AppTypography.body),
      bodyMedium: apply(AppTypography.bodySmall),
      bodySmall: apply(AppTypography.caption, color: colors.inkSecondary),
      labelLarge: apply(AppTypography.bodyEmphasis),
      labelSmall: apply(AppTypography.captionUppercase,
          color: colors.inkSecondary),
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: colors.background,
      splashFactory: InkRipple.splashFactory,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: colors.accent,
        onPrimary: colors.onAccent,
        secondary: colors.inkSecondary,
        onSecondary: colors.ink,
        error: colors.error,
        onError: colors.onAccent,
        surface: colors.surface,
        onSurface: colors.ink,
        surfaceContainerHighest: colors.surfaceAlt,
        outline: colors.divider,
      ),
      textTheme: textTheme,
      dividerColor: colors.divider,
      dividerTheme: DividerThemeData(
        color: colors.divider,
        thickness: 1,
        space: 1,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        // Transition sobre et rapide, identique sur toutes plateformes.
        TargetPlatform.android: _LesungPageTransitionsBuilder(),
        TargetPlatform.iOS: _LesungPageTransitionsBuilder(),
        TargetPlatform.linux: _LesungPageTransitionsBuilder(),
      }),
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        foregroundColor: colors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: apply(AppTypography.title, serifFont: true),
      ),
      cardTheme: CardTheme(
        color: colors.surface,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.card),
        margin: EdgeInsets.zero,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.ink,
        contentTextStyle:
            apply(AppTypography.bodySmall, color: colors.background),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.cardSmall),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: colors.surface,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.card),
        titleTextStyle: apply(AppTypography.title, serifFont: true),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surface,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheet),
        showDragHandle: true,
        dragHandleColor: colors.inkTertiary,
      ),
      progressIndicatorTheme:
          ProgressIndicatorThemeData(color: colors.accent),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.background,
        indicatorColor: colors.accentSubtle,
        labelTextStyle: WidgetStateProperty.all(
            apply(AppTypography.caption, color: colors.inkSecondary)),
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? colors.accent
                : colors.inkSecondary)),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colors.background,
        indicatorColor: colors.accentSubtle,
        selectedIconTheme: IconThemeData(color: colors.accent),
        unselectedIconTheme: IconThemeData(color: colors.inkSecondary),
        labelType: NavigationRailLabelType.all,
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: colors.surfaceAlt,
        selectedColor: colors.accentSubtle,
        labelStyle: apply(AppTypography.bodySmall),
        side: BorderSide.none,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.chip),
      ),
    );
  }
}

/// Transition de page Lesung : fondu + glissement vertical de 8 px,
/// 200 ms maximum. Aucun effet décoratif.
class _LesungPageTransitionsBuilder extends PageTransitionsBuilder {
  const _LesungPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: AppMotion.enter,
      reverseCurve: AppMotion.exit,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.02),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
