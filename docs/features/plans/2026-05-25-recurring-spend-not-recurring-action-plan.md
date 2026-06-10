# Recurring Spend Not Recurring Action Plan

- slug: `recurring-spend-not-recurring-action`
- size: `medium`

## Files

- `lib/core/database/tables.dart`
- `lib/core/database/app_database.dart`
- `lib/core/database/app_database.g.dart`
- `lib/core/database/providers/database_providers.dart` if helper exposure is needed
- `lib/features/dashboard/application/dashboard_summary_provider.dart`
- `lib/features/dashboard/application/recurring_spend_detector.dart` if group key filtering is colocated there
- `lib/features/dashboard/presentation/dashboard_screen.dart`
- `test/features/dashboard/dashboard_summary_provider_test.dart`
- `test/features/dashboard/dashboard_screen_test.dart`
- database or migration-focused test file if needed
- `docs/features/results/2026-05-25-recurring-spend-not-recurring-action-result.md`

## Steps

- 새 override 저장 모델에 대한 테스트부터 추가한다.
  - `groupKey`가 override 목록에 있으면 summary에서 제외되는지
  - 상세 시트에서 `반복 아님` 액션을 누르면 저장과 갱신이 일어나는지
- `recurring_spend_overrides` Drift 테이블을 추가한다.
- schema version을 올리고 마이그레이션을 추가한다.
- override 조회/저장 helper를 database 또는 dashboard application 계층에 만든다.
- dashboard summary 계산 시 override된 `groupKey`를 읽어 recurring groups를 후처리 필터링한다.
- 상세 시트 하단에 `반복 아님` 버튼을 추가한다.
- 버튼 탭 시 확인 다이얼로그를 띄우고 승인되면 override를 저장한다.
- 저장 후 상세 시트를 닫고, 기존 stream 갱신으로 홈 카드와 목록이 자동 갱신되게 연결한다.
- detector/provider/dashboard 관련 테스트를 다시 돌려 회귀가 없는지 확인한다.

## Verification

- `flutter test --no-pub test/features/dashboard/dashboard_summary_provider_test.dart`
- `flutter test --no-pub test/features/dashboard/dashboard_screen_test.dart`
- 관련 DB 테스트 파일이 생기면 그 테스트까지 개별 실행
- `flutter test --no-pub test/features/dashboard/recurring_spend_detector_test.dart test/features/dashboard/dashboard_summary_provider_test.dart test/features/dashboard/dashboard_screen_test.dart`
