# Recurring Spend Not Recurring Action Result

- 실제 변경: 반복지출 보정용 `RecurringSpendOverrides` Drift 테이블을 추가했고, `groupKey` 기준 `not_recurring` 상태를 영속 저장할 수 있게 했다.
- 실제 변경: 대시보드 summary가 override 목록을 같이 구독하도록 바꿔서, 제외된 `groupKey`는 홈 카드와 반복지출 목록 계산에서 빠지게 했다.
- 실제 변경: 반복지출 상세 시트 하단에 `반복 아님` 액션과 확인 다이얼로그를 추가했다.
- 실제 변경: 저장 후 상세 시트는 닫히고, 반복지출 바텀시트는 provider를 다시 보도록 바꿔 이후 갱신 흐름을 받을 수 있게 했다.
- 계획과 차이: 별도 관리 화면이나 복구 액션은 넣지 않았고, 이번 범위는 `not_recurring` 단일 액션에만 고정했다.
- 검증: `./flutterw.bat test --no-pub test/features/dashboard/recurring_spend_detector_test.dart test/features/dashboard/dashboard_summary_provider_test.dart test/features/dashboard/dashboard_screen_test.dart`
- 다음 할 일: 제외된 반복지출을 다시 복구하는 관리 화면이나 설정 진입점을 설계해야 한다.
