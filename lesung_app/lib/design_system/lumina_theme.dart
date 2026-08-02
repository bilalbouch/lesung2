import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'tokens/lumina_colors.dart';
import 'tokens/lumina_typography.dart';
import 'tokens/lumina_radius.dart';

/// Thème Lumina — Clair & Sombre
class LuminaTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: LuminaColors.primary,
        onPrimary: LuminaColors.textInverse,
        primaryContainer: LuminaColors.primarySubtle,
        onPrimaryContainer: LuminaColors.primary,
        secondary: LuminaColors.secondary,
        onSecondary: LuminaColors.textInverse,
        secondaryContainer: LuminaColors.secondarySubtle,
        onSecondaryContainer: LuminaColors.secondary,
        surface: LuminaColors.surface,
        onSurface: LuminaColors.textPrimary,
        surfaceContainerHighest: LuminaColors.surfaceSubtle,
        onSurfaceVariant: LuminaColors.textSecondary,
        outline: LuminaColors.border,
        outlineVariant: LuminaColors.divider,
        error: LuminaColors.error,
        onError: LuminaColors.textInverse,
        errorContainer: LuminaColors.accentSubtle,
        onErrorContainer: LuminaColors.accent,
        shadow: Colors.black,
        scrim: Colors.black54,
      ),
      scaffoldBackgroundColor: LuminaColors.background,
      textTheme: LuminaTypography.textTheme,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 68,
        backgroundColor: LuminaColors.background.withValues(alpha: 0.94),
        foregroundColor: LuminaColors.textPrimary,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: LuminaTypography.textTheme.displaySmall,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        backgroundColor: LuminaColors.surface.withValues(alpha: 0.96),
        indicatorColor: LuminaColors.primarySubtle,
        indicatorShape: const StadiumBorder(),
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
              size: 24,
              color: states.contains(WidgetState.selected)
                  ? LuminaColors.primary
                  : LuminaColors.textTertiary,
            )),
        labelTextStyle: WidgetStateProperty.resolveWith((states) =>
            LuminaTypography.textTheme.labelSmall?.copyWith(
              color: states.contains(WidgetState.selected)
                  ? LuminaColors.primary
                  : LuminaColors.textTertiary,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w700
                  : FontWeight.w500,
            )),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: LuminaColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LuminaRadius.l),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: LuminaColors.primary,
          foregroundColor: LuminaColors.textInverse,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(LuminaRadius.s),
          ),
          textStyle: LuminaTypography.textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: LuminaColors.textPrimary,
          side: const BorderSide(color: LuminaColors.border, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(LuminaRadius.s),
          ),
          textStyle: LuminaTypography.textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: LuminaColors.primary,
          textStyle: LuminaTypography.textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: LuminaColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(LuminaRadius.s),
          borderSide: const BorderSide(color: LuminaColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(LuminaRadius.s),
          borderSide: const BorderSide(color: LuminaColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(LuminaRadius.s),
          borderSide: const BorderSide(color: LuminaColors.primary, width: 1.5),
        ),
        hintStyle: LuminaTypography.textTheme.bodyLarge?.copyWith(
          color: LuminaColors.textTertiary,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: LuminaColors.surface,
        selectedItemColor: LuminaColors.primary,
        unselectedItemColor: LuminaColors.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 2,
      ),
      dividerTheme: const DividerThemeData(
        color: LuminaColors.divider,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: LuminaColors.textPrimary,
        contentTextStyle: LuminaTypography.textTheme.bodyMedium?.copyWith(
          color: LuminaColors.textInverse,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LuminaRadius.s),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: LuminaColorsDark.primary,
        onPrimary: LuminaColorsDark.textInverse,
        primaryContainer: LuminaColorsDark.primarySubtle,
        onPrimaryContainer: LuminaColorsDark.primary,
        secondary: LuminaColorsDark.secondary,
        onSecondary: LuminaColorsDark.textInverse,
        secondaryContainer: LuminaColorsDark.secondarySubtle,
        onSecondaryContainer: LuminaColorsDark.secondary,
        surface: LuminaColorsDark.surface,
        onSurface: LuminaColorsDark.textPrimary,
        surfaceContainerHighest: LuminaColorsDark.surfaceSubtle,
        onSurfaceVariant: LuminaColorsDark.textSecondary,
        outline: LuminaColorsDark.border,
        outlineVariant: LuminaColorsDark.divider,
        error: LuminaColorsDark.error,
        onError: LuminaColorsDark.textInverse,
        errorContainer: LuminaColorsDark.accentSubtle,
        onErrorContainer: LuminaColorsDark.accent,
        shadow: Colors.black,
        scrim: Colors.black87,
      ),
      scaffoldBackgroundColor: LuminaColorsDark.background,
      textTheme: LuminaTypography.darkTextTheme,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 68,
        backgroundColor: LuminaColorsDark.background.withValues(alpha: 0.94),
        foregroundColor: LuminaColorsDark.textPrimary,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: LuminaTypography.darkTextTheme.displaySmall,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        backgroundColor: LuminaColorsDark.surface.withValues(alpha: 0.96),
        indicatorColor: LuminaColorsDark.primarySubtle,
        indicatorShape: const StadiumBorder(),
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
              size: 24,
              color: states.contains(WidgetState.selected)
                  ? LuminaColorsDark.primary
                  : LuminaColorsDark.textTertiary,
            )),
        labelTextStyle: WidgetStateProperty.resolveWith((states) =>
            LuminaTypography.darkTextTheme.labelSmall?.copyWith(
              color: states.contains(WidgetState.selected)
                  ? LuminaColorsDark.primary
                  : LuminaColorsDark.textTertiary,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w700
                  : FontWeight.w500,
            )),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: LuminaColorsDark.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LuminaRadius.l),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: LuminaColorsDark.primary,
          foregroundColor: LuminaColorsDark.textInverse,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(LuminaRadius.s),
          ),
          textStyle: LuminaTypography.darkTextTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: LuminaColorsDark.textPrimary,
          side: const BorderSide(color: LuminaColorsDark.border, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(LuminaRadius.s),
          ),
          textStyle: LuminaTypography.darkTextTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: LuminaColorsDark.primary,
          textStyle: LuminaTypography.darkTextTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: LuminaColorsDark.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(LuminaRadius.s),
          borderSide: const BorderSide(color: LuminaColorsDark.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(LuminaRadius.s),
          borderSide: const BorderSide(color: LuminaColorsDark.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(LuminaRadius.s),
          borderSide: const BorderSide(color: LuminaColorsDark.primary, width: 1.5),
        ),
        hintStyle: LuminaTypography.darkTextTheme.bodyLarge?.copyWith(
          color: LuminaColorsDark.textTertiary,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: LuminaColorsDark.surface,
        selectedItemColor: LuminaColorsDark.primary,
        unselectedItemColor: LuminaColorsDark.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 2,
      ),
      dividerTheme: const DividerThemeData(
        color: LuminaColorsDark.divider,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: LuminaColorsDark.surfaceElevated,
        contentTextStyle: LuminaTypography.darkTextTheme.bodyMedium?.copyWith(
          color: LuminaColorsDark.textPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LuminaRadius.s),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
