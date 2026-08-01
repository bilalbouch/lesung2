import 'package:flutter/animation.dart';

/// Tokens de mouvement.
///
/// Discrétion absolue : transitions fonctionnelles uniquement,
/// JAMAIS décoratives. Durée maximale 200 ms, courbes douces.
class AppMotion {
  const AppMotion._();

  /// Courbe standard de l'app : sortie douce, sans rebond.
  static const Curve standard = Curves.easeOutCubic;

  /// Courbe d'entrée de surface (bottom sheets, dialogues).
  static const Curve enter = Curves.easeOutQuart;

  /// Courbe de sortie (fermeture, disparition).
  static const Curve exit = Curves.easeInCubic;
}

/// Tokens de durée — aucune animation ne dépasse 200 ms.
class AppDurations {
  const AppDurations._();

  /// Micro-interactions (appui, ripple visuel, bascule favori).
  static const Duration instant = Duration(milliseconds: 100);

  /// Transitions de contenu (fade, changement d'état).
  static const Duration fast = Duration(milliseconds: 140);

  /// Transitions de surface (bottom sheet, page, scale léger).
  static const Duration normal = Duration(milliseconds: 200);

  /// Ripple Material : laissé au SDK, pas de durée custom au-delà.
}
