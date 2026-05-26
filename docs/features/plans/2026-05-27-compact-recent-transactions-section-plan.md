- 파일: `lib/features/dashboard/presentation/dashboard_screen.dart`
- 파일: `test/features/dashboard/dashboard_screen_test.dart`

- 단계: 최근 거래가 4건 이상일 때 홈에는 3건만 노출되는 위젯 테스트를 먼저 추가한다.
- 단계: `_RecentTransactionsSection`에 `onOpenTimeline`을 받아 하단 `전체 보기` 액션을 추가한다.
- 단계: 카드 안에서 `transactions.take(3)`만 렌더링하고, 각 거래 타일에 key를 부여해 검증 가능하게 만든다.
- 단계: result 문서에 홈에서 리스트를 줄인 이유와 역할 변화를 남긴다.

- 검증: `./flutterw.bat test --no-pub test/features/dashboard/dashboard_screen_test.dart`
