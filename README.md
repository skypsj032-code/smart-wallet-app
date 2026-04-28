# smart_wallet_app

Workspace-local Flutter entrypoints for this project:

- `flutterw.bat`
- `flutterw.ps1`
- `dartw.bat`
- `dartw.ps1`

Use these wrappers instead of plain `flutter` when working from Codex or other sandboxed shells.

Examples:

```powershell
.\flutterw.bat --version
.\flutterw.bat test -r expanded test\widget_test.dart
.\flutterw.bat run -d windows --no-resident
.\dartw.bat analyze lib
```

Notes:

- Active Flutter SDK: `C:\dev\flutter`
- Avoid `flutter doctor -v` inside Codex when possible. It scans external tools and can stall in wrapped shells.
- Prefer direct task commands such as `test`, `run`, `pub get`, and `dart analyze`.
