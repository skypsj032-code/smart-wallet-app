import 'package:flutter/material.dart';

abstract final class AppColors {
  static const primary = Color(0xFFD1A65A);
  static const primaryDark = Color(0xFFB68B42);
  static const primaryLight = Color(0xFFF2D6A2);

  static const income = Color(0xFF3FA37C);
  static const expense = Color(0xFFD86C59);
  static const warning = Color(0xFFE0A63C);
  static const info = Color(0xFF6E8AC7);

  static const backgroundLight = Color(0xFFF7F3EC);
  static const backgroundDark = Color(0xFF111111);
  static const cardLight = Color(0xFFFFFCF8);
  static const cardDark = Color(0xFF181716);

  static const ink = Color(0xFF1E1B18);
  static const mutedInk = Color(0xFF746B61);
  static const softHighlight = Color(0xFFF2E7D4);

  static const borderLight = Color(0xFFE7DDD2);
  static const borderDark = Color(0xFF2A2724);

  static const primaryGradient = LinearGradient(
    colors: [Color(0xFFD6B171), Color(0xFFB88948)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const heroGradient = LinearGradient(
    colors: [Color(0xFF1D1A17), Color(0xFF2A241E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const surfaceGlow = LinearGradient(
    colors: [Color(0x14F4E3C5), Color(0x00FFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
