# ledger-axis-control-surface-batch

- 파일: `lib/features/calendar/presentation/calendar_screen.dart`, `lib/features/statistics/presentation/statistics_screen.dart`, `lib/features/accounts/presentation/accounts_screen.dart`
- 달력 보기 카드의 helper copy를 빼고 padding/radius를 한 단계 줄인다.
- 통계 기간 카드의 helper copy를 빼고 padding/radius와 월 이동 버튼 밀도를 줄인다.
- 자산 계좌 액션을 filled보다 가벼운 outlined 계열로 낮춘다.
- 확인: `./flutterw.bat analyze --no-pub lib/features/calendar/presentation/calendar_screen.dart lib/features/statistics/presentation/statistics_screen.dart lib/features/accounts/presentation/accounts_screen.dart`
