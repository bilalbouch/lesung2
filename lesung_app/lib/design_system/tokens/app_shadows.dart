import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Tokens d'ombre — élévation très douce, presque imperceptible.
/// Le minimalisme allemand préfère les séparateurs fins aux ombres ;
/// elles ne servent qu'à détacher couvertures, cartes flottantes et
/// surfaces superposées.
class AppShadows {
  const AppShadows._();

  static List<BoxShadow> cover(AppColorScheme colors) => [
        BoxShadow(
          color: colors.shadow,
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> raised(AppColorScheme colors) => [
        BoxShadow(
          color: colors.shadow,
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> overlay(AppColorScheme colors) => [
        BoxShadow(
          color: colors.shadow,
          blurRadius: 32,
          offset: const Offset(0, 12),
        ),
      ];
}
