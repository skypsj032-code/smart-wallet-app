import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppTypography {
  static TextTheme textTheme(Brightness brightness) {
    final bodyColor =
        brightness == Brightness.dark ? const Color(0xFFFFFBF6) : const Color(0xFF1E1B18);
    final mutedColor =
        brightness == Brightness.dark ? const Color(0xFFB1A699) : const Color(0xFF746B61);

    final base = GoogleFonts.notoSansKrTextTheme().apply(
      bodyColor: bodyColor,
      displayColor: bodyColor,
    );

    return base.copyWith(
      displayLarge: GoogleFonts.notoSansKr(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        height: 1.12,
        letterSpacing: -1.2,
        color: bodyColor,
      ),
      displayMedium: GoogleFonts.notoSansKr(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.14,
        letterSpacing: -0.9,
        color: bodyColor,
      ),
      headlineLarge: GoogleFonts.notoSansKr(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.18,
        letterSpacing: -0.7,
        color: bodyColor,
      ),
      headlineMedium: GoogleFonts.notoSansKr(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.5,
        color: bodyColor,
      ),
      headlineSmall: GoogleFonts.notoSansKr(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1.22,
        letterSpacing: -0.35,
        color: bodyColor,
      ),
      titleLarge: GoogleFonts.notoSansKr(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 1.32,
        letterSpacing: -0.25,
        color: bodyColor,
      ),
      titleMedium: GoogleFonts.notoSansKr(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.34,
        color: bodyColor,
      ),
      titleSmall: GoogleFonts.notoSansKr(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.34,
        color: bodyColor,
      ),
      bodyLarge: GoogleFonts.notoSansKr(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.56,
        color: bodyColor,
      ),
      bodyMedium: GoogleFonts.notoSansKr(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.56,
        color: bodyColor,
      ),
      bodySmall: GoogleFonts.notoSansKr(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: mutedColor,
      ),
      labelLarge: GoogleFonts.jetBrainsMono(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.3,
        letterSpacing: 0.4,
        color: mutedColor,
      ),
      labelMedium: GoogleFonts.jetBrainsMono(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 1.3,
        letterSpacing: 0.5,
        color: mutedColor,
      ),
      labelSmall: GoogleFonts.jetBrainsMono(
        fontSize: 10.5,
        fontWeight: FontWeight.w500,
        height: 1.3,
        letterSpacing: 0.55,
        color: mutedColor,
      ),
    );
  }

  static TextStyle mono({
    required Brightness brightness,
    double fontSize = 12,
    FontWeight fontWeight = FontWeight.w500,
    Color? color,
    double letterSpacing = 0.4,
  }) {
    final resolvedColor =
        color ??
        (brightness == Brightness.dark ? const Color(0xFFB1A699) : const Color(0xFF746B61));

    return GoogleFonts.jetBrainsMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: 1.28,
      letterSpacing: letterSpacing,
      color: resolvedColor,
    );
  }
}
