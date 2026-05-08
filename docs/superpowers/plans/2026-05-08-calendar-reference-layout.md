# Calendar Reference Layout Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild the calendar detail screen so it matches the provided reference layout visually while preserving Smart Wallet's current calendar behavior.

**Architecture:** Keep the existing calendar providers, inline month/year picker flow, selected-day detail, and transaction sorting. Replace the current card-heavy presentation with a flat white page composed of a title band, a route-aware top tab band, a compact monthly totals band, a larger monthly grid, and a daily detail section that continues below the grid.

**Tech Stack:** Flutter, Riverpod, GoRouter, Drift-backed calendar providers, `flutter_test`

---

## File Structure

### Existing files to modify

- `C:/smart wallet/app/.worktrees/calendar-home-keyboard/lib/features/calendar/presentation/calendar_screen.dart`
  - reduce the screen to orchestration, page scroll structure, and state wiring
- `C:/smart wallet/app/.worktrees/calendar-home-keyboard/lib/shared/widgets/app_scaffold.dart`
  - keep white-page rendering stable for the calendar route if small layout hooks are needed
- `C:/smart wallet/app/.worktrees/calendar-home-keyboard/test/features/calendar/presentation/calendar_screen_test.dart`
  - rewrite tests around the new reference layout and preserved interactions

### New production files to create

- `C:/smart wallet/app/.worktrees/calendar-home-keyboard/lib/features/calendar/presentation/calendar_reference_tabs.dart`
  - top tab row with active underline and route navigation
- `C:/smart wallet/app/.worktrees/calendar-home-keyboard/lib/features/calendar/presentation/calendar_month_surface.dart`
  - monthly totals, weekday row, monthly grid shell, inline month/year picker surface
- `C:/smart wallet/app/.worktrees/calendar-home-keyboard/lib/features/calendar/presentation/calendar_day_detail_section.dart`
  - selected-day summary, sort toggle, transaction list container

### Why split the file

`calendar_screen.dart` is already ~1250 lines and currently mixes page structure, visual styling, picker rendering, cell layout, and daily detail. This redesign is primarily a presentation rewrite, so splitting by visual responsibility reduces the risk of IDE-only layout regressions and makes the screen testable in smaller pieces.

---

### Task 1: Split the calendar presentation into reference-layout units

**Files:**
- Create: `C:/smart wallet/app/.worktrees/calendar-home-keyboard/lib/features/calendar/presentation/calendar_reference_tabs.dart`
- Create: `C:/smart wallet/app/.worktrees/calendar-home-keyboard/lib/features/calendar/presentation/calendar_month_surface.dart`
- Create: `C:/smart wallet/app/.worktrees/calendar-home-keyboard/lib/features/calendar/presentation/calendar_day_detail_section.dart`
- Modify: `C:/smart wallet/app/.worktrees/calendar-home-keyboard/lib/features/calendar/presentation/calendar_screen.dart`
- Test: `C:/smart wallet/app/.worktrees/calendar-home-keyboard/test/features/calendar/presentation/calendar_screen_test.dart`

- [ ] **Step 1: Write the failing structure tests**

```dart
testWidgets('calendar detail renders a flat reference layout shell', (tester) async {
  await tester.pumpWidget(_buildCalendarTestApp());

  expect(find.byKey(const Key('calendar-reference-page')), findsOneWidget);
  expect(find.byKey(const Key('calendar-reference-tabs')), findsOneWidget);
  expect(find.byKey(const Key('calendar-month-surface')), findsOneWidget);
  expect(find.byKey(const Key('calendar-day-detail-section')), findsOneWidget);
});

testWidgets('legacy explorer chrome is no longer rendered', (tester) async {
  await tester.pumpWidget(_buildCalendarTestApp());

  expect(find.byKey(const Key('calendar-explorer-handle')), findsNothing);
  expect(find.byKey(const Key('calendar-explorer-panel')), findsNothing);
});
```

- [ ] **Step 2: Run the test to verify it fails for the right reason**

Run:

```powershell
& 'C:\smart wallet\flutterw.bat' test --no-pub .\app\.worktrees\calendar-home-keyboard\test\features\calendar\presentation\calendar_screen_test.dart
```

Expected:
- FAIL because the new keys and split widgets do not exist yet

- [ ] **Step 3: Create the split presentation units and reduce `calendar_screen.dart` to composition**

Create the new widgets with these entrypoints:

```dart
class CalendarReferenceTabs extends StatelessWidget {
  const CalendarReferenceTabs({
    super.key,
    required this.onOpenTimeline,
    required this.onOpenStatistics,
  });

  final VoidCallback onOpenTimeline;
  final VoidCallback onOpenStatistics;
}
```

```dart
class CalendarMonthSurface extends StatelessWidget {
  const CalendarMonthSurface({
    super.key,
    required this.displayedMonth,
    required this.monthIncome,
    required this.monthExpense,
    required this.isMonthPickerOpen,
    required this.onOpenPicker,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onPreviousYear,
    required this.onNextYear,
    required this.onSelectMonth,
    required this.onSelectDay,
    required this.selectedDay,
    required this.cells,
  });
}
```

```dart
class CalendarDayDetailSection extends StatelessWidget {
  const CalendarDayDetailSection({
    super.key,
    required this.selectedDay,
    required this.incomeTotal,
    required this.expenseTotal,
    required this.sortOrder,
    required this.onChangeSortOrder,
    required this.transactions,
  });
}
```

Reduce `CalendarScreen.build` to a `CustomScrollView` or `SingleChildScrollView` that composes these three blocks inside a white page:

```dart
return AppScaffold(
  title: '달력',
  backgroundColor: scheme.surface,
  appBarBackgroundColor: scheme.surface,
  contentPadding: EdgeInsets.zero,
  body: KeyedSubtree(
    key: const Key('calendar-reference-page'),
    child: SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CalendarReferenceTabs(
            onOpenTimeline: () => context.go('/timeline'),
            onOpenStatistics: () => context.go('/statistics'),
          ),
          CalendarMonthSurface(...),
          CalendarDayDetailSection(...),
        ],
      ),
    ),
  ),
);
```

- [ ] **Step 4: Run structure tests and analyze**

Run:

```powershell
& 'C:\smart wallet\dartw.bat' analyze .\app\.worktrees\calendar-home-keyboard\lib\features\calendar\presentation\calendar_screen.dart .\app\.worktrees\calendar-home-keyboard\lib\features\calendar\presentation\calendar_reference_tabs.dart .\app\.worktrees\calendar-home-keyboard\lib\features\calendar\presentation\calendar_month_surface.dart .\app\.worktrees\calendar-home-keyboard\lib\features\calendar\presentation\calendar_day_detail_section.dart .\app\.worktrees\calendar-home-keyboard\test\features\calendar\presentation\calendar_screen_test.dart
& 'C:\smart wallet\flutterw.bat' test --no-pub .\app\.worktrees\calendar-home-keyboard\test\features\calendar\presentation\calendar_screen_test.dart
```

Expected:
- `analyze`: PASS
- calendar screen test: PASS for structure checks, other visual expectations may still fail

- [ ] **Step 5: Commit**

```powershell
git -C 'C:\smart wallet\app\.worktrees\calendar-home-keyboard' add -- 'lib/features/calendar/presentation/calendar_screen.dart' 'lib/features/calendar/presentation/calendar_reference_tabs.dart' 'lib/features/calendar/presentation/calendar_month_surface.dart' 'lib/features/calendar/presentation/calendar_day_detail_section.dart' 'test/features/calendar/presentation/calendar_screen_test.dart'
git -C 'C:\smart wallet\app\.worktrees\calendar-home-keyboard' commit -m "refactor: split calendar reference layout surface"
```

---

### Task 2: Rebuild the title, tabs, and monthly totals bands to match the reference hierarchy

**Files:**
- Modify: `C:/smart wallet/app/.worktrees/calendar-home-keyboard/lib/features/calendar/presentation/calendar_reference_tabs.dart`
- Modify: `C:/smart wallet/app/.worktrees/calendar-home-keyboard/lib/features/calendar/presentation/calendar_month_surface.dart`
- Test: `C:/smart wallet/app/.worktrees/calendar-home-keyboard/test/features/calendar/presentation/calendar_screen_test.dart`

- [ ] **Step 1: Write the failing hierarchy tests**

```dart
testWidgets('title, tabs, and monthly totals render in reference order', (tester) async {
  await tester.pumpWidget(_buildCalendarTestApp());

  expect(find.byKey(const Key('calendar-month-title')), findsOneWidget);
  expect(find.byKey(const Key('calendar-reference-tabs')), findsOneWidget);
  expect(find.byKey(const Key('calendar-month-totals')), findsOneWidget);
  expect(find.byKey(const Key('calendar-month-grid')), findsOneWidget);
});

testWidgets('calendar tab is active and routes are wired for sibling tabs', (tester) async {
  await tester.pumpWidget(_buildCalendarNavigationTestApp());

  expect(find.byKey(const Key('calendar-tab-active-indicator')), findsOneWidget);

  await tester.tap(find.byKey(const Key('calendar-tab-transactions')));
  await tester.pumpAndSettle();
  expect(find.text('내역'), findsOneWidget);
});
```

- [ ] **Step 2: Run the test to verify it fails**

Run:

```powershell
& 'C:\smart wallet\flutterw.bat' test --no-pub .\app\.worktrees\calendar-home-keyboard\test\features\calendar\presentation\calendar_screen_test.dart
```

Expected:
- FAIL because the new hierarchy keys and tab navigation contract do not exist yet

- [ ] **Step 3: Implement the title band, tab band, and totals band**

Use a flat white structure with no card wrappers:

```dart
Padding(
  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
  child: Row(
    children: [
      InkWell(
        key: const Key('calendar-month-title'),
        onTap: onOpenPicker,
        child: Text(
          _formatMonth(displayedMonth),
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: scheme.onSurface,
          ),
        ),
      ),
      const Spacer(),
      IconButton(
        key: const Key('calendar-previous-month'),
        onPressed: onPreviousMonth,
        icon: const Icon(Icons.chevron_left_rounded),
      ),
      IconButton(
        key: const Key('calendar-next-month'),
        onPressed: onNextMonth,
        icon: const Icon(Icons.chevron_right_rounded),
      ),
    ],
  ),
)
```

```dart
Container(
  key: const Key('calendar-month-totals'),
  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text.rich(TextSpan(children: [
        const TextSpan(text: '지출 '),
        TextSpan(text: currency.format(monthExpense), style: expenseStyle),
      ])),
      const SizedBox(height: 8),
      Text.rich(TextSpan(children: [
        const TextSpan(text: '수입 '),
        TextSpan(text: currency.format(monthIncome), style: incomeStyle),
      ])),
    ],
  ),
)
```

For the tabs, keep the active underline thin and quiet:

```dart
Container(
  key: const Key('calendar-reference-tabs'),
  height: 56,
  decoration: BoxDecoration(
    border: Border(
      bottom: BorderSide(color: scheme.outlineVariant),
    ),
  ),
  child: Row(
    children: [
      _CalendarTopTab(...),
      _CalendarTopTab(...),
      _CalendarTopTab(...),
    ],
  ),
)
```

- [ ] **Step 4: Run tests and verify layout still fits compact width**

Run:

```powershell
& 'C:\smart wallet\flutterw.bat' test --no-pub .\app\.worktrees\calendar-home-keyboard\test\features\calendar\presentation\calendar_screen_test.dart --plain-name "title, tabs, and monthly totals render in reference order"
& 'C:\smart wallet\flutterw.bat' test --no-pub .\app\.worktrees\calendar-home-keyboard\test\features\calendar\presentation\calendar_screen_test.dart --plain-name "calendar tab is active and routes are wired for sibling tabs"
```

Expected:
- both PASS

- [ ] **Step 5: Commit**

```powershell
git -C 'C:\smart wallet\app\.worktrees\calendar-home-keyboard' add -- 'lib/features/calendar/presentation/calendar_reference_tabs.dart' 'lib/features/calendar/presentation/calendar_month_surface.dart' 'test/features/calendar/presentation/calendar_screen_test.dart'
git -C 'C:\smart wallet\app\.worktrees\calendar-home-keyboard' commit -m "refactor: rebuild calendar header and totals bands"
```

---

### Task 3: Flatten the monthly grid so the calendar becomes the visual center

**Files:**
- Modify: `C:/smart wallet/app/.worktrees/calendar-home-keyboard/lib/features/calendar/presentation/calendar_month_surface.dart`
- Test: `C:/smart wallet/app/.worktrees\calendar-home-keyboard/test/features/calendar/presentation/calendar_screen_test.dart`

- [ ] **Step 1: Write the failing monthly-grid visual tests**

```dart
testWidgets('monthly grid renders as a flat surface without boxed day chrome', (tester) async {
  await tester.pumpWidget(_buildCalendarTestApp());

  expect(find.byKey(const Key('calendar-month-grid-shell')), findsNothing);
  expect(find.byKey(const Key('calendar-flat-month-grid')), findsOneWidget);
});

testWidgets('selected day uses subtle highlight while normal cells stay flat', (tester) async {
  await tester.pumpWidget(_buildCalendarTestApp());

  final selected = tester.widget<DecoratedBox>(
    find.byKey(const Key('calendar-selected-day-highlight')),
  );

  expect(selected.decoration, isA<BoxDecoration>());
});
```

- [ ] **Step 2: Run the tests to verify they fail**

Run:

```powershell
& 'C:\smart wallet\flutterw.bat' test --no-pub .\app\.worktrees\calendar-home-keyboard\test\features\calendar\presentation\calendar_screen_test.dart
```

Expected:
- FAIL because the grid still uses heavier wrappers or lacks the new keys

- [ ] **Step 3: Flatten the month grid and enlarge its share of the viewport**

Render the grid directly on the white page surface:

```dart
Padding(
  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
  child: Column(
    key: const Key('calendar-flat-month-grid'),
    children: [
      _WeekdayHeaderRow(...),
      const SizedBox(height: 18),
      GridView.builder(
        key: const Key('calendar-month-grid'),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          mainAxisSpacing: 18,
          crossAxisSpacing: 10,
          childAspectRatio: 0.78,
        ),
        itemBuilder: ...
      ),
    ],
  ),
)
```

For cells, remove mini-card chrome and keep fixed text slots:

```dart
class _FlatCalendarDayCell extends StatelessWidget {
  const _FlatCalendarDayCell(...);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: _SelectedDayBubble(...),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(child: _AmountText(...income...)),
            const SizedBox(width: 6),
            Expanded(child: _AmountText(...expense...)),
          ],
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: Run compact-layout tests and a Windows debug build**

Run:

```powershell
& 'C:\smart wallet\flutterw.bat' test --no-pub .\app\.worktrees\calendar-home-keyboard\test\features\calendar\presentation\calendar_screen_test.dart --plain-name "monthly grid renders as a flat surface without boxed day chrome"
& 'C:\smart wallet\flutterw.bat' build windows --debug --no-pub
```

Expected:
- grid visual tests PASS
- Windows debug build PASS with no overflow regressions

- [ ] **Step 5: Commit**

```powershell
git -C 'C:\smart wallet\app\.worktrees\calendar-home-keyboard' add -- 'lib/features/calendar/presentation/calendar_month_surface.dart' 'test/features/calendar/presentation/calendar_screen_test.dart'
git -C 'C:\smart wallet\app\.worktrees\calendar-home-keyboard' commit -m "refactor: flatten calendar month grid chrome"
```

---

### Task 4: Keep daily detail below the grid as the persistent day view

**Files:**
- Modify: `C:/smart wallet/app/.worktrees/calendar-home-keyboard/lib/features/calendar/presentation/calendar_day_detail_section.dart`
- Modify: `C:/smart wallet/app/.worktrees/calendar-home-keyboard/lib/features/calendar/presentation/calendar_screen.dart`
- Test: `C:/smart wallet/app/.worktrees/calendar-home-keyboard/test/features/calendar/presentation/calendar_screen_test.dart`

- [ ] **Step 1: Write the failing day-detail continuity tests**

```dart
testWidgets('selected-day detail defaults to today below the monthly grid', (tester) async {
  await tester.pumpWidget(_buildCalendarTestApp(now: DateTime(2026, 5, 8)));

  expect(find.byKey(const Key('calendar-day-detail-section')), findsOneWidget);
  expect(find.textContaining('2026.05.08'), findsOneWidget);
});

testWidgets('tapping a date updates only the daily detail section', (tester) async {
  await tester.pumpWidget(_buildCalendarTestApp());

  await tester.tap(find.byKey(const Key('calendar-day-2026-05-12')));
  await tester.pumpAndSettle();

  expect(find.textContaining('2026.05.12'), findsOneWidget);
  expect(find.byKey(const Key('calendar-flat-month-grid')), findsOneWidget);
});
```

- [ ] **Step 2: Run the tests to verify they fail**

Run:

```powershell
& 'C:\smart wallet\flutterw.bat' test --no-pub .\app\.worktrees\calendar-home-keyboard\test\features\calendar\presentation\calendar_screen_test.dart
```

Expected:
- FAIL because the new daily-detail keys and title expectations do not exist yet

- [ ] **Step 3: Rebuild the daily detail as a flat continuation section**

Keep the behavior, but reduce card feel:

```dart
Container(
  key: const Key('calendar-day-detail-section'),
  padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
  decoration: BoxDecoration(
    border: Border(
      top: BorderSide(color: scheme.outlineVariant),
    ),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(_formatSelectedDate(selectedDay), style: headingStyle),
      const SizedBox(height: 12),
      _DayTotalsRow(...),
      const SizedBox(height: 18),
      _SortToggleRow(...),
      const SizedBox(height: 16),
      _TransactionList(...),
    ],
  ),
)
```

Ensure default selected day is still today when available:

```dart
final initialSelectedDay = _resolveInitialSelectedDay(
  displayedMonth: displayedMonth,
  now: clock.now(),
);
```

- [ ] **Step 4: Run day-detail tests and verify sort toggle still works**

Run:

```powershell
& 'C:\smart wallet\flutterw.bat' test --no-pub .\app\.worktrees\calendar-home-keyboard\test\features\calendar\presentation\calendar_screen_test.dart --plain-name "selected-day detail defaults to today below the monthly grid"
& 'C:\smart wallet\flutterw.bat' test --no-pub .\app\.worktrees\calendar-home-keyboard\test\features\calendar\presentation\calendar_screen_test.dart --plain-name "tapping a date updates only the daily detail section"
```

Expected:
- both PASS

- [ ] **Step 5: Commit**

```powershell
git -C 'C:\smart wallet\app\.worktrees\calendar-home-keyboard' add -- 'lib/features/calendar/presentation/calendar_day_detail_section.dart' 'lib/features/calendar/presentation/calendar_screen.dart' 'test/features/calendar/presentation/calendar_screen_test.dart'
git -C 'C:\smart wallet\app\.worktrees\calendar-home-keyboard' commit -m "refactor: continue calendar into daily detail section"
```

---

### Task 5: Preserve inline month picker and back behavior inside the new layout

**Files:**
- Modify: `C:/smart wallet/app/.worktrees/calendar-home-keyboard/lib/features/calendar/presentation/calendar_month_surface.dart`
- Modify: `C:/smart wallet/app/.worktrees/calendar-home-keyboard/lib/features/calendar/presentation/calendar_screen.dart`
- Test: `C:/smart wallet/app/.worktrees/calendar-home-keyboard/test/features/calendar/presentation/calendar_screen_test.dart`

- [ ] **Step 1: Write the failing picker-regression tests**

```dart
testWidgets('month title still opens inline picker inside the calendar surface', (tester) async {
  await tester.pumpWidget(_buildCalendarTestApp());

  await tester.tap(find.byKey(const Key('calendar-month-title')));
  await tester.pumpAndSettle();

  expect(find.byKey(const Key('calendar-inline-month-picker')), findsOneWidget);
  expect(find.byKey(const Key('calendar-flat-month-grid')), findsNothing);
});

testWidgets('back closes picker before leaving the calendar screen', (tester) async {
  await tester.pumpWidget(_buildCalendarTestApp());

  await tester.tap(find.byKey(const Key('calendar-month-title')));
  await tester.pumpAndSettle();

  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();

  expect(find.byKey(const Key('calendar-inline-month-picker')), findsNothing);
  expect(find.byKey(const Key('calendar-flat-month-grid')), findsOneWidget);
});
```

- [ ] **Step 2: Run the tests to verify they fail**

Run:

```powershell
& 'C:\smart wallet\flutterw.bat' test --no-pub .\app\.worktrees\calendar-home-keyboard\test\features\calendar\presentation\calendar_screen_test.dart
```

Expected:
- FAIL because the picker is not yet wired into the refactored month surface

- [ ] **Step 3: Reattach existing picker behavior to the refactored layout**

Inside `CalendarMonthSurface`, branch only the body region:

```dart
if (isMonthPickerOpen) {
  return _InlineMonthPickerSurface(
    key: const Key('calendar-inline-month-picker'),
    year: displayedMonth.year,
    onPreviousYear: onPreviousYear,
    onNextYear: onNextYear,
    onSelectMonth: onSelectMonth,
  );
}

return _FlatMonthGridSurface(
  key: const Key('calendar-flat-month-grid'),
  ...
);
```

Inside `CalendarScreen`, preserve the current `PopScope` or equivalent callback:

```dart
Future<bool> _handleCalendarBack() async {
  if (ref.read(calendarMonthPickerOpenProvider)) {
    ref.read(calendarMonthPickerOpenProvider.notifier).state = false;
    return false;
  }
  return true;
}
```

- [ ] **Step 4: Run the full calendar screen test suite and final verification build**

Run:

```powershell
& 'C:\smart wallet\dartw.bat' analyze .\app\.worktrees\calendar-home-keyboard\lib\features\calendar\presentation\calendar_screen.dart .\app\.worktrees\calendar-home-keyboard\lib\features\calendar\presentation\calendar_reference_tabs.dart .\app\.worktrees\calendar-home-keyboard\lib\features\calendar\presentation\calendar_month_surface.dart .\app\.worktrees\calendar-home-keyboard\lib\features\calendar\presentation\calendar_day_detail_section.dart .\app\.worktrees\calendar-home-keyboard\test\features\calendar\presentation\calendar_screen_test.dart
& 'C:\smart wallet\flutterw.bat' test --no-pub .\app\.worktrees\calendar-home-keyboard\test\features\calendar\presentation\calendar_screen_test.dart
& 'C:\smart wallet\flutterw.bat' build windows --debug --no-pub
```

Expected:
- `analyze`: PASS
- calendar screen tests: PASS
- Windows debug build: PASS

- [ ] **Step 5: Commit**

```powershell
git -C 'C:\smart wallet\app\.worktrees\calendar-home-keyboard' add -- 'lib/features/calendar/presentation/calendar_screen.dart' 'lib/features/calendar/presentation/calendar_month_surface.dart' 'test/features/calendar/presentation/calendar_screen_test.dart'
git -C 'C:\smart wallet\app\.worktrees\calendar-home-keyboard' commit -m "feat: apply reference calendar layout"
```

---

## Self-Review

### Spec coverage

- white full-page surface: covered by Tasks 1 and 2
- reference-style title, tabs, totals, grid bands: covered by Tasks 2 and 3
- selected-day detail below the grid: covered by Task 4
- preserved month picker and back behavior: covered by Task 5
- preserved interactions and routing: covered by Tasks 2, 4, and 5

No spec sections are currently uncovered.

### Placeholder scan

- no `TODO`, `TBD`, or vague “handle later” language remains
- every task has exact files, commands, expected outcomes, and code targets

### Type consistency

- `CalendarReferenceTabs`, `CalendarMonthSurface`, and `CalendarDayDetailSection` are defined consistently across tasks
- keys introduced in tests match the implementation names used later in the plan

