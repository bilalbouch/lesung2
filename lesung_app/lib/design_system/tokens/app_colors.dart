import 'package:flutter/material.dart';

/// Tokens couleur — Lesung.
///
/// Minimalisme allemand : neutres calmes, contraste élevé, un seul
/// accent (sauge). AUCUNE couleur ne doit être codée en dur ailleurs
/// dans l'application : tout passe par [AppColors].
class AppColors {
  const AppColors._();

  // ---------------- Accent lecture (orange chaleureux) --------------
  static const Color accentLight = Color(0xFFFF8A00);
  static const Color accentDark = Color(0xFFFF9F0A);

  // ---------------- Mode clair --------------------------------------
  static const _light = AppColorScheme(
    background: Color(0xFFF7F7FA),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFEFEFF4),
    ink: Color(0xFF17171A),
    inkSecondary: Color(0xFF636366),
    inkTertiary: Color(0xFF9A9AA1),
    accent: accentLight,
    onAccent: Color(0xFFFFFFFF),
    accentSubtle: Color(0xFFFFEBD2),
    divider: Color(0xFFE3E3E8),
    error: Color(0xFFFF3B30),
    success: Color(0xFF34C759),
    scrim: Color(0x66000000),
    shadow: Color(0x1F1C1C1E),
  );

  // ---------------- Mode sombre -------------------------------------
  static const _dark = AppColorScheme(
    background: Color(0xFF000000),
    surface: Color(0xFF1C1C1E),
    surfaceAlt: Color(0xFF2C2C2E),
    ink: Color(0xFFF5F5F7),
    inkSecondary: Color(0xFFAEAEB2),
    inkTertiary: Color(0xFF6C6C70),
    accent: accentDark,
    onAccent: Color(0xFFFFFFFF),
    accentSubtle: Color(0xFF3A2B18),
    divider: Color(0xFF38383A),
    error: Color(0xFFFF453A),
    success: Color(0xFF30D158),
    scrim: Color(0x99000000),
    shadow: Color(0x99000000),
  );

  static AppColorScheme of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _dark : _light;

  static AppColorScheme get light => _light;
  static AppColorScheme get dark => _dark;
}

/// Palette sémantique : les noms décrivent le RÔLE, jamais la teinte.
class AppColorScheme {
  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color ink;
  final Color inkSecondary;
  final Color inkTertiary;
  final Color accent;
  final Color onAccent;
  final Color accentSubtle;
  final Color divider;
  final Color error;
  final Color success;
  final Color scrim;
  final Color shadow;

  const AppColorScheme({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.ink,
    required this.inkSecondary,
    required this.inkTertiary,
    required this.accent,
    required this.onAccent,
    required this.accentSubtle,
    required this.divider,
    required this.error,
    required this.success,
    required this.scrim,
    required this.shadow,
  });
}
