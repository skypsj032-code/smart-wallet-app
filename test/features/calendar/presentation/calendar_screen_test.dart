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
    expect(find.text('\uC218\uC785'), findsOneWidget);
    expect(find.text('\uC9C0\uCD9C'), findsOneWidget);
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
      'switches to day mode and shows inline entry for the selected date',
      (WidgetTester tester) async {
    await _pumpCalendarScreen(
      tester,
      snapshot: snapshot,
      transactions: transactions,
    );

    expect(find.byKey(const Key('calendar-view-day')), findsOneWidget);
    expect(find.byKey(const Key('calendar-view-month')), findsOneWidget);
    expect(find.byKey(const Key('calendar-view-year')), findsOneWidget);
    expect(find.byKey(const Key('calendar-view-week')), findsNothing);

    await _tapCalendarDay(tester, '2026-05-05');
    await _scrollUntilFinderVisible(
      tester,
      find.byKey(const Key('calendar-view-day')),
      -200,
    );
    await tester.tap(find.byKey(const Key('calendar-view-day')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('calendar-inline-entry-card')), findsOneWidget);
    expect(
        find.byKey(const Key('calendar-inline-amount-field')), findsOneWidget);
    expect(
        find.byKey(const Key('calendar-inline-save-button')), findsOneWidget);
  });

  testWidgets('selected-day summary chips stay above the inline entry card',
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
    final inlineTop = tester
        .getTopLeft(find.byKey(const Key('calendar-inline-entry-card')))
        .dy;

    expect(summaryTop, lessThan(inlineTop));
  });
}

Future<void> _pumpCalendarScreen(
  WidgetTester tester, {
  required CalendarSnapshot snapshot,
  required List<Transaction> transactions,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        calendarTodayProvider.overrideWith((ref) => DateTime(2026, 5, 5)),
        calendarSnapshotProvider.overrideWith(
          (ref) => Stream.value(snapshot),
        ),
        quickEntryAccountsProvider.overrideWith(
          (ref) => Stream.value(
            const [
              QuickEntryAccountOption(id: 'cash-wallet', name: '현금'),
            ],
          ),
        ),
        quickEntryCategoriesProvider('expense').overrideWith(
          (ref) => Stream.value(
            const [
              QuickEntryCategoryOption(
                id: 'expense-food',
                name: '식비',
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
                name: '급여',
                type: 'income',
              ),
            ],
          ),
        ),
        selectedCalendarTransactionsProvider.overrideWith((ref) {
          final selectedDate = ref.watch(selectedCalendarDateProvider);
          final filter = ref.watch(calendarTypeFilterProvider);
          final query = ref.watch(calendarSearchQueryProvider);
          return Stream.value(
            _filterTransactions(
              transactions,
              selectedDate: selectedDate,
              filter: filter,
              query: query,
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
    ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
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
