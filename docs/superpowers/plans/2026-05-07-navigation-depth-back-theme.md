# Navigation Depth, Back Behavior, Theme Picker, and Calendar Sort Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make back behavior predictable across the whole app, enforce a hard depth limit of 3 for pages and overlays, add a newest-first/oldest-first sort toggle to calendar day transactions, and replace the broken theme picker UI with a clear 3-way segmented control.

**Architecture:** Add one shared navigation policy layer at the app shell boundary, then keep calendar sorting and theme picking as thin screen-level concerns. The shell owns exit, home return, and depth control. Calendar owns list ordering. Settings owns the segmented theme control only.

**Tech Stack:** Flutter, Riverpod, GoRouter, Drift, widget tests, Flutter analyze/test/build.

---

## File Map

### Root navigation and depth policy

- Create: `lib/features/root/application/navigation_depth_policy.dart`
  - Shared helpers for root-vs-detail detection, max depth evaluation, and exit grace timing state.
- Create: `lib/features/root/presentation/guarded_navigation_overlays.dart`
  - Common helpers for guarded `showDialog` and `showModalBottomSheet` entry points.
- Modify: `lib/features/root/presentation/app_shell.dart`
  - Route back behavior through the shared policy and enforce home/non-home behavior consistently.
- Modify: `lib/app/router/app_router.dart`
  - Reuse the shared depth policy when deciding whether a new routed layer would exceed the depth cap.
- Modify: `lib/features/accounts/presentation/accounts_screen.dart`
  - Route account editor and destructive confirmation dialogs through the guarded helper.
- Modify: `lib/features/budgets/presentation/budget_screen.dart`
  - Route budget edit and delete dialogs through the guarded helper.
- Modify: `lib/features/recurring_expenses/presentation/recurring_expenses_screen.dart`
  - Route recurring transaction editor dialogs through the guarded helper.
- Modify: `lib/features/settings/presentation/settings_screen.dart`
  - Route restore/export/security dialogs through the guarded helper.
- Modify: `lib/features/settings/presentation/lock_setup_dialog.dart`
  - Route PIN setup through the guarded helper.
- Modify: `lib/features/transactions/presentation/quick_entry_screen.dart`
  - Route category create/rename dialogs and category/account sheets through the guarded helper.
- Create: `test/features/root/app_shell_back_behavior_test.dart`
  - Covers double-back exit, non-home back-to-home, and overlay-first dismissal behavior.

### Calendar selected-day sorting

- Modify: `lib/features/calendar/application/calendar_provider.dart`
  - Restore newest-first as the default and add a sort-order state provider.
- Modify: `lib/features/calendar/presentation/calendar_screen.dart`
  - Add the visible sort toggle for selected-day transactions.
- Modify: `test/features/calendar/presentation/calendar_screen_test.dart`
  - Update the existing time-order test and add toggle coverage.

### Theme picker

- Modify: `lib/features/settings/presentation/settings_screen.dart`
  - Replace the trailing dropdown with a proper grouped segmented control with icon + label.
- Create: `lib/features/settings/presentation/theme_mode_tile.dart`
  - Public extracted widget for the grouped theme control.
- Create: `test/features/settings/theme_mode_tile_test.dart`
  - Covers rendering and mode switching for the new control.

### Depth-limit regression coverage

- Create: `test/features/root/navigation_depth_policy_test.dart`
  - Unit tests for level counting and level-4 blocking decisions.
- Create: `test/features/root/guarded_navigation_overlays_test.dart`
  - Covers blocked level-4 overlays and allowed level-3 overlays.

---

### Task 1: Add The Shared Navigation Depth Policy

**Files:**
- Create: `lib/features/root/application/navigation_depth_policy.dart`
- Create: `test/features/root/navigation_depth_policy_test.dart`

- [ ] **Step 1: Write the failing unit tests for depth counting**

Create `test/features/root/navigation_depth_policy_test.dart` with:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet_app/features/root/application/navigation_depth_policy.dart';

void main() {
  test('root routes are level 1', () {
    expect(navigationDepthForPath('/'), 1);
    expect(navigationDepthForPath('/timeline'), 1);
    expect(navigationDepthForPath('/tools'), 1);
    expect(navigationDepthForPath('/settings'), 1);
  });

  test('detail routes are level 2', () {
    expect(navigationDepthForPath('/calendar'), 2);
    expect(navigationDepthForPath('/statistics'), 2);
    expect(navigationDepthForPath('/recurring-expenses'), 2);
  });

  test('level 4 is rejected', () {
    expect(canEnterAdditionalLevel(currentDepth: 3), isFalse);
    expect(canEnterAdditionalLevel(currentDepth: 2), isTrue);
  });
}
```

- [ ] **Step 2: Run the depth-policy tests and verify they fail**

Run:

```powershell
& 'C:\smart wallet\flutterw.bat' test --no-pub test\features\root\navigation_depth_policy_test.dart
```

Expected: FAIL because the shared policy file does not exist yet.

- [ ] **Step 3: Create the shared policy helpers**

Create `lib/features/root/application/navigation_depth_policy.dart` with:

```dart
const maxNavigationDepth = 3;

int navigationDepthForPath(String location) {
  if (location == '/' ||
      location.startsWith('/?') ||
      location.startsWith('/timeline') ||
      location.startsWith('/tools') ||
      location.startsWith('/settings')) {
    return 1;
  }

  if (location.startsWith('/calendar') ||
      location.startsWith('/statistics') ||
      location.startsWith('/search') ||
      location.startsWith('/accounts') ||
      location.startsWith('/budgets') ||
      location.startsWith('/ocr') ||
      location.startsWith('/recurring-expenses') ||
      location.startsWith('/quick-entry')) {
    return 2;
  }

  return 2;
}

bool canEnterAdditionalLevel({required int currentDepth}) {
  return currentDepth < maxNavigationDepth;
}
```

- [ ] **Step 4: Re-run the depth-policy tests and verify they pass**

Run:

```powershell
& 'C:\smart wallet\flutterw.bat' test --no-pub test\features\root\navigation_depth_policy_test.dart
```

Expected: PASS.

- [ ] **Step 5: Commit the policy helper**

```powershell
git -C 'C:\smart wallet\app\.worktrees\calendar-home-keyboard' add `
  lib/features/root/application/navigation_depth_policy.dart `
  test/features/root/navigation_depth_policy_test.dart
git -C 'C:\smart wallet\app\.worktrees\calendar-home-keyboard' commit -m "feat: add shared navigation depth policy"
```

### Task 2: Rebuild Back Behavior At The App Shell

**Files:**
- Modify: `lib/features/root/presentation/app_shell.dart`
- Create: `test/features/root/app_shell_back_behavior_test.dart`

- [ ] **Step 1: Write the failing shell behavior tests**

Create `test/features/root/app_shell_back_behavior_test.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wallet_app/features/root/presentation/app_shell.dart';

void main() {
  testWidgets('back once from non-home returns to home', (tester) async {
    final router = GoRouter(
      initialLocation: '/calendar',
      routes: [
        ShellRoute(
          builder: (context, state, child) => AppShell(child: child),
          routes: [
            GoRoute(path: '/', builder: (_, __) => const Scaffold(body: Text('home'))),
            GoRoute(path: '/calendar', builder: (_, __) => const Scaffold(body: Text('calendar'))),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('back twice from home exits through shell guard', (tester) async {
    // Assert first back shows snackbar instead of exiting.
  });
}
```

- [ ] **Step 2: Run the shell tests and verify the current behavior fails**

Run:

```powershell
& 'C:\smart wallet\flutterw.bat' test --no-pub test\features\root\app_shell_back_behavior_test.dart
```

Expected: FAIL because the test harness is missing or the current shell behavior does not fully match the new rules.

- [ ] **Step 3: Refactor `app_shell.dart` to use the shared policy**

Update `lib/features/root/presentation/app_shell.dart` so:

```dart
import '../application/navigation_depth_policy.dart';
```

Replace `_locationToIndex` branches to keep current tab mapping, but make `_handleBackPressed` follow:

```dart
Future<bool> _handleBackPressed(BuildContext context, String location) async {
  final router = GoRouter.of(context);

  if (router.canPop()) {
    router.pop();
    return false;
  }

  if (!_isHomeLocation(location)) {
    _lastBackPressedAt = null;
    context.go('/');
    return false;
  }

  final now = DateTime.now();
  final shouldExit = _lastBackPressedAt != null &&
      now.difference(_lastBackPressedAt!) <= _exitGracePeriod;

  if (shouldExit) {
    return true;
  }

  _lastBackPressedAt = now;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      const SnackBar(
        content: Text('뒤로가기를 한 번 더 누르면 앱이 종료됩니다.'),
        duration: _exitGracePeriod,
        behavior: SnackBarBehavior.floating,
      ),
    );
  return false;
}
```

The key rule is:

- home => double back exits
- non-home => one back goes home
- existing overlay/pop route behavior stays first in priority

- [ ] **Step 4: Finish the home double-back test**

Complete the second test in `test/features/root/app_shell_back_behavior_test.dart`:

```dart
testWidgets('back once from home shows snackbar and does not exit', (tester) async {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, __) => const Scaffold(body: Text('home'))),
        ],
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();

  await tester.binding.handlePopRoute();
  await tester.pump();

  expect(find.text('뒤로가기를 한 번 더 누르면 앱이 종료됩니다.'), findsOneWidget);
  expect(find.text('home'), findsOneWidget);
});
```

- [ ] **Step 5: Run the shell tests and verify they pass**

Run:

```powershell
& 'C:\smart wallet\flutterw.bat' test --no-pub test\features\root\app_shell_back_behavior_test.dart
```

Expected: PASS.

- [ ] **Step 6: Commit the shell behavior change**

```powershell
git -C 'C:\smart wallet\app\.worktrees\calendar-home-keyboard' add `
  lib/features/root/presentation/app_shell.dart `
  test/features/root/app_shell_back_behavior_test.dart
git -C 'C:\smart wallet\app\.worktrees\calendar-home-keyboard' commit -m "feat: unify app back behavior"
```

### Task 3: Guard Overlay Entry Points At Depth 3

**Files:**
- Create: `lib/features/root/presentation/guarded_navigation_overlays.dart`
- Modify: `lib/app/router/app_router.dart`
- Modify: `lib/features/accounts/presentation/accounts_screen.dart`
- Modify: `lib/features/budgets/presentation/budget_screen.dart`
- Modify: `lib/features/recurring_expenses/presentation/recurring_expenses_screen.dart`
- Modify: `lib/features/settings/presentation/settings_screen.dart`
- Modify: `lib/features/settings/presentation/lock_setup_dialog.dart`
- Modify: `lib/features/transactions/presentation/quick_entry_screen.dart`
- Create: `test/features/root/guarded_navigation_overlays_test.dart`

- [ ] **Step 1: Write the failing guarded-overlay tests**

Create `test/features/root/guarded_navigation_overlays_test.dart` with:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet_app/features/root/application/navigation_depth_policy.dart';

void main() {
  test('level 3 can still open one overlay', () {
    expect(canOpenOverlayAtDepth(currentDepth: 2), isTrue);
  });

  test('level 4 overlay is blocked', () {
    expect(canOpenOverlayAtDepth(currentDepth: 3), isFalse);
  });
}
```

- [ ] **Step 2: Run the guarded-overlay tests and verify they fail**

Run:

```powershell
& 'C:\smart wallet\flutterw.bat' test --no-pub test\features\root\guarded_navigation_overlays_test.dart
```

Expected: FAIL because `canOpenOverlayAtDepth` and the guarded overlay helpers do not exist yet.

- [ ] **Step 3: Add explicit overlay-depth helpers**

Extend `lib/features/root/application/navigation_depth_policy.dart` with:

```dart
bool canOpenOverlayAtDepth({required int currentDepth}) {
  return currentDepth < maxNavigationDepth;
}
```

Create `lib/features/root/presentation/guarded_navigation_overlays.dart` with helpers like:

```dart
Future<T?> showGuardedDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  required int currentDepth,
}) {
  if (!canOpenOverlayAtDepth(currentDepth: currentDepth)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('더 깊게 들어갈 수 없습니다.')),
    );
    return Future.value(null);
  }

  return showDialog<T>(
    context: context,
    builder: builder,
  );
}
```

and:

```dart
Future<T?> showGuardedModalBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  required int currentDepth,
}) {
  if (!canOpenOverlayAtDepth(currentDepth: currentDepth)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('더 깊게 들어갈 수 없습니다.')),
    );
    return Future.value(null);
  }

  return showModalBottomSheet<T>(
    context: context,
    builder: (_) => builder(context),
  );
}
```

- [ ] **Step 4: Route the highest-risk overlay entry points through the guarded helpers**

In `lib/app/router/app_router.dart`, expose the current route depth in a way the shell and guarded overlay helpers can reuse:

```dart
int currentRouteDepthForState(GoRouterState state) {
  return navigationDepthForPath(state.uri.toString());
}
```

Then update these files to use `showGuardedDialog` or `showGuardedModalBottomSheet` instead of raw calls:

- `lib/features/accounts/presentation/accounts_screen.dart`
- `lib/features/budgets/presentation/budget_screen.dart`
- `lib/features/recurring_expenses/presentation/recurring_expenses_screen.dart`
- `lib/features/settings/presentation/settings_screen.dart`
- `lib/features/settings/presentation/lock_setup_dialog.dart`
- `lib/features/transactions/presentation/quick_entry_screen.dart`

Use the current route depth as the guard input. For first implementation, pass explicit depths from the hosting screen rather than introducing a more complex route-stack inspector.

- [ ] **Step 5: Run the guarded-overlay tests and targeted screen tests**

Run:

```powershell
& 'C:\smart wallet\flutterw.bat' test --no-pub `
  test\features\root\guarded_navigation_overlays_test.dart `
  test\features\calendar\presentation\calendar_screen_test.dart
```

Expected: PASS.

- [ ] **Step 6: Commit the overlay guard work**

```powershell
git -C 'C:\smart wallet\app\.worktrees\calendar-home-keyboard' add `
  lib/features/root/application/navigation_depth_policy.dart `
  lib/features/root/presentation/guarded_navigation_overlays.dart `
  lib/features/accounts/presentation/accounts_screen.dart `
  lib/features/budgets/presentation/budget_screen.dart `
  lib/features/recurring_expenses/presentation/recurring_expenses_screen.dart `
  lib/features/settings/presentation/settings_screen.dart `
  lib/features/settings/presentation/lock_setup_dialog.dart `
  lib/features/transactions/presentation/quick_entry_screen.dart `
  test/features/root/guarded_navigation_overlays_test.dart
git -C 'C:\smart wallet\app\.worktrees\calendar-home-keyboard' commit -m "feat: guard overlay entry depth"
```

### Task 4: Restore Newest-First And Add Calendar Sort Toggle

**Files:**
- Modify: `lib/features/calendar/application/calendar_provider.dart`
- Modify: `lib/features/calendar/presentation/calendar_screen.dart`
- Modify: `test/features/calendar/presentation/calendar_screen_test.dart`

- [ ] **Step 1: Add the failing sort toggle test**

In `test/features/calendar/presentation/calendar_screen_test.dart`, replace the ascending-only expectation with a default newest-first expectation and a toggle test:

```dart
testWidgets('selected day transactions default to newest first and can be reversed',
    (tester) async {
  // Build two transactions on the same date with different times.
  // Expect the later one first by default.
  // Tap the sort toggle.
  // Expect the earlier one first.
});
```

- [ ] **Step 2: Run the calendar screen test and verify it fails**

Run:

```powershell
& 'C:\smart wallet\flutterw.bat' test --no-pub test\features\calendar\presentation\calendar_screen_test.dart
```

Expected: FAIL because the provider is currently sorted oldest-first and there is no UI toggle yet.

- [ ] **Step 3: Add a sort-order provider and restore newest-first**

In `lib/features/calendar/application/calendar_provider.dart` add:

```dart
enum CalendarTransactionSortOrder {
  newestFirst,
  oldestFirst,
}

final calendarTransactionSortOrderProvider =
    StateProvider<CalendarTransactionSortOrder>(
  (ref) => CalendarTransactionSortOrder.newestFirst,
);
```

Then update `selectedCalendarTransactionsProvider`:

```dart
final sortOrder = ref.watch(calendarTransactionSortOrderProvider);
```

and:

```dart
..orderBy([
  if (sortOrder == CalendarTransactionSortOrder.newestFirst) ...[
    (t) => OrderingTerm.desc(t.occurredAt),
    (t) => OrderingTerm.desc(t.createdAt),
  ] else ...[
    (t) => OrderingTerm.asc(t.occurredAt),
    (t) => OrderingTerm.asc(t.createdAt),
  ],
]))
```

- [ ] **Step 4: Add the visible sort toggle**

In `lib/features/calendar/presentation/calendar_screen.dart`, in the selected-day transaction section header, add a compact toggle action like:

```dart
SegmentedButton<CalendarTransactionSortOrder>(
  segments: const [
    ButtonSegment(
      value: CalendarTransactionSortOrder.newestFirst,
      icon: Icon(Icons.south_rounded),
      label: Text('최신순'),
    ),
    ButtonSegment(
      value: CalendarTransactionSortOrder.oldestFirst,
      icon: Icon(Icons.north_rounded),
      label: Text('오래된순'),
    ),
  ],
  selected: {sortOrder},
  onSelectionChanged: (selection) {
    ref.read(calendarTransactionSortOrderProvider.notifier).state =
        selection.first;
  },
)
```

- [ ] **Step 5: Update the test helper ordering**

In `test/features/calendar/presentation/calendar_screen_test.dart`, keep the fake transaction list newest-first by default:

```dart
..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
```

Then add the toggle branch expectation in the widget test.

- [ ] **Step 6: Run the calendar test and verify it passes**

Run:

```powershell
& 'C:\smart wallet\flutterw.bat' test --no-pub test\features\calendar\presentation\calendar_screen_test.dart
```

Expected: PASS.

- [ ] **Step 7: Commit the calendar sort work**

```powershell
git -C 'C:\smart wallet\app\.worktrees\calendar-home-keyboard' add `
  lib/features/calendar/application/calendar_provider.dart `
  lib/features/calendar/presentation/calendar_screen.dart `
  test/features/calendar/presentation/calendar_screen_test.dart
git -C 'C:\smart wallet\app\.worktrees\calendar-home-keyboard' commit -m "feat: add calendar transaction sort toggle"
```

### Task 5: Replace The Theme Dropdown With A 3-Way Segmented Control

**Files:**
- Modify: `lib/features/settings/presentation/settings_screen.dart`
- Create: `lib/features/settings/presentation/theme_mode_tile.dart`
- Create: `test/features/settings/theme_mode_tile_test.dart`

- [ ] **Step 1: Write the failing theme tile test**

Create `test/features/settings/theme_mode_tile_test.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet_app/features/settings/presentation/theme_mode_tile.dart';

void main() {
  testWidgets('theme tile shows system light and dark as one grouped control',
      (tester) async {
    var changedTo = '';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox.shrink(),
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ThemeModeTile(
            currentMode: 'system',
            onChanged: (value) => changedTo = value,
          ),
        ),
      ),
    );

    expect(find.text('시스템'), findsOneWidget);
    expect(find.text('라이트'), findsOneWidget);
    expect(find.text('다크'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run the theme tile test and verify it fails or is incomplete**

Run:

```powershell
& 'C:\smart wallet\flutterw.bat' test --no-pub test\features\settings\theme_mode_tile_test.dart
```

Expected: FAIL because `ThemeModeTile` does not exist yet.

- [ ] **Step 3: Create `ThemeModeTile` in its own file**

Create:

```text
lib/features/settings/presentation/theme_mode_tile.dart
```

with a public widget:

```dart
class ThemeModeTile extends StatelessWidget {
  const ThemeModeTile({
    super.key,
    required this.currentMode,
    required this.onChanged,
  });
```

- [ ] **Step 4: Replace the dropdown with a segmented control**

Use a grouped 3-way control:

```dart
SegmentedButton<String>(
  segments: const [
    ButtonSegment(
      value: 'system',
      icon: Icon(Icons.brightness_auto_outlined),
      label: Text('시스템'),
    ),
    ButtonSegment(
      value: 'light',
      icon: Icon(Icons.light_mode_outlined),
      label: Text('라이트'),
    ),
    ButtonSegment(
      value: 'dark',
      icon: Icon(Icons.dark_mode_outlined),
      label: Text('다크'),
    ),
  ],
  selected: {currentMode},
  onSelectionChanged: (selection) => onChanged(selection.first),
)
```

Keep:

- icon + text
- strong selected state
- grouped layout inside the card

Then update `lib/features/settings/presentation/settings_screen.dart` to import `theme_mode_tile.dart` and replace the old private `_ThemeModeTile` usage with `ThemeModeTile`.

- [ ] **Step 5: Run the theme tile test and verify it passes**

Run:

```powershell
& 'C:\smart wallet\flutterw.bat' test --no-pub test\features\settings\theme_mode_tile_test.dart
```

Expected: PASS.

- [ ] **Step 6: Commit the theme picker change**

```powershell
git -C 'C:\smart wallet\app\.worktrees\calendar-home-keyboard' add `
  lib/features/settings/presentation/settings_screen.dart `
  lib/features/settings/presentation/theme_mode_tile.dart `
  test/features/settings/theme_mode_tile_test.dart
git -C 'C:\smart wallet\app\.worktrees\calendar-home-keyboard' commit -m "refactor: rebuild theme mode picker"
```

### Task 6: Run Final Verification Across Navigation, Calendar, And Settings

**Files:**
- Modify: none
- Verify: all files from Tasks 1-4

- [ ] **Step 1: Run targeted analyze**

Run:

```powershell
& 'C:\smart wallet\dartw.bat' analyze `
  lib\features\root\application\navigation_depth_policy.dart `
  lib\features\root\presentation\guarded_navigation_overlays.dart `
  lib\features\root\presentation\app_shell.dart `
  lib\app\router\app_router.dart `
  lib\features\calendar\application\calendar_provider.dart `
  lib\features\calendar\presentation\calendar_screen.dart `
  lib\features\settings\presentation\settings_screen.dart `
  lib\features\settings\presentation\theme_mode_tile.dart `
  test\features\root\navigation_depth_policy_test.dart `
  test\features\root\guarded_navigation_overlays_test.dart `
  test\features\root\app_shell_back_behavior_test.dart `
  test\features\calendar\presentation\calendar_screen_test.dart `
  test\features\settings\theme_mode_tile_test.dart
```

Expected: `No issues found!`

- [ ] **Step 2: Run targeted widget and unit tests**

Run:

```powershell
& 'C:\smart wallet\flutterw.bat' test --no-pub `
  test\features\root\navigation_depth_policy_test.dart `
  test\features\root\guarded_navigation_overlays_test.dart `
  test\features\root\app_shell_back_behavior_test.dart `
  test\features\calendar\presentation\calendar_screen_test.dart `
  test\features\settings\theme_mode_tile_test.dart
```

Expected: `All tests passed!`

- [ ] **Step 3: Run the Windows debug build**

Run:

```powershell
& 'C:\smart wallet\flutterw.bat' build windows --debug --no-pub
```

Expected: build succeeds and the app can be relaunched for manual QA.

- [ ] **Step 4: Commit any final test-only adjustments**

```powershell
git -C 'C:\smart wallet\app\.worktrees\calendar-home-keyboard' add -A
git -C 'C:\smart wallet\app\.worktrees\calendar-home-keyboard' commit -m "test: cover navigation depth and calendar sort behavior"
```
