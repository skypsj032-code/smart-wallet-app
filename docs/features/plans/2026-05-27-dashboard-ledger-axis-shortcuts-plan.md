- Files: `lib/features/dashboard/presentation/dashboard_screen.dart`
- Files: `test/features/dashboard/dashboard_screen_test.dart`

- Add a compact shortcut section for `달력`, `통계`, `자산` near the top of the home.
- Keep the layout closer to a classic ledger tool than an insight feed.
- Wire each shortcut to existing routes with direct navigation.
- Add widget coverage for presence and tap behavior.

- Verify: `./flutterw.bat test --no-pub test/features/dashboard/dashboard_screen_test.dart`
