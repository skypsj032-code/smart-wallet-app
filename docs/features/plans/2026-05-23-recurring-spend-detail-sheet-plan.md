# Recurring Spend Detail Sheet Plan

- slug: `recurring-spend-detail-sheet`
- size: `medium`

## Files

- `lib/features/dashboard/presentation/dashboard_screen.dart`
- `test/features/dashboard/dashboard_screen_test.dart`
- `docs/features/results/2026-05-23-recurring-spend-detail-sheet-result.md`

## Steps

- 반복지출 바텀시트 항목 탭 시 상세 시트가 열리는 동작을 위젯 테스트로 먼저 고정한다.
- 상세 시트 상단에 항목명, 유형, 이번 달 금액을 넣는다.
- `반복으로 본 이유` 섹션을 추가하고, detector 규칙을 번역한 bullet 설명을 노출한다.
- `최근 거래 내역` 섹션을 추가해 묶인 거래들을 최신 순으로 보여준다.
- 최근 결제일, 다음 예상 시점, 지난달 대비를 요약 정보로 넣는다.
- 상세 시트는 바텀시트 위에서 다시 열리는 흐름으로 유지한다.
- dashboard 전용 테스트와 기존 detector/provider/dashboard 테스트를 함께 재검증한다.

## Verification

- `flutter test --no-pub test/features/dashboard/dashboard_screen_test.dart`
- `flutter test --no-pub test/features/dashboard/recurring_spend_detector_test.dart test/features/dashboard/dashboard_summary_provider_test.dart test/features/dashboard/dashboard_screen_test.dart`
