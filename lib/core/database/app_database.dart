import 'dart:async';

import 'package:drift/drift.dart';

import '../../features/budgets/application/budget_provider.dart';
import 'connection/connection.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Transactions,
    Categories,
    Budgets,
    RecurringExpenses,
    Accounts,
    AppSettings,
    BackupMetadata,
    OcrDrafts,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.addColumn(appSettings, appSettings.pinCode);
          }
          if (from < 3) {
            try {
              await customStatement(
                'ALTER TABLE app_settings DROP COLUMN onboarding_completed;',
              );
            } catch (_) {}
            try {
              await customStatement('DROP TABLE IF EXISTS local_user_profile;');
            } catch (_) {}
          }
          if (from < 4) {
            await m.createTable(recurringExpenses);
          }
          if (from < 5) {
            await m.addColumn(
              appSettings,
              appSettings.defaultCategorySeedVersion,
            );
          }
          if (from >= 4 && from < 6) {
            await transaction(() async {
              await customStatement('''
                CREATE TABLE recurring_expenses_new (
                  local_id TEXT NOT NULL PRIMARY KEY,
                  name TEXT NOT NULL,
                  type TEXT NOT NULL,
                  amount INTEGER NOT NULL,
                  cadence TEXT NOT NULL,
                  day_of_month INTEGER NULL,
                  weekday INTEGER NULL,
                  account_id TEXT NOT NULL,
                  category_id TEXT NULL,
                  is_active INTEGER NOT NULL DEFAULT 1,
                  last_suggested_cycle_key TEXT NULL,
                  last_completed_cycle_key TEXT NULL,
                  last_dismissed_cycle_key TEXT NULL,
                  created_at INTEGER NOT NULL,
                  last_modified_at INTEGER NOT NULL
                );
              ''');
              await customStatement('''
                INSERT INTO recurring_expenses_new (
                  local_id,
                  name,
                  type,
                  amount,
                  cadence,
                  day_of_month,
                  weekday,
                  account_id,
                  category_id,
                  is_active,
                  last_completed_cycle_key,
                  created_at,
                  last_modified_at
                )
                SELECT
                  local_id,
                  name,
                  'expense',
                  amount,
                  'monthly',
                  day_of_month,
                  NULL,
                  account_id,
                  category_id,
                  is_active,
                  last_created_month_key,
                  created_at,
                  last_modified_at
                FROM recurring_expenses;
              ''');
              await customStatement('DROP TABLE recurring_expenses;');
              await customStatement(
                'ALTER TABLE recurring_expenses_new RENAME TO recurring_expenses;',
              );
            });
          }
        },
      );

  // ── 예산 요약 ───────────────────────────────────────────────────────────────
  Stream<BudgetSummary> watchBudgetSummary() {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final nextMonth = DateTime(now.year, now.month + 1, 1);
    final monthKey =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';

    final monthlyBudgets =
        (select(budgets)..where((b) => b.monthKey.equals(monthKey))).watch();

    final monthlyExpenses = (select(transactions)
          ..where((t) =>
              t.deletedAt.isNull() &
              t.type.equals('expense') &
              t.occurredAt.isBiggerOrEqualValue(monthStart) &
              t.occurredAt.isSmallerThanValue(nextMonth)))
        .watch();

    final activeCategories =
        (select(categories)..where((c) => c.isActive.equals(true))).watch();

    return monthlyBudgets.combineLatest(
      monthlyExpenses.combineLatest(activeCategories, (txs, cats) => (txs, cats)),
      (bgs, payload) {
        final txs = payload.$1;
        final cats = payload.$2;
        final categoryNames = {for (final c in cats) c.localId: c.name};

        final items = bgs.map((budget) {
          final spent = txs
              .where((tx) => tx.categoryId == budget.categoryId)
              .fold<int>(0, (sum, tx) => sum + tx.amount);

          return BudgetSummaryItem(
            categoryId: budget.categoryId,
            label: budget.categoryId == null
                ? '전체 예산'
                : (categoryNames[budget.categoryId] ?? '알 수 없는 카테고리'),
            limitAmount: budget.amountLimit,
            spentAmount: spent,
          );
        }).toList();

        final totalBudget =
            items.fold<int>(0, (sum, item) => sum + item.limitAmount);
        final totalSpent = txs.fold<int>(0, (sum, tx) => sum + tx.amount);

        return BudgetSummary(
          monthKey: monthKey,
          totalBudget: totalBudget,
          totalSpent: totalSpent,
          remaining: totalBudget - totalSpent,
          items: items,
        );
      },
    );
  }

  // ── 타임라인 ────────────────────────────────────────────────────────────────
  Stream<List<Transaction>> watchTimelineTransactions() {
    return (select(transactions)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([
            (t) => OrderingTerm.desc(t.occurredAt),
            (t) => OrderingTerm.desc(t.createdAt),
          ]))
        .watch();
  }

}

// ── StreamCombineLatest 유틸 ──────────────────────────────────────────────────
extension _CombineLatestExtension<A> on Stream<A> {
  Stream<R> combineLatest<B, R>(
    Stream<B> other,
    R Function(A a, B b) combiner,
  ) {
    late A latestA;
    late B latestB;
    var hasA = false;
    var hasB = false;

    final controller = StreamController<R>.broadcast();
    late StreamSubscription<A> subA;
    late StreamSubscription<B> subB;

    void emitIfReady() {
      if (hasA && hasB) {
        controller.add(combiner(latestA, latestB));
      }
    }

    subA = listen(
      (value) {
        latestA = value;
        hasA = true;
        emitIfReady();
      },
      onError: controller.addError,
      onDone: () async {
        await subB.cancel();
        await controller.close();
      },
    );

    subB = other.listen(
      (value) {
        latestB = value;
        hasB = true;
        emitIfReady();
      },
      onError: controller.addError,
    );

    controller.onCancel = () async {
      await subA.cancel();
      await subB.cancel();
    };

    return controller.stream;
  }
}
