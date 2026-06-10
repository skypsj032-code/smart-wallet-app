- Files: `lib/shared/widgets/app_ledger_axis_intro.dart`
- Files: `lib/shared/widgets/app_ledger_axis_navigation.dart`
- Files: `lib/features/accounts/presentation/accounts_screen.dart`
- Files: `lib/features/calendar/presentation/calendar_screen.dart`
- Files: `lib/features/statistics/presentation/statistics_screen.dart`

- Normalize the most visible axis-related surfaces to a slightly tighter radius.
- Keep layout, padding, and colors unchanged so this stays a pure texture pass.
- Verify the shared widgets and three screens still analyze cleanly.

- Verify: `./flutterw.bat analyze --no-pub lib/shared/widgets/app_ledger_axis_intro.dart lib/shared/widgets/app_ledger_axis_navigation.dart lib/features/accounts/presentation/accounts_screen.dart lib/features/calendar/presentation/calendar_screen.dart lib/features/statistics/presentation/statistics_screen.dart`
