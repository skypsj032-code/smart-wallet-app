import 'package:flutter/animation.dart';

/// 애니메이션 duration & curve 상수.
/// 모든 전환에 여기서 정의한 값을 사용한다.
abstract final class AppMotion {
  // ── Durations ──────────────────────────────────────────
  /// 50 ms — 즉각적인 피드백 (버튼 눌림, 토글)
  static const Duration instant = Duration(milliseconds: 50);

  /// 150 ms — 짧은 상태 전환 (아이콘 교체, 색상 변화)
  static const Duration fast = Duration(milliseconds: 150);

  /// 250 ms — 표준 전환 (페이드, 슬라이드)
  static const Duration normal = Duration(milliseconds: 250);

  /// 350 ms — 중간 전환 (바텀시트, 드로어)
  static const Duration medium = Duration(milliseconds: 350);

  /// 500 ms — 느린 전환 (화면 전체 전환, Hero)
  static const Duration slow = Duration(milliseconds: 500);

  /// 800 ms — 강조 애니메이션 (로딩, 환영 화면)
  static const Duration xslow = Duration(milliseconds: 800);

  // ── Curves ─────────────────────────────────────────────
  /// 기본 감속 — 요소가 화면 안으로 진입할 때
  static const Curve decelerate = Curves.easeOutCubic;

  /// 기본 가속 — 요소가 화면 밖으로 퇴장할 때
  static const Curve accelerate = Curves.easeInCubic;

  /// 기본 가감속 — 화면 내 이동, 크기 변화
  static const Curve standard = Curves.easeInOutCubic;

  /// Material Emphasized — 큰 화면 전환에 사용
  static const Curve emphasized = Cubic(0.2, 0.0, 0.0, 1.0);

  /// 바운스 효과 — 토스트, 팝업 등장
  static const Curve spring = Cubic(0.34, 1.56, 0.64, 1.0);

  /// 선형 — 루프 애니메이션 (스피너, 진행 바)
  static const Curve linear = Curves.linear;
}
