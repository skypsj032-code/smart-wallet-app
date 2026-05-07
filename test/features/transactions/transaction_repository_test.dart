import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet_app/core/database/app_database.dart';
import 'package:smart_wallet_app/features/transactions/application/quick_entry_form_provider.dart';
import 'package:smart_wallet_app/features/transactions/data/transaction_repository.dart';

import '../../test_support/sqlite_test_setup.dart';

void main() {
  late AppDatabase database;
  late TransactionRepository repository;

  setUpAll(() {
    configureSqliteForTests();
  });

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = TransactionRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('createFromQuickEntry stores an expense transaction', () async {
    await repository.createFromQuickEntry(
      QuickEntryFormState(
        type: TransactionEntryType.expense,
        amount: '12000',
        accountId: 'cash',
        categoryId: 'expense-food',
        memo: 'lunch',
        occurredAt: DateTime(2026, 5, 4, 12, 30),
      ),
    );

    final rows = await database.select(database.transactions).get();
    expect(rows, hasLength(1));
    expect(rows.single.type, 'expense');
    expect(rows.single.amount, 12000);
    expect(rows.single.accountId, 'cash');
    expect(rows.single.categoryId, 'expense-food');
    expect(rows.single.fromAccountId, isNull);
    expect(rows.single.toAccountId, isNull);
    expect(rows.single.memo, 'lunch');
  });

  test('createFromQuickEntry rejects transfer between the same account', () async {
    await expectLater(
      repository.createFromQuickEntry(
        const QuickEntryFormState(
          type: TransactionEntryType.transfer,
          amount: '5000',
          fromAccountId: 'cash',
          toAccountId: 'cash',
        ),
      ),
      throwsArgumentError,
    );

    final rows = await database.select(database.transactions).get();
    expect(rows, isEmpty);
  });

  test('updateFromQuickEntry converts transfer into expense and clears transfer fields',
      () async {
    await repository.createFromQuickEntry(
      QuickEntryFormState(
        type: TransactionEntryType.transfer,
        amount: '30000',
        fromAccountId: 'bank',
        toAccountId: 'cash',
        memo: 'withdraw',
        occurredAt: DateTime(2026, 5, 4, 9),
      ),
    );
    final original = await database.select(database.transactions).getSingle();

    await repository.updateFromQuickEntry(
      QuickEntryFormState(
        type: TransactionEntryType.expense,
        amount: '18000',
        accountId: 'card',
        categoryId: 'expense-shopping',
        memo: 'supplies',
        occurredAt: DateTime(2026, 5, 4, 10),
        editingId: original.localId,
      ),
    );

    final updated = await database.select(database.transactions).getSingle();
    expect(updated.type, 'expense');
    expect(updated.amount, 18000);
    expect(updated.accountId, 'card');
    expect(updated.categoryId, 'expense-shopping');
    expect(updated.fromAccountId, isNull);
    expect(updated.toAccountId, isNull);
    expect(updated.memo, 'supplies');
  });

  test('softDeleteTransaction hides a transaction without removing the row', () async {
    await repository.createFromQuickEntry(
      QuickEntryFormState(
        type: TransactionEntryType.income,
        amount: '90000',
        accountId: 'bank',
        categoryId: 'income-salary',
        occurredAt: DateTime(2026, 5, 4, 8),
      ),
    );
    final original = await database.select(database.transactions).getSingle();

    await repository.softDeleteTransaction(original.localId);

    final deleted = await database.select(database.transactions).getSingle();
    expect(deleted.deletedAt, isNotNull);
    expect(deleted.lastModifiedAt.isAfter(original.lastModifiedAt), isTrue);
  });
}
