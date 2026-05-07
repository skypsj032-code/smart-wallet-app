# Calendar Home And Keyboard Policy Implementation Plan

Implementation note on 2026-05-07:
- Final calendar modes are `week / day / month / year`.
- `week` stays, and `day` is added as a separate detail mode.
- Inline entry is attached to the selected-day detail card in calendar flow.

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rework calendar navigation to `일별 / 월별 / 연별`, keep home calendar/statistics previews always visible, and introduce an app-wide keyboard avoidance policy so input UIs stop being covered.

**Architecture:** Treat this as three linked but separable units: a global input-layout policy in shared scaffold/helpers, always-visible home preview cards, and a richer calendar screen with inline date-based quick entry. Reuse existing providers and quick-entry form state where possible instead of inventing a second transaction entry model.

**Tech Stack:** Flutter, Riverpod, Drift, GoRouter, widget tests, Flutter analyze/test/build.

---

## File Map

### Shared layout and keyboard policy

- Modify: `lib/shared/widgets/app_scaffold.dart`
  - Add a reusable keyboard-aware body wrapper policy.
- Create: `lib/shared/widgets/keyboard_aware_body.dart`
  - Small focused widget that applies bottom inset, safe scroll behavior, and animation.
- Modify: `lib/features/transactions/presentation/quick_entry_screen.dart`
  - Align with the new shared keyboard-aware layout.
- Modify: `lib/features/settings/presentation/lock_setup_dialog.dart`
  - Apply dialog keyboard inset handling.
- Modify: `lib/features/accounts/presentation/accounts_screen.dart`
  - Apply form-area keyboard-safe behavior.
- Modify: `lib/features/budgets/presentation/budget_screen.dart`
  - Apply form-area keyboard-safe behavior.
- Modify: `lib/features/recurring_expenses/presentation/recurring_expenses_screen.dart`
  - Apply form-area keyboard-safe behavior.

### Home previews

- Modify: `lib/features/dashboard/presentation/dashboard_home_links_card.dart`
  - Remove fold state, keep previews always visible, remove group labels and fold controls.
- Modify: `lib/features/dashboard/presentation/dashboard_screen.dart`
  - Pass through unchanged preview data, adapt layout spacing if needed.
- Modify: `test/features/dashboard/dashboard_home_links_card_test.dart`
  - Replace fold behavior assertions with always-visible preview assertions.
- Modify: `test/features/dashboard/dashboard_screen_navigation_test.dart`
  - Keep navigation coverage with new visible-card interaction.

### Calendar mode + inline entry

- Modify: `lib/features/calendar/application/calendar_provider.dart`
  - Rename/redefine view modes to day/month/year and add any state needed for selected-day inline entry.
- Modify: `lib/features/calendar/presentation/calendar_screen.dart`
  - Replace week mode with day mode, add inline quick-entry card, preserve month/year flows.
- Create: `lib/features/calendar/presentation/calendar_inline_entry_card.dart`
  - Focused UI for selected-day inline quick entry.
- Create: `lib/features/calendar/application/calendar_inline_entry_controller.dart`
  - Thin adapter around existing quick-entry form state or transaction repository for day-based inline save.
- Modify: `test/features/calendar/presentation/calendar_screen_test.dart`
  - Cover day/month/year switching, selected date behavior, and inline-entry visibility.
- Create: `test/features/calendar/application/calendar_inline_entry_controller_test.dart`
  - Cover save/update/reset behavior for inline entry.

### Verification

- Modify: `docs/superpowers/specs/2026-05-07-calendar-home-and-keyboard-policy-design.md`
  - Only if implementation-level naming changes need sync.

---

### Task 1: Add App-Wide Keyboard Avoidance Policy

**Files:**
- Create: `lib/shared/widgets/keyboard_aware_body.dart`
- Modify: `lib/shared/widgets/app_scaffold.dart`
- Modify: `lib/features/transactions/presentation/quick_entry_screen.dart`
- Modify: `lib/features/settings/presentation/lock_setup_dialog.dart`
- Modify: `lib/features/accounts/presentation/accounts_screen.dart`
- Modify: `lib/features/budgets/presentation/budget_screen.dart`
- Modify: `lib/features/recurring_expenses/presentation/recurring_expenses_screen.dart`

- [ ] **Step 1: Write the failing keyboard-aware widget test scaffold**

Add a new focused test file:

`test/shared/widgets/keyboard_aware_body_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet_app/shared/widgets/keyboard_aware_body.dart';

void main() {
  testWidgets('adds bottom padding from keyboard insets', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          viewInsets: EdgeInsets.only(bottom: 280),
        ),
        child: const MaterialApp(
          home: Scaffold(
            body: KeyboardAwareBody(
              child: SizedBox(height: 120, child: Text('field')),
            ),
          ),
        ),
      ),
    );

    final padding = tester.widget<AnimatedPadding>(
      find.byType(AnimatedPadding),
    );

    expect(padding.padding.bottom, 280);
  });
}
```

- [ ] **Step 2: Run the new test to verify it fails**

Run:

```powershell
& 'C:\smart wallet\flutterw.bat' test --no-pub test\shared\widgets\keyboard_aware_body_test.dart
```

Expected: FAIL because `KeyboardAwareBody` does not exist yet.

- [ ] **Step 3: Implement the shared keyboard-aware wrapper**

Create `lib/shared/widgets/keyboard_aware_body.dart` with a focused widget:

```dart
import 'package:flutter/material.dart';

class KeyboardAwareBody extends StatelessWidget {
  const KeyboardAwareBody({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 180),
  });

  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: duration,
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: insets),
      child: child,
    );
  }
}
```

- [ ] **Step 4: Apply the wrapper in `AppScaffold`**

Update `lib/shared/widgets/app_scaffold.dart` so the body is wrapped once in the shared policy:

```dart
body: SafeArea(
  child: KeyboardAwareBody(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        0,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: body,
      ),
    ),
  ),
),
```

- [ ] **Step 5: Normalize dialog/form usage**

Update the input-heavy screens so their content can actually move when the wrapper adds inset:

```dart
return AppScaffold(
  title: '...',
  body: ListView(
    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
    children: [
      ...
    ],
  ),
);
```

For input dialogs:

```dart
return AnimatedPadding(
  duration: const Duration(milliseconds: 180),
  padding: EdgeInsets.only(
    bottom: MediaQuery.of(dialogContext).viewInsets.bottom,
  ),
  child: SingleChildScrollView(
    child: AlertDialog(
      ...
    ),
  ),
);
```

- [ ] **Step 6: Run targeted analyze**

Run:

```powershell
& 'C:\smart wallet\dartw.bat' analyze lib\shared\widgets\app_scaffold.dart lib\shared\widgets\keyboard_aware_body.dart lib\features\transactions\presentation\quick_entry_screen.dart lib\features\settings\presentation\lock_setup_dialog.dart lib\features\accounts\presentation\accounts_screen.dart lib\features\budgets\presentation\budget_screen.dart lib\features\recurring_expenses\presentation\recurring_expenses_screen.dart test\shared\widgets\keyboard_aware_body_test.dart
```

Expected: `No issues found!`

- [ ] **Step 7: Run targeted test**

Run:

```powershell
& 'C:\smart wallet\flutterw.bat' test --no-pub test\shared\widgets\keyboard_aware_body_test.dart
```

Expected: PASS

- [ ] **Step 8: Commit**

```bash
git add lib/shared/widgets/keyboard_aware_body.dart lib/shared/widgets/app_scaffold.dart lib/features/transactions/presentation/quick_entry_screen.dart lib/features/settings/presentation/lock_setup_dialog.dart lib/features/accounts/presentation/accounts_screen.dart lib/features/budgets/presentation/budget_screen.dart lib/features/recurring_expenses/presentation/recurring_expenses_screen.dart test/shared/widgets/keyboard_aware_body_test.dart
git commit -m "feat: add shared keyboard avoidance policy"
```

### Task 2: Make Home Calendar And Statistics Previews Always Visible

**Files:**
- Modify: `lib/features/dashboard/presentation/dashboard_home_links_card.dart`
- Modify: `lib/features/dashboard/presentation/dashboard_screen.dart`
- Modify: `test/features/dashboard/dashboard_home_links_card_test.dart`
- Modify: `test/features/dashboard/dashboard_screen_navigation_test.dart`

- [ ] **Step 1: Rewrite the home preview tests to the new structure**

Update `test/features/dashboard/dashboard_home_links_card_test.dart` with assertions like:

```dart
testWidgets('shows calendar and statistics previews without expanding', (tester) async {
  await tester.pumpWidget(_buildCard());

  expect(find.byKey(const Key('dashboard-calendar-preview-grid')), findsOneWidget);
  expect(find.byKey(const Key('dashboard-statistics-preview-list')), findsOneWidget);
  expect(find.byKey(const Key('dashboard-calendar-fold')), findsNothing);
  expect(find.byKey(const Key('dashboard-statistics-fold')), findsNothing);
});
```

- [ ] **Step 2: Run the updated dashboard test to verify it fails**

Run:

```powershell
& 'C:\smart wallet\flutterw.bat' test --no-pub test\features\dashboard\dashboard_home_links_card_test.dart
```

Expected: FAIL because the fold widgets still exist.

- [ ] **Step 3: Remove fold state and make both previews always visible**

Refactor `lib/features/dashboard/presentation/dashboard_home_links_card.dart`:

```dart
class DashboardHomeLinksCard extends StatelessWidget {
  const DashboardHomeLinksCard({...});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      blur: 16,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CalendarPreview(...),
          const SizedBox(height: AppSpacing.md),
          _StatisticsPreview(...),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Remove grouping labels and reduce framing text**

Delete:

- `HOME PREVIEW`
- `달력과 통계`
- fold tile labels and toggles

Keep only the preview content and tap affordance:

```dart
InkWell(
  key: const Key('dashboard-open-calendar'),
  onTap: onOpenCalendar,
  child: _CalendarPreview(...),
)
```

And same for statistics.

- [ ] **Step 5: Update navigation test if tap target changed**

Update `test/features/dashboard/dashboard_screen_navigation_test.dart`:

```dart
await tester.tap(find.byKey(const Key('dashboard-open-calendar')));
await tester.pumpAndSettle();
expect(router.routerDelegate.currentConfiguration.uri.toString(), '/calendar');
```

- [ ] **Step 6: Run targeted analyze**

Run:

```powershell
& 'C:\smart wallet\dartw.bat' analyze lib\features\dashboard\presentation\dashboard_home_links_card.dart lib\features\dashboard\presentation\dashboard_screen.dart test\features\dashboard\dashboard_home_links_card_test.dart test\features\dashboard\dashboard_screen_navigation_test.dart
```

Expected: `No issues found!`

- [ ] **Step 7: Run targeted tests**

Run:

```powershell
& 'C:\smart wallet\flutterw.bat' test --no-pub test\features\dashboard\dashboard_home_links_card_test.dart test\features\dashboard\dashboard_screen_navigation_test.dart
```

Expected: PASS

- [ ] **Step 8: Commit**

```bash
git add lib/features/dashboard/presentation/dashboard_home_links_card.dart lib/features/dashboard/presentation/dashboard_screen.dart test/features/dashboard/dashboard_home_links_card_test.dart test/features/dashboard/dashboard_screen_navigation_test.dart
git commit -m "feat: keep home calendar and statistics previews visible"
```

### Task 3: Rebuild Calendar As Day / Month / Year With Inline Entry

**Files:**
- Modify: `lib/features/calendar/application/calendar_provider.dart`
- Modify: `lib/features/calendar/presentation/calendar_screen.dart`
- Create: `lib/features/calendar/application/calendar_inline_entry_controller.dart`
- Create: `lib/features/calendar/presentation/calendar_inline_entry_card.dart`
- Modify: `test/features/calendar/presentation/calendar_screen_test.dart`
- Create: `test/features/calendar/application/calendar_inline_entry_controller_test.dart`

- [ ] **Step 1: Update the provider test surface first**

Add `test/features/calendar/application/calendar_inline_entry_controller_test.dart`:

```dart
test('creates expense for selected calendar day', () async {
  final controller = CalendarInlineEntryController(database);

  await controller.save(
    selectedDate: DateTime(2026, 5, 7),
    type: 'expense',
    amount: 12000,
    categoryId: 'food',
    accountId: 'cash',
    memo: '점심',
  );

  final rows = await database.select(database.transactions).get();
  expect(rows.single.type, 'expense');
  expect(rows.single.amount, 12000);
  expect(rows.single.occurredAt.day, 7);
});
```

- [ ] **Step 2: Run the new test to verify it fails**

Run:

```powershell
& 'C:\smart wallet\flutterw.bat' test --no-pub test\features\calendar\application\calendar_inline_entry_controller_test.dart
```

Expected: FAIL because the controller does not exist yet.

- [ ] **Step 3: Replace week mode with day mode in the provider**

Update `calendar_provider.dart`:

```dart
enum CalendarViewMode {
  day,
  month,
  year,
}
```

And update `_periodStart` / `_periodEnd` logic so:

```dart
CalendarViewMode.day => DateTime(anchorDate.year, anchorDate.month, anchorDate.day)
```

Also make the current selected date the anchor for day mode when available.

- [ ] **Step 4: Implement a minimal inline entry controller**

Create `lib/features/calendar/application/calendar_inline_entry_controller.dart`:

```dart
class CalendarInlineEntryController {
  const CalendarInlineEntryController(this._database);

  final AppDatabase _database;

  Future<void> save({
    required DateTime selectedDate,
    required String type,
    required int amount,
    required String categoryId,
    required String accountId,
    required String memo,
  }) async {
    await _database.into(_database.transactions).insert(
      TransactionsCompanion.insert(
        type: type,
        amount: amount,
        categoryId: Value(categoryId),
        accountId: accountId,
        memo: Value(memo.isEmpty ? null : memo),
        occurredAt: selectedDate,
      ),
    );
  }
}
```

- [ ] **Step 5: Add the inline entry card UI**

Create `lib/features/calendar/presentation/calendar_inline_entry_card.dart` with a compact card:

```dart
class CalendarInlineEntryCard extends ConsumerStatefulWidget {
  const CalendarInlineEntryCard({
    super.key,
    required this.selectedDate,
    required this.onSaved,
  });

  final DateTime selectedDate;
  final VoidCallback onSaved;
}
```

The card should render:

- a `SegmentedButton` for `지출 / 수입`
- amount `TextField`
- category picker
- account picker
- memo `TextField`
- save button

- [ ] **Step 6: Insert inline entry into calendar screen**

Update `calendar_screen.dart` so:

- top mode switch is `일별 / 월별 / 연별`
- month mode stays the main calendar grid
- selecting a date shows both:
  - `_CalendarSelectedDayCard`
  - `CalendarInlineEntryCard`

Target shape:

```dart
if (selectedDate != null && viewMode != CalendarViewMode.year) ...[
  AppSection(
    title: _selectedDateLabel(selectedDate),
    child: _CalendarSelectedDayCard(...),
  ),
  const SizedBox(height: AppSpacing.lg),
  AppSection(
    title: '이 날짜에 바로 기록하기',
    child: CalendarInlineEntryCard(
      selectedDate: selectedDate,
      onSaved: () => refreshCalendarData(ref),
    ),
  ),
]
```

For `CalendarViewMode.day`, use the selected day or anchor date as the main focus and skip the month grid.

- [ ] **Step 7: Update the widget tests**

In `test/features/calendar/presentation/calendar_screen_test.dart`, add:

```dart
testWidgets('switches between day month and year modes', (tester) async {
  await tester.pumpWidget(_buildCalendar());

  await tester.tap(find.text('일별'));
  await tester.pumpAndSettle();
  expect(find.text('이 날짜에 바로 기록하기'), findsOneWidget);

  await tester.tap(find.text('연별'));
  await tester.pumpAndSettle();
  expect(find.text('기간 흐름'), findsOneWidget);
});
```

And:

```dart
testWidgets('shows inline entry card after selecting a month day', (tester) async {
  await tester.pumpWidget(_buildCalendar());
  await tester.tap(find.byKey(const Key('calendar-day-2026-05-05')));
  await tester.pumpAndSettle();

  expect(find.text('이 날짜에 바로 기록하기'), findsOneWidget);
  expect(find.byType(CalendarInlineEntryCard), findsOneWidget);
});
```

- [ ] **Step 8: Run targeted analyze**

Run:

```powershell
& 'C:\smart wallet\dartw.bat' analyze lib\features\calendar\application\calendar_provider.dart lib\features\calendar\application\calendar_inline_entry_controller.dart lib\features\calendar\presentation\calendar_inline_entry_card.dart lib\features\calendar\presentation\calendar_screen.dart test\features\calendar\application\calendar_inline_entry_controller_test.dart test\features\calendar\presentation\calendar_screen_test.dart
```

Expected: `No issues found!`

- [ ] **Step 9: Run targeted tests**

Run:

```powershell
& 'C:\smart wallet\flutterw.bat' test --no-pub test\features\calendar\application\calendar_inline_entry_controller_test.dart test\features\calendar\presentation\calendar_screen_test.dart
```

Expected: PASS

- [ ] **Step 10: Commit**

```bash
git add lib/features/calendar/application/calendar_provider.dart lib/features/calendar/application/calendar_inline_entry_controller.dart lib/features/calendar/presentation/calendar_inline_entry_card.dart lib/features/calendar/presentation/calendar_screen.dart test/features/calendar/application/calendar_inline_entry_controller_test.dart test/features/calendar/presentation/calendar_screen_test.dart
git commit -m "feat: add day month year calendar with inline entry"
```

### Task 4: Final Verification And Doc Sync

**Files:**
- Modify: `docs/superpowers/specs/2026-05-07-calendar-home-and-keyboard-policy-design.md` (only if names changed)

- [ ] **Step 1: Run focused feature test bundle**

Run:

```powershell
& 'C:\smart wallet\flutterw.bat' test --no-pub test\shared\widgets\keyboard_aware_body_test.dart test\features\dashboard\dashboard_home_links_card_test.dart test\features\dashboard\dashboard_screen_navigation_test.dart test\features\calendar\application\calendar_inline_entry_controller_test.dart test\features\calendar\presentation\calendar_screen_test.dart
```

Expected: `All tests passed!`

- [ ] **Step 2: Run focused analyze bundle**

Run:

```powershell
& 'C:\smart wallet\dartw.bat' analyze lib\shared\widgets\app_scaffold.dart lib\shared\widgets\keyboard_aware_body.dart lib\features\dashboard\presentation\dashboard_home_links_card.dart lib\features\dashboard\presentation\dashboard_screen.dart lib\features\calendar\application\calendar_provider.dart lib\features\calendar\application\calendar_inline_entry_controller.dart lib\features\calendar\presentation\calendar_inline_entry_card.dart lib\features\calendar\presentation\calendar_screen.dart test\shared\widgets\keyboard_aware_body_test.dart test\features\dashboard\dashboard_home_links_card_test.dart test\features\dashboard\dashboard_screen_navigation_test.dart test\features\calendar\application\calendar_inline_entry_controller_test.dart test\features\calendar\presentation\calendar_screen_test.dart
```

Expected: `No issues found!`

- [ ] **Step 3: Run app build verification**

Run:

```powershell
& 'C:\smart wallet\flutterw.bat' build windows --debug --no-pub
& 'C:\smart wallet\flutterw.bat' build apk --release --no-pub
```

Expected:

- Windows debug build succeeds
- APK release build succeeds

- [ ] **Step 4: Sync the spec if implementation naming moved**

If the final names differ from the spec, update:

`docs/superpowers/specs/2026-05-07-calendar-home-and-keyboard-policy-design.md`

Typical sync examples:

```md
- If `일별` becomes `하루 보기`, rename it in the spec.
- If inline entry uses a bottom CTA label other than `이 날짜에 바로 기록하기`, update the spec text.
```

- [ ] **Step 5: Commit**

```bash
git add docs/superpowers/specs/2026-05-07-calendar-home-and-keyboard-policy-design.md
git commit -m "docs: sync calendar home keyboard spec to implementation"
```

## Self-Review

### Spec coverage

- Home previews always visible: covered by Task 2.
- Calendar `일별 / 월별 / 연별`: covered by Task 3.
- Calendar inline entry with category/account/memo: covered by Task 3.
- App-wide keyboard avoidance policy: covered by Task 1.
- Removal of grouped explanatory framing on home: covered by Task 2.

### Placeholder scan

- No `TODO`, `TBD`, or “implement later” placeholders remain.
- Each task includes exact file paths, commands, and expected outcomes.

### Type consistency

- Plan consistently uses `CalendarViewMode.day/month/year`.
- Inline entry uses `CalendarInlineEntryCard` and `CalendarInlineEntryController` consistently.
- Shared keyboard wrapper is consistently named `KeyboardAwareBody`.
