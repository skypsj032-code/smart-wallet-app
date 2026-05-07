# Recurring Transaction Suggestion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Expand fixed monthly expenses into recurring transactions for income and expense, then surface one due recommendation on the home screen that asks the user to create the transaction instead of auto-creating it.

**Architecture:** Keep the work in four layers: Drift schema and persistence, recurring transaction domain/service logic, recurring transaction management UI, and a dedicated home recommendation provider/card. Reuse the existing recurring-expense feature as the migration base, but stop treating it as an expense-only or auto-materialization feature.

**Tech Stack:** Flutter, Riverpod, Drift, GoRouter, widget tests, Flutter analyze/test/build, build_runner.

---

## File Map

### Database and persistence

- Modify: `lib/core/database/tables.dart`
  - Expand the recurring table from monthly expense-only fields to general recurring transaction fields.
- Modify: `lib/core/database/app_database.dart`
  - Bump schema version and add migration steps for the new recurring transaction columns.
- Modify: `lib/core/database/app_database.g.dart`
  - Regenerated Drift output after schema changes.
- Modify: `lib/features/settings/application/backup_service.dart`
  - Export and restore the expanded recurring transaction shape.
- Modify: `test/features/settings/backup_service_test.dart`
  - Cover backup/restore for weekly/monthly, income/expense, and dismiss/create cycle keys.

### Recurring transaction domain

- Modify: `lib/features/recurring_expenses/application/recurring_expense_service.dart`
  - Convert expense-only service methods into recurring transaction methods, selection logic, dismiss logic, and creation-on-approval logic.
- Create: `lib/features/recurring_expenses/application/recurring_transaction_suggestion.dart`
  - Focused model/helpers for a due suggestion candidate and priority calculation.
- Modify: `test/features/recurring_expenses/recurring_expense_service_test.dart`
  - Replace monthly-only materialization tests with suggestion selection, dismiss, and approval tests.

### Recurring transaction management UI

- Modify: `lib/features/recurring_expenses/presentation/recurring_expenses_screen.dart`
  - Reframe the screen from fixed expenses to recurring transactions and support income/expense plus weekly/monthly schedule editing.
- Create: `test/features/recurring_expenses/recurring_expenses_screen_test.dart`
  - Cover the new form labels, cadence inputs, and type switching.

### Home recommendation UI

- Create: `lib/features/dashboard/application/recurring_transaction_suggestion_provider.dart`
  - Build a single top-priority due suggestion stream for the dashboard.
- Modify: `lib/features/dashboard/presentation/dashboard_screen.dart`
  - Remove the old repeat-suggestion section from the home feed and insert the recurring transaction alert card as its own block, separate from calendar/statistics.
- Create: `lib/features/dashboard/presentation/recurring_transaction_suggestion_card.dart`
  - Small alert-style card with `생성` and `이번엔 닫기`.
- Modify: `test/features/dashboard/dashboard_screen_navigation_test.dart`
  - Override the new suggestion provider and verify the home feed behavior.
- Create: `test/features/dashboard/recurring_transaction_suggestion_card_test.dart`
  - Cover conditional rendering and the two card actions.

### Documentation sync

- Modify: `docs/superpowers/specs/2026-05-07-recurring-transaction-suggestion-design.md`
  - Only if implementation naming moves from the current approved spec.

---

### Task 1: Expand The Recurring Transaction Table And Backup Shape

**Files:**
- Modify: `lib/core/database/tables.dart`
- Modify: `lib/core/database/app_database.dart`
- Modify: `lib/features/settings/application/backup_service.dart`
- Modify: `test/features/settings/backup_service_test.dart`

- [ ] **Step 1: Write the failing backup test for the expanded recurring shape**

Add a new test to `test/features/settings/backup_service_test.dart`:

```dart
test('backup and restore keep recurring transaction cadence and cycle keys',
    () async {
  await database.into(database.recurringExpenses).insert(
        RecurringExpensesCompanion.insert(
          localId: 'rec_salary',
          name: '월급',
          type: 'income',
          amount: 3200000,
          cadence: 'monthly',
          dayOfMonth: const drift.Value(5),
          weekday: const drift.Value(null),
          accountId: 'bank_main',
          categoryId: const drift.Value('income-salary'),
          lastSuggestedCycleKey: const drift.Value('2026-05'),
          lastCompletedCycleKey: const drift.Value('2026-04'),
          lastDismissedCycleKey: const drift.Value('2026-03'),
          createdAt: DateTime(2026, 5, 1),
          lastModifiedAt: DateTime(2026, 5, 1),
        ),
      );

  final json = await service.exportJsonBackup();
  final data = jsonDecode(json) as Map<String, dynamic>;
  final recurring = (data['recurringExpenses'] as List<dynamic>).single
      as Map<String, dynamic>;

  expect(recurring['type'], 'income');
  expect(recurring['cadence'], 'monthly');
  expect(recurring['dayOfMonth'], 5);
  expect(recurring['weekday'], isNull);
  expect(recurring['lastSuggestedCycleKey'], '2026-05');
  expect(recurring['lastCompletedCycleKey'], '2026-04');
  expect(recurring['lastDismissedCycleKey'], '2026-03');
});
```

- [ ] **Step 2: Run the targeted backup test and verify it fails**

Run:

```powershell
& 'C:\dev\flutter\bin\flutter.bat' test --no-pub test\features\settings\backup_service_test.dart --plain-name "backup and restore keep recurring transaction cadence and cycle keys"
```

Expected: FAIL because the recurring table and backup payload do not have `type`, `cadence`, `weekday`, or the new cycle-key fields yet.

- [ ] **Step 3: Expand the Drift table to the new recurring transaction shape**

Update `lib/core/database/tables.dart` so the recurring table looks like:

```dart
class RecurringExpenses extends Table {
  TextColumn get localId => text()();
  TextColumn get name => text()();
  TextColumn get type => text()();
  IntColumn get amount => integer()();
  TextColumn get cadence => text()();
  IntColumn get dayOfMonth => integer().nullable()();
  IntColumn get weekday => integer().nullable()();
  TextColumn get accountId => text()();
  TextColumn get categoryId => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  TextColumn get lastSuggestedCycleKey => text().nullable()();
  TextColumn get lastCompletedCycleKey => text().nullable()();
  TextColumn get lastDismissedCycleKey => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastModifiedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {localId};
}
```

- [ ] **Step 4: Add the migration path in `AppDatabase`**

Update `lib/core/database/app_database.dart`:

```dart
@override
int get schemaVersion => 6;
```

And in `onUpgrade` add:

```dart
if (from < 6) {
  await m.addColumn(recurringExpenses, recurringExpenses.type);
  await m.addColumn(recurringExpenses, recurringExpenses.cadence);
  await m.addColumn(recurringExpenses, recurringExpenses.weekday);
  await m.addColumn(
    recurringExpenses,
    recurringExpenses.lastSuggestedCycleKey,
  );
  await m.addColumn(
    recurringExpenses,
    recurringExpenses.lastCompletedCycleKey,
  );
  await m.addColumn(
    recurringExpenses,
    recurringExpenses.lastDismissedCycleKey,
  );
  await customStatement(
    "UPDATE recurring_expenses SET type = 'expense' WHERE type IS NULL;",
  );
  await customStatement(
    "UPDATE recurring_expenses SET cadence = 'monthly' WHERE cadence IS NULL;",
  );
}
```

- [ ] **Step 5: Regenerate the Drift output**

Run:

```powershell
& 'C:\dev\flutter\bin\dart.bat' run build_runner build --delete-conflicting-outputs
```

Expected: `Succeeded` and regenerated `lib/core/database/app_database.g.dart`.

- [ ] **Step 6: Extend backup export and restore**

Update `lib/features/settings/application/backup_service.dart` so recurring rows serialize and restore:

```dart
'type': row.type,
'cadence': row.cadence,
'dayOfMonth': row.dayOfMonth,
'weekday': row.weekday,
'lastSuggestedCycleKey': row.lastSuggestedCycleKey,
'lastCompletedCycleKey': row.lastCompletedCycleKey,
'lastDismissedCycleKey': row.lastDismissedCycleKey,
```

And on restore:

```dart
type: row['type'] as String? ?? 'expense',
cadence: row['cadence'] as String? ?? 'monthly',
dayOfMonth: drift.Value(row['dayOfMonth'] as int?),
weekday: drift.Value(row['weekday'] as int?),
lastSuggestedCycleKey: drift.Value(
  row['lastSuggestedCycleKey'] as String?,
),
lastCompletedCycleKey: drift.Value(
  row['lastCompletedCycleKey'] as String?,
),
lastDismissedCycleKey: drift.Value(
  row['lastDismissedCycleKey'] as String?,
),
```

- [ ] **Step 7: Run targeted analyze**

Run:

```powershell
& 'C:\dev\flutter\bin\dart.bat' analyze lib\core\database\tables.dart lib\core\database\app_database.dart lib\features\settings\application\backup_service.dart test\features\settings\backup_service_test.dart
```

Expected: `No issues found!`

- [ ] **Step 8: Run the targeted backup test and full backup test file**

Run:

```powershell
& 'C:\dev\flutter\bin\flutter.bat' test --no-pub test\features\settings\backup_service_test.dart
```

Expected: PASS

- [ ] **Step 9: Commit**

```bash
git add lib/core/database/tables.dart lib/core/database/app_database.dart lib/core/database/app_database.g.dart lib/features/settings/application/backup_service.dart test/features/settings/backup_service_test.dart
git commit -m "feat: expand recurring transaction persistence model"
```

### Task 2: Replace Monthly Auto-Materialization With Recurring Suggestion Logic

**Files:**
- Create: `lib/features/recurring_expenses/application/recurring_transaction_suggestion.dart`
- Modify: `lib/features/recurring_expenses/application/recurring_expense_service.dart`
- Modify: `test/features/recurring_expenses/recurring_expense_service_test.dart`

- [ ] **Step 1: Rewrite the service test around suggestion selection**

Replace the current materialization-first test flow in `test/features/recurring_expenses/recurring_expense_service_test.dart` with a failing suggestion test:

```dart
test('selectDueSuggestion returns the highest priority due recurring item',
    () async {
  await service.createRecurringTransaction(
    name: '통신비',
    type: 'expense',
    amount: 55000,
    cadence: 'monthly',
    dayOfMonth: 10,
    weekday: null,
    accountId: 'card_main',
    categoryId: 'expense-telecom',
  );
  await service.createRecurringTransaction(
    name: '월급',
    type: 'income',
    amount: 3200000,
    cadence: 'monthly',
    dayOfMonth: 5,
    weekday: null,
    accountId: 'bank_main',
    categoryId: 'income-salary',
  );

  final suggestion = await service.selectDueSuggestion(
    today: DateTime(2026, 5, 10),
  );

  expect(suggestion, isNotNull);
  expect(suggestion!.transaction.name, '통신비');
  expect(suggestion.cycleKey, '2026-05');
});
```

- [ ] **Step 2: Run the service test and verify it fails**

Run:

```powershell
& 'C:\dev\flutter\bin\flutter.bat' test --no-pub test\features\recurring_expenses\recurring_expense_service_test.dart --plain-name "selectDueSuggestion returns the highest priority due recurring item"
```

Expected: FAIL because `createRecurringTransaction` and `selectDueSuggestion` do not exist yet.

- [ ] **Step 3: Add a focused suggestion model/helper file**

Create `lib/features/recurring_expenses/application/recurring_transaction_suggestion.dart`:

```dart
import '../../../core/database/app_database.dart';

class RecurringTransactionSuggestion {
  const RecurringTransactionSuggestion({
    required this.transaction,
    required this.cycleKey,
    required this.dueDate,
  });

  final RecurringExpense transaction;
  final String cycleKey;
  final DateTime dueDate;
}
```

Also add helper functions for:

```dart
String recurringCycleKey({
  required String cadence,
  required DateTime date,
})

DateTime recurringDueDateForCycle(
  RecurringExpense transaction, {
  required DateTime today,
})
```

- [ ] **Step 4: Replace monthly-only service methods with recurring transaction methods**

Refactor `lib/features/recurring_expenses/application/recurring_expense_service.dart` to expose:

```dart
Future<String> createRecurringTransaction({
  required String name,
  required String type,
  required int amount,
  required String cadence,
  required int? dayOfMonth,
  required int? weekday,
  required String accountId,
  String? categoryId,
})

Future<void> updateRecurringTransaction({...})

Future<void> dismissSuggestion({
  required String recurringId,
  required String cycleKey,
})

Future<bool> createTransactionFromSuggestion({
  required String recurringId,
  required DateTime today,
})

Future<RecurringTransactionSuggestion?> selectDueSuggestion({
  required DateTime today,
})
```

- [ ] **Step 5: Implement due filtering and “this occurrence only” dismissal**

The core due-selection logic should look like:

```dart
if (!row.isActive) return false;
if (row.lastCompletedCycleKey == cycleKey) return false;
if (row.lastDismissedCycleKey == cycleKey) return false;
if (!_matchesToday(row, today: today)) return false;
return true;
```

And dismissal should only write:

```dart
lastDismissedCycleKey: Value(cycleKey),
lastModifiedAt: Value(now),
```

Creation on approval should insert a normal transaction and write:

```dart
lastCompletedCycleKey: Value(cycleKey),
lastSuggestedCycleKey: Value(cycleKey),
```

- [ ] **Step 6: Add service tests for dismissal and approval**

Add to `test/features/recurring_expenses/recurring_expense_service_test.dart`:

```dart
test('dismissSuggestion hides only the current cycle', () async {
  final recurringId = await service.createRecurringTransaction(...);

  await service.dismissSuggestion(
    recurringId: recurringId,
    cycleKey: '2026-05',
  );

  final suggestionMay = await service.selectDueSuggestion(
    today: DateTime(2026, 5, 10),
  );
  final suggestionJune = await service.selectDueSuggestion(
    today: DateTime(2026, 6, 10),
  );

  expect(suggestionMay, isNull);
  expect(suggestionJune, isNotNull);
});
```

```dart
test('createTransactionFromSuggestion inserts one transaction and closes the cycle',
    () async {
  final recurringId = await service.createRecurringTransaction(...);

  final created = await service.createTransactionFromSuggestion(
    recurringId: recurringId,
    today: DateTime(2026, 5, 10),
  );

  expect(created, isTrue);
  final rows = await database.select(database.transactions).get();
  expect(rows, hasLength(1));
  expect(rows.single.memo, '통신비');
});
```

- [ ] **Step 7: Run targeted analyze**

Run:

```powershell
& 'C:\dev\flutter\bin\dart.bat' analyze lib\features\recurring_expenses\application\recurring_transaction_suggestion.dart lib\features\recurring_expenses\application\recurring_expense_service.dart test\features\recurring_expenses\recurring_expense_service_test.dart
```

Expected: `No issues found!`

- [ ] **Step 8: Run the full recurring service test file**

Run:

```powershell
& 'C:\dev\flutter\bin\flutter.bat' test --no-pub test\features\recurring_expenses\recurring_expense_service_test.dart
```

Expected: PASS

- [ ] **Step 9: Commit**

```bash
git add lib/features/recurring_expenses/application/recurring_transaction_suggestion.dart lib/features/recurring_expenses/application/recurring_expense_service.dart test/features/recurring_expenses/recurring_expense_service_test.dart
git commit -m "feat: add recurring transaction suggestion logic"
```

### Task 3: Rebuild The Management Screen As Recurring Transactions

**Files:**
- Modify: `lib/features/recurring_expenses/presentation/recurring_expenses_screen.dart`
- Create: `test/features/recurring_expenses/recurring_expenses_screen_test.dart`

- [ ] **Step 1: Write the failing screen test for type and cadence fields**

Create `test/features/recurring_expenses/recurring_expenses_screen_test.dart`:

```dart
testWidgets('editor supports income expense and weekly monthly cadence',
    (tester) async {
  await tester.pumpWidget(_buildScreen());

  await tester.tap(find.text('정기 거래 추가'));
  await tester.pumpAndSettle();

  expect(find.text('수입'), findsOneWidget);
  expect(find.text('지출'), findsOneWidget);
  expect(find.text('매주'), findsOneWidget);
  expect(find.text('매달'), findsOneWidget);
});
```

- [ ] **Step 2: Run the new screen test and verify it fails**

Run:

```powershell
& 'C:\dev\flutter\bin\flutter.bat' test --no-pub test\features\recurring_expenses\recurring_expenses_screen_test.dart
```

Expected: FAIL because the dialog still renders a fixed monthly expense form.

- [ ] **Step 3: Rename the screen copy and action labels**

Update `lib/features/recurring_expenses/presentation/recurring_expenses_screen.dart` so user-facing copy shifts to recurring transactions:

```dart
return AppScaffold(
  title: '정기 거래',
  body: ...
)
```

Button copy:

```dart
label: const Text('정기 거래 추가')
```

Section intro:

```dart
const AppSectionIntro(
  title: '반복되는 수입과 지출을 미리 준비해요',
)
```

- [ ] **Step 4: Replace the editor fields with type/cadence-aware controls**

The dialog should include:

```dart
SegmentedButton<String>(
  segments: const [
    ButtonSegment(value: 'expense', label: Text('지출')),
    ButtonSegment(value: 'income', label: Text('수입')),
  ],
  selected: {_type},
  onSelectionChanged: (selection) => setState(() => _type = selection.first),
)
```

and

```dart
SegmentedButton<String>(
  segments: const [
    ButtonSegment(value: 'monthly', label: Text('매달')),
    ButtonSegment(value: 'weekly', label: Text('매주')),
  ],
  selected: {_cadence},
  onSelectionChanged: (selection) => setState(() => _cadence = selection.first),
)
```

Then switch the schedule field:

```dart
if (_cadence == 'monthly')
  TextField(... labelText: '매달 날짜')
else
  DropdownButtonFormField<int>(... labelText: '요일')
```

- [ ] **Step 5: Wire the form to the new service methods**

Save flow should call:

```dart
await service.createRecurringTransaction(
  name: result.name,
  type: result.type,
  amount: result.amount,
  cadence: result.cadence,
  dayOfMonth: result.dayOfMonth,
  weekday: result.weekday,
  accountId: result.accountId,
  categoryId: result.categoryId,
);
```

And the tile subtitle should render cadence-specific text:

```dart
String _scheduleLabel(RecurringExpense item) {
  if (item.cadence == 'weekly') {
    return '매주 ${_weekdayLabel(item.weekday!)}';
  }
  return '매달 ${item.dayOfMonth}일';
}
```

- [ ] **Step 6: Keep delete/deactivate behavior but remove old manual materialize wording**

Replace the popup actions with:

```dart
PopupMenuItem(value: 'edit', child: Text('수정')),
PopupMenuItem(value: 'delete', child: Text('비활성화')),
```

Do not keep the old “이번 달 거래로 기록” action in this screen. The new creation path belongs on the home suggestion card.

- [ ] **Step 7: Run targeted analyze**

Run:

```powershell
& 'C:\dev\flutter\bin\dart.bat' analyze lib\features\recurring_expenses\presentation\recurring_expenses_screen.dart test\features\recurring_expenses\recurring_expenses_screen_test.dart
```

Expected: `No issues found!`

- [ ] **Step 8: Run the recurring screen test**

Run:

```powershell
& 'C:\dev\flutter\bin\flutter.bat' test --no-pub test\features\recurring_expenses\recurring_expenses_screen_test.dart
```

Expected: PASS

- [ ] **Step 9: Commit**

```bash
git add lib/features/recurring_expenses/presentation/recurring_expenses_screen.dart test/features/recurring_expenses/recurring_expenses_screen_test.dart
git commit -m "feat: rebuild recurring transaction management screen"
```

### Task 4: Show One Home Suggestion Card And Remove The Old Repeat-Suggestion Section

**Files:**
- Create: `lib/features/dashboard/application/recurring_transaction_suggestion_provider.dart`
- Create: `lib/features/dashboard/presentation/recurring_transaction_suggestion_card.dart`
- Modify: `lib/features/dashboard/presentation/dashboard_screen.dart`
- Modify: `test/features/dashboard/dashboard_screen_navigation_test.dart`
- Create: `test/features/dashboard/recurring_transaction_suggestion_card_test.dart`

- [ ] **Step 1: Write the failing widget test for the home suggestion card**

Create `test/features/dashboard/recurring_transaction_suggestion_card_test.dart`:

```dart
testWidgets('renders recurring transaction suggestion card with create and dismiss',
    (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: RecurringTransactionSuggestionCard(
          suggestion: _suggestion(name: '통신비', amount: 55000),
          onCreate: () {},
          onDismiss: () {},
        ),
      ),
    ),
  );

  expect(find.text('오늘 처리할 정기 거래가 있어요'), findsOneWidget);
  expect(find.text('통신비 55,000원'), findsOneWidget);
  expect(find.text('생성'), findsOneWidget);
  expect(find.text('이번엔 닫기'), findsOneWidget);
});
```

- [ ] **Step 2: Run the new widget test and verify it fails**

Run:

```powershell
& 'C:\dev\flutter\bin\flutter.bat' test --no-pub test\features\dashboard\recurring_transaction_suggestion_card_test.dart
```

Expected: FAIL because the card and provider do not exist yet.

- [ ] **Step 3: Create a dedicated home suggestion provider**

Create `lib/features/dashboard/application/recurring_transaction_suggestion_provider.dart`:

```dart
final recurringTransactionSuggestionProvider =
    StreamProvider<RecurringTransactionSuggestion?>((ref) async* {
  final service = ref.watch(recurringExpenseServiceProvider);
  yield await service.selectDueSuggestion(today: DateTime.now());
});
```

If you need refresh-on-write behavior, make this a `FutureProvider.autoDispose` plus manual invalidation from the card actions instead.

- [ ] **Step 4: Create the alert-style home card**

Create `lib/features/dashboard/presentation/recurring_transaction_suggestion_card.dart`:

```dart
class RecurringTransactionSuggestionCard extends StatelessWidget {
  const RecurringTransactionSuggestionCard({
    super.key,
    required this.suggestion,
    required this.onCreate,
    required this.onDismiss,
  });

  final RecurringTransactionSuggestion suggestion;
  final VoidCallback onCreate;
  final VoidCallback onDismiss;
}
```

Card shape:

```dart
GlassCard(
  blur: 16,
  padding: const EdgeInsets.all(AppSpacing.md),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('오늘 처리할 정기 거래가 있어요'),
      Text('${suggestion.transaction.name} ${formatCurrency(suggestion.transaction.amount)}'),
      Text(_cadenceLabel(suggestion.transaction)),
      Row(
        children: [
          FilledButton(onPressed: onCreate, child: const Text('생성')),
          const SizedBox(width: AppSpacing.sm),
          TextButton(onPressed: onDismiss, child: const Text('이번엔 닫기')),
        ],
      ),
    ],
  ),
)
```

- [ ] **Step 5: Replace the old repeat-suggestion section in `DashboardScreen`**

Update `lib/features/dashboard/presentation/dashboard_screen.dart`:

- watch the new provider
- remove the current `summary.repeatSuggestions` section from the home feed
- insert the recurring suggestion card as its own block between the always-visible previews and the rest of the feed

Target structure:

```dart
final recurringSuggestionAsync =
    ref.watch(recurringTransactionSuggestionProvider);
```

```dart
if (recurringSuggestionAsync.valueOrNull case final suggestion?) ...[
  const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
  SliverToBoxAdapter(
    child: RecurringTransactionSuggestionCard(
      suggestion: suggestion,
      onCreate: () async {
        await ref.read(recurringExpenseServiceProvider).createTransactionFromSuggestion(
          recurringId: suggestion.transaction.localId,
          today: DateTime.now(),
        );
        ref.invalidate(recurringTransactionSuggestionProvider);
      },
      onDismiss: () async {
        await ref.read(recurringExpenseServiceProvider).dismissSuggestion(
          recurringId: suggestion.transaction.localId,
          cycleKey: suggestion.cycleKey,
        );
        ref.invalidate(recurringTransactionSuggestionProvider);
      },
    ),
  ),
],
```

- [ ] **Step 6: Update dashboard tests to the new provider flow**

Add a navigation/rendering test:

```dart
testWidgets('shows recurring suggestion card separately from preview cards',
    (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        recurringTransactionSuggestionProvider.overrideWith(
          (ref) => Stream.value(_suggestion(name: '통신비', amount: 55000)),
        ),
      ],
      child: _buildDashboard(),
    ),
  );

  expect(find.byKey(const Key('dashboard-calendar-preview-grid')), findsOneWidget);
  expect(find.byKey(const Key('dashboard-statistics-preview-list')), findsOneWidget);
  expect(find.text('오늘 처리할 정기 거래가 있어요'), findsOneWidget);
});
```

- [ ] **Step 7: Run targeted analyze**

Run:

```powershell
& 'C:\dev\flutter\bin\dart.bat' analyze lib\features\dashboard\application\recurring_transaction_suggestion_provider.dart lib\features\dashboard\presentation\recurring_transaction_suggestion_card.dart lib\features\dashboard\presentation\dashboard_screen.dart test\features\dashboard\recurring_transaction_suggestion_card_test.dart test\features\dashboard\dashboard_screen_navigation_test.dart
```

Expected: `No issues found!`

- [ ] **Step 8: Run the targeted dashboard tests**

Run:

```powershell
& 'C:\dev\flutter\bin\flutter.bat' test --no-pub test\features\dashboard\recurring_transaction_suggestion_card_test.dart test\features\dashboard\dashboard_screen_navigation_test.dart
```

Expected: PASS

- [ ] **Step 9: Commit**

```bash
git add lib/features/dashboard/application/recurring_transaction_suggestion_provider.dart lib/features/dashboard/presentation/recurring_transaction_suggestion_card.dart lib/features/dashboard/presentation/dashboard_screen.dart test/features/dashboard/recurring_transaction_suggestion_card_test.dart test/features/dashboard/dashboard_screen_navigation_test.dart
git commit -m "feat: show recurring transaction suggestion on home"
```

### Task 5: Final Verification And Spec Sync

**Files:**
- Modify: `docs/superpowers/specs/2026-05-07-recurring-transaction-suggestion-design.md` (only if names changed)

- [ ] **Step 1: Run the recurring feature test bundle**

Run:

```powershell
& 'C:\dev\flutter\bin\flutter.bat' test --no-pub test\features\settings\backup_service_test.dart test\features\recurring_expenses\recurring_expense_service_test.dart test\features\recurring_expenses\recurring_expenses_screen_test.dart test\features\dashboard\recurring_transaction_suggestion_card_test.dart test\features\dashboard\dashboard_screen_navigation_test.dart
```

Expected: `All tests passed!`

- [ ] **Step 2: Run the recurring feature analyze bundle**

Run:

```powershell
& 'C:\dev\flutter\bin\dart.bat' analyze lib\core\database\tables.dart lib\core\database\app_database.dart lib\features\settings\application\backup_service.dart lib\features\recurring_expenses\application\recurring_transaction_suggestion.dart lib\features\recurring_expenses\application\recurring_expense_service.dart lib\features\recurring_expenses\presentation\recurring_expenses_screen.dart lib\features\dashboard\application\recurring_transaction_suggestion_provider.dart lib\features\dashboard\presentation\recurring_transaction_suggestion_card.dart lib\features\dashboard\presentation\dashboard_screen.dart test\features\settings\backup_service_test.dart test\features\recurring_expenses\recurring_expense_service_test.dart test\features\recurring_expenses\recurring_expenses_screen_test.dart test\features\dashboard\recurring_transaction_suggestion_card_test.dart test\features\dashboard\dashboard_screen_navigation_test.dart
```

Expected: `No issues found!`

- [ ] **Step 3: Run build verification**

Run:

```powershell
& 'C:\dev\flutter\bin\flutter.bat' build windows --debug --no-pub
& 'C:\dev\flutter\bin\flutter.bat' build apk --release --no-pub
```

Expected:

- Windows debug build succeeds
- Android release APK build succeeds

- [ ] **Step 4: Sync the spec only if naming drifted**

If implementation renames any of these, update:

`docs/superpowers/specs/2026-05-07-recurring-transaction-suggestion-design.md`

Targets to keep aligned:

- `정기 거래`
- `생성`
- `이번엔 닫기`
- `매주 / 매달`
- `수입 / 지출`

- [ ] **Step 5: Commit**

```bash
git add docs/superpowers/specs/2026-05-07-recurring-transaction-suggestion-design.md
git commit -m "docs: sync recurring transaction suggestion spec"
```

## Self-Review

### Spec coverage

- Expand fixed expenses into recurring transactions for income and expense: covered by Tasks 1-3.
- Support weekly and monthly cadence: covered by Tasks 1-3.
- Do not auto-create; ask for confirmation: covered by Tasks 2 and 4.
- Hide only the current occurrence on dismiss: covered by Task 2.
- Show only one top-priority suggestion on home: covered by Tasks 2 and 4.
- Keep the recommendation visually separate from calendar/statistics: covered by Task 4.
- Leave local notifications out of scope: respected by all tasks.

### Placeholder scan

- No `TODO`, `TBD`, or “implement later” placeholders remain.
- Each task has exact file paths, concrete method names, commands, and expected output.
- Code steps include concrete API shapes instead of abstract instructions.

### Type consistency

- The plan consistently uses `RecurringExpense` as the existing Drift row type, even while the feature concept becomes recurring transactions.
- The new service surface consistently uses `createRecurringTransaction`, `updateRecurringTransaction`, `selectDueSuggestion`, `dismissSuggestion`, and `createTransactionFromSuggestion`.
- Cadence/type values stay consistent as `'weekly' | 'monthly'` and `'income' | 'expense'`.
