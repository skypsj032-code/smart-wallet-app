import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet_app/core/database/app_database.dart';
import 'package:smart_wallet_app/core/database/providers/database_providers.dart';
import 'package:smart_wallet_app/features/calendar/application/calendar_provider.dart';

import '../../../test_support/sqlite_test_setup.dart';

void main() {
  late AppDatabase database;
  late ProviderContainer container;

  setUpAll(configureSqliteForTests);

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        calendarTodayProvider.overrideWith((ref) => DateTime(2026, 5, 5)),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await database.close();
  });

  test('calendarSnapshotProvider filters days by type and search query',
      () async {
    await _insertCategory(
      database,
      localId: 'expense-cafe-snack',
      name: 'Cafe Snack',
      type: 'expense',
    );
    await _insertCategory(
      database,
      localId: 'income-salary',
      name: 'Salary',
      type: 'income',
    );
    await _insertTransaction(
      database,
      localId: 'tx-expense-match',
      type: 'expense',
      amount: 5300,
      occurredAt: DateTime(2026, 5, 5, 8),
      categoryId: 'expense-cafe-snack',
      merchantName: 'Star Cafe Gangnam',
    );
    await _insertTransaction(
      database,
      localId: 'tx-income-other',
      type: 'income',
      amount: 3200000,
      occurredAt: DateTime(2026, 5, 5, 9),
      categoryId: 'income-salary',
      memo: 'May salary',
    );
    await _insertTransaction(
      database,
      localId: 'tx-expense-other-day',
      type: 'expense',
      amount: 12000,
      occurredAt: DateTime(2026, 5, 6, 12),
      merchantName: 'Bakery',
    );
    await _insertTransaction(
      database,
      localId: 'tx-expense-same-day-non-match',
      type: 'expense',
      amount: 8700,
      occurredAt: DateTime(2026, 5, 5, 20),
      merchantName: 'Night Market',
    );

    container.read(visibleCalendarDateProvider.notifier).state =
        DateTime(2026, 5, 5);
    container.read(calendarTypeFilterProvider.notifier).state =
        CalendarTransactionFilter.expense;
    container.read(calendarSearchQueryProvider.notifier).state = 'star';

    final snapshot = await container.read(calendarSnapshotProvider.future);

    expect(snapshot.totalIncome, 0);
    expect(snapshot.totalExpense, 5300);
    expect(snapshot.days, hasLength(1));
    expect(snapshot.days.single.date, DateTime(2026, 5, 5));
    expect(snapshot.days.single.transactionCount, 2);
    expect(snapshot.days.single.matchCount, 1);
    expect(snapshot.days.single.income, 0);
    expect(snapshot.days.single.expense, 5300);
  });

  test('selectedCalendarTransactionsProvider filters by category search query',
      () async {
    await _insertCategory(
      database,
      localId: 'expense-travel',
      name: 'Travel',
      type: 'expense',
      isActive: false,
    );
    await _insertTransaction(
      database,
      localId: 'tx-category-match',
      type: 'expense',
      amount: 4500,
      occurredAt: DateTime(2026, 5, 5, 14),
      categoryId: 'expense-travel',
      merchantName: 'Gangnam Station',
    );
    await _insertTransaction(
      database,
      localId: 'tx-no-match',
      type: 'expense',
      amount: 7000,
      occurredAt: DateTime(2026, 5, 5, 18),
      merchantName: 'Bookstore',
    );

    container.read(selectedCalendarDateProvider.notifier).state =
        DateTime(2026, 5, 5);
    container.read(calendarSearchQueryProvider.notifier).state = 'travel';

    final transactions =
        await container.read(selectedCalendarTransactionsProvider.future);

    expect(transactions, hasLength(1));
    expect(transactions.single.localId, 'tx-category-match');
  });

  test('selectedCalendarTransactionsProvider filters by memo search query',
      () async {
    await _insertTransaction(
      database,
      localId: 'tx-memo-match',
      type: 'expense',
      amount: 18000,
      occurredAt: DateTime(2026, 5, 5, 11),
      memo: 'Team dinner meal',
      merchantName: 'Office Restaurant',
    );
    await _insertTransaction(
      database,
      localId: 'tx-memo-no-match',
      type: 'expense',
      amount: 4900,
      occurredAt: DateTime(2026, 5, 5, 15),
      memo: 'Coffee beans',
      merchantName: 'Cafe',
    );

    container.read(selectedCalendarDateProvider.notifier).state =
        DateTime(2026, 5, 5);
    container.read(calendarSearchQueryProvider.notifier).state = 'dinner';

    final transactions =
        await container.read(selectedCalendarTransactionsProvider.future);

    expect(transactions, hasLength(1));
    expect(transactions.single.localId, 'tx-memo-match');
  });

  test('selectedCalendarTransactionsProvider filters by merchant search query',
      () async {
    await _insertTransaction(
      database,
      localId: 'tx-merchant-match',
      type: 'expense',
      amount: 8200,
      occurredAt: DateTime(2026, 5, 5, 13),
      merchantName: 'Olive Young Gangnam',
    );
    await _insertTransaction(
      database,
      localId: 'tx-merchant-no-match',
      type: 'expense',
      amount: 6500,
      occurredAt: DateTime(2026, 5, 5, 16),
      merchantName: 'Homeplus',
    );

    container.read(selectedCalendarDateProvider.notifier).state =
        DateTime(2026, 5, 5);
    container.read(calendarSearchQueryProvider.notifier).state = 'olive';

    final transactions =
        await container.read(selectedCalendarTransactionsProvider.future);

    expect(transactions, hasLength(1));
    expect(transactions.single.localId, 'tx-merchant-match');
  });

  test('calendarHomeSummaryProvider returns today count and totals', () async {
    await _insertTransaction(
      database,
      localId: 'tx-today-income',
      type: 'income',
      amount: 100000,
      occurredAt: DateTime(2026, 5, 5, 9),
    );
    await _insertTransaction(
      database,
      localId: 'tx-today-expense',
      type: 'expense',
      amount: 23000,
      occurredAt: DateTime(2026, 5, 5, 19),
    );
    await _insertTransaction(
      database,
      localId: 'tx-other-day',
      type: 'expense',
      amount: 999,
      occurredAt: DateTime(2026, 5, 4, 19),
    );

    final summary = await container.read(calendarHomeSummaryProvider.future);

    expect(summary.date, DateTime(2026, 5, 5));
    expect(summary.transactionCount, 2);
    expect(summary.income, 100000);
    expect(summary.expense, 23000);
  });
}

Future<void> _insertCategory(
  AppDatabase database, {
  required String localId,
  required String name,
  required String type,
  bool isActive = true,
}) {
  final now = DateTime(2026, 5, 5);
  return database.into(database.categories).insert(
        CategoriesCompanion.insert(
          localId: localId,
          name: name,
          type: type,
          isActive: Value(isActive),
          createdAt: now,
          lastModifiedAt: now,
        ),
      );
}

Future<void> _insertTransaction(
  AppDatabase database, {
  required String localId,
  required String type,
  required int amount,
  required DateTime occurredAt,
  String? categoryId,
  String? merchantName,
  String? memo,
}) {
  return database.into(database.transactions).insert(
        TransactionsCompanion.insert(
          localId: localId,
          type: type,
          amount: amount,
          occurredAt: occurredAt,
          categoryId: Value(categoryId),
          merchantName: Value(merchantName),
          memo: Value(memo),
          createdAt: occurredAt,
          lastModifiedAt: occurredAt,
        ),
      );
}
