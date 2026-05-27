# Calendar Exploration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 홈의 달력 요약 카드와 달력 화면을 연결하고, 달력 안에서 검색과 `전체 / 수입 / 지출` 필터를 유지한 채 날짜별 흐름을 탐색할 수 있게 만든다.

**Architecture:** 기존 `calendar_provider.dart` 중심 구조를 유지하되, 탐색 상태를 provider 두 개로 추가하고 날짜 집계 모델을 확장한다. 화면은 `calendar_screen.dart`에서 바로 다 키우지 말고 검색/필터 헤더와 날짜별 목록 책임을 작은 위젯으로 나눠서 테스트 가능하게 유지한다.

**Tech Stack:** Flutter, Riverpod, Drift, GoRouter, flutter_test

---

## File Structure

### Modify
- `C:\smart wallet\app\lib\features\calendar\application\calendar_provider.dart`
  - 달력 타입 필터, 검색어 상태, 필터 반영 집계, 홈 요약 provider 추가
- `C:\smart wallet\app\lib\features\calendar\presentation\calendar_screen.dart`
  - 검색/필터 상단 영역, 날짜 셀 정보 확장, 선택 날짜 목록 동기화
- `C:\smart wallet\app\lib\features\dashboard\presentation\dashboard_home_links_card.dart`
  - 달력 요약 카드에 건수/수입/지출 요약 표시
- `C:\smart wallet\app\lib\features\dashboard\presentation\dashboard_screen.dart`
  - 홈에서 달력 요약 카드에 새 데이터 전달

### Create
- `C:\smart wallet\app\test\features\calendar\application\calendar_provider_test.dart`
  - 필터/검색/홈 요약 상태 테스트
- `C:\smart wallet\app\test\features\calendar\presentation\calendar_screen_test.dart`
  - 달력 화면 상호작용 테스트

### Reuse / Verify
- `C:\smart wallet\app\test\features\dashboard\dashboard_home_links_card_test.dart`
  - 홈 카드 표시/진입 회귀 테스트 보강
- `C:\smart wallet\app\lib\app\router\app_router.dart`
  - 라우트 추가는 불필요한지 확인만 하고, 필요 없으면 수정하지 않는다

---

### Task 1: 달력 상태 모델 확장

**Files:**
- Modify: `C:\smart wallet\app\lib\features\calendar\application\calendar_provider.dart`
- Create: `C:\smart wallet\app\test\features\calendar\application\calendar_provider_test.dart`

- [ ] **Step 1: 날짜 집계와 탐색 상태 테스트를 먼저 작성**

```dart
test('calendarSnapshotProvider filters days by type and search query', () async {
  final container = createContainerWithDatabase();
  final database = container.read(appDatabaseProvider);

  await database.into(database.transactions).insert(
        TransactionsCompanion.insert(
          type: 'expense',
          amount: 18000,
          occurredAt: DateTime(2026, 5, 5, 12),
          merchantName: const Value('스타벅스'),
          categoryId: const Value(1),
        ),
      );
  await database.into(database.transactions).insert(
        TransactionsCompanion.insert(
          type: 'income',
          amount: 50000,
          occurredAt: DateTime(2026, 5, 5, 18),
          memo: const Value('용돈'),
        ),
      );

  container.read(calendarTypeFilterProvider.notifier).state =
      CalendarTransactionFilter.expense;
  container.read(calendarSearchQueryProvider.notifier).state = '스타';

  final snapshot = await container.read(calendarSnapshotProvider.future);

  expect(snapshot.days, hasLength(1));
  expect(snapshot.days.single.transactionCount, 1);
  expect(snapshot.days.single.expense, 18000);
  expect(snapshot.days.single.income, 0);
});

test('calendarHomeSummaryProvider returns today count and totals', () async {
  final container = createContainerWithDatabase();
  final database = container.read(appDatabaseProvider);

  await database.into(database.transactions).insert(
        TransactionsCompanion.insert(
          type: 'expense',
          amount: 12000,
          occurredAt: DateTime(2026, 5, 5, 9, 30),
          merchantName: const Value('편의점'),
        ),
      );
  await database.into(database.transactions).insert(
        TransactionsCompanion.insert(
          type: 'income',
          amount: 70000,
          occurredAt: DateTime(2026, 5, 5, 20, 10),
          memo: const Value('정산'),
        ),
      );

  final summary = await container.read(calendarHomeSummaryProvider.future);

  expect(summary.transactionCount, 2);
  expect(summary.income, 70000);
  expect(summary.expense, 12000);
});
```

- [ ] **Step 2: 테스트를 단독 실행해서 실패를 확인**

Run:

```powershell
& 'C:\smart wallet\flutterw.bat' test --no-pub test\features\calendar\application\calendar_provider_test.dart
```

Expected:
- `The getter 'transactionCount' isn't defined`
- `Undefined name 'calendarTypeFilterProvider'`
- 또는 `StateError` 계열의 미구현 실패

- [ ] **Step 3: 탐색 상태와 집계 모델을 최소 구현**

```dart
enum CalendarTransactionFilter { all, income, expense }

class CalendarDaySummary {
  const CalendarDaySummary({
    required this.date,
    required this.income,
    required this.expense,
    required this.transactionCount,
    required this.matchCount,
  });

  final DateTime date;
  final int income;
  final int expense;
  final int transactionCount;
  final int matchCount;
}

class CalendarHomeSummary {
  const CalendarHomeSummary({
    required this.date,
    required this.transactionCount,
    required this.income,
    required this.expense,
  });

  final DateTime date;
  final int transactionCount;
  final int income;
  final int expense;
}

final calendarTypeFilterProvider =
    StateProvider<CalendarTransactionFilter>((ref) {
  return CalendarTransactionFilter.all;
});

final calendarSearchQueryProvider = StateProvider<String>((ref) => '');
```

```dart
bool _matchesCalendarFilter(
  Transaction row,
  CalendarTransactionFilter filter,
  String query,
) {
  final matchesType = switch (filter) {
    CalendarTransactionFilter.all => true,
    CalendarTransactionFilter.income => row.type == 'income',
    CalendarTransactionFilter.expense => row.type == 'expense',
  };

  if (!matchesType) {
    return false;
  }

  final normalized = query.trim().toLowerCase();
  if (normalized.isEmpty) {
    return true;
  }

  final haystacks = <String>[
    row.memo ?? '',
    row.merchantName ?? '',
  ];

  return haystacks.any((value) => value.toLowerCase().contains(normalized));
}
```

```dart
final calendarHomeSummaryProvider = StreamProvider<CalendarHomeSummary>((ref) {
  final database = ref.watch(appDatabaseProvider);
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day);
  final end = start.add(const Duration(days: 1));

  return (database.select(database.transactions)
        ..where((t) =>
            t.deletedAt.isNull() &
            t.occurredAt.isBiggerOrEqualValue(start) &
            t.occurredAt.isSmallerThanValue(end)))
      .watch()
      .map((rows) {
    var income = 0;
    var expense = 0;

    for (final row in rows) {
      if (row.type == 'income') income += row.amount;
      if (row.type == 'expense') expense += row.amount;
    }

    return CalendarHomeSummary(
      date: start,
      transactionCount: rows.length,
      income: income,
      expense: expense,
    );
  });
});
```

- [ ] **Step 4: `calendarSnapshotProvider`와 `selectedCalendarTransactionsProvider`에 새 상태를 연결**

```dart
final calendarSnapshotProvider = StreamProvider<CalendarSnapshot>((ref) {
  final mode = ref.watch(calendarViewModeProvider);
  final anchorDate = ref.watch(visibleCalendarDateProvider);
  final filter = ref.watch(calendarTypeFilterProvider);
  final query = ref.watch(calendarSearchQueryProvider);
  final database = ref.watch(appDatabaseProvider);
  final periodStart = _periodStart(anchorDate, mode);
  final periodEnd = _periodEnd(periodStart, mode);

  return (database.select(database.transactions)
        ..where((t) =>
            t.deletedAt.isNull() &
            t.occurredAt.isBiggerOrEqualValue(periodStart) &
            t.occurredAt.isSmallerThanValue(periodEnd))
        ..orderBy([(t) => OrderingTerm.asc(t.occurredAt)]))
      .watch()
      .map((rows) {
    final grouped = <DateTime, CalendarDaySummary>{};
    var totalIncome = 0;
    var totalExpense = 0;

    for (final row in rows) {
      if (!_matchesCalendarFilter(row, filter, query)) {
        continue;
      }

      final key = DateTime(row.occurredAt.year, row.occurredAt.month, row.occurredAt.day);
      final current = grouped[key] ??
          CalendarDaySummary(
            date: key,
            income: 0,
            expense: 0,
            transactionCount: 0,
            matchCount: 0,
          );

      grouped[key] = CalendarDaySummary(
        date: key,
        income: row.type == 'income' ? current.income + row.amount : current.income,
        expense: row.type == 'expense' ? current.expense + row.amount : current.expense,
        transactionCount: current.transactionCount + 1,
        matchCount: current.matchCount + 1,
      );

      if (row.type == 'income') totalIncome += row.amount;
      if (row.type == 'expense') totalExpense += row.amount;
    }

    return CalendarSnapshot(
      mode: mode,
      anchorDate: anchorDate,
      periodStart: periodStart,
      periodEnd: periodEnd,
      days: grouped.values.toList()..sort((a, b) => a.date.compareTo(b.date)),
      totalIncome: totalIncome,
      totalExpense: totalExpense,
    );
  });
});
```

```dart
final selectedCalendarTransactionsProvider =
    StreamProvider<List<Transaction>>((ref) {
  final selected = ref.watch(selectedCalendarDateProvider);
  final filter = ref.watch(calendarTypeFilterProvider);
  final query = ref.watch(calendarSearchQueryProvider);
  if (selected == null) {
    return Stream.value(const <Transaction>[]);
  }

  final database = ref.watch(appDatabaseProvider);
  final dayStart = DateTime(selected.year, selected.month, selected.day);
  final nextDay = dayStart.add(const Duration(days: 1));

  return (database.select(database.transactions)
        ..where((t) =>
            t.deletedAt.isNull() &
            t.occurredAt.isBiggerOrEqualValue(dayStart) &
            t.occurredAt.isSmallerThanValue(nextDay))
        ..orderBy([
          (t) => OrderingTerm.desc(t.occurredAt),
          (t) => OrderingTerm.desc(t.createdAt),
        ]))
      .watch()
      .map((rows) => [
            for (final row in rows)
              if (_matchesCalendarFilter(row, filter, query)) row,
          ]);
});
```

- [ ] **Step 5: 상태 테스트를 다시 실행해서 통과 확인**

Run:

```powershell
& 'C:\smart wallet\flutterw.bat' test --no-pub test\features\calendar\application\calendar_provider_test.dart
```

Expected:
- `All tests passed!`

- [ ] **Step 6: Commit**

```powershell
git -C 'C:\smart wallet\app' add lib/features/calendar/application/calendar_provider.dart test/features/calendar/application/calendar_provider_test.dart
git -C 'C:\smart wallet\app' commit -m "feat: add calendar exploration state"
```

---

### Task 2: 달력 화면에 검색/필터 헤더 붙이기

**Files:**
- Modify: `C:\smart wallet\app\lib\features\calendar\presentation\calendar_screen.dart`
- Create: `C:\smart wallet\app\test\features\calendar\presentation\calendar_screen_test.dart`

- [ ] **Step 1: 달력 화면 상호작용 테스트를 먼저 작성**

```dart
testWidgets('calendar screen filters selected-day list by type and search', (tester) async {
  await tester.pumpWidget(createCalendarTestApp());

  expect(find.text('달력'), findsOneWidget);
  expect(find.text('전체'), findsOneWidget);
  expect(find.text('수입'), findsOneWidget);
  expect(find.text('지출'), findsOneWidget);

  await tester.tap(find.text('지출'));
  await tester.pumpAndSettle();

  expect(find.text('급여'), findsNothing);
  expect(find.text('스타벅스'), findsOneWidget);

  await tester.enterText(find.byType(TextField), '편의점');
  await tester.pumpAndSettle();

  expect(find.text('스타벅스'), findsNothing);
  expect(find.text('편의점'), findsOneWidget);
});

testWidgets('tapping a day updates the list below without navigation', (tester) async {
  await tester.pumpWidget(createCalendarTestApp());

  await tester.tap(find.text('5').first);
  await tester.pumpAndSettle();

  expect(find.text('선택한 날의 거래'), findsOneWidget);
  expect(find.text('수정'), findsWidgets);
  expect(find.byType(CalendarScreen), findsOneWidget);
});
```

- [ ] **Step 2: 위젯 테스트를 실행해 실패를 확인**

Run:

```powershell
& 'C:\smart wallet\flutterw.bat' test --no-pub test\features\calendar\presentation\calendar_screen_test.dart
```

Expected:
- `Expected: exactly one matching candidate` for filter labels
- `find.byType(TextField)` 실패

- [ ] **Step 3: 상단 검색/필터 UI를 작은 위젯으로 추가**

```dart
class _CalendarExplorerHeader extends ConsumerWidget {
  const _CalendarExplorerHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(calendarTypeFilterProvider);
    final query = ref.watch(calendarSearchQueryProvider);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: TextEditingController(text: query)
                ..selection = TextSelection.collapsed(offset: query.length),
              onChanged: (value) {
                ref.read(calendarSearchQueryProvider.notifier).state = value;
              },
              decoration: const InputDecoration(
                hintText: '메모, 거래처, 카테고리 검색',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SegmentedButton<CalendarTransactionFilter>(
              segments: const [
                ButtonSegment(
                  value: CalendarTransactionFilter.all,
                  label: Text('전체'),
                ),
                ButtonSegment(
                  value: CalendarTransactionFilter.income,
                  label: Text('수입'),
                ),
                ButtonSegment(
                  value: CalendarTransactionFilter.expense,
                  label: Text('지출'),
                ),
              ],
              selected: {filter},
              onSelectionChanged: (selection) {
                ref.read(calendarTypeFilterProvider.notifier).state =
                    selection.first;
              },
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: 달력 목록/셀/인사이트를 새 상태에 맞게 연결**

```dart
children: [
  const _CalendarExplorerHeader(),
  const SizedBox(height: AppSpacing.lg),
  AppSection(
    title: _periodTitle(viewMode),
    action: _CalendarPeriodSwitcher(...),
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: switch (viewMode) {
          CalendarViewMode.week => _WeekCalendarView(...),
          CalendarViewMode.month => _MonthCalendarView(...),
          CalendarViewMode.year => _YearCalendarView(...),
        },
      ),
    ),
  ),
```

```dart
if (summary != null && summary.matchCount > 0)
  Text(
    '${summary.matchCount}건',
    style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
  ),
```

```dart
final body = selectedDate == null
    ? '날짜를 누르면 같은 화면 아래에서 그날의 거래를 시간순으로 볼 수 있어요.'
    : '선택한 날짜의 거래를 아래에서 바로 확인하고, 필터와 검색은 같은 기준으로 유지돼요.';
```

- [ ] **Step 5: 위젯 테스트를 다시 실행해서 통과 확인**

Run:

```powershell
& 'C:\smart wallet\flutterw.bat' test --no-pub test\features\calendar\presentation\calendar_screen_test.dart
```

Expected:
- `All tests passed!`

- [ ] **Step 6: Commit**

```powershell
git -C 'C:\smart wallet\app' add lib/features/calendar/presentation/calendar_screen.dart test/features/calendar/presentation/calendar_screen_test.dart
git -C 'C:\smart wallet\app' commit -m "feat: add calendar exploration controls"
```

---

### Task 3: 홈 달력 요약 카드 연결

**Files:**
- Modify: `C:\smart wallet\app\lib\features\dashboard\presentation\dashboard_home_links_card.dart`
- Modify: `C:\smart wallet\app\lib\features\dashboard\presentation\dashboard_screen.dart`
- Modify: `C:\smart wallet\app\test\features\dashboard\dashboard_home_links_card_test.dart`

- [ ] **Step 1: 홈 카드 표시 테스트를 먼저 보강**

```dart
testWidgets('home links card shows calendar counts and totals', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: DashboardHomeLinksCard(
        onOpenCalendar: () {},
        onOpenStatistics: () {},
        calendarSummary: const CalendarHomeSummary(
          date: DateTime(2026, 5, 5),
          transactionCount: 3,
          income: 50000,
          expense: 18000,
        ),
      ),
    ),
  );

  expect(find.text('오늘 3건'), findsOneWidget);
  expect(find.textContaining('수입'), findsWidgets);
  expect(find.textContaining('지출'), findsWidgets);
});
```

- [ ] **Step 2: 테스트를 실행해 실패를 확인**

Run:

```powershell
& 'C:\smart wallet\flutterw.bat' test --no-pub test\features\dashboard\dashboard_home_links_card_test.dart
```

Expected:
- `The named parameter 'calendarSummary' isn't defined`

- [ ] **Step 3: 홈 카드에 새 입력과 표시를 추가**

```dart
class DashboardHomeLinksCard extends StatelessWidget {
  const DashboardHomeLinksCard({
    super.key,
    required this.onOpenCalendar,
    required this.onOpenStatistics,
    required this.calendarSummary,
  });

  final VoidCallback onOpenCalendar;
  final VoidCallback onOpenStatistics;
  final CalendarHomeSummary? calendarSummary;
```

```dart
if (calendarSummary != null) ...[
  const SizedBox(height: AppSpacing.md),
  Wrap(
    spacing: AppSpacing.sm,
    runSpacing: AppSpacing.sm,
    children: [
      _MiniInfoChip(label: '오늘 ${calendarSummary!.transactionCount}건'),
      _MiniInfoChip(label: '수입 ${_formatAmount(calendarSummary!.income)}'),
      _MiniInfoChip(label: '지출 ${_formatAmount(calendarSummary!.expense)}'),
    ],
  ),
],
```

```dart
final calendarSummaryAsync = ref.watch(calendarHomeSummaryProvider);

DashboardHomeLinksCard(
  onOpenCalendar: () => context.push('/calendar'),
  onOpenStatistics: () => context.push('/statistics'),
  calendarSummary: calendarSummaryAsync.valueOrNull,
),
```

- [ ] **Step 4: 홈 카드 테스트를 다시 실행해 통과 확인**

Run:

```powershell
& 'C:\smart wallet\flutterw.bat' test --no-pub test\features\dashboard\dashboard_home_links_card_test.dart
```

Expected:
- `All tests passed!`

- [ ] **Step 5: Commit**

```powershell
git -C 'C:\smart wallet\app' add lib/features/dashboard/presentation/dashboard_home_links_card.dart lib/features/dashboard/presentation/dashboard_screen.dart test/features/dashboard/dashboard_home_links_card_test.dart
git -C 'C:\smart wallet\app' commit -m "feat: show calendar summary on dashboard"
```

---

### Task 4: 통합 검증과 회귀 정리

**Files:**
- Verify only:
  - `C:\smart wallet\app\lib\features\calendar\application\calendar_provider.dart`
  - `C:\smart wallet\app\lib\features\calendar\presentation\calendar_screen.dart`
  - `C:\smart wallet\app\lib\features\dashboard\presentation\dashboard_home_links_card.dart`
  - `C:\smart wallet\app\lib\features\dashboard\presentation\dashboard_screen.dart`
  - `C:\smart wallet\app\test\features\calendar\application\calendar_provider_test.dart`
  - `C:\smart wallet\app\test\features\calendar\presentation\calendar_screen_test.dart`
  - `C:\smart wallet\app\test\features\dashboard\dashboard_home_links_card_test.dart`

- [ ] **Step 1: 분석 실행**

Run:

```powershell
& 'C:\smart wallet\dartw.bat' analyze lib\features\calendar lib\features\dashboard test\features\calendar test\features\dashboard\dashboard_home_links_card_test.dart
```

Expected:
- `No issues found!`

- [ ] **Step 2: 달력/홈 관련 테스트 묶음 실행**

Run:

```powershell
& 'C:\smart wallet\flutterw.bat' test --no-pub test\features\calendar\application\calendar_provider_test.dart test\features\calendar\presentation\calendar_screen_test.dart test\features\dashboard\dashboard_home_links_card_test.dart
```

Expected:
- `All tests passed!`

- [ ] **Step 3: 데스크톱 빌드 회귀 확인**

Run:

```powershell
& 'C:\smart wallet\flutterw.bat' build windows --debug --no-pub
```

Expected:
- `Built build\windows\x64\runner\Debug\smart_wallet_app.exe`

- [ ] **Step 4: 최종 커밋**

```powershell
git -C 'C:\smart wallet\app' add lib/features/calendar lib/features/dashboard test/features/calendar test/features/dashboard/dashboard_home_links_card_test.dart
git -C 'C:\smart wallet\app' commit -m "feat: upgrade calendar exploration flow"
```

---

## Self-Review

### Spec coverage
- 홈의 달력 진입 강화: Task 3에서 반영
- 홈의 건수 + 금액 요약: Task 3에서 반영
- 검색해도 달력 구조 유지: Task 1, Task 2에서 반영
- `전체 / 수입 / 지출` 3분할 필터: Task 1, Task 2에서 반영
- 날짜 선택 시 같은 화면 아래 목록 갱신: Task 2에서 반영
- 통계 제외: 작업 범위에 포함하지 않음

### Placeholder scan
- `TODO`, `TBD`, `적절히`, `유사하게` 표현 없음
- 각 태스크에 테스트, 실행 명령, 기대 결과, 커밋 메시지 포함

### Type consistency
- 필터 enum 이름을 `CalendarTransactionFilter`로 통일
- 검색 상태는 `calendarSearchQueryProvider`로 통일
- 홈 요약 타입은 `CalendarHomeSummary`로 통일
