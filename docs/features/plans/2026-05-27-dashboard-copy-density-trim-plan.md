- Files: `lib/features/dashboard/presentation/dashboard_screen.dart`

- Remove redundant subtitles from recurring spend, monthly pace, upcoming recurring, repeat suggestions, and category pressure section intros.
- Leave recent transactions and budget flow intros untouched, since they still help orient the lower part of the home screen.

- Verify: `./flutterw.bat test --no-pub test/features/dashboard/dashboard_screen_test.dart`
