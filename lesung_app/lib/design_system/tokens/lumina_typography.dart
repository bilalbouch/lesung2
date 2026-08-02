import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typographie Lumina — Source Serif 4 + Inter
class LuminaTypography {
  static TextTheme get textTheme => TextTheme(
        displayLarge: GoogleFonts.inter(
          fontSize: 42,
          height: 1.08,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.4,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 34,
          height: 1.1,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.0,
        ),
        displaySmall: GoogleFonts.inter(

          fontSize: 28,
          height: 1.15,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.6,
        ),
        headlineLarge: GoogleFonts.inter(
          fontSize: 24,
          height: 1.25,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 20,
          height: 1.3,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.25,
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
