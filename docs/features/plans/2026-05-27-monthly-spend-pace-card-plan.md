- 파일: `lib/features/dashboard/application/dashboard_summary_provider.dart`
- 파일: `lib/features/dashboard/presentation/dashboard_screen.dart`
- 파일: `test/features/dashboard/dashboard_summary_provider_test.dart`
- 파일: `test/features/dashboard/dashboard_screen_test.dart`

- 단계: summary 테스트에 소비 페이스 계산 기대값을 먼저 추가해서 application 계층에서 실패를 만든다.
- 단계: `DashboardSummary`에 소비 페이스 모델을 추가하고, `buildDashboardSummary`에서 월말 예상 지출과 상태를 계산한다.
- 단계: 홈에 `이번 달 소비 페이스` 카드를 반복지출 카드 다음에 추가하고, 상태 문구와 예상 금액을 노출한다.
- 단계: 위젯 테스트에 카드 노출과 핵심 문구를 추가해 홈 보상 흐름을 고정한다.
- 단계: result 문서에 실제 문구와 계산 기준, 구현 중 달라진 점을 남긴다.

- 검증: `./flutterw.bat test --no-pub test/features/dashboard/dashboard_summary_provider_test.dart test/features/dashboard/dashboard_screen_test.dart`
