- Files: `lib/shared/widgets/app_ledger_axis_intro.dart`
- Files: `lib/features/calendar/presentation/calendar_screen.dart`
- Files: `lib/features/statistics/presentation/statistics_screen.dart`
- Files: `lib/features/accounts/presentation/accounts_screen.dart`
- Files: `test/shared/widgets/app_ledger_axis_intro_test.dart`

- Reduce intro headline/body typography by one step.
- Shorten the helper copy in the calendar/statistics top cards to one short sentence each.
- Keep structure and actions unchanged; density only.

- Verify:
  - `./flutterw.bat analyze lib/shared/widgets/app_ledger_axis_intro.dart lib/features/calendar/presentation/calendar_screen.dart lib/features/statistics/presentation/statistics_screen.dart lib/features/accounts/presentation/accounts_screen.dart`
  - `./flutterw.bat test --no-pub test/shared/widgets/app_ledger_axis_intro_test.dart`
