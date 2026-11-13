import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet_app/core/database/app_database.dart';
import 'package:smart_wallet_app/core/database/providers/database_providers.dart';
import 'package:smart_wallet_app/features/dashboard/application/dashboard_summary_provider.dart';

import '../../test_support/sqlite_test_setup.dart';

void main() {
  setUpAll(configureSqliteForTests);

  test('overall budget includes categorized spending without adding category limits',
      () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final now = DateTime.now();
    final monthKey =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';

    await database.into(database.budgets).insert(BudgetsCompanion.insert(
          localId: 'overall',
          monthKey: monthKey,
          amountLimit: 1000000,
          createdAt: now,
          lastModifiedAt: now,
        ));
    await database.into(database.budgets).insert(BudgetsCompanion.insert(
          localId: 'food',
          monthKey: monthKey,
          categoryId: const drift.Value('food'),
          amountLimit: 300000,
          createdAt: now,
          lastModifiedAt: now,
        ));
    for (final entry in [
      ('categorized', 50000, 'food'),
      ('uncategorized', 30000, null),
    ]) {
      await database.into(database.transactions).insert(
            TransactionsCompanion.insert(
              localId: entry.$1,
              type: 'expense',
              amount: entry.$2,
              occurredAt: now,
              categoryId: drift.Value(entry.$3),
              createdAt: now,
              lastModifiedAt: now,
            ),
          );
    }

    final summary = await database.watchBudgetSummary().first;
    expect(summary.totalBudget, 1000000);
    expect(summary.totalSpent, 80000);
    expect(summary.remaining, 920000);
    expect(summary.items.singleWhere((item) => item.categoryId == null).spentAmount,
        80000);
    expect(summary.items.singleWhere((item) => item.categoryId == 'food').spentAmount,
        50000);

    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
    );
    addTearDown(container.dispose);
    final dashboard = await container.read(dashboardSummaryProvider.future);
    expect(dashboard.totalBudget, 1000000);
    expect(dashboard.remainingBudget, 920000);
  });

  test('category limits are summed when there is no overall budget', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final now = DateTime.now();
    final monthKey =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';

    for (final entry in [('food', 300000), ('transport', 100000)]) {
      await database.into(database.budgets).insert(BudgetsCompanion.insert(
            localId: entry.$1,
            monthKey: monthKey,
            categoryId: drift.Value(entry.$1),
            amountLimit: entry.$2,
            createdAt: now,
            lastModifiedAt: now,
          ));
    }
    final summary = await database.watchBudgetSummary().first;
    expect(summary.totalBudget, 400000);
  });

  test('duplicate overall rows remain intact and the latest cap is used',
      () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final now = DateTime.now();
    final monthKey =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';
    for (final row in [
      ('older', 1000000, now.subtract(const Duration(minutes: 1))),
      ('newer', 900000, now),
    ]) {
      await database.into(database.budgets).insert(BudgetsCompanion.insert(
            localId: row.$1,
            monthKey: monthKey,
            amountLimit: row.$2,
            createdAt: row.$3,
            lastModifiedAt: row.$3,
          ));
    }

    final summary = await database.watchBudgetSummary().first;
    expect(summary.totalBudget, 900000);
    expect(await database.select(database.budgets).get(), hasLength(2));
  });
}
