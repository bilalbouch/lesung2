import 'package:flutter/material.dart';

/// Tokens couleur — Lesung.
///
/// Minimalisme allemand : neutres calmes, contraste élevé, un seul
/// accent (sauge). AUCUNE couleur ne doit être codée en dur ailleurs
/// dans l'application : tout passe par [AppColors].
class AppColors {
  const AppColors._();

  // ---------------- Accent (identique clair/sombre, décliné) --------
  static const Color accentLight = Color(0xFF4A6B57);
  static const Color accentDark = Color(0xFF9BC2A9);

  // ---------------- Mode clair --------------------------------------
  static const _light = AppColorScheme(
    background: Color(0xFFFAF9F6),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF1EFE9),
    ink: Color(0xFF1B1B1F),
    inkSecondary: Color(0xFF62636B),
    inkTertiary: Color(0xFF9B9CA3),
    accent: accentLight,
    onAccent: Color(0xFFFFFFFF),
    accentSubtle: Color(0xFFE7EEE9),
    divider: Color(0xFFE6E4DD),
    error: Color(0xFFB0443C),
    success: Color(0xFF3E7A55),
    scrim: Color(0x73000000),
    shadow: Color(0x14000000),
  );

  // ---------------- Mode sombre -------------------------------------
  static const _dark = AppColorScheme(
    background: Color(0xFF121214),
    surface: Color(0xFF1B1B1F),
    surfaceAlt: Color(0xFF232329),
    ink: Color(0xFFEAE8E3),
    inkSecondary: Color(0xFFA9A7A2),
    inkTertiary: Color(0xFF6E6D69),
    accent: accentDark,
    onAccent: Color(0xFF0F1512),
    accentSubtle: Color(0xFF26332C),
    divider: Color(0xFF2B2B31),
    error: Color(0xFFE08A84),
    success: Color(0xFF8FC7A5),
    scrim: Color(0x8C000000),
    shadow: Color(0x4D000000),
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
