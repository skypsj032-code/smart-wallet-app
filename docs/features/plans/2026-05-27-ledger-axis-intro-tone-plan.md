- Files: `lib/shared/widgets/app_ledger_axis_intro.dart`
- Files: `lib/features/calendar/presentation/calendar_screen.dart`
- Files: `lib/features/statistics/presentation/statistics_screen.dart`
- Files: `lib/features/accounts/presentation/accounts_screen.dart`
- Files: `test/shared/widgets/app_ledger_axis_intro_test.dart`

- Add one shared intro card for classic ledger axes with a label, headline, and supporting copy.
- Insert it below the axis navigation on calendar, statistics, and accounts.
- Keep each screen's specific controls intact, but make the first visual tone consistent.
- Add a widget test for the shared intro card content.

- Verify: `./flutterw.bat test --no-pub test/shared/widgets/app_ledger_axis_intro_test.dart`
