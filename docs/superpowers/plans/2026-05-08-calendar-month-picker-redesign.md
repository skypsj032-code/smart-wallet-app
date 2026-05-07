# Calendar Month Picker Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace chip-based calendar modes with a monthly calendar plus inline month/year picker, remove day mode, and keep selected-day detail below the calendar.

**Architecture:** Simplify the calendar screen to a primary monthly view backed by a small state model: displayed month, selected day, picker-open flag, and transaction sort order. Remove `CalendarViewMode`-driven UI switching from the presentation layer and replace it with an in-place month/year picker that swaps the calendar body while staying in the same route and content block.

**Tech Stack:** Flutter, Flutter Riverpod, Drift, existing `CalendarSnapshot` / selected-day providers, widget tests with `flutter_test`

---

## File Structure

### Existing files to modify

- `C:/smart wallet/app/.worktrees/calendar-home-keyboard/lib/features/calendar/application/calendar_provider.dart`
  - remove unused day/week/year mode state
  - introduce month-picker state and simplified displayed month state
  - keep selected-day transaction sorting behavior
- `C:/smart wallet/app/.worktrees/calendar-home-keyboard/lib/features/calendar/presentation/calendar_screen.dart`
  - remove top chip-based mode controls
  - rebuild header, month summary, inline picker, and selected-day detail structure
- `C:/smart wallet/app/.worktrees/calendar-home-keyboard/test/features/calendar/presentation/calendar_screen_test.dart`
  - rewrite mode-based tests into monthly view + inline picker tests

### No new production files expected

This work should stay inside the existing calendar provider and screen unless the refactor proves impossible without creating a small private widget file. Start without splitting.

---

### Task 1: Replace `CalendarViewMode` state with month-centered state

**Files:**
- Modify: `C:/smart wallet/app/.worktrees/calendar-home-keyboard/lib/features/calendar/application/calendar_provider.dart`
- Test: `C:/smart wallet/app/.worktrees/calendar-home-keyboard/test/features/calendar/presentation/calendar_screen_test.dart`

- [ ] **Step 1: Write the failing provider-facing widget tests**

Add or rewrite tests so they assert the new state model instead of old mode chips:

```dart
testWidgets('month label opens inline picker and hides the month grid', (tester) async {
  await tester.pumpWidget(_buildCalendarTestApp());

  await tester.tap(find.text('2026.05'));
  await tester.pumpAndSettle();

  expect(find.byKey(const Key('calendar-inline-month-picker')), findsOneWidget);
  expect(find.byKey(const Key('calendar-month-grid')), findsNothing);
});

testWidgets('picker shows 12 months in a 3 by 4 grid', (tester) async {
  await tester.pumpWidget(_buildCalendarTestApp());

  await tester.tap(find.text('2026.05'));
  await tester.pumpAndSettle();

  expect(find.text('1월'), findsOneWidget);
  expect(find.text('12월'), findsOneWidget);
  expect(find.byKey(const Key('calendar-inline-month-picker')), findsOneWidget);
});
```

- [ ] **Step 2: Run tests to verify they fail for the right reason**

Run:

```powershell
& 'C:\dev\flutter\bin\flutter.bat' test --no-pub .\test\features\calendar\presentation\calendar_screen_test.dart
```

Expected:
- FAIL because the current screen still exposes chip-based modes and no inline picker key exists.

- [ ] **Step 3: Remove old mode providers and add month-centered state**

Refactor `calendar_provider.dart` so the state model is centered on a displayed month and picker visibility:

```dart
final displayedCalendarMonthProvider =
    StateProvider<DateTime>((ref) => _normalizeMonth(DateTime.now()));

final calendarMonthPickerOpenProvider = StateProvider<bool>((ref) => false);

DateTime _normalizeMonth(DateTime value) => DateTime(value.year, value.month, 1);
```

Preserve:

```dart
final calendarTransactionSortOrderProvider =
    StateProvider<CalendarTransactionSortOrder>(
  (ref) => CalendarTransactionSortOrder.newestFirst,
);
```

Update any monthly summary and selected-day providers so they derive from `displayedCalendarMonthProvider` instead of `CalendarViewMode.month`.

- [ ] **Step 4: Run tests to verify state refactor still fails only at presentation layer**

Run:

```powershell
& 'C:\dev\flutter\bin\dart.bat' analyze .\lib\features\calendar\application\calendar_provider.dart
& 'C:\dev\flutter\bin\flutter.bat' test --no-pub .\test\features\calendar\presentation\calendar_screen_test.dart
```

Expected:
- analyze PASS
- widget tests still FAIL because the screen is not yet rewritten

- [ ] **Step 5: Commit**

```powershell
git add -- 'lib/features/calendar/application/calendar_provider.dart' 'test/features/calendar/presentation/calendar_screen_test.dart'
git commit -m "refactor: center calendar state on displayed month"
```

---

### Task 2: Rebuild the calendar header and remove mode chips

**Files:**
- Modify: `C:/smart wallet/app/.worktrees/calendar-home-keyboard/lib/features/calendar/presentation/calendar_screen.dart`
- Test: `C:/smart wallet/app/.worktrees/calendar-home-keyboard/test/features/calendar/presentation/calendar_screen_test.dart`

- [ ] **Step 1: Write failing tests for the new header**

Add tests that assert:
- no week/day/month/year chips
- month label exists
- month arrows still exist

```dart
testWidgets('calendar header uses month label instead of mode chips', (tester) async {
  await tester.pumpWidget(_buildCalendarTestApp());

  expect(find.text('주간'), findsNothing);
  expect(find.text('일별'), findsNothing);
  expect(find.text('월별'), findsNothing);
  expect(find.text('연별'), findsNothing);
  expect(find.text('2026.05'), findsOneWidget);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```powershell
& 'C:\dev\flutter\bin\flutter.bat' test --no-pub .\test\features\calendar\presentation\calendar_screen_test.dart
```

Expected:
- FAIL because the old chips are still present.

- [ ] **Step 3: Replace header UI with month label trigger**

In `calendar_screen.dart`, remove the chip group and replace it with a simple header:

```dart
Row(
  children: [
    InkWell(
      key: const Key('calendar-month-label'),
      onTap: () => ref.read(calendarMonthPickerOpenProvider.notifier).state = true,
      child: Text(
        _formatMonth(displayedMonth),
        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
      ),
    ),
    const Spacer(),
    IconButton(
      key: const Key('calendar-previous-period'),
      onPressed: () => _moveMonth(ref, -1),
      icon: const Icon(Icons.chevron_left_rounded),
    ),
    IconButton(
      key: const Key('calendar-next-period'),
      onPressed: () => _moveMonth(ref, 1),
      icon: const Icon(Icons.chevron_right_rounded),
    ),
  ],
)
```

Also remove all rendering branches based on `CalendarViewMode.day`, `week`, and `year` from the top-level content flow.

- [ ] **Step 4: Run tests to verify the new header passes**

Run:

```powershell
& 'C:\dev\flutter\bin\flutter.bat' test --no-pub .\test\features\calendar\presentation\calendar_screen_test.dart
```

Expected:
- header-related tests PASS
- picker behavior tests may still FAIL until Task 3

- [ ] **Step 5: Commit**

```powershell
git add -- 'lib/features/calendar/presentation/calendar_screen.dart' 'test/features/calendar/presentation/calendar_screen_test.dart'
git commit -m "refactor: replace calendar mode chips with month header"
```

---

### Task 3: Add the inline month/year picker

**Files:**
- Modify: `C:/smart wallet/app/.worktrees/calendar-home-keyboard/lib/features/calendar/presentation/calendar_screen.dart`
- Test: `C:/smart wallet/app/.worktrees/calendar-home-keyboard/test/features/calendar/presentation/calendar_screen_test.dart`

- [ ] **Step 1: Write failing tests for picker open/close and month selection**

```dart
testWidgets('tapping month label opens the inline picker', (tester) async {
  await tester.pumpWidget(_buildCalendarTestApp());

  await tester.tap(find.byKey(const Key('calendar-month-label')));
  await tester.pumpAndSettle();

  expect(find.byKey(const Key('calendar-inline-month-picker')), findsOneWidget);
});

testWidgets('tapping a month in the picker returns to the month grid', (tester) async {
  await tester.pumpWidget(_buildCalendarTestApp());

  await tester.tap(find.byKey(const Key('calendar-month-label')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('11월'));
  await tester.pumpAndSettle();

  expect(find.byKey(const Key('calendar-inline-month-picker')), findsNothing);
  expect(find.text('2026.11'), findsOneWidget);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```powershell
& 'C:\dev\flutter\bin\flutter.bat' test --no-pub .\test\features\calendar\presentation\calendar_screen_test.dart
```

Expected:
- FAIL because no inline picker exists yet.

- [ ] **Step 3: Implement inline picker body**

Add a body branch inside `calendar_screen.dart`:

```dart
final isMonthPickerOpen = ref.watch(calendarMonthPickerOpenProvider);

Widget body = isMonthPickerOpen
    ? _InlineMonthPicker(
        year: displayedMonth.year,
        onPreviousYear: () => _shiftPickerYear(ref, -1),
        onNextYear: () => _shiftPickerYear(ref, 1),
        onSelectMonth: (month) => _selectMonth(ref, displayedMonth.year, month),
      )
    : _MonthCalendarContent(...);
```

The picker widget should expose:

```dart
Wrap(
  key: const Key('calendar-inline-month-picker'),
  spacing: AppSpacing.sm,
  runSpacing: AppSpacing.sm,
  children: List.generate(12, (index) {
    final month = index + 1;
    return SizedBox(
      width: monthCellWidth,
      child: OutlinedButton(
        onPressed: () => onSelectMonth(month),
        child: Text('${month}월'),
      ),
    );
  }),
)
```

Use a 3-column layout by computing width from available space, not fixed absolute widths.

- [ ] **Step 4: Run tests to verify picker behavior passes**

Run:

```powershell
& 'C:\dev\flutter\bin\flutter.bat' test --no-pub .\test\features\calendar\presentation\calendar_screen_test.dart
```

Expected:
- picker open/close tests PASS

- [ ] **Step 5: Commit**

```powershell
git add -- 'lib/features/calendar/presentation/calendar_screen.dart' 'test/features/calendar/presentation/calendar_screen_test.dart'
git commit -m "feat: add inline calendar month picker"
```

---

### Task 4: Rebuild the monthly layout around the calendar body

**Files:**
- Modify: `C:/smart wallet/app/.worktrees/calendar-home-keyboard/lib/features/calendar/presentation/calendar_screen.dart`
- Test: `C:/smart wallet/app/.worktrees/calendar-home-keyboard/test/features/calendar/presentation/calendar_screen_test.dart`

- [ ] **Step 1: Write failing tests for monthly summary and dominant grid**

```dart
testWidgets('month view shows expense and income summary above the grid', (tester) async {
  await tester.pumpWidget(_buildCalendarTestApp());

  expect(find.text('지출'), findsOneWidget);
  expect(find.text('수입'), findsOneWidget);
  expect(find.byKey(const Key('calendar-month-grid')), findsOneWidget);
});
```

- [ ] **Step 2: Run test to verify it fails if structure is not yet correct**

Run:

```powershell
& 'C:\dev\flutter\bin\flutter.bat' test --no-pub .\test\features\calendar\presentation\calendar_screen_test.dart
```

Expected:
- FAIL if the old summary/card hierarchy still leaks through.

- [ ] **Step 3: Simplify the monthly summary to two text rows**

Refactor the top summary in `calendar_screen.dart`:

```dart
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text('지출 ${_formatCurrency(snapshot.expenseTotal)}'),
    const SizedBox(height: 8),
    Text('수입 ${_formatCurrency(snapshot.incomeTotal)}'),
  ],
)
```

Then ensure the monthly calendar grid is the largest visual block below it, not wrapped in extra control chrome.

- [ ] **Step 4: Run tests to verify layout behavior passes**

Run:

```powershell
& 'C:\dev\flutter\bin\flutter.bat' test --no-pub .\test\features\calendar\presentation\calendar_screen_test.dart
```

Expected:
- monthly summary tests PASS
- existing compact overflow tests remain green

- [ ] **Step 5: Commit**

```powershell
git add -- 'lib/features/calendar/presentation/calendar_screen.dart' 'test/features/calendar/presentation/calendar_screen_test.dart'
git commit -m "refactor: rebuild monthly calendar layout"
```

---

### Task 5: Keep selected-day detail as the replacement for day mode

**Files:**
- Modify: `C:/smart wallet/app/.worktrees/calendar-home-keyboard/lib/features/calendar/presentation/calendar_screen.dart`
- Test: `C:/smart wallet/app/.worktrees\calendar-home-keyboard/test/features/calendar/presentation/calendar_screen_test.dart`

- [ ] **Step 1: Write failing tests for selected-day detail after month changes**

```dart
testWidgets('selected day detail updates after tapping a date in month view', (tester) async {
  await tester.pumpWidget(_buildCalendarTestApp());

  await tester.tap(find.byKey(const Key('calendar-day-2026-05-10')));
  await tester.pumpAndSettle();

  expect(find.byKey(const Key('calendar-selected-day-card')), findsOneWidget);
  expect(find.byKey(const Key('calendar-transaction-sort-toggle')), findsOneWidget);
});
```

- [ ] **Step 2: Run test to verify it fails if detail keys or behavior are missing**

Run:

```powershell
& 'C:\dev\flutter\bin\flutter.bat' test --no-pub .\test\features\calendar\presentation\calendar_screen_test.dart
```

Expected:
- FAIL if detail section no longer updates correctly after the refactor.

- [ ] **Step 3: Keep detail section mounted only for month view and wire sort toggle**

In `calendar_screen.dart`, keep this structure below the grid:

```dart
if (!isMonthPickerOpen && effectiveSelectedDate != null)
  _CalendarSelectedDayCard(
    key: const Key('calendar-selected-day-card'),
    ...
    sortOrder: sortOrder,
    onChangeSortOrder: (value) {
      ref.read(calendarTransactionSortOrderProvider.notifier).state = value;
    },
  ),
```

Also give the sort segmented control a key:

```dart
key: const Key('calendar-transaction-sort-toggle')
```

- [ ] **Step 4: Run tests to verify selected-day detail still works**

Run:

```powershell
& 'C:\dev\flutter\bin\flutter.bat' test --no-pub .\test\features\calendar\presentation\calendar_screen_test.dart
```

Expected:
- selected-day detail tests PASS
- sort toggle tests PASS

- [ ] **Step 5: Commit**

```powershell
git add -- 'lib/features/calendar/presentation/calendar_screen.dart' 'test/features/calendar/presentation/calendar_screen_test.dart'
git commit -m "refactor: keep selected-day detail below month calendar"
```

---

### Task 6: Back behavior closes the inline picker first

**Files:**
- Modify: `C:/smart wallet/app/.worktrees/calendar-home-keyboard/lib/features/calendar/presentation/calendar_screen.dart`
- Test: `C:/smart wallet/app/.worktrees/calendar-home-keyboard/test/features/calendar/presentation/calendar_screen_test.dart`

- [ ] **Step 1: Write failing test for back closing the picker**

```dart
testWidgets('back closes the month picker before leaving calendar', (tester) async {
  await tester.pumpWidget(_buildCalendarTestApp());

  await tester.tap(find.byKey(const Key('calendar-month-label')));
  await tester.pumpAndSettle();

  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();

  expect(find.byKey(const Key('calendar-inline-month-picker')), findsNothing);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```powershell
& 'C:\dev\flutter\bin\flutter.bat' test --no-pub .\test\features\calendar\presentation\calendar_screen_test.dart
```

Expected:
- FAIL because back currently follows app-level rules instead of closing the inline picker.

- [ ] **Step 3: Implement picker-close-first back handling**

Inside `calendar_screen.dart`, wrap the body with:

```dart
PopScope(
  canPop: !isMonthPickerOpen,
  onPopInvokedWithResult: (didPop, result) {
    if (!didPop && isMonthPickerOpen) {
      ref.read(calendarMonthPickerOpenProvider.notifier).state = false;
    }
  },
  child: ...
)
```

Make sure this only handles the inline picker state and does not fight the app-shell back policy when the picker is already closed.

- [ ] **Step 4: Run tests to verify back behavior passes**

Run:

```powershell
& 'C:\dev\flutter\bin\flutter.bat' test --no-pub .\test\features\calendar\presentation\calendar_screen_test.dart
```

Expected:
- back-close-picker test PASS

- [ ] **Step 5: Commit**

```powershell
git add -- 'lib/features/calendar/presentation/calendar_screen.dart' 'test/features/calendar/presentation/calendar_screen_test.dart'
git commit -m "feat: close inline month picker on back"
```

---

### Task 7: Final verification

**Files:**
- Verify: `C:/smart wallet/app/.worktrees/calendar-home-keyboard/lib/features/calendar/application/calendar_provider.dart`
- Verify: `C:/smart wallet/app/.worktrees/calendar-home-keyboard/lib/features/calendar/presentation/calendar_screen.dart`
- Verify: `C:/smart wallet/app/.worktrees/calendar-home-keyboard/test/features/calendar/presentation/calendar_screen_test.dart`

- [ ] **Step 1: Run focused analyze**

Run:

```powershell
& 'C:\dev\flutter\bin\dart.bat' analyze .\lib\features\calendar\application\calendar_provider.dart .\lib\features\calendar\presentation\calendar_screen.dart .\test\features\calendar\presentation\calendar_screen_test.dart
```

Expected:
- `No issues found!`

- [ ] **Step 2: Run focused calendar widget tests**

Run:

```powershell
& 'C:\dev\flutter\bin\flutter.bat' test --no-pub .\test\features\calendar\presentation\calendar_screen_test.dart
```

Expected:
- `All tests passed!`

- [ ] **Step 3: Run windows debug build**

Run:

```powershell
& 'C:\dev\flutter\bin\flutter.bat' build windows --debug --no-pub
```

Expected:
- successful build of `build\windows\x64\runner\Debug\smart_wallet_app.exe`

- [ ] **Step 4: Commit final cleanups if needed**

```powershell
git status --short
```

If there are verification-driven cleanup edits:

```powershell
git add -A
git commit -m "test: finalize calendar month picker redesign"
```

If clean, skip commit.

---

## Self-Review

### Spec coverage

- remove chip-based modes: covered by Task 2
- remove day mode: covered by Tasks 1 and 2
- inline year/month picker inside same area: covered by Task 3
- 3 x 4 month grid: covered by Task 3
- monthly summary above main grid: covered by Task 4
- selected-day detail replaces day mode: covered by Task 5
- back closes picker before leaving calendar: covered by Task 6
- focused verification: covered by Task 7

No uncovered spec requirements remain.

### Placeholder scan

No `TBD`, `TODO`, or “implement later” placeholders remain. Every task includes file paths, expected test behavior, commands, and commit checkpoints.

### Type consistency

The plan consistently uses:

- `displayedCalendarMonthProvider`
- `calendarMonthPickerOpenProvider`
- `calendarTransactionSortOrderProvider`
- `calendar-inline-month-picker`
- `calendar-month-label`
- `calendar-selected-day-card`
- `calendar-transaction-sort-toggle`

These identifiers should be used consistently during implementation.
