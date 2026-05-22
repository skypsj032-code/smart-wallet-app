# Recurring Spend Bottom Sheet Result

- slug: `recurring-spend-bottom-sheet`
- completed: 2026-05-22

## Changed

- 반복지출 카드 탭 시 열리는 바텀시트를 추가했다.
- 상단에 총액 요약을 두고, `새로 보이는 반복지출`과 `다가오는 반복지출` 섹션으로 목록을 분리했다.
- 메인 목록은 다음 예상 시점 기준으로 정렬하고, 생활 반복지출은 최근 거래일 기준으로 보조 정렬했다.
- 각 항목에 유형, 이번 달 금액, 증감 문구, 시간성 문구를 넣었다.

## Plan Delta

- detector 모델은 바꾸지 않고 presentation helper에서 최근 거래일과 다음 예상 시점을 계산했다.
- `다가오는 반복지출` 섹션에서는 중복 노출을 피하려고 새로 보이는 항목을 제외했다.

## Verification

- `flutter test --no-pub test/features/dashboard/dashboard_screen_test.dart`
- `flutter test --no-pub test/features/dashboard/recurring_spend_detector_test.dart test/features/dashboard/dashboard_summary_provider_test.dart test/features/dashboard/dashboard_screen_test.dart`
