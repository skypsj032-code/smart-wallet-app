import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet_app/core/database/app_database.dart';
import 'package:smart_wallet_app/core/database/providers/database_providers.dart';
import 'package:smart_wallet_app/features/calendar/application/calendar_inline_entry_controller.dart';
import 'package:smart_wallet_app/features/calendar/application/calendar_provider.dart';
import 'package:smart_wallet_app/features/transactions/application/quick_entry_form_provider.dart';

import '../../../test_support/sqlite_test_setup.dart';

void main() {
  late AppDatabase database;
  late ProviderContainer container;
  final selectedDate = DateTime(2026, 5, 7);

  setUpAll(configureSqliteForTests);

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        calendarTodayProvider.overrideWith((ref) => selectedDate),
      ],
    );

    container.read(selectedCalendarDateProvider.notifier).state = selectedDate;

    await _insertAccount(
      database,
      localId: 'cash-wallet',
      name: '현금',
      type: 'cash',
    );
    await _insertCategory(
      database,
      localId: 'expense-food',
      name: '식비',
      type: 'expense',
      sortOrder: 1,
    );
    await _insertCategory(
      database,
      localId: 'income-salary',
      name: '급여',
      type: 'income',
      sortOrder: 1,
    );
  });

  tearDown(() async {
    container.dispose();
    await database.close();
  });

  test('save inserts a transaction on the selected date and clears the draft',
      () async {
    final notifier = container.read(calendarInlineEntryControllerProvider.notifier);

    notifier.setType(TransactionEntryType.expense);
    notifier.setAccount('cash-wallet');
    notifier.setCategory('expense-food');
    notifier.setAmount('5300');
    notifier.setMemo('점심');

    final saved = await notifier.save();
    final transactions = await database.select(database.transactions).get();
    final state = container.read(calendarInlineEntryControllerProvider);

    expect(saved, isTrue);
    expect(transactions, hasLength(1));
    expect(transactions.single.type, 'expense');
    expect(transactions.single.amount, 5300);
    expect(transactions.single.accountId, 'cash-wallet');
    expect(transactions.single.categoryId, 'expense-food');
    expect(transactions.single.memo, '점심');
    expect(
      transactions.single.occurredAt,
      DateTime(2026, 5, 7),
    );
    expect(state.form.amount, isEmpty);
    expect(state.form.memo, isEmpty);
    expect(state.form.occurredAt, DateTime(2026, 5, 7));
    expect(state.form.accountId, 'cash-wallet');
    expect(state.form.categoryId, 'expense-food');
  });

  test('save updates the loaded transaction instead of inserting a new row',
      () async {
    await database.into(database.transactions).insert(
          TransactionsCompanion.insert(
            localId: 'tx-existing',
            type: 'expense',
            amount: 4100,
            occurredAt: DateTime(2026, 5, 7, 9),
            accountId: const Value('cash-wallet'),
            categoryId: const Value('expense-food'),
            memo: const Value('아침'),
            createdAt: DateTime(2026, 5, 7, 9),
            lastModifiedAt: DateTime(2026, 5, 7, 9),
          ),
        );

    final transaction = await (database.select(database.transactions)
          ..where((tbl) => tbl.localId.equals('tx-existing')))
        .getSingle();

    final notifier = container.read(calendarInlineEntryControllerProvider.notifier);
    notifier.loadTransaction(transaction);
    notifier.setAmount('9900');
    notifier.setMemo('점심 약속');

    final saved = await notifier.save();
    final transactions = await database.select(database.transactions).get();
    final updated = transactions.singleWhere((row) => row.localId == 'tx-existing');

    expect(saved, isTrue);
    expect(transactions, hasLength(1));
    expect(updated.amount, 9900);
    expect(updated.memo, '점심 약속');
    expect(updated.accountId, 'cash-wallet');
    expect(updated.categoryId, 'expense-food');
  });

  test('reset keeps the selected date but clears typed values', () {
    final notifier = container.read(calendarInlineEntryControllerProvider.notifier);

    notifier.setAccount('cash-wallet');
    notifier.setCategory('expense-food');
    notifier.setAmount('12000');
    notifier.setMemo('장보기');
    notifier.reset();

    final state = container.read(calendarInlineEntryControllerProvider);

    expect(state.form.amount, isEmpty);
    expect(state.form.memo, isEmpty);
    expect(state.form.occurredAt, DateTime(2026, 5, 7));
    expect(state.form.accountId, 'cash-wallet');
    expect(state.form.categoryId, 'expense-food');
    expect(state.form.editingId, isNull);
  });
}

Future<void> _insertAccount(
  AppDatabase database, {
  required String localId,
  required String name,
  required String type,
}) {
  final now = DateTime(2026, 5, 7);
  return database.into(database.accounts).insert(
        AccountsCompanion.insert(
          localId: localId,
          name: name,
          type: type,
          createdAt: now,
          lastModifiedAt: now,
        ),
      );
}

Future<void> _insertCategory(
  AppDatabase database, {
  required String localId,
  required String name,
  required String type,
  required int sortOrder,
}) {
  final now = DateTime(2026, 5, 7);
  return database.into(database.categories).insert(
        CategoriesCompanion.insert(
          localId: localId,
          name: name,
          type: type,
          sortOrder: Value(sortOrder),
          createdAt: now,
          lastModifiedAt: now,
        ),
      );
}
