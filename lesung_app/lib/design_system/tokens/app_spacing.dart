import 'package:flutter/material.dart';

/// Tokens d'espacement — échelle de 4 pt. Aucun padding/margin codé
/// en dur ailleurs : tout passe par [AppSpacing].
class AppSpacing {
  const AppSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// Marges de l'écran (téléphone). La tablette passe par
  /// [AppBreakpoints] qui augmente les marges.
  static const double screenEdge = l;

  static const EdgeInsets screen = EdgeInsets.symmetric(horizontal: l);
  static const EdgeInsets card = EdgeInsets.all(l);
  static const EdgeInsets cardCompact = EdgeInsets.all(m);
  static const EdgeInsets listItem =
      EdgeInsets.symmetric(horizontal: l, vertical: m);
  static const EdgeInsets section = EdgeInsets.only(top: xl, bottom: m);

  /// Espacements verticaux prêts à l'emploi.
  static const Widget gapXs = SizedBox(height: xs);
  static const Widget gapS = SizedBox(height: s);
  static const Widget gapM = SizedBox(height: m);
  static const Widget gapL = SizedBox(height: l);
  static const Widget gapXl = SizedBox(height: xl);
  static const Widget gapXxl = SizedBox(height: xxl);

  /// Espacements horizontaux prêts à l'emploi.
  static const Widget hGapXs = SizedBox(width: xs);
  static const Widget hGapS = SizedBox(width: s);
  static const Widget hGapM = SizedBox(width: m);
  static const Widget hGapL = SizedBox(width: l);
}
