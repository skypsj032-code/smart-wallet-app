/// 컴포넌트 사이즈 상수.
/// 아이콘, 버튼, 인풋, 아바타 등의 크기를 통일한다.
abstract final class AppSizes {
  // ── Icons ──────────────────────────────────────────────
  static const double iconXS = 14.0; // 인라인 텍스트 아이콘
  static const double iconSM = 18.0; // 소형 버튼, 칩 아이콘
  static const double iconMD = 24.0; // 기본 아이콘 (네비게이션, 리스트)
  static const double iconLG = 32.0; // 카드 헤더 아이콘
  static const double iconXL = 40.0; // 빈 상태(empty state) 일러스트
  static const double iconXXL = 56.0; // 온보딩, 히어로 아이콘

  // ── Buttons ────────────────────────────────────────────
  static const double btnHeightSM = 34.0; // 소형 (퀵 패널 기록 버튼)
  static const double btnHeightMD = 44.0; // 중형 (인라인 액션)
  static const double btnHeightLG = 50.0; // 기본 (화면 하단 CTA)

  static const double btnMinWidthSM = 38.0; // 소형 토글 버튼 최소 너비
  static const double btnMinWidthMD = 64.0;

  // ── Inputs ─────────────────────────────────────────────
  static const double inputHeightMD = 48.0;
  static const double inputHeightLG = 56.0;

  // ── Avatars / thumbnails ───────────────────────────────
  static const double avatarSM = 28.0;
  static const double avatarMD = 40.0;
  static const double avatarLG = 56.0;

  // ── Navigation ─────────────────────────────────────────
  static const double navBarHeight = 74.0;
  static const double appBarHeight = 56.0;

  // ── Cards ──────────────────────────────────────────────
  static const double cardBorderWidth = 0.7;

  // ── Dividers ───────────────────────────────────────────
  static const double dividerThickness = 1.0;
  static const double accentBarHeight = 3.0; // SummaryCard 상단 액센트 바

  // ── Touch targets ──────────────────────────────────────
  /// 최소 터치 영역 (Material 가이드라인)
  static const double touchTarget = 48.0;

  // ── Frame / desktop ────────────────────────────────────
  /// 데스크톱 폰 프레임 최대 너비
  static const double phoneFrameMaxWidth = 430.0;

  /// 반응형 브레이크포인트
  static const double breakpointMobile = 640.0;
}
