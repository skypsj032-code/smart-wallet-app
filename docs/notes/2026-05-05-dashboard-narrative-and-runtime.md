# Dashboard Narrative Redesign And Codex Runtime Notes

Date: `2026-05-05`

## Summary

This document records the full context for the dashboard hero narrative redesign and the test/runtime failures encountered while implementing and verifying it from Codex on Windows.

It exists for two reasons:

1. Preserve the product intent behind the home top narrative area.
2. Prevent the same Flutter/Codex execution failures from being rediscovered in future sessions.

## Product Problem

The original home top sentence behaved like a generic status compliment:

- `이번 달은 안정적으로 관리되고 있어요`
- `지출은 빠르지만 기록은 잘 남고 있어요`

That was not aligned with the intended role of the space. This area is not a congratulatory banner or feature explanation. It is the place where the app should read the user's monthly spending flow back to them in a way that feels specific and believable.

The user requirement was:

- do not explain features there
- do not write vague praise
- do not force emotional wording
- do describe how money is being used this month
- keep the copy natural in Korean

## Final Product Direction

The home top area is now defined as a spending-interpretation surface.

Structure:

- headline: one short interpretation sentence
- evidence: one short supporting sentence

Tone:

- observational, not preachy
- empathic through pattern recognition, not emotional overstatement
- concrete enough to feel personal
- short enough to stay readable on mobile

Examples of the intended shape:

- `이번 달은 식비 쪽 지출이 먼저 커졌어요.`
- `작게 자주 쓰는 흐름이 이어지고 있어요.`
- `큰 금액 위주로 드문드문 나가는 달이에요.`
- `아직 이번 달 소비 흐름은 조금 더 쌓여야 보여요.`

## Planning Decisions

The design decisions that were locked in:

- role: `소비 해석형`
- specificity: `패턴 요약형`
- structure: `메인 1줄 + 근거 1줄`
- scope: `홈 상단만`

Explicitly out of scope for this change:

- settings copy rewrite
- timeline copy rewrite
- app-wide writing system
- AI-generated personalized summaries
- long-term learning or server-side profiling

## Implementation Summary

### New narrative model

Added a dedicated dashboard narrative layer instead of branching directly inside the widget.

Main file:

- `lib/features/dashboard/application/dashboard_narrative.dart`

Key types:

- `DashboardNarrativeSnapshot`
- `DashboardNarrativeCopy`
- `DashboardDominantPattern`
- `RecentExpenseMomentum`
- `BudgetPressureLevel`
- `LoggingConsistencyLevel`

### Narrative signals

The narrative now uses monthly expense data plus category information to derive:

- top expense category
- top category share
- expense transaction count
- average expense amount
- recent expense momentum
- budget pressure
- logging consistency
- dominant spending pattern

### Narrative priority

Headline priority order:

1. insufficient data
2. category-focused spending
3. small frequent spending
4. large sparse spending
5. budget pressure
6. logging just started / actively continuing
7. balanced monthly flow

### UI extraction

The narrative card was extracted into its own presentational widget:

- `lib/features/dashboard/presentation/dashboard_narrative_card.dart`

This keeps the rule engine testable and avoids reusing the full animated dashboard screen for simple rendering checks.

### Dashboard integration

The dashboard summary provider now computes the narrative snapshot directly:

- `lib/features/dashboard/application/dashboard_summary_provider.dart`

The screen consumes the computed snapshot instead of building strings inline:

- `lib/features/dashboard/presentation/dashboard_screen.dart`

## Tests Added

### Logic tests

- `test/features/dashboard/dashboard_narrative_test.dart`

Covered scenarios:

- insufficient data
- category-focused copy
- small frequent spending
- priority of category signal over budget pressure
- no awkward `오늘 기록` evidence when there is no today entry
- safe handling of `미분류`

### Widget test

- `test/features/dashboard/dashboard_screen_test.dart`

Important note: this test no longer mounts the entire `DashboardScreen`. It tests the extracted `DashboardNarrativeCard` directly.

That change is intentional and should be preserved unless there is a strong reason to reintroduce a full-screen widget test.

## Verification Result

Verified successfully after the final fixes:

- `dart analyze lib\features\dashboard\application\dashboard_narrative.dart lib\features\dashboard\application\dashboard_summary_provider.dart lib\features\dashboard\presentation\dashboard_narrative_card.dart lib\features\dashboard\presentation\dashboard_screen.dart test\features\dashboard\dashboard_narrative_test.dart test\features\dashboard\dashboard_screen_test.dart`
- `flutter test --no-pub test\features\dashboard\dashboard_narrative_test.dart test\features\dashboard\dashboard_screen_test.dart`

Result:

- analyze: no issues found
- tests: all passed

## Root Cause Notes For Runtime Failures

This section is the main recurrence-prevention record.

### 1. `CreateFile failed 5` during `dart analyze`

Observed symptom:

- analysis server failed to start
- `ProcessException: 액세스가 거부되었습니다`
- command referenced `dartaotruntime.exe` and `analysis_server_aot.dart.snapshot`

Actual cause:

- Codex sandbox / process-spawn restrictions blocked the analysis server child process from starting correctly in this environment.

Resolution:

- rerun `dart analyze` outside the sandbox with escalated execution

Rule:

- if `dart analyze` fails with `CreateFile failed 5`, do not debug Dart code first
- treat it as an execution-environment problem
- rerun the same analysis command with escalated execution

### 2. `CreateFile failed 5` during test native asset hook

Observed symptom:

- `flutter test` or `dart test` failed while `objective_c` native build hooks were running
- stack trace referenced `hooks_runner`
- command attempted to spawn `cmd.exe /c ... dart.exe compile kernel ... hook\build.dart`

Actual cause:

- the native asset hook needed to spawn `cmd.exe`
- sandboxed execution blocked that child process path

Resolution:

- rerun the test command outside the sandbox with escalated execution

Rule:

- if a Flutter or Dart test fails inside `Running build hooks...` with `CreateFile failed 5`, assume environment first
- rerun the same test outside the sandbox before changing application code

### 3. Long-running `flutter test` sessions with no useful output

Observed symptom:

- tests appeared to hang for minutes
- wrapper-driven `cmd.exe` processes remained alive
- no meaningful test output appeared

Contributing causes:

- multiple Flutter test commands were launched in parallel
- wrapper processes accumulated
- SDK lock / wrapper waiting made the situation look like a code hang

Resolution:

- stop leftover wrapper processes
- run only one Flutter test command at a time
- prefer narrower test targets

Rule:

- never run multiple `flutter test` commands in parallel in this repository from Codex
- if tests appear stuck, inspect running `cmd.exe` wrapper processes before assuming app logic is hanging

### 4. Heavy widget test scope

Observed symptom:

- full `DashboardScreen` widget test was more expensive than needed
- it pulled in slivers, pinned header behavior, and animation-related complexity

Actual cause:

- the test scope was too broad for what needed verification

Resolution:

- extract `DashboardNarrativeCard`
- test the card directly

Rule:

- for copy rendering, typography, and local UI contract checks, prefer the smallest public widget that expresses the behavior
- do not mount the whole dashboard unless navigation or screen composition itself is the thing being tested

## Recommended Command Policy For Future Sessions

### Normal expectation

Use the repository wrappers first:

- `C:\smart wallet\flutterw.bat`
- `C:\smart wallet\dartw.bat`

### When to escalate immediately

Use escalated execution when any of these appear:

- `CreateFile failed 5`
- `ProcessException: 액세스가 거부되었습니다`
- native hook execution under `Running build hooks...`
- analysis server child-process spawn failures

### Test execution rules

- run Flutter tests one command at a time
- do not parallelize multiple `flutter test` invocations
- prefer file-targeted tests over broader suites during debugging
- prefer extracted widget tests over full-screen widget tests when the behavior is local

## Files Added Or Changed For This Work

Primary implementation files:

- `lib/features/dashboard/application/dashboard_narrative.dart`
- `lib/features/dashboard/application/dashboard_summary_provider.dart`
- `lib/features/dashboard/presentation/dashboard_narrative_card.dart`
- `lib/features/dashboard/presentation/dashboard_screen.dart`

Primary test files:

- `test/features/dashboard/dashboard_narrative_test.dart`
- `test/features/dashboard/dashboard_screen_test.dart`

Documentation files:

- `README.md`
- `CLAUDE.md`
- `docs/notes/2026-05-05-dashboard-narrative-and-runtime.md`

## Follow-up Guidance

If the home narrative is revisited later, keep these invariants:

- the area should interpret spending, not explain features
- the area should sound specific, not congratulatory
- evidence lines should justify the headline
- future expansion should prefer richer category / cadence signals before introducing more emotional language

## Additional UX Bug Fixed After Initial Rollout

### Symptom

When the user added a single food expense, the evidence line could say:

- `이번 달 지출의 100%가 식비에 모였어요`

This was technically true but product-wise wrong. With only one or two records, percentage language sounded overconfident and unnatural.

### Root cause

The narrative system correctly marked very small samples as `insufficientData`, but the evidence builder still generated category-share percentage text before checking whether the sample size was large enough to support that claim.

In practice this meant:

- headline: cautious
- evidence: overconfident

That mismatch made the card feel shallow and statistically naive.

### Fix

The evidence rules were tightened:

- fewer than 3 expense records: do not use category-share percentages
- 1 expense record: use `아직은 소비 흐름을 단정하긴 일러요`
- 2 expense records: use `<category> 쪽이 먼저 보이지만 아직 단정하긴 일러요`
- only 3 or more expense records may use `%가 <category>에 모였어요`

### Regression coverage

Added test coverage to ensure small samples do not emit `100%` concentration copy:

- `test/features/dashboard/dashboard_narrative_test.dart`
