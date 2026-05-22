# Recurring Spend Bottom Sheet Plan

- slug: `recurring-spend-bottom-sheet`
- size: `medium`

## Files

- `lib/features/dashboard/presentation/dashboard_screen.dart`
- `test/features/dashboard/dashboard_screen_test.dart`
- `docs/features/results/2026-05-22-recurring-spend-bottom-sheet-result.md`

## Steps

- 반복지출 카드 탭 시 바텀시트가 열리는 동작을 위젯 테스트로 먼저 고정한다.
- 바텀시트 헤더에 제목, 총액 요약, 닫기 액션을 추가한다.
- `새로 보이는 반복지출` 섹션을 분리하고 `previousMonthAmount == 0` 조건으로 노출한다.
- 전체 반복지출 목록은 `다가오는 순서`를 기본 정렬로 계산한다.
- 각 항목에는 이름, 유형, 이번 달 금액, 지난달 대비, 최근 결제일 또는 다음 예상 시점을 넣는다.
- 생활 반복지출처럼 다음 시점이 불명확한 경우 최근 거래일 기준으로 보조 정렬한다.
- 구현 후 위젯 테스트와 기존 detector/provider/dashboard 테스트를 함께 다시 돌린다.

## Verification

- `flutter test --no-pub test/features/dashboard/dashboard_screen_test.dart`
- `flutter test --no-pub test/features/dashboard/recurring_spend_detector_test.dart test/features/dashboard/dashboard_summary_provider_test.dart test/features/dashboard/dashboard_screen_test.dart`
