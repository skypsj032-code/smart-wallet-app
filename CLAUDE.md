## Project Guardrails

This repository contains a Flutter app under `C:\smart wallet\app`.

### Flutter command policy

For this project, do not run Flutter or Dart wrapper commands unless the user explicitly asks in the current session.

Blocked by default:

- `flutter`
- `flutterw.bat`
- `flutterw.ps1`
- `dart`
- `dartw.bat`
- `dartw.ps1`

This includes, but is not limited to:

- `flutter devices`
- `flutter run`
- `flutter doctor`
- `flutter test`
- `flutter pub get`
- `dart analyze`

Required behavior:

- Ask first before launching, probing, or diagnosing Flutter.
- If QA is requested, prefer an already-running app URL or static/code review first.
- If no app is already running, do not start one without explicit permission from the user in that session.
