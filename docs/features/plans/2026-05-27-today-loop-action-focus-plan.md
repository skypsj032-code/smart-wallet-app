- Files: `lib/features/dashboard/presentation/dashboard_screen.dart`
- Files: `test/features/dashboard/dashboard_screen_test.dart`

- Remove the timeline action from `_TodayLoopCard` usage and constructor.
- Keep one clear CTA by adding a stable key to the quick-entry button.
- Add a widget test that proves `Today Loop` has no secondary outlined action while the recent-transactions card still exposes timeline navigation.

- Verify: `./flutterw.bat test --no-pub test/features/dashboard/dashboard_screen_test.dart`
