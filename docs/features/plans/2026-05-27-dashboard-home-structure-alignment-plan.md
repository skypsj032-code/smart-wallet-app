- Files: `lib/features/dashboard/presentation/dashboard_screen.dart`
- Files: `test/features/dashboard/dashboard_screen_test.dart`

- Move the classic ledger sections (`income/expense`, `budget`, `recent transactions`) above interpretation-heavy cards.
- Keep all existing cards and actions, but lower the prominence of `Today Loop` and recurring insights.
- Add one widget test that verifies the home order is now closer to the classic ledger flow.

- Verify: `./flutterw.bat test --no-pub test/features/dashboard/dashboard_screen_test.dart`
