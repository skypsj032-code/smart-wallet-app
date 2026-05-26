import 'package:flutter/material.dart';

abstract final class AppColors {
  // ── Brand primary ─────────────────────────────────────
  /// 웜 골드 — 브랜드 메인 컬러
  static const primary = Color(0xFFD1A65A);
  static const primaryDark = Color(0xFFB68B42);
  static const primaryLight = Color(0xFFF2D6A2);

  // ── Semantic (기능 컬러) ──────────────────────────────
  /// 수입 — 에메랄드 그린
  static const income = Color(0xFF3FA37C);
  static const incomeLight = Color(0xFFE6F5EF); // 수입 틴트 배경 (라이트)
  static const incomeDark = Color(0xFF1A3D30); // 수입 틴트 배경 (다크)

  /// 지출 — 산호 레드
  static const expense = Color(0xFFD86C59);
  static const expenseLight = Color(0xFFF7EAE8); // 지출 틴트 배경 (라이트)
  static const expenseDark = Color(0xFF3D1F1A); // 지출 틴트 배경 (다크)

  /// 경고 — 앰버
  static const warning = Color(0xFFE0A63C);
  static const warningLight = Color(0xFFF9F0DC);
  static const warningDark = Color(0xFF3D2D0F);

  /// 정보 — 소프트 블루
  static const info = Color(0xFF6E8AC7);
  static const infoLight = Color(0xFFE8EDF7);
  static const infoDark = Color(0xFF1E2840);

  // ── Neutrals ──────────────────────────────────────────
  /// 라이트 모드 배경 — 웜 아이보리
  static const backgroundLight = Color(0xFFF7F3EC);

  /// 다크 모드 배경 — 딥 블랙
  static const backgroundDark = Color(0xFF111111);

  /// 라이트 모드 카드
  static const cardLight = Color(0xFFFFFCF8);

  /// 다크 모드 카드
  static const cardDark = Color(0xFF181716);

  // ── Text ──────────────────────────────────────────────
  /// 기본 텍스트 — 딥 브라운
  static const ink = Color(0xFF14100B);

  /// 보조 텍스트 — 뮤트 브라운
  static const mutedInk = Color(0xFF4F4030);

  /// 소프트 하이라이트 — 크림
  static const softHighlight = Color(0xFFF2E7D4);

  // ── Borders ───────────────────────────────────────────
  static const borderLight = Color(0xFFE7DDD2);
  static const borderDark = Color(0xFF2A2724);

  // ── Gradients ─────────────────────────────────────────
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

  /// 수입 그라데이션 — 긍정적 요약 카드 등에 사용
  static const incomeGradient = LinearGradient(
    colors: [Color(0xFF3FA37C), Color(0xFF2D8061)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// 지출 그라데이션
  static const expenseGradient = LinearGradient(
    colors: [Color(0xFFD86C59), Color(0xFFBF5240)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Helpers ───────────────────────────────────────────

  /// [isIncome]에 따라 수입/지출 컬러를 반환한다.
  static Color transactionColor(bool isIncome) =>
      isIncome ? income : expense;

  /// [isIncome]에 따라 틴트 배경 컬러를 반환한다.
  static Color transactionTint({required bool isIncome, required bool isDark}) {
    if (isIncome) return isDark ? incomeDark : incomeLight;
    return isDark ? expenseDark : expenseLight;
  }
}
