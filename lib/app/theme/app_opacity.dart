/// 불투명도(opacity/alpha) 상수.
/// 코드 곳곳에 하드코딩된 alpha 값 대신 이 상수를 사용한다.
abstract final class AppOpacity {
  // ── Material 3 state layers ────────────────────────────
  static const double hovered = 0.08;
  static const double focused = 0.12;
  static const double pressed = 0.12;
  static const double dragged = 0.16;
  static const double disabled = 0.38;

  // ── Glass card fills ───────────────────────────────────
  /// 라이트 모드 카드 배경 (white @ 78%)
  static const double glassLight = 0.78;

  /// 다크 모드 카드 배경 (white @ 8%)
  static const double glassDark = 0.08;

  // ── Glass overlays ─────────────────────────────────────
  /// 강조 오버레이 (white @ 60%) — highlightSurface light
  static const double overlayHighlightLight = 0.60;

  /// 유틸리티 오버레이 (white @ 55%) — utilitySurface light
  static const double overlayUtilityLight = 0.55;

  /// 강조 오버레이 다크 (white @ 14%)
  static const double overlayHighlightDark = 0.14;

  /// 유틸리티 오버레이 다크 (white @ 9%)
  static const double overlayUtilityDark = 0.09;

  // ── Borders ────────────────────────────────────────────
  /// 유리 카드 테두리 기본
  static const double borderGlass = 0.10;

  /// 유리 카드 테두리 강조 (포커스, 선택)
  static const double borderGlassStrong = 0.34;

  /// 라이트 모드 Primary 테두리
  static const double borderPrimaryLight = 0.46;

  // ── Icon/Text ──────────────────────────────────────────
  /// 비활성 아이콘/텍스트
  static const double iconInactive = 0.72;

  /// 약하게 비활성 (네비게이션 라벨)
  static const double textSoft = 0.76;

  // ── Semantic chip / accent ─────────────────────────────
  /// Chip 선택 배경 (primary @ 14%)
  static const double chipSelected = 0.14;
}
