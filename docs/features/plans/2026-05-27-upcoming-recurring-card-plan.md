- 파일: `lib/features/dashboard/presentation/dashboard_screen.dart`
- 파일: `test/features/dashboard/dashboard_screen_test.dart`

- 단계: 위젯 테스트에 `곧 나갈 돈` 카드 노출과 날짜순 항목 표시를 먼저 추가해서 실패를 만든다.
- 단계: 기존 `_RecurringSheetGroupView` 계산을 재사용해 fixed/subscription upcoming 후보를 홈 카드로 뽑는다.
- 단계: 홈에서 `이번 달 소비 페이스` 다음에 `곧 나갈 돈` 카드를 노출하고, 카드 전체 탭으로 기존 반복지출 바텀시트를 연다.
- 단계: upcoming 후보가 없을 때 카드를 숨기는 테스트도 같이 고정한다.
- 단계: result 문서에 홈 보상 흐름에서 이 카드가 맡는 역할을 기록한다.

- 검증: `./flutterw.bat test --no-pub test/features/dashboard/dashboard_screen_test.dart`
