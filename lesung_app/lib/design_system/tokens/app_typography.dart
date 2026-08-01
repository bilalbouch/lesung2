import 'package:flutter/material.dart';

/// Tokens typographiques — Lesung.
///
/// Deux familles : Lora (serif — titres, contenu livre, identité) et
/// Inter (sans — interface, métadonnées, actions). Les tailles/poids/
/// hauteurs sont définis ici ; la police effective est injectée par le
/// thème (google_fonts). Aucune taille codée en dur ailleurs.
class AppTypography {
  const AppTypography._();

  // ---------------- Échelle -----------------------------------------
  static const double sizeDisplay = 32;
  static const double sizeHeadline = 26;
  static const double sizeTitle = 20;
  static const double sizeSubtitle = 17;
  static const double sizeBody = 15;
  static const double sizeBodySmall = 13;
  static const double sizeCaption = 11;

  // ---------------- Hauteurs de ligne -------------------------------
  static const double heightTight = 1.2;
  static const double heightNormal = 1.4;
  static const double heightReading = 1.6;

  // ---------------- Styles abstraits (couleur appliquée par le thème)
  static const TextStyle display = TextStyle(
    fontSize: sizeDisplay,
    fontWeight: FontWeight.w600,
    height: heightTight,
    letterSpacing: -0.5,
  );

  static const TextStyle headline = TextStyle(
    fontSize: sizeHeadline,
    fontWeight: FontWeight.w600,
    height: heightTight,
    letterSpacing: -0.3,
  );

  static const TextStyle title = TextStyle(
    fontSize: sizeTitle,
    fontWeight: FontWeight.w600,
    height: heightTight,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: sizeSubtitle,
    fontWeight: FontWeight.w500,
    height: heightNormal,
  );

  static const TextStyle body = TextStyle(
    fontSize: sizeBody,
    fontWeight: FontWeight.w400,
    height: heightNormal,
  );

  static const TextStyle bodyEmphasis = TextStyle(
    fontSize: sizeBody,
    fontWeight: FontWeight.w600,
    height: heightNormal,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: sizeBodySmall,
    fontWeight: FontWeight.w400,
    height: heightNormal,
  );

  static const TextStyle caption = TextStyle(
    fontSize: sizeCaption,
    fontWeight: FontWeight.w500,
    height: heightNormal,
    letterSpacing: 0.2,
  );

  static const TextStyle captionUppercase = TextStyle(
    fontSize: sizeCaption,
    fontWeight: FontWeight.w600,
    height: heightNormal,
    letterSpacing: 1.1,
  );
}
