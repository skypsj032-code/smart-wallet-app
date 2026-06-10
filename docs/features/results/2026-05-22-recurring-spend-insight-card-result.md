# Recurring Spend Insight Card Result

- slug: `recurring-spend-insight-card`
- completed: 2026-05-22

## Changed

- 홈 대시보드의 첫 인사이트 블록으로 반복지출 카드를 추가했다.
- 카드에 이번 달 반복지출 총액, 월 지출 대비 비중, 상위 3개 항목, 설명형 한 줄 해석을 넣었다.
- 반복지출 그룹이 없을 때는 카드가 보이지 않도록 숨김 조건을 유지했다.

## Plan Delta

- 상세 바텀시트 진입은 이번 범위에서 제외하고 홈 카드 렌더링까지 먼저 마쳤다.
- 해석 문구는 detector가 가진 데이터만 써서 새 항목, 증감, 생활 반복 여부 중심으로 구성했다.

## Verification

- `flutter test --no-pub test/features/dashboard/dashboard_screen_test.dart`
- `flutter test --no-pub test/features/dashboard/recurring_spend_detector_test.dart test/features/dashboard/dashboard_summary_provider_test.dart test/features/dashboard/dashboard_screen_test.dart`
