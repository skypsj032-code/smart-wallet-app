import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/providers/database_providers.dart';

enum StatisticsRange {
  month,
  quarter,
  all,
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
    required this.periodLabel,
    required this.categories,
  });

  final int totalExpense;
  final int totalIncome;
  final int balance;
  final int transactionCount;
  final String periodLabel;
  final List<CategoryStat> categories;

  CategoryStat? get topCategory => categories.isEmpty ? null : categories.first;
  double get savingsRate {
    if (totalIncome <= 0) {
      return 0;
    }

    return balance / totalIncome;
  }
}

final statisticsRangeProvider = StateProvider<StatisticsRange>((ref) {
  return StatisticsRange.month;
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
      (t) => t.occurredAt.isBiggerOrEqualValue(start!) & t.occurredAt.isSmallerThanValue(end!),
    );
  }

  final txStream = baseQuery.watch();
  final categoryStream = (database.select(database.categories)
        ..where((c) => c.isActive.equals(true)))
      .watch();

  return txStream.combineLatest(categoryStream, (rows, categories) {
    final categoryNames = {for (final category in categories) category.localId: category.name};

    final totalIncome = rows
        .where((tx) => tx.type == 'income')
        .fold<int>(0, (sum, tx) => sum + tx.amount);
    final totalExpense = rows
        .where((tx) => tx.type == 'expense')
        .fold<int>(0, (sum, tx) => sum + tx.amount);

    final expenseByCategory = <String, int>{};
    for (final tx in rows.where((tx) => tx.type == 'expense')) {
      final key = tx.categoryId == null ? '미분류' : (categoryNames[tx.categoryId] ?? '미분류');
      expenseByCategory[key] = (expenseByCategory[key] ?? 0) + tx.amount;
    }

    final categoriesList = expenseByCategory.entries
        .map(
          (entry) => CategoryStat(
            label: entry.key,
            amount: entry.value,
            share: totalExpense <= 0 ? 0 : entry.value / totalExpense,
          ),
        )
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    return StatisticsSnapshot(
      totalExpense: totalExpense,
      totalIncome: totalIncome,
      balance: totalIncome - totalExpense,
      transactionCount: rows.length,
      periodLabel: periodLabel,
      categories: categoriesList,
    );
  });
});

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
