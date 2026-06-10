- 파일: `lib/features/dashboard/presentation/dashboard_screen.dart`
- 파일: `test/features/dashboard/dashboard_screen_test.dart`

- 단계: 위젯 테스트에 `budget-status-card` 존재와 핵심 수치 노출을 먼저 추가한다.
- 단계: `_BudgetStatusCard`에 key를 추가하고, 큰 headline을 줄여 `진행률 + 남은 예산 + 짧은 설명` 중심 레이아웃으로 압축한다.
- 단계: 앞선 보상 카드와 역할이 겹치지 않도록 문구를 보조 톤으로 조정한다.
- 단계: result 문서에 홈 정보 위계에서 이 카드의 역할 변경을 남긴다.

- 검증: `./flutterw.bat test --no-pub test/features/dashboard/dashboard_screen_test.dart`
