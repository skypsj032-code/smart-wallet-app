# Recurring Spend Detail Sheet Result

- slug: `recurring-spend-detail-sheet`
- completed: 2026-05-23

## Changed

- 반복지출 바텀시트 항목 탭 시 열리는 상세 시트를 추가했다.
- 상세 시트 상단에 항목명, 유형, 이번 달 금액을 두고 `반복으로 본 이유`를 먼저 보여주도록 구성했다.
- 이유 문구는 detector 규칙을 kind 기준 bullet로 번역해 노출했다.
- 최근 거래 내역과 요약 정보 섹션을 추가해 최근 결제일, 다음 예상 시점, 지난달 대비를 같이 보게 했다.

## Plan Delta

- detector 모델을 늘리지 않고 presentation helper에서 이유 문구를 계산했다.
- 이유 설명은 현재 kind 기반 최소 번역으로만 두고, score 세부 근거 노출은 다음 단계로 남겼다.

## Verification

- `flutter test --no-pub test/features/dashboard/dashboard_screen_test.dart`
- `flutter test --no-pub test/features/dashboard/recurring_spend_detector_test.dart test/features/dashboard/dashboard_summary_provider_test.dart test/features/dashboard/dashboard_screen_test.dart`
