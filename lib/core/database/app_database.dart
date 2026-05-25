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
    Accounts,
    AppSettings,
    BackupMetadata,
    OcrDrafts,
    RecurringSpendOverrides,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());

  @override
  int get schemaVersion => 4;

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
            await m.createTable(recurringSpendOverrides);
          }
        },
      );

  Stream<Set<String>> watchNotRecurringGroupKeys() {
    return (select(recurringSpendOverrides)
          ..where((t) => t.actionType.equals('not_recurring')))
        .watch()
        .map((rows) => rows.map((row) => row.groupKey).toSet().cast<String>());
  }

  Future<void> markRecurringSpendGroupNotRecurring(String groupKey) {
    final now = DateTime.now();
    return into(recurringSpendOverrides).insertOnConflictUpdate(
      RecurringSpendOverridesCompanion.insert(
        groupKey: groupKey,
        actionType: 'not_recurring',
        createdAt: now,
        lastModifiedAt: now,
      ),
    );
  }

  Future<void> unmarkRecurringSpendGroupNotRecurring(String groupKey) {
    return (delete(recurringSpendOverrides)
          ..where((t) => t.groupKey.equals(groupKey)))
        .go();
  }

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
      monthlyExpenses.combineLatest(
          activeCategories, (txs, cats) => (txs, cats)),
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
