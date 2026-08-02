import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typographie Lumina — Source Serif 4 + Inter
class LuminaTypography {
  static TextTheme get textTheme => TextTheme(
        displayLarge: GoogleFonts.sourceSerif4(
          fontSize: 48,
          height: 1.1,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.sourceSerif4(
          fontSize: 36,
          height: 1.15,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        displaySmall: GoogleFonts.sourceSerif4(
          fontSize: 28,
          height: 1.2,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        headlineLarge: GoogleFonts.sourceSerif4(
          fontSize: 24,
          height: 1.3,
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: GoogleFonts.sourceSerif4(
          fontSize: 20,
          height: 1.35,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: GoogleFonts.inter(
          fontSize: 18,
          height: 1.4,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 16,
          height: 1.5,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 14,
          height: 1.5,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          height: 1.6,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          height: 1.5,
          fontWeight: FontWeight.w400,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          height: 1.5,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.2,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          height: 1.0,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 12,
          height: 1.0,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11,
          height: 1.4,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.3,
        ),
      );

  static TextTheme get darkTextTheme => textTheme;
}
