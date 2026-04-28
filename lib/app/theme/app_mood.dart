import 'package:flutter/material.dart';

import 'app_colors.dart';

@immutable
class AppMood extends ThemeExtension<AppMood> {
  const AppMood({
    required this.heroBackground,
    required this.heroForeground,
    required this.heroMutedForeground,
    required this.highlightSurface,
    required this.utilitySurface,
    required this.positiveAccent,
    required this.warningAccent,
    required this.lockedAccent,
  });

  final Color heroBackground;
  final Color heroForeground;
  final Color heroMutedForeground;
  final Color highlightSurface;
  final Color utilitySurface;
  final Color positiveAccent;
  final Color warningAccent;
  final Color lockedAccent;

  factory AppMood.light() {
    return const AppMood(
      heroBackground: Color(0xFF201C18),
      heroForeground: Color(0xFFFFFBF6),
      heroMutedForeground: Color(0xD9F6EBDD),
      highlightSurface: Color(0xFFF4ECE0),
      utilitySurface: Color(0xFFF9F5EE),
      positiveAccent: AppColors.income,
      warningAccent: AppColors.warning,
      lockedAccent: Color(0xFF836447),
    );
  }

  factory AppMood.dark() {
    return const AppMood(
      heroBackground: Color(0xFF161311),
      heroForeground: Color(0xFFFFFBF6),
      heroMutedForeground: Color(0xCCEFE0CB),
      highlightSurface: Color(0xFF211C18),
      utilitySurface: Color(0xFF1A1715),
      positiveAccent: AppColors.income,
      warningAccent: AppColors.warning,
      lockedAccent: Color(0xFFD1A65A),
    );
  }

  @override
  ThemeExtension<AppMood> copyWith({
    Color? heroBackground,
    Color? heroForeground,
    Color? heroMutedForeground,
    Color? highlightSurface,
    Color? utilitySurface,
    Color? positiveAccent,
    Color? warningAccent,
    Color? lockedAccent,
  }) {
    return AppMood(
      heroBackground: heroBackground ?? this.heroBackground,
      heroForeground: heroForeground ?? this.heroForeground,
      heroMutedForeground: heroMutedForeground ?? this.heroMutedForeground,
      highlightSurface: highlightSurface ?? this.highlightSurface,
      utilitySurface: utilitySurface ?? this.utilitySurface,
      positiveAccent: positiveAccent ?? this.positiveAccent,
      warningAccent: warningAccent ?? this.warningAccent,
      lockedAccent: lockedAccent ?? this.lockedAccent,
    );
  }

  @override
  ThemeExtension<AppMood> lerp(covariant ThemeExtension<AppMood>? other, double t) {
    if (other is! AppMood) {
      return this;
    }

    return AppMood(
      heroBackground: Color.lerp(heroBackground, other.heroBackground, t) ?? heroBackground,
      heroForeground: Color.lerp(heroForeground, other.heroForeground, t) ?? heroForeground,
      heroMutedForeground:
          Color.lerp(heroMutedForeground, other.heroMutedForeground, t) ??
          heroMutedForeground,
      highlightSurface:
          Color.lerp(highlightSurface, other.highlightSurface, t) ?? highlightSurface,
      utilitySurface: Color.lerp(utilitySurface, other.utilitySurface, t) ?? utilitySurface,
      positiveAccent: Color.lerp(positiveAccent, other.positiveAccent, t) ?? positiveAccent,
      warningAccent: Color.lerp(warningAccent, other.warningAccent, t) ?? warningAccent,
      lockedAccent: Color.lerp(lockedAccent, other.lockedAccent, t) ?? lockedAccent,
    );
  }
}
