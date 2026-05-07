import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet_app/core/database/app_database.dart';
import 'package:smart_wallet_app/features/recurring_expenses/application/recurring_expense_service.dart';
import 'package:smart_wallet_app/features/recurring_expenses/application/recurring_transaction_suggestion.dart';

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

  test('createRecurringTransaction rejects invalid schedule values', () async {
    await expectLater(
      service.createRecurringTransaction(
        name: 'Rent',
        type: 'expense',
        amount: 0,
        cadence: 'monthly',
        dayOfMonth: 25,
        weekday: null,
        accountId: 'bank',
        categoryId: 'expense-home',
      ),
      throwsArgumentError,
    );

    await expectLater(
      service.createRecurringTransaction(
        name: 'Rent',
        type: 'expense',
        amount: 900000,
        cadence: 'weekly',
        dayOfMonth: null,
        weekday: 8,
        accountId: 'bank',
        categoryId: 'expense-home',
      ),
      throwsArgumentError,
    );
  });

  test('selectDueSuggestion returns the highest priority due recurring item',
      () async {
    await service.createRecurringTransaction(
      name: 'Salary',
      type: 'income',
      amount: 3200000,
      cadence: 'monthly',
      dayOfMonth: 10,
      weekday: null,
      accountId: 'bank_main',
      categoryId: 'income-salary',
    );
    await service.createRecurringTransaction(
      name: 'Phone Bill',
      type: 'expense',
      amount: 55000,
      cadence: 'monthly',
      dayOfMonth: 10,
      weekday: null,
      accountId: 'card_main',
      categoryId: 'expense-telecom',
    );

    final suggestion = await service.selectDueSuggestion(
      today: DateTime(2026, 5, 10),
    );

    expect(suggestion, isNotNull);
    expect(suggestion!.transaction.name, 'Salary');
    expect(suggestion.cycleKey, '2026-05');
  });

  test('dismissSuggestion hides only the current cycle', () async {
    final recurringId = await service.createRecurringTransaction(
      name: 'Phone Bill',
      type: 'expense',
      amount: 55000,
      cadence: 'monthly',
      dayOfMonth: 10,
      weekday: null,
      accountId: 'card_main',
      categoryId: 'expense-telecom',
    );

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

  test(
      'createTransactionFromSuggestion inserts one transaction and closes the cycle',
      () async {
    final recurringId = await service.createRecurringTransaction(
      name: 'Phone Bill',
      type: 'expense',
      amount: 55000,
      cadence: 'monthly',
      dayOfMonth: 10,
      weekday: null,
      accountId: 'card_main',
      categoryId: 'expense-telecom',
    );

    final created = await service.createTransactionFromSuggestion(
      recurringId: recurringId,
      today: DateTime(2026, 5, 10),
    );

    expect(created, isTrue);

    final rows = await database.select(database.transactions).get();
    expect(rows, hasLength(1));
    expect(rows.single.type, 'expense');
    expect(rows.single.amount, 55000);
    expect(rows.single.accountId, 'card_main');
    expect(rows.single.categoryId, 'expense-telecom');
    expect(rows.single.memo, 'Phone Bill');
    expect(rows.single.occurredAt, DateTime(2026, 5, 10));

    final recurring =
        await database.select(database.recurringExpenses).getSingle();
    expect(recurring.lastCompletedCycleKey, '2026-05');

    final repeated = await service.selectDueSuggestion(
      today: DateTime(2026, 5, 10),
    );
    expect(repeated, isNull);
  });

  test('sortRecurringExpensesByNextDueDate puts the nearest due date first', () {
    final today = DateTime(2026, 5, 20);
    final items = [
      _recurringExpense(
        localId: 'week_sun',
        name: 'Sunday',
        cadence: 'weekly',
        dayOfMonth: null,
        weekday: DateTime.sunday,
      ),
      _recurringExpense(
        localId: 'month_25',
        name: 'This month card',
        cadence: 'monthly',
        dayOfMonth: 25,
        weekday: null,
      ),
      _recurringExpense(
        localId: 'week_tue',
        name: 'Tuesday',
        cadence: 'weekly',
        dayOfMonth: null,
        weekday: DateTime.tuesday,
      ),
    ];

    final sorted = sortRecurringExpensesByNextDueDate(items, today: today);

    expect(
      sorted.map((item) => item.localId),
      ['week_sun', 'month_25', 'week_tue'],
    );
  });

  test('recurringCycleKey uses month key for monthly and week start for weekly',
      () {
    expect(
      recurringCycleKey(cadence: 'monthly', date: DateTime(2026, 5, 10)),
      '2026-05',
    );
    expect(
      recurringCycleKey(cadence: 'weekly', date: DateTime(2026, 5, 10)),
      '2026-05-04',
    );
  });
}

RecurringExpense _recurringExpense({
  required String localId,
  required String name,
  required String cadence,
  required int? dayOfMonth,
  required int? weekday,
}) {
  final now = DateTime(2026, 5, 4);
  return RecurringExpense(
    localId: localId,
    name: name,
    type: 'expense',
    amount: 10000,
    cadence: cadence,
    dayOfMonth: dayOfMonth,
    weekday: weekday,
    accountId: 'bank',
    isActive: true,
    createdAt: now,
    lastModifiedAt: now,
  );
}
