- Files: `lib/shared/widgets/app_ledger_axis_navigation.dart`
- Files: `lib/features/calendar/presentation/calendar_screen.dart`
- Files: `lib/features/statistics/presentation/statistics_screen.dart`
- Files: `lib/features/accounts/presentation/accounts_screen.dart`
- Files: `test/shared/widgets/app_ledger_axis_navigation_test.dart`

- Create one shared navigation surface for the three classic ledger axes.
- Insert it near the top of calendar, statistics, and accounts so each screen keeps the same product skeleton.
- Highlight the current axis and keep other axes tappable with existing routes.
- Add a widget test for current-axis emphasis and tap callbacks.

- Verify: `./flutterw.bat test --no-pub test/shared/widgets/app_ledger_axis_navigation_test.dart`
