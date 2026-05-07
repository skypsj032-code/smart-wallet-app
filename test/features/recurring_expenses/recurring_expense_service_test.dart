import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet_app/core/database/app_database.dart';
import 'package:smart_wallet_app/features/recurring_expenses/application/recurring_expense_service.dart';

import '../../test_support/sqlite_test_setup.dart';

void main() {
  late AppDatabase database;
  late RecurringExpenseService service;

  setUpAll(() {
    configureSqliteForTests();
  });

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    service = RecurringExpenseService(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('createFixedMonthly rejects invalid schedule values', () async {
    await expectLater(
      service.createFixedMonthly(
        name: 'Rent',
        amount: 0,
        dayOfMonth: 25,
        accountId: 'bank',
        categoryId: 'expense-home',
      ),
      throwsArgumentError,
    );

    await expectLater(
      service.createFixedMonthly(
        name: 'Rent',
        amount: 900000,
        dayOfMonth: 32,
        accountId: 'bank',
        categoryId: 'expense-home',
      ),
      throwsArgumentError,
    );
  });

  test('materializeForMonth creates one expense transaction for the month',
      () async {
    final recurringId = await service.createFixedMonthly(
      name: 'Netflix',
      amount: 17000,
      dayOfMonth: 31,
      accountId: 'card',
      categoryId: 'expense-subscription',
    );

    final created = await service.materializeForMonth(
      recurringId: recurringId,
      month: DateTime(2026, 2, 1),
    );

    expect(created, isTrue);

    final rows = await database.select(database.transactions).get();
    expect(rows, hasLength(1));
    expect(rows.single.type, 'expense');
    expect(rows.single.amount, 17000);
    expect(rows.single.occurredAt, DateTime(2026, 2, 28));
    expect(rows.single.accountId, 'card');
    expect(rows.single.categoryId, 'expense-subscription');
    expect(rows.single.memo, 'Netflix');

    final recurring =
        await database.select(database.recurringExpenses).getSingle();
    expect(recurring.lastCreatedMonthKey, '2026-02');
  });

  test('materializeForMonth does not duplicate an already-created month',
      () async {
    final recurringId = await service.createFixedMonthly(
      name: 'Rent',
      amount: 700000,
      dayOfMonth: 25,
      accountId: 'bank',
      categoryId: 'expense-home',
    );

    final first = await service.materializeForMonth(
      recurringId: recurringId,
      month: DateTime(2026, 5, 1),
    );
    final second = await service.materializeForMonth(
      recurringId: recurringId,
      month: DateTime(2026, 5, 20),
    );

    expect(first, isTrue);
    expect(second, isFalse);

    final rows = await database.select(database.transactions).get();
    expect(rows, hasLength(1));
  });

  test('sortRecurringExpensesByNextDueDate puts the nearest due date first', () {
    final today = DateTime(2026, 5, 20);
    final items = [
      _recurringExpense(localId: 'day_01', name: 'Next month rent', day: 1),
      _recurringExpense(localId: 'day_25', name: 'This month card', day: 25),
      _recurringExpense(localId: 'day_20', name: 'Today insurance', day: 20),
      _recurringExpense(localId: 'day_31', name: 'End month subscription', day: 31),
    ];

    final sorted = sortRecurringExpensesByNextDueDate(items, today: today);

    expect(
      sorted.map((item) => item.localId),
      ['day_20', 'day_25', 'day_31', 'day_01'],
    );
  });
}

RecurringExpense _recurringExpense({
  required String localId,
  required String name,
  required int day,
}) {
  final now = DateTime(2026, 5, 4);
  return RecurringExpense(
    localId: localId,
    name: name,
    amount: 10000,
    dayOfMonth: day,
    accountId: 'bank',
    isActive: true,
    createdAt: now,
    lastModifiedAt: now,
  );
}
