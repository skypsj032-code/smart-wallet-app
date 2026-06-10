- Files: `lib/features/calendar/presentation/calendar_screen.dart`
- Files: `lib/features/statistics/presentation/statistics_screen.dart`
- Files: `lib/features/accounts/presentation/accounts_screen.dart`

- Reduce top-level vertical gaps from `AppSpacing.lg` to `AppSpacing.md` where the screens currently feel too spread out.
- Tighten the accounts summary and empty-state card padding by one step.
- Keep card content and behavior unchanged; adjust density only.

- Verify: `./flutterw.bat analyze lib/features/calendar/presentation/calendar_screen.dart lib/features/statistics/presentation/statistics_screen.dart lib/features/accounts/presentation/accounts_screen.dart`
