import 'package:flutter/material.dart';

abstract final class AppColors {
  // ── Brand primary ─────────────────────────────────────
  /// 하늘색 — 브랜드 메인 컬러
  static const primary = Color(0xFF4C89C1);
  static const primaryDark = Color(0xFF23629D);
  static const primaryLight = Color(0xFFABD8F7);

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
  /// 라이트 모드 배경 — 하늘빛
  static const backgroundLight = Color(0xFFEAF5FC);

  /// 다크 모드 배경 — 깊은 남색
  static const backgroundDark = Color(0xFF13253D);

  /// 라이트 모드 카드
  static const cardLight = Color(0xFFF1F8FD);

  /// 다크 모드 카드
  static const cardDark = Color(0xFF203451);

  // ── Text ──────────────────────────────────────────────
  /// 기본 텍스트 — 짙은 남색
  static const ink = Color(0xFF142F49);

  /// 보조 텍스트 — 차분한 파랑
  static const mutedInk = Color(0xFF385A74);

  /// 소프트 하이라이트
  static const softHighlight = Color(0xFFD7EBF8);

  // ── Borders ───────────────────────────────────────────
  static const borderLight = Color(0xFFAFCDE1);
  static const borderDark = Color(0xFF425975);

  // ── Gradients ─────────────────────────────────────────
  static const primaryGradient = LinearGradient(
    colors: [Color(0xFF87C7EF), Color(0xFF4785BF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const heroGradient = LinearGradient(
    colors: [Color(0xFF1C466F), Color(0xFF285A83)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const surfaceGlow = LinearGradient(
    colors: [Color(0x14D6EFFD), Color(0x00FFFFFF)],
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
