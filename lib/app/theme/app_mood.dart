import 'package:flutter/material.dart';

import 'app_colors.dart';

@immutable
class AppMood extends ThemeExtension<AppMood> {
  const AppMood({
    required this.heroBackground,
    required this.heroForeground,
    required this.heroMutedForeground,
    required this.frameTopColor,
    required this.highlightSurface,
    required this.utilitySurface,
    required this.positiveAccent,
    required this.warningAccent,
    required this.lockedAccent,
  });

  final Color heroBackground;
  final Color heroForeground;
  final Color heroMutedForeground;

  /// 앱 프레임 그라데이션 최상단 색. 헤더 축소 시 배경 오버레이에 사용.
  /// app_frame.dart의 그라데이션 첫 번째 색과 동기화할 것.
  final Color frameTopColor;

  final Color highlightSurface;
  final Color utilitySurface;
  final Color positiveAccent;
  final Color warningAccent;
  final Color lockedAccent;

  factory AppMood.light() {
    return const AppMood(
      heroBackground: Color(0x00000000),
      heroForeground: Color(0xFF120D05),
      heroMutedForeground: Color(0xFF3B2B17),
      frameTopColor: Color(0xFFF9F3E8), // app_frame.dart 라이트 그라데이션[0]
      highlightSurface: Color(0x99FFFFFF),
      utilitySurface: Color(0x8CFFFFFF),
      positiveAccent: AppColors.income,
      warningAccent: AppColors.warning,
      lockedAccent: Color(0xFF836447),
    );
  }

  factory AppMood.dark() {
    return const AppMood(
      heroBackground: Color(0x00000000),
      heroForeground: Color(0xFFF3FBFF),
      heroMutedForeground: Color(0xDDE8F5FF),
      frameTopColor: Color(0xFF0C1220), // app_frame.dart 다크 그라데이션[0]
      highlightSurface: Color(0x24FFFFFF),
      utilitySurface: Color(0x16FFFFFF),
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
    Color? frameTopColor,
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
      frameTopColor: frameTopColor ?? this.frameTopColor,
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
      frameTopColor: Color.lerp(frameTopColor, other.frameTopColor, t) ?? frameTopColor,
      highlightSurface:
          Color.lerp(highlightSurface, other.highlightSurface, t) ?? highlightSurface,
      utilitySurface: Color.lerp(utilitySurface, other.utilitySurface, t) ?? utilitySurface,
      positiveAccent: Color.lerp(positiveAccent, other.positiveAccent, t) ?? positiveAccent,
      warningAccent: Color.lerp(warningAccent, other.warningAccent, t) ?? warningAccent,
      lockedAccent: Color.lerp(lockedAccent, other.lockedAccent, t) ?? lockedAccent,
    );
  }
}
