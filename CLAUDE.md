## Project Guardrails

### Hard rule for this app

Do not run Flutter or Dart commands for this project unless the user explicitly asks for that exact action in the current session.

Blocked by default:

- `flutter`
- `flutterw.bat`
- `flutterw.ps1`
- `dart`
- `dartw.bat`
- `dartw.ps1`

Examples that must not be run without permission:

- `flutter devices`
- `flutter run`
- `flutter doctor`
- `flutter test`
- `flutter pub get`
- `dart analyze`

Required behavior:

- Never auto-probe the Flutter environment.
- Never launch the app just to inspect or QA it.
- Prefer code inspection, existing logs, existing screenshots, or a user-provided running URL first.
- If runtime verification is needed, ask the user first and wait for permission.
