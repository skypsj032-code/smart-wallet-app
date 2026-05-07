import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet_app/core/database/app_database.dart';
import 'package:smart_wallet_app/features/calendar/application/calendar_provider.dart';
import 'package:smart_wallet_app/features/calendar/presentation/calendar_screen.dart';
import 'package:smart_wallet_app/features/transactions/application/quick_entry_options_provider.dart';

void main() {
  final may5 = DateTime(2026, 5, 5);
  final may6 = DateTime(2026, 5, 6);

  final snapshot = CalendarSnapshot(
    mode: CalendarViewMode.month,
    anchorDate: may5,
    periodStart: DateTime(2026, 5, 1),
    periodEnd: DateTime(2026, 6, 1),
    days: [
      CalendarDaySummary(
        date: may5,
        income: 3200000,
        expense: 14000,
        transactionCount: 3,
        matchCount: 3,
      ),
      CalendarDaySummary(
        date: may6,
        income: 0,
        expense: 12000,
        transactionCount: 1,
        matchCount: 1,
      ),
    ],
    totalIncome: 3200000,
    totalExpense: 26000,
  );

  final transactions = [
    _transaction(
      localId: 'tx-expense-cafe',
      type: 'expense',
      amount: 5300,
      occurredAt: DateTime(2026, 5, 5, 8),
      merchantName: 'Star Cafe',
      categoryId: 'expense-food',
    ),
    _transaction(
      localId: 'tx-income-salary',
      type: 'income',
      amount: 3200000,
      occurredAt: DateTime(2026, 5, 5, 9),
      memo: 'May salary',
    ),
    _transaction(
      localId: 'tx-expense-market',
      type: 'expense',
      amount: 8700,
      occurredAt: DateTime(2026, 5, 5, 20),
      merchantName: 'Night Market',
      categoryId: 'expense-food',
    ),
    _transaction(
      localId: 'tx-expense-bakery',
      type: 'expense',
      amount: 12000,
      occurredAt: DateTime(2026, 5, 6, 12),
      merchantName: 'Bakery',
      categoryId: 'expense-food',
    ),
  ];

  testWidgets('keeps explorer controls hidden until the handle opens them',
      (WidgetTester tester) async {
    await _pumpCalendarScreen(
      tester,
      snapshot: snapshot,
      transactions: transactions,
    );

    expect(find.byKey(const Key('calendar-explorer-handle')), findsOneWidget);
    expect(find.byKey(const Key('calendar-search-field')), findsNothing);
    expect(find.byKey(const Key('calendar-filter-all')), findsNothing);
    expect(find.byKey(const Key('calendar-filter-income')), findsNothing);
    expect(find.byKey(const Key('calendar-filter-expense')), findsNothing);

    await tester.tap(find.byKey(const Key('calendar-explorer-handle')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('calendar-search-field')), findsOneWidget);
    expect(find.byKey(const Key('calendar-filter-all')), findsOneWidget);
    expect(find.byKey(const Key('calendar-filter-income')), findsOneWidget);
    expect(find.byKey(const Key('calendar-filter-expense')), findsOneWidget);
    expect(find.text('\uC804\uCCB4'), findsOneWidget);
    expect(find.text('\uC218\uC785'), findsWidgets);
    expect(find.text('\uC9C0\uCD9C'), findsWidgets);
  });

  testWidgets('selected-day list follows filter and search state',
      (WidgetTester tester) async {
    await _pumpCalendarScreen(
      tester,
      snapshot: snapshot,
      transactions: transactions,
    );

    await _tapCalendarDay(tester, '2026-05-05');
    await _scrollUntilTextVisible(tester, 'Star Cafe');

    expect(find.text('Star Cafe'), findsOneWidget);
    expect(find.text('May salary'), findsOneWidget);
    expect(find.text('Night Market'), findsOneWidget);

    await _scrollUntilFinderVisible(
      tester,
      find.byKey(const Key('calendar-explorer-handle')),
      -240,
    );
    await tester.tap(find.byKey(const Key('calendar-explorer-handle')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('calendar-filter-income')));
    await tester.pumpAndSettle();
    await _scrollUntilTextVisible(tester, 'May salary');

    expect(find.text('May salary'), findsOneWidget);
    expect(find.text('Star Cafe'), findsNothing);
    expect(find.text('Night Market'), findsNothing);

    await _scrollUntilFinderVisible(
      tester,
      find.byKey(const Key('calendar-filter-all')),
      -240,
    );
    await tester.tap(find.byKey(const Key('calendar-filter-all')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('calendar-search-field')),
      'star',
    );
    await tester.pumpAndSettle();
    await _scrollUntilTextVisible(tester, 'Star Cafe');

    expect(find.text('Star Cafe'), findsOneWidget);
    expect(find.text('May salary'), findsNothing);
    expect(find.text('Night Market'), findsNothing);
  });

  testWidgets('month view keeps a compact summary block above a dominant grid',
      (WidgetTester tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(340, 737);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await _pumpCalendarScreen(
      tester,
      snapshot: snapshot,
      transactions: transactions,
    );

    final summaryBlock = find.byKey(const Key('calendar-month-summary-block'));
    final gridShell = find.byKey(const Key('calendar-month-grid-shell'));

    expect(summaryBlock, findsOneWidget);
    expect(gridShell, findsOneWidget);
    expect(
      find.byKey(const Key('calendar-month-summary-expense')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('calendar-month-summary-income')),
      findsNothing,
    );
    expect(
      find.descendant(of: summaryBlock, matching: find.text('지출')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: summaryBlock, matching: find.text('수입')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: summaryBlock, matching: find.text('26,000\uC6D0')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: summaryBlock,
        matching: find.text('3,200,000\uC6D0'),
      ),
      findsOneWidget,
    );

    final summaryRect = tester.getRect(summaryBlock);
    final gridRect = tester.getRect(gridShell);

    expect(summaryRect.bottom, lessThan(gridRect.top));
    expect(gridRect.height, greaterThan(summaryRect.height * 3));
  });

  testWidgets('month grid follows the displayed month provider state',
      (WidgetTester tester) async {
    final juneTransactions = [
      _transaction(
        localId: 'tx-expense-june-rent',
        type: 'expense',
        amount: 910000,
        occurredAt: DateTime(2026, 6, 3, 9),
        merchantName: 'June Rent',
        categoryId: 'expense-food',
      ),
      _transaction(
        localId: 'tx-income-june-bonus',
        type: 'income',
        amount: 250000,
        occurredAt: DateTime(2026, 6, 18, 18),
        memo: 'June bonus',
      ),
    ];

    await _pumpCalendarScreen(
      tester,
      snapshot: snapshot,
      transactions: juneTransactions,
      displayedMonth: DateTime(2026, 6, 1),
    );

    expect(find.byKey(const Key('calendar-day-2026-06-03')), findsOneWidget);
    expect(find.byKey(const Key('calendar-day-2026-06-18')), findsOneWidget);
    expect(find.byKey(const Key('calendar-day-2026-05-05')), findsNothing);
  });

  testWidgets('tapping a day updates the lower list on the same screen',
      (WidgetTester tester) async {
    await _pumpCalendarScreen(
      tester,
      snapshot: snapshot,
      transactions: transactions,
    );

    await _tapCalendarDay(tester, '2026-05-05');
    await _scrollUntilTextVisible(tester, 'Star Cafe');

    expect(find.byType(CalendarScreen), findsOneWidget);
    expect(find.text('Star Cafe'), findsOneWidget);
    expect(find.text('Bakery'), findsNothing);

    await _scrollUntilFinderVisible(
      tester,
      find.byKey(const Key('calendar-day-2026-05-06')),
      -240,
    );
    await _tapCalendarDay(tester, '2026-05-06');
    await _scrollUntilTextVisible(tester, 'Bakery');

    expect(find.byType(CalendarScreen), findsOneWidget);
    expect(find.text('Bakery'), findsOneWidget);
    expect(find.text('Star Cafe'), findsNothing);
  });

  testWidgets(
      'selected-day detail stays mounted across month changes and keeps sort controls',
      (WidgetTester tester) async {
    final crossMonthTransactions = [
      ...transactions,
      _transaction(
        localId: 'tx-expense-june-lunch',
        type: 'expense',
        amount: 8800,
        occurredAt: DateTime(2026, 6, 5, 13),
        merchantName: 'June Lunch',
        categoryId: 'expense-food',
      ),
    ];

    await _pumpCalendarScreen(
      tester,
      snapshot: snapshot,
      transactions: crossMonthTransactions,
    );

    await _tapCalendarDay(tester, '2026-05-05');
    await _scrollUntilFinderVisible(
      tester,
      find.byKey(const Key('calendar-selected-day-card')),
      240,
    );

    expect(find.byKey(const Key('calendar-selected-day-card')), findsOneWidget);
    expect(
      find.byKey(const Key('calendar-transaction-sort-toggle')),
      findsOneWidget,
    );

    await tester.tap(find.text('\uC624\uB798\uB41C\uC21C'));
    await tester.pumpAndSettle();

    await _scrollUntilFinderVisible(
      tester,
      find.byKey(const Key('calendar-next-period')),
      -240,
    );
    await tester.tap(find.byKey(const Key('calendar-next-period')));
    await tester.pumpAndSettle();

    await _scrollUntilFinderVisible(
      tester,
      find.byKey(const Key('calendar-selected-day-card')),
      240,
    );

    expect(find.text('6\uC6D4 5\uC77C'), findsOneWidget);
    expect(find.byKey(const Key('calendar-selected-day-card')), findsOneWidget);
    expect(
      find.byKey(const Key('calendar-transaction-sort-toggle')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('calendar-selected-summary-expense')),
      findsOneWidget,
    );
    expect(find.text('8,800\uC6D0'), findsWidgets);
    expect(find.text('June Lunch'), findsOneWidget);
  });

  testWidgets(
      'selected day transactions default to newest first and can be reversed',
      (WidgetTester tester) async {
    await _pumpCalendarScreen(
      tester,
      snapshot: snapshot,
      transactions: transactions,
    );

    await _tapCalendarDay(tester, '2026-05-05');
    await _scrollUntilTextVisible(tester, 'Star Cafe');

    var marketTop = tester.getTopLeft(find.text('Night Market')).dy;
    var salaryTop = tester.getTopLeft(find.text('May salary')).dy;
    var cafeTop = tester.getTopLeft(find.text('Star Cafe')).dy;

    expect(marketTop, lessThan(salaryTop));
    expect(salaryTop, lessThan(cafeTop));

    await tester.tap(find.text('\uC624\uB798\uB41C\uC21C'));
    await tester.pumpAndSettle();
    await _scrollUntilTextVisible(tester, 'Star Cafe');

    marketTop = tester.getTopLeft(find.text('Night Market')).dy;
    salaryTop = tester.getTopLeft(find.text('May salary')).dy;
    cafeTop = tester.getTopLeft(find.text('Star Cafe')).dy;

    expect(cafeTop, lessThan(salaryTop));
    expect(salaryTop, lessThan(marketTop));
  });

  testWidgets('calendar header uses a month label instead of mode chips',
      (WidgetTester tester) async {
    await _pumpCalendarScreen(
      tester,
      snapshot: snapshot,
      transactions: transactions,
    );

    expect(find.byKey(const Key('calendar-month-label')), findsOneWidget);
    expect(find.text('2026.05'), findsOneWidget);
    expect(find.byKey(const Key('calendar-previous-period')), findsOneWidget);
    expect(find.byKey(const Key('calendar-next-period')), findsOneWidget);
    expect(find.byKey(const Key('calendar-view-week')), findsNothing);
    expect(find.byKey(const Key('calendar-view-day')), findsNothing);
    expect(find.byKey(const Key('calendar-view-month')), findsNothing);
    expect(find.byKey(const Key('calendar-view-year')), findsNothing);
    expect(find.text('\uC8FC\uAC04'), findsNothing);
    expect(find.text('\uC77C\uBCC4'), findsNothing);
    expect(find.text('\uC6D4\uBCC4'), findsNothing);
    expect(find.text('\uC5F0\uBCC4'), findsNothing);
  });

  testWidgets('month header arrows move the displayed month label',
      (WidgetTester tester) async {
    await _pumpCalendarScreen(
      tester,
      snapshot: snapshot,
      transactions: transactions,
    );

    expect(find.text('2026.05'), findsOneWidget);

    await tester.tap(find.byKey(const Key('calendar-next-period')));
    await tester.pumpAndSettle();
    expect(find.text('2026.06'), findsOneWidget);

    await tester.tap(find.byKey(const Key('calendar-previous-period')));
    await tester.pumpAndSettle();
    expect(find.text('2026.05'), findsOneWidget);
  });

  testWidgets('tapping the month label opens the inline picker in place',
      (WidgetTester tester) async {
    await _pumpCalendarScreen(
      tester,
      snapshot: snapshot,
      transactions: transactions,
    );

    expect(find.byKey(const Key('calendar-month-grid')), findsOneWidget);
    expect(find.byKey(const Key('calendar-inline-month-picker')), findsNothing);

    await tester.tap(find.byKey(const Key('calendar-month-label')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('calendar-inline-month-picker')), findsOneWidget);
    expect(find.byKey(const Key('calendar-month-grid')), findsNothing);
    expect(find.byType(CalendarScreen), findsOneWidget);
  });

  testWidgets('selecting a month in the inline picker returns to the month grid',
      (WidgetTester tester) async {
    await _pumpCalendarScreen(
      tester,
      snapshot: snapshot,
      transactions: transactions,
    );

    await tester.tap(find.byKey(const Key('calendar-month-label')));
    await tester.pumpAndSettle();

    expect(find.text('11월'), findsOneWidget);

    await tester.tap(find.text('11월'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('calendar-inline-month-picker')), findsNothing);
    expect(find.byKey(const Key('calendar-month-grid')), findsOneWidget);
    expect(find.text('2026.11'), findsOneWidget);
  });

  testWidgets('changing the displayed month scrolls back to the top',
      (WidgetTester tester) async {
    await _pumpCalendarScreen(
      tester,
      snapshot: snapshot,
      transactions: transactions,
    );

    await _tapCalendarDay(tester, '2026-05-05');
    await _scrollUntilTextVisible(tester, 'Star Cafe');

    final scrollable =
        tester.state<ScrollableState>(find.byType(Scrollable).first);
    final beforeSwitchOffset = scrollable.position.pixels;
    expect(beforeSwitchOffset, greaterThan(0));

    await _scrollUntilFinderVisible(
      tester,
      find.byKey(const Key('calendar-next-period')),
      -240,
    );
    await tester.tap(find.byKey(const Key('calendar-next-period')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 260));

    expect(scrollable.position.pixels, lessThan(beforeSwitchOffset));
  });

  testWidgets('selected-day summary chips stay above the transaction list',
      (WidgetTester tester) async {
    await _pumpCalendarScreen(
      tester,
      snapshot: snapshot,
      transactions: transactions,
    );

    await _tapCalendarDay(tester, '2026-05-05');
    await _scrollUntilFinderVisible(
      tester,
      find.byKey(const Key('calendar-selected-summary-income')),
      240,
    );

    final summaryTop = tester
        .getTopLeft(find.byKey(const Key('calendar-selected-summary-income')))
        .dy;
    final transactionTop = tester.getTopLeft(find.text('Star Cafe')).dy;

    expect(summaryTop, lessThan(transactionTop));
  });

  testWidgets('month view does not overflow on compact window size',
      (WidgetTester tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(340, 737);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await _pumpCalendarScreen(
      tester,
      snapshot: snapshot,
      transactions: transactions,
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('inline picker does not overflow on compact window size',
      (WidgetTester tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(340, 737);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await _pumpCalendarScreen(
      tester,
      snapshot: snapshot,
      transactions: transactions,
    );

    await tester.tap(find.byKey(const Key('calendar-month-label')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('calendar-inline-month-picker')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('month header controls do not crash the calendar screen',
      (WidgetTester tester) async {
    await _pumpCalendarScreen(
      tester,
      snapshot: snapshot,
      transactions: transactions,
    );

    await tester.tap(find.byKey(const Key('calendar-next-period')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('calendar-previous-period')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpCalendarScreen(
  WidgetTester tester, {
  required CalendarSnapshot snapshot,
  required List<Transaction> transactions,
  DateTime? displayedMonth,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        calendarTodayProvider.overrideWith((ref) => DateTime(2026, 5, 5)),
        displayedCalendarMonthProvider.overrideWith(
          (ref) => displayedMonth ??
              DateTime(snapshot.periodStart.year, snapshot.periodStart.month, 1),
        ),
        visibleCalendarDateProvider.overrideWith((ref) => snapshot.anchorDate),
        calendarSnapshotProvider.overrideWith((ref) {
          final month = ref.watch(displayedCalendarMonthProvider);
          final anchorDate = ref.watch(visibleCalendarDateProvider);
          return Stream.value(
            _buildSnapshot(
              displayedMonth: month,
              anchorDate: anchorDate,
              transactions: transactions,
            ),
          );
        }),
        quickEntryAccountsProvider.overrideWith(
          (ref) => Stream.value(
            const [
              QuickEntryAccountOption(
                id: 'cash-wallet',
                name: '\uD604\uAE08',
              ),
            ],
          ),
        ),
        quickEntryCategoriesProvider('expense').overrideWith(
          (ref) => Stream.value(
            const [
              QuickEntryCategoryOption(
                id: 'expense-food',
                name: '\uC2DD\uBE44',
                type: 'expense',
              ),
            ],
          ),
        ),
        quickEntryCategoriesProvider('income').overrideWith(
          (ref) => Stream.value(
            const [
              QuickEntryCategoryOption(
                id: 'income-salary',
                name: '\uAE09\uC5EC',
                type: 'income',
              ),
            ],
          ),
        ),
        selectedCalendarTransactionsProvider.overrideWith((ref) {
          final selectedDate = ref.watch(selectedCalendarDateProvider);
          final filter = ref.watch(calendarTypeFilterProvider);
          final query = ref.watch(calendarSearchQueryProvider);
          final sortOrder = ref.watch(calendarTransactionSortOrderProvider);
          return Stream.value(
            _filterTransactions(
              transactions,
              selectedDate: selectedDate,
              filter: filter,
              query: query,
              sortOrder: sortOrder,
            ),
          );
        }),
      ],
      child: const MaterialApp(
        home: CalendarScreen(),
      ),
    ),
  );

  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

CalendarSnapshot _buildSnapshot({
  required DateTime displayedMonth,
  required DateTime anchorDate,
  required List<Transaction> transactions,
}) {
  final periodStart = _normalizeMonthForTest(displayedMonth);
  final periodEnd = DateTime(periodStart.year, periodStart.month + 1, 1);
  final grouped = <DateTime, CalendarDaySummary>{};
  var totalIncome = 0;
  var totalExpense = 0;

  for (final transaction in transactions) {
    if (transaction.occurredAt.isBefore(periodStart) ||
        !transaction.occurredAt.isBefore(periodEnd)) {
      continue;
    }

    final key = DateTime(
      transaction.occurredAt.year,
      transaction.occurredAt.month,
      transaction.occurredAt.day,
    );
    final current = grouped[key] ??
        CalendarDaySummary(
          date: key,
          income: 0,
          expense: 0,
        );

    final nextIncome = transaction.type == 'income'
        ? current.income + transaction.amount
        : current.income;
    final nextExpense = transaction.type == 'expense'
        ? current.expense + transaction.amount
        : current.expense;

    if (transaction.type == 'income') {
      totalIncome += transaction.amount;
    } else if (transaction.type == 'expense') {
      totalExpense += transaction.amount;
    }

    grouped[key] = CalendarDaySummary(
      date: key,
      income: nextIncome,
      expense: nextExpense,
      transactionCount: current.transactionCount + 1,
      matchCount: current.matchCount + 1,
    );
  }

  final days = grouped.values.toList()..sort((a, b) => a.date.compareTo(b.date));

  return CalendarSnapshot(
    mode: CalendarViewMode.month,
    anchorDate: anchorDate,
    periodStart: periodStart,
    periodEnd: periodEnd,
    days: days,
    totalIncome: totalIncome,
    totalExpense: totalExpense,
  );
}

DateTime _normalizeMonthForTest(DateTime value) {
  return DateTime(value.year, value.month, 1);
}

Future<void> _tapCalendarDay(
  WidgetTester tester,
  String dayKey,
) async {
  final finder = find.byKey(Key('calendar-day-$dayKey'));
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _scrollUntilTextVisible(
  WidgetTester tester,
  String text,
) async {
  await _scrollUntilFinderVisible(tester, find.text(text), 240);
  await tester.pumpAndSettle();
}

Future<void> _scrollUntilFinderVisible(
  WidgetTester tester,
  Finder finder,
  double delta,
) async {
  await tester.scrollUntilVisible(
    finder,
    delta,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

List<Transaction> _filterTransactions(
  List<Transaction> transactions, {
  required DateTime? selectedDate,
  required CalendarTransactionFilter filter,
  required String query,
  required CalendarTransactionSortOrder sortOrder,
}) {
  if (selectedDate == null) {
    return const <Transaction>[];
  }

  final normalizedQuery = query.trim().toLowerCase();

  return transactions.where((transaction) {
    if (!_isSameDate(transaction.occurredAt, selectedDate)) {
      return false;
    }

    final matchesType = switch (filter) {
      CalendarTransactionFilter.all => true,
      CalendarTransactionFilter.income => transaction.type == 'income',
      CalendarTransactionFilter.expense => transaction.type == 'expense',
    };
    if (!matchesType) {
      return false;
    }

    if (normalizedQuery.isEmpty) {
      return true;
    }

    final haystacks = <String>[
      transaction.memo ?? '',
      transaction.merchantName ?? '',
      if (transaction.categoryId == 'expense-food') 'food',
    ];

    return haystacks.any(
      (value) => value.toLowerCase().contains(normalizedQuery),
    );
  }).toList()
    ..sort((a, b) => switch (sortOrder) {
          CalendarTransactionSortOrder.newestFirst =>
            b.occurredAt.compareTo(a.occurredAt),
          CalendarTransactionSortOrder.oldestFirst =>
            a.occurredAt.compareTo(b.occurredAt),
        });
}

bool _isSameDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

Transaction _transaction({
  required String localId,
  required String type,
  required int amount,
  required DateTime occurredAt,
  String? categoryId,
  String? merchantName,
  String? memo,
}) {
  return Transaction(
    localId: localId,
    type: type,
    amount: amount,
    occurredAt: occurredAt,
    categoryId: categoryId,
    merchantName: merchantName,
    memo: memo,
    createdAt: occurredAt,
    lastModifiedAt: occurredAt,
  );
}
