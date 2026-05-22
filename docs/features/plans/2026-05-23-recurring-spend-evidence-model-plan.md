# Recurring Spend Evidence Model Plan

- slug: `recurring-spend-evidence-model`
- size: `medium`

## Files

- `lib/features/dashboard/application/recurring_spend_detector.dart`
- `lib/features/dashboard/presentation/dashboard_screen.dart`
- `test/features/dashboard/recurring_spend_detector_test.dart`
- `test/features/dashboard/dashboard_screen_test.dart`
- `docs/features/results/2026-05-23-recurring-spend-evidence-model-result.md`

## Steps

- detector 테스트에 evidence code와 confidence level 기대값을 먼저 추가한다.
- `RecurringSpendGroup`에 confidence와 evidence 필드를 추가한다.
- fixed / subscription / lifestyle 판정에서 실제로 사용한 근거 코드를 함께 반환하도록 detector를 확장한다.
- score 기준으로 `high` / `medium` confidence를 계산한다.
- 상세 시트가 presentation helper 대신 detector evidence를 읽어 설명과 신뢰 레벨을 보여주도록 수정한다.
- detector 테스트와 dashboard screen 테스트를 함께 다시 돌려 regression을 막는다.

## Verification

- `flutter test --no-pub test/features/dashboard/recurring_spend_detector_test.dart`
- `flutter test --no-pub test/features/dashboard/dashboard_screen_test.dart`
- `flutter test --no-pub test/features/dashboard/recurring_spend_detector_test.dart test/features/dashboard/dashboard_summary_provider_test.dart test/features/dashboard/dashboard_screen_test.dart`
