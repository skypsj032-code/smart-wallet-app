## Project Guardrails

### Flutter command policy

Codex may run Flutter and Dart wrapper commands when they are directly useful for implementation, verification, build diagnosis, or QA.

Allowed by default:

- `& 'C:\smart wallet\flutterw.bat' test --no-pub ...`
- `& 'C:\smart wallet\dartw.bat' analyze ...`
- `& 'C:\smart wallet\flutterw.bat' pub run build_runner build --delete-conflicting-outputs`
- `& 'C:\smart wallet\flutterw.bat' build windows --debug --no-pub`

Required behavior:

- Always use the repo-root wrappers `C:\smart wallet\flutterw.bat` and `C:\smart wallet\dartw.bat`.
- Treat those wrapper paths as the only supported entrypoints for Flutter and Dart in this repository across future sessions.
- These wrappers run the app from `C:\smart wallet\app` and pin `PUB_CACHE` to `C:\smart wallet\.pub-cache`.
- In Codex, run Flutter wrapper commands with escalated execution because the selected SDK writes cache locks under `C:\dev\flutter`, outside the workspace writable roots.
- Prefer the absolute wrapper paths in commands, for example `& 'C:\smart wallet\flutterw.bat' test --no-pub`.
- Do not invoke `C:\dev\flutter\bin\flutter.bat` or the Dart SDK directly unless the wrappers are broken.

Runtime QA policy:

- Avoid long-running `flutter run` as the default QA path.
- Prefer `build windows --debug --no-pub` first, then launch the generated exe directly.
- Starting the Windows GUI app with `Start-Process` may require user approval because it opens a visible desktop window.
- If `flutter run` is specifically needed, explain why and use `--no-pub` when possible.
- Do not background Flutter builds with `cmd start`, `Start-Job`, or detached PowerShell wrappers. In this environment those can leave runaway `cmd.exe` processes and hide logs.

### Known failure patterns

- If `dart analyze` fails with `CreateFile failed 5` or `ProcessException: 액세스가 거부되었습니다`, treat it as an execution-environment failure first. Rerun the same analyze command with escalated execution instead of changing app code immediately.
- If `flutter test` or `dart test` fails during `Running build hooks...` and the stack trace mentions `hooks_runner` or native asset hook compilation, rerun the same test with escalated execution. In this environment the hook may need to spawn `cmd.exe`, which can fail inside the sandbox.
- Do not run multiple `flutter test` commands in parallel from Codex in this repository. Wrapper processes and SDK lock waiting can make them look hung for minutes.
- If a test seems stuck, inspect and stop leftover wrapper `cmd.exe` processes before retrying.
- For dashboard narrative UI checks, prefer the extracted `DashboardNarrativeCard` widget test over a full `DashboardScreen` widget test unless the full screen behavior itself is the target.
- Default categories are intentionally user-editable. When expanding seeded defaults, use one-time versioned backfill behavior instead of "reinsert missing defaults on every launch", or deleted defaults will resurrect.

### Reference

- Full incident and implementation notes: `docs/notes/2026-05-05-dashboard-narrative-and-runtime.md`
- Default category rollout notes: `docs/notes/2026-05-05-default-category-seeding.md`
