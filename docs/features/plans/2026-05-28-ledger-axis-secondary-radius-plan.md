- Files: `lib/features/accounts/presentation/accounts_screen.dart`
- Files: `lib/features/calendar/presentation/calendar_screen.dart`
- Files: `lib/features/statistics/presentation/statistics_screen.dart`

- Normalize remaining secondary card radii from 20 to 18.
- Keep all spacing and content unchanged.
- Verify only these screens to keep the loop tight.

- Verify: `./flutterw.bat analyze --no-pub lib/features/accounts/presentation/accounts_screen.dart lib/features/calendar/presentation/calendar_screen.dart lib/features/statistics/presentation/statistics_screen.dart`
