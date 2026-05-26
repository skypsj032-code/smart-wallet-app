- 파일: `lib/features/budgets/application/budget_provider.dart`
- 파일: `lib/features/dashboard/presentation/dashboard_screen.dart`
- 파일: `test/features/budgets/budget_provider_test.dart`
- 파일: `test/features/dashboard/dashboard_screen_test.dart`

- 단계: `BudgetSummary`에서 카테고리 압박 인사이트를 뽑는 pure helper 테스트를 먼저 추가해서 실패를 만든다.
- 단계: helper와 모델을 `budget_provider.dart`에 추가하고, 예산 우선 / 최다 지출 fallback 규칙을 구현한다.
- 단계: 홈에 `카테고리 압박` 카드를 추가하고 `budgetSummaryProvider`를 읽어 카드 노출과 문구를 구성한다.
- 단계: 예산 summary가 없거나 인사이트가 없을 때 카드가 숨는 위젯 테스트를 고정한다.
- 단계: result 문서에 하이브리드 규칙과 홈 정보 위계 역할을 남긴다.

- 검증: `./flutterw.bat test --no-pub test/features/budgets/budget_provider_test.dart test/features/dashboard/dashboard_screen_test.dart`
