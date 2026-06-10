# Recurring Spend Insight Card Plan

- slug: `recurring-spend-insight-card`
- size: `medium`

## Files

- `lib/features/dashboard/presentation/dashboard_screen.dart`
- `test/features/dashboard/dashboard_screen_test.dart`

## Steps

- 대시보드 화면에 반복지출 인사이트 카드가 보여야 하는 조건을 위젯 테스트로 먼저 고정한다.
- 카드 위치를 홈의 첫 인사이트 블록으로 넣고, 총액/증감/상위 항목 3개를 렌더링한다.
- 반복지출이 없을 때는 카드가 노출되지 않도록 숨김 조건을 유지한다.
- 카드 문구는 훈계형이 아니라 설명형으로 두고, 기존 대시보드 스타일과 어조를 맞춘다.
- 대시보드 전용 위젯 테스트만 먼저 검증하고, 기존 detector/provider 테스트와 함께 돌린다.

## Verification

- `flutter test --no-pub test/features/dashboard/dashboard_screen_test.dart`
- `flutter test --no-pub test/features/dashboard/recurring_spend_detector_test.dart test/features/dashboard/dashboard_summary_provider_test.dart test/features/dashboard/dashboard_screen_test.dart`
