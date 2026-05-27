import 'package:flutter/painting.dart';

/// 그림자 스케일.
/// 라이트/다크 모드를 별도로 제공한다.
abstract final class AppShadows {
  // ── Light mode ─────────────────────────────────────────

  static const List<BoxShadow> noneLight = [];

  static const List<BoxShadow> smLight = [
    BoxShadow(
      color: Color(0x0D000000),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> mdLight = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
    BoxShadow(
      color: Color(0x08000000),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> lgLight = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x0D000000),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> xlLight = [
    BoxShadow(
      color: Color(0x20000000),
      blurRadius: 32,
      offset: Offset(0, 8),
    ),
    BoxShadow(
      color: Color(0x10000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  // ── Dark mode ──────────────────────────────────────────

  static const List<BoxShadow> noneDark = [];

  static const List<BoxShadow> smDark = [
    BoxShadow(
      color: Color(0x26000000),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> mdDark = [
    BoxShadow(
      color: Color(0x33000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> lgDark = [
    BoxShadow(
      color: Color(0x40000000),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x26000000),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> xlDark = [
    BoxShadow(
      color: Color(0x4D000000),
      blurRadius: 32,
      offset: Offset(0, 8),
    ),
    BoxShadow(
      color: Color(0x33000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  // ── Semantic ───────────────────────────────────────────

  /// Primary 골드 컬러 글로우 — 주요 액션 버튼, 강조 카드
  static const List<BoxShadow> primaryGlow = [
    BoxShadow(
      color: Color(0x40D1A65A), // AppColors.primary @ 25%
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  /// 수입 초록 글로우
  static const List<BoxShadow> incomeGlow = [
    BoxShadow(
      color: Color(0x333FA37C), // AppColors.income @ 20%
      blurRadius: 10,
      offset: Offset(0, 3),
    ),
  ];

  /// 지출 빨간 글로우
  static const List<BoxShadow> expenseGlow = [
    BoxShadow(
      color: Color(0x33D86C59), // AppColors.expense @ 20%
      blurRadius: 10,
      offset: Offset(0, 3),
    ),
  ];

  // ── Helpers ────────────────────────────────────────────

  static List<BoxShadow> sm({required bool isDark}) =>
      isDark ? smDark : smLight;

  /// brightness에 따라 적절한 md 그림자를 반환한다.
  static List<BoxShadow> md({required bool isDark}) =>
      isDark ? mdDark : mdLight;

  static List<BoxShadow> lg({required bool isDark}) =>
      isDark ? lgDark : lgLight;
}
