import 'package:flutter/widgets.dart';

/// Tokens de mise en page adaptative — téléphone et tablette.
class AppBreakpoints {
  const AppBreakpoints._();

  /// À partir de 600 dp de large : layout tablette (rail + marges
  /// élargies, grilles plus denses).
  static const double tablet = 600;

  /// Largeur de contenu maximale centrée sur très grands écrans.
  static const double contentMaxWidth = 960;

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tablet;

  /// Nombre de colonnes d'une grille de couvertures selon la largeur.
  static int gridColumns(double width) {
    if (width >= 1200) return 6;
    if (width >= 900) return 5;
    if (width >= tablet) return 4;
    if (width >= 420) return 3;
    return 2;
  }

  /// Marge latérale selon la largeur (plus généreuse sur tablette).
  static double horizontalMargin(double width) =>
      width >= tablet ? 32 : 16;
}
