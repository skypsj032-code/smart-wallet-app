- Files: `lib/features/dashboard/presentation/dashboard_screen.dart`
- Files: `test/features/dashboard/dashboard_screen_test.dart`

- Remove the extra recurring management button that sits below `_RepeatSuggestionSection`.
- Add a widget test proving repeat suggestions can render without also showing `recurring-hidden-count-button`.
- Keep the existing recurring-card management entry unchanged.

- Verify: `./flutterw.bat test --no-pub test/features/dashboard/dashboard_screen_test.dart`
