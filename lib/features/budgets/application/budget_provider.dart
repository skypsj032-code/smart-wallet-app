import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/providers/database_providers.dart';
import '../data/budget_repository_interface.dart';

class BudgetSummary {
  const BudgetSummary({
    required this.monthKey,
    required this.totalBudget,
    required this.totalSpent,
    required this.remaining,
    required this.items,
  });

  final String monthKey;
  final int totalBudget;
  final int totalSpent;
  final int remaining;
  final List<BudgetSummaryItem> items;
}

class BudgetSummaryItem {
  const BudgetSummaryItem({
    required this.categoryId,
    required this.label,
    required this.limitAmount,
    required this.spentAmount,
  });

  final String? categoryId;
  final String label;
  final int limitAmount;
  final int spentAmount;

  int get remaining => limitAmount - spentAmount;
  double get progress => limitAmount <= 0 ? 0 : spentAmount / limitAmount;
}

class BudgetCategoryOption {
  const BudgetCategoryOption({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;
}

final budgetSummaryProvider = StreamProvider<BudgetSummary>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return database.watchBudgetSummary();
});

final budgetCategoryOptionsProvider = StreamProvider<List<BudgetCategoryOption>>((ref) {
  final database = ref.watch(appDatabaseProvider);

  return (database.select(database.categories)
        ..where((tbl) => tbl.isActive.equals(true) & tbl.type.equals('expense'))
        ..orderBy([(tbl) => OrderingTerm(expression: tbl.sortOrder)]))
      .watch()
      .map(
        (rows) => rows
            .map((row) => BudgetCategoryOption(id: row.localId, name: row.name))
            .toList(),
      );
});

class BudgetEditorService implements IBudgetRepository {
  BudgetEditorService(this._database);

  final AppDatabase _database;

  Future<void> saveBudget({
    required String monthKey,
    required String? categoryId,
    required int amountLimit,
  }) async {
    if (amountLimit <= 0) {
      throw ArgumentError('amountLimit must be greater than zero');
    }

    final existing = await (_database.select(_database.budgets)
          ..where(
            (tbl) => tbl.monthKey.equals(monthKey) & _sameCategory(tbl.categoryId, categoryId),
          ))
        .getSingleOrNull();

    final now = DateTime.now();

    if (existing == null) {
      await _database.into(_database.budgets).insert(
            BudgetsCompanion.insert(
              localId: 'budget_${monthKey}_${categoryId ?? 'all'}_${now.microsecondsSinceEpoch}',
              monthKey: monthKey,
              categoryId: Value(categoryId),
              amountLimit: amountLimit,
              createdAt: now,
              lastModifiedAt: now,
            ),
          );
      return;
    }

    await (_database.update(_database.budgets)
          ..where((tbl) => tbl.localId.equals(existing.localId)))
        .write(
          BudgetsCompanion(
            amountLimit: Value(amountLimit),
            lastModifiedAt: Value(now),
          ),
        );
  }

  Future<void> deleteBudget({
    required String monthKey,
    required String? categoryId,
  }) async {
    await (_database.delete(_database.budgets)
          ..where(
            (tbl) => tbl.monthKey.equals(monthKey) & _sameCategory(tbl.categoryId, categoryId),
          ))
        .go();
  }

  Expression<bool> _sameCategory(GeneratedColumn<String> column, String? categoryId) {
    if (categoryId == null) {
      return column.isNull();
    }

    return column.equals(categoryId);
  }
}

/// Provider는 인터페이스 타입으로 노출 — 테스트에서 override 가능.
final budgetEditorServiceProvider = Provider<IBudgetRepository>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return BudgetEditorService(database);
});
