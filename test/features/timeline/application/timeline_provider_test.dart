import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet_app/core/database/app_database.dart';
import 'package:smart_wallet_app/core/database/providers/database_providers.dart';
import 'package:smart_wallet_app/features/timeline/application/timeline_provider.dart';

import '../../../test_support/sqlite_test_setup.dart';

void main() {
  late AppDatabase database;

  setUpAll(() {
    configureSqliteForTests();
  });

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('watchTimelineTransactions returns only the newest rows up to the limit',
      () async {
    await _insertTransaction(
      database,
      localId: 'oldest',
      type: 'expense',
      amount: 1000,
      occurredAt: DateTime(2026, 5, 1, 8),
      merchantName: 'Oldest',
    );
    await _insertTransaction(
      database,
      localId: 'middle',
      type: 'income',
      amount: 2000,
      occurredAt: DateTime(2026, 5, 2, 8),
      merchantName: 'Middle',
    );
    await _insertTransaction(
      database,
      localId: 'newest',
      type: 'expense',
      amount: 3000,
      occurredAt: DateTime(2026, 5, 3, 8),
      merchantName: 'Newest',
    );

    final rows = await database.watchTimelineTransactions(limit: 2).first;

    expect(rows.map((row) => row.localId).toList(), ['newest', 'middle']);
  });

  test('timeline queries apply transfer filter and report matching count',
      () async {
    await _insertTransaction(
      database,
      localId: 'expense',
      type: 'expense',
      amount: 1100,
      occurredAt: DateTime(2026, 5, 1, 8),
      merchantName: 'Expense',
    );
    await _insertTransaction(
      database,
      localId: 'reserved',
      type: 'transfer_reserved',
      amount: 2200,
      occurredAt: DateTime(2026, 5, 2, 8),
      merchantName: 'Reserved',
    );
    await _insertTransaction(
      database,
      localId: 'transfer',
      type: 'transfer',
      amount: 3300,
      occurredAt: DateTime(2026, 5, 3, 8),
      merchantName: 'Transfer',
    );

    final rows = await database
        .watchTimelineTransactions(limit: 10, typeFilter: 'transfer')
        .first;
    final count = await database
        .watchTimelineTransactionCount(typeFilter: 'transfer')
        .first;

    expect(rows.map((row) => row.localId).toList(), ['transfer', 'reserved']);
    expect(count, 2);
  });

  test('timelineTransactionsProvider expands the visible page when limit grows',
      () async {
    await _insertTransaction(
      database,
      localId: 'oldest',
      type: 'expense',
      amount: 1000,
      occurredAt: DateTime(2026, 5, 1, 8),
      merchantName: 'Oldest',
    );
    await _insertTransaction(
      database,
      localId: 'middle',
      type: 'expense',
      amount: 2000,
      occurredAt: DateTime(2026, 5, 2, 8),
      merchantName: 'Middle',
    );
    await _insertTransaction(
      database,
      localId: 'newest',
      type: 'expense',
      amount: 3000,
      occurredAt: DateTime(2026, 5, 3, 8),
      merchantName: 'Newest',
    );

    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) => database),
        timelinePageSizeProvider.overrideWith((ref) => 2),
      ],
    );
    addTearDown(container.dispose);

    final sub = container.listen(
      timelineTransactionsProvider,
      (_, __) {},
      fireImmediately: true,
    );
    addTearDown(sub.close);

    final initial = await container.read(timelineTransactionsProvider.future);
    expect(initial.items.map((row) => row.localId).toList(), [
      'newest',
      'middle',
    ]);
    expect(initial.hasMore, isTrue);

    container.read(timelineVisibleLimitProvider.notifier).state +=
        container.read(timelinePageSizeProvider);

    final expanded = await container.read(timelineTransactionsProvider.future);
    expect(expanded.items.map((row) => row.localId).toList(), [
      'newest',
      'middle',
      'oldest',
    ]);
    expect(expanded.hasMore, isFalse);
  });

  test('changing timeline filter resets the visible limit to the page size',
      () async {
    final container = ProviderContainer(
      overrides: [
        timelinePageSizeProvider.overrideWith((ref) => 7),
      ],
    );
    addTearDown(container.dispose);

    container.read(timelineVisibleLimitProvider.notifier).state = 21;
    container.read(timelineSelectedTypeProvider.notifier).state = 'expense';
    container.read(timelineSelectedTypeProvider.notifier).state = 'income';
    container.read(timelineVisibleLimitProvider.notifier).state =
        container.read(timelinePageSizeProvider);

    expect(container.read(timelineSelectedTypeProvider), 'income');
    expect(container.read(timelineVisibleLimitProvider), 7);
  });
}

Future<void> _insertTransaction(
  AppDatabase database, {
  required String localId,
  required String type,
  required int amount,
  required DateTime occurredAt,
  required String merchantName,
}) {
  return database.into(database.transactions).insert(
        TransactionsCompanion.insert(
          localId: localId,
          type: type,
          amount: amount,
          occurredAt: occurredAt,
          merchantName: drift.Value(merchantName),
          createdAt: occurredAt,
          lastModifiedAt: occurredAt,
        ),
      );
}
