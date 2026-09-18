import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tipografia unificada do Design System Glassmorphism (Padrão Apple HIG)
/// Uma única família (Inter), com hierarquia construída exclusivamente pelo peso.
class AppTypography {
  static TextTheme textTheme(Color base) => TextTheme(
        displayLarge: GoogleFonts.inter(
          fontSize: 38,
          fontWeight: FontWeight.w700,
          height: 1.15,
          letterSpacing: -0.4,
          color: base,
        ),
        headlineLarge: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          height: 1.2,
          letterSpacing: -0.3,
          color: base,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          height: 1.25,
          letterSpacing: -0.2,
          color: base,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          height: 1.25,
          letterSpacing: -0.2,
          color: base,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          height: 1.3,
          color: base,
        ),
        titleSmall: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 1.3,
          color: base,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          height: 1.4,
          color: base,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.5,
          color: base.withValues(alpha: 0.72),
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          height: 1.4,
          color: base.withValues(alpha: 0.60),
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 1.3,
          color: base,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          height: 1.3,
          color: base.withValues(alpha: 0.75),
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          height: 1.35,
          color: base.withValues(alpha: 0.55),
        ),
      );
}
