import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/providers/database_providers.dart';

enum StatisticsRange {
  month,
  quarter,
  all,
}

enum StatisticsTypeFilter {
  all,
  income,
  expense,
}

class CategoryStat {
  const CategoryStat({
    required this.label,
    required this.amount,
    required this.share,
  });

  final String label;
  final int amount;
  final double share;
}

class StatisticsSnapshot {
  const StatisticsSnapshot({
    required this.totalExpense,
    required this.totalIncome,
    required this.balance,
    required this.transactionCount,
    required this.incomeTransactionCount,
    required this.expenseTransactionCount,
    required this.periodLabel,
    required this.allCategories,
    required this.incomeCategories,
    required this.expenseCategories,
  });

  final int totalExpense;
  final int totalIncome;
  final int balance;
  final int transactionCount;
  final int incomeTransactionCount;
  final int expenseTransactionCount;
  final String periodLabel;
  final List<CategoryStat> allCategories;
  final List<CategoryStat> incomeCategories;
  final List<CategoryStat> expenseCategories;

  List<CategoryStat> get categories => expenseCategories;

  CategoryStat? get topCategory =>
      expenseCategories.isEmpty ? null : expenseCategories.first;

  double get savingsRate {
    if (totalIncome <= 0) {
      return 0;
    }

    return balance / totalIncome;
  }

  List<CategoryStat> categoriesFor(StatisticsTypeFilter filter) {
    switch (filter) {
      case StatisticsTypeFilter.all:
        return allCategories;
      case StatisticsTypeFilter.income:
        return incomeCategories;
      case StatisticsTypeFilter.expense:
        return expenseCategories;
    }
  }

  CategoryStat? topCategoryFor(StatisticsTypeFilter filter) {
    final categories = categoriesFor(filter);
    return categories.isEmpty ? null : categories.first;
  }

  int transactionCountFor(StatisticsTypeFilter filter) {
    switch (filter) {
      case StatisticsTypeFilter.all:
        return transactionCount;
      case StatisticsTypeFilter.income:
        return incomeTransactionCount;
      case StatisticsTypeFilter.expense:
        return expenseTransactionCount;
    }
  }

  int totalAmountFor(StatisticsTypeFilter filter) {
    switch (filter) {
      case StatisticsTypeFilter.all:
        return totalIncome + totalExpense;
      case StatisticsTypeFilter.income:
        return totalIncome;
      case StatisticsTypeFilter.expense:
        return totalExpense;
    }
  }

  int averageAmountFor(StatisticsTypeFilter filter) {
    final count = transactionCountFor(filter);
    if (count <= 0) {
      return 0;
    }

    switch (filter) {
      case StatisticsTypeFilter.all:
        return (totalIncome + totalExpense) ~/ count;
      case StatisticsTypeFilter.income:
        return totalIncome ~/ count;
      case StatisticsTypeFilter.expense:
        return totalExpense ~/ count;
    }
  }
}

final statisticsRangeProvider = StateProvider<StatisticsRange>((ref) {
  return StatisticsRange.month;
});

final statisticsTypeFilterProvider = StateProvider<StatisticsTypeFilter>((ref) {
  return StatisticsTypeFilter.all;
});

final statisticsMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, 1);
});

final statisticsProvider = StreamProvider.autoDispose<StatisticsSnapshot>((ref) {
  final database = ref.watch(appDatabaseProvider);
  final month = ref.watch(statisticsMonthProvider);
  final range = ref.watch(statisticsRangeProvider);

  final baseQuery = database.select(database.transactions)
    ..where((t) => t.deletedAt.isNull());

  late DateTime? start;
  late DateTime? end;
  late String periodLabel;

  switch (range) {
    case StatisticsRange.month:
      start = DateTime(month.year, month.month, 1);
      end = DateTime(month.year, month.month + 1, 1);
      periodLabel = '${month.year}.${month.month.toString().padLeft(2, '0')}';
      break;
    case StatisticsRange.quarter:
      start = DateTime(month.year, month.month - 2, 1);
      end = DateTime(month.year, month.month + 1, 1);
      periodLabel =
          '${start.year}.${start.month.toString().padLeft(2, '0')} - ${month.year}.${month.month.toString().padLeft(2, '0')}';
      break;
    case StatisticsRange.all:
      start = null;
      end = null;
      periodLabel = '전체 기간';
      break;
  }

  if (start != null && end != null) {
    baseQuery.where(
      (t) => t.occurredAt.isBiggerOrEqualValue(start!) &
          t.occurredAt.isSmallerThanValue(end!),
    );
  }

  final transactionStream = baseQuery.watch();
  final categoryStream = (database.select(database.categories)
        ..where((c) => c.isActive.equals(true)))
      .watch();

  return transactionStream.combineLatest(categoryStream, (rows, categories) {
    final categoryNames = {
      for (final category in categories) category.localId: category.name,
    };
    final incomeRows =
        rows.where((transaction) => transaction.type == 'income').toList();
    final expenseRows =
        rows.where((transaction) => transaction.type == 'expense').toList();

    final totalIncome =
        incomeRows.fold<int>(0, (sum, transaction) => sum + transaction.amount);
    final totalExpense = expenseRows.fold<int>(
      0,
      (sum, transaction) => sum + transaction.amount,
    );

    final allByCategory = <String, int>{};
    final incomeByCategory = <String, int>{};
    final expenseByCategory = <String, int>{};

    String categoryLabelFor(String? categoryId) {
      if (categoryId == null) {
        return '미분류';
      }

      return categoryNames[categoryId] ?? '미분류';
    }

    for (final transaction in rows) {
      final key = categoryLabelFor(transaction.categoryId);
      allByCategory[key] = (allByCategory[key] ?? 0) + transaction.amount;
    }

    for (final transaction in incomeRows) {
      final key = categoryLabelFor(transaction.categoryId);
      incomeByCategory[key] = (incomeByCategory[key] ?? 0) + transaction.amount;
    }

    for (final transaction in expenseRows) {
      final key = categoryLabelFor(transaction.categoryId);
      expenseByCategory[key] =
          (expenseByCategory[key] ?? 0) + transaction.amount;
    }

    List<CategoryStat> buildCategoryList(Map<String, int> entries, int total) {
      final items = entries.entries
          .map(
            (entry) => CategoryStat(
              label: entry.key,
              amount: entry.value,
              share: total <= 0 ? 0 : entry.value / total,
            ),
          )
          .toList()
        ..sort((a, b) => b.amount.compareTo(a.amount));
      return items;
    }

    return StatisticsSnapshot(
      totalExpense: totalExpense,
      totalIncome: totalIncome,
      balance: totalIncome - totalExpense,
      transactionCount: rows.length,
      incomeTransactionCount: incomeRows.length,
      expenseTransactionCount: expenseRows.length,
      periodLabel: periodLabel,
      allCategories: buildCategoryList(allByCategory, totalIncome + totalExpense),
      incomeCategories: buildCategoryList(incomeByCategory, totalIncome),
      expenseCategories: buildCategoryList(expenseByCategory, totalExpense),
    );
  });
});

final statisticsHomePreviewProvider = StreamProvider.autoDispose<List<CategoryStat>>(
  (ref) {
    final database = ref.watch(appDatabaseProvider);
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 1);

    final transactionStream = (database.select(database.transactions)
          ..where((t) =>
              t.deletedAt.isNull() &
              t.occurredAt.isBiggerOrEqualValue(monthStart) &
              t.occurredAt.isSmallerThanValue(monthEnd))
          ..orderBy([(t) => OrderingTerm.asc(t.occurredAt)]))
        .watch();
    final categoryStream = (database.select(database.categories)
          ..where((c) => c.isActive.equals(true)))
        .watch();

    return transactionStream.combineLatest(categoryStream, (rows, categories) {
      final categoryNames = {
        for (final category in categories) category.localId: category.name,
      };
      final byCategory = <String, int>{};
      var totalExpense = 0;

      for (final row in rows) {
        if (row.type != 'expense') {
          continue;
        }

        final key = row.categoryId == null
            ? '미분류'
            : (categoryNames[row.categoryId] ?? '미분류');
        byCategory[key] = (byCategory[key] ?? 0) + row.amount;
        totalExpense += row.amount;
      }

      final items = byCategory.entries
          .map(
            (entry) => CategoryStat(
              label: entry.key,
              amount: entry.value,
              share: totalExpense <= 0 ? 0 : entry.value / totalExpense,
            ),
          )
          .toList()
        ..sort((a, b) => b.amount.compareTo(a.amount));

      return items.take(3).toList();
    });
  },
);

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
