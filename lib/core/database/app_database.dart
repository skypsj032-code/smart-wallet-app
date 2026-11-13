import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';

import '../../features/budgets/application/budget_provider.dart';
import '../../shared/utils/budget_totals.dart';
import 'connection/connection.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Transactions,
    Categories,
    Budgets,
    RecurringExpenses,
    RecurringSpendOverrides,
    Accounts,
    AppSettings,
    BackupMetadata,
    OcrDrafts,
    NotificationHistories,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 9;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (details) async {
          // WAL 모드: 동시 읽기/쓰기 시 DB Lock 마비 방지 (Read ↔ Write 비블로킹)
          await customStatement('PRAGMA journal_mode=WAL;');
          await customStatement('PRAGMA foreign_keys = ON;');
        },
        onCreate: (Migrator m) async {
          await transaction(() async {
            await m.createAll();
            await customStatement('PRAGMA user_version = $schemaVersion');
          });
        },
        onUpgrade: (Migrator m, int from, int to) async {
          await transaction(() async {
          if (from < 2 && !await _appSettingsHasColumn('pin_code')) {
            await m.addColumn(appSettings, appSettings.pinCode);
          }
          if (from < 3) {
            try {
              await customStatement(
                'ALTER TABLE app_settings DROP COLUMN onboarding_completed;',
              );
            } catch (error, stackTrace) {
              debugPrint(
                'Skipping onboarding_completed drop during migration: '
                '$error\n$stackTrace',
              );
            }
            // The old profile is no longer used by this app, but keeping the
            // table avoids discarding legacy device and backup information.
          }
          if (from < 4 && !await _tableExists('recurring_expenses')) {
            await m.createTable(recurringExpenses);
          }
          if (from < 5 &&
              !await _appSettingsHasColumn('default_category_seed_version')) {
            await m.addColumn(
              appSettings,
              appSettings.defaultCategorySeedVersion,
            );
          }
          if (from >= 4 && from < 6) {
            // Version 4 was used by two independent branches. One has an
            // older recurring_expenses table; the other has no such table.
            final hasRecurringExpenses =
                await _tableExists('recurring_expenses');
            if (!hasRecurringExpenses) {
              await m.createTable(recurringExpenses);
            } else {
              final columns = await customSelect(
                'PRAGMA table_info(recurring_expenses)',
              ).get();
              final names = columns.map((row) => row.data['name']).toSet();
              if (!names.contains('last_created_month_key')) {
                // Never rebuild a table whose shape we do not recognize.
                if (!names.containsAll({
                  'type',
                  'cadence',
                  'last_completed_cycle_key',
                })) {
                  throw StateError('Unrecognized recurring_expenses schema');
                }
              } else {
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
            }
          }
          if (from < 7 && !await _tableExists('notification_histories')) {
            await m.createTable(notificationHistories);
          }
          if (from < 8) {
            await customStatement('''
              CREATE INDEX IF NOT EXISTS transactions_timeline_idx
              ON transactions (deleted_at, occurred_at DESC, created_at DESC);
            ''');
            await customStatement('''
              CREATE INDEX IF NOT EXISTS transactions_category_timeline_idx
              ON transactions (deleted_at, category_id, occurred_at DESC);
            ''');
          }
          if (from < 9 &&
              !await _tableExists('recurring_spend_overrides')) {
            await m.createTable(recurringSpendOverrides);
          }
          // Persist the version in the same transaction as the schema. This
          // makes an interrupted upgrade safe to retry on the next launch.
          await customStatement('PRAGMA user_version = $to');
          });
        },
      );

  Future<bool> _appSettingsHasColumn(String column) async {
    final rows = await customSelect('PRAGMA table_info(app_settings)').get();
    return rows.any((row) => row.data['name'] == column);
  }

  Future<bool> _tableExists(String name) async {
    final rows = await customSelect(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
      variables: [Variable.withString(name)],
    ).get();
    return rows.isNotEmpty;
  }

  Stream<Set<String>> watchNotRecurringGroupKeys() {
    return (select(recurringSpendOverrides)
          ..where((row) => row.actionType.equals('not_recurring')))
        .watch()
        .map((rows) => rows.map((row) => row.groupKey).toSet());
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
          ..where((row) => row.groupKey.equals(groupKey)))
        .go();
  }

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
      monthlyExpenses.combineLatest(
          activeCategories, (txs, cats) => (txs, cats)),
      (bgs, payload) {
        final txs = payload.$1;
        final cats = payload.$2;
        final categoryNames = {for (final c in cats) c.localId: c.name};

        final items = bgs.map((budget) {
          final spent = txs
              .where((tx) =>
                  budget.categoryId == null || tx.categoryId == budget.categoryId)
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

        final totalBudget = effectiveBudgetTotal(bgs.map((budget) => (
              categoryId: budget.categoryId,
              amount: budget.amountLimit,
              modifiedAt: budget.lastModifiedAt,
              id: budget.localId,
            )));
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

  // ── 알림 이력 ───────────────────────────────────────────────────────────────
  Future<void> insertNotificationHistory({
    required String packageName,
    required int amount,
    required String type,
    String? merchant,
    String? suggestedCategory,
    required DateTime detectedAt,
  }) {
    return into(notificationHistories).insert(
      NotificationHistoriesCompanion.insert(
        packageName: packageName,
        amount: amount,
        type: type,
        merchant: Value(merchant),
        suggestedCategory: Value(suggestedCategory),
        detectedAt: detectedAt,
      ),
    );
  }

  Stream<List<NotificationHistory>> watchNotificationHistories(
      {int limit = 100}) {
    return (select(notificationHistories)
          ..orderBy([(h) => OrderingTerm.desc(h.detectedAt)])
          ..limit(limit))
        .watch();
  }

  Future<void> deleteOldNotificationHistories({int keepCount = 200}) async {
    final all = await (select(notificationHistories)
          ..orderBy([(h) => OrderingTerm.desc(h.detectedAt)]))
        .get();
    if (all.length <= keepCount) return;
    final toDelete = all.sublist(keepCount).map((h) => h.id).toList();
    await (delete(notificationHistories)..where((h) => h.id.isIn(toDelete)))
        .go();
  }

  /// 최근 [dayRange]일간 감지된 알림 건수를 반환한다.
  Future<int> countRecentNotificationHistories({int dayRange = 30}) async {
    final since = DateTime.now().subtract(Duration(days: dayRange));
    final countExpr = notificationHistories.id.count();
    final query = selectOnly(notificationHistories)
      ..addColumns([countExpr])
      ..where(notificationHistories.detectedAt.isBiggerThanValue(since));
    final row = await query.getSingle();
    return row.read(countExpr) ?? 0;
  }

  // ── 타임라인 ────────────────────────────────────────────────────────────────
  Stream<int> watchTimelineTransactionCount({String? typeFilter}) {
    final countExpression = transactions.localId.count();
    final query = selectOnly(transactions)
      ..addColumns([countExpression])
      ..where(_timelineFilterExpression(transactions, typeFilter));

    return query.watchSingle().map((row) => row.read(countExpression) ?? 0);
  }

  Stream<List<Transaction>> watchTimelineTransactions({
    required int limit,
    String? typeFilter,
  }) {
    return (select(transactions)
          ..where((table) => _timelineFilterExpression(table, typeFilter))
          ..orderBy([
            (t) => OrderingTerm.desc(t.occurredAt),
            (t) => OrderingTerm.desc(t.createdAt),
          ])
          ..limit(limit))
        .watch();
  }

  Expression<bool> _timelineFilterExpression(
    $TransactionsTable table,
    String? typeFilter,
  ) {
    final activeRows = table.deletedAt.isNull();
    if (typeFilter == null) {
      return activeRows;
    }
    if (typeFilter == 'transfer') {
      return activeRows &
          (table.type.equals('transfer') |
              table.type.equals('transfer_reserved'));
    }
    return activeRows & table.type.equals(typeFilter);
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
