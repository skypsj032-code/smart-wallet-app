import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/providers/database_providers.dart';
import 'recurring_spend_detector.dart';
import 'recurring_spend_override_store.dart';

enum MonthlySpendPaceStatus {
  steady,
  watch,
  overspending,
  noBudget,
}

class MonthlySpendPace {
  const MonthlySpendPace({
    required this.status,
    required this.elapsedDays,
    required this.daysInMonth,
    required this.projectedMonthExpense,
    required this.projectedBudgetUsageRate,
  });

  final MonthlySpendPaceStatus status;
  final int elapsedDays;
  final int daysInMonth;
  final int projectedMonthExpense;
  final double? projectedBudgetUsageRate;
}

class DashboardSummary {
  const DashboardSummary({
    required this.monthIncome,
    required this.monthExpense,
    required this.todayExpense,
    required this.todayTransactionCount,
    required this.remainingBudget,
    required this.totalBudget,
    required this.netCashflow,
    required this.recentTransactions,
    required this.repeatSuggestions,
    required this.recurringSpendInsight,
    required this.spendPace,
    required this.excludedRecurringSpendGroups,
  });

  final int monthIncome;
  final int monthExpense;
  final int todayExpense;
  final int todayTransactionCount;
  final int remainingBudget;
  final int totalBudget;
  final int netCashflow;
  final List<Transaction> recentTransactions;
  final List<Transaction> repeatSuggestions;
  final RecurringSpendInsight recurringSpendInsight;
  final MonthlySpendPace spendPace;
  final List<RecurringSpendGroup> excludedRecurringSpendGroups;

  double get budgetUsageRate {
    if (totalBudget <= 0) {
      return 0;
    }

    return monthExpense / totalBudget;
  }
}

final dashboardSummaryProvider = StreamProvider<DashboardSummary>((ref) {
  final database = ref.watch(appDatabaseProvider);
  final overrideStore = ref.watch(recurringSpendOverrideStoreProvider);
  final queryNow = DateTime.now();
  final nextMonth = DateTime(queryNow.year, queryNow.month + 1, 1);
  final lookbackStart = queryNow.subtract(const Duration(days: 90));
  final monthKey =
      '${queryNow.year.toString().padLeft(4, '0')}-${queryNow.month.toString().padLeft(2, '0')}';

  final lookbackTransactions = (database.select(database.transactions)
        ..where((t) =>
            t.deletedAt.isNull() &
            t.occurredAt.isBiggerOrEqualValue(lookbackStart) &
            t.occurredAt.isSmallerThanValue(nextMonth)))
      .watch();

  final monthlyBudgets = (database.select(database.budgets)
        ..where((b) => b.monthKey.equals(monthKey)))
      .watch();

  final recentTransactions = (database.select(database.transactions)
        ..where((t) => t.deletedAt.isNull())
        ..orderBy([
          (t) => OrderingTerm.desc(t.occurredAt),
          (t) => OrderingTerm.desc(t.createdAt),
        ])
        ..limit(12))
      .watch();
  final excludedRecurringGroupKeys = overrideStore.watchNotRecurringGroupKeys();

  return _combine4(
    lookbackTransactions,
    monthlyBudgets,
    recentTransactions,
    excludedRecurringGroupKeys,
    (lookback, budgets, recent, excludedGroupKeys) {
      return buildDashboardSummary(
        lookbackTransactions: lookback,
        budgets: budgets,
        recentTransactions: recent,
        now: DateTime.now(),
        excludedRecurringGroupKeys: excludedGroupKeys,
      );
    },
  );
});

DashboardSummary buildDashboardSummary({
  required List<Transaction> lookbackTransactions,
  required List<Budget> budgets,
  required List<Transaction> recentTransactions,
  required DateTime now,
  Set<String> excludedRecurringGroupKeys = const {},
}) {
  final monthStart = DateTime(now.year, now.month, 1);
  final nextMonth = DateTime(now.year, now.month + 1, 1);
  final monthTransactions = lookbackTransactions.where((tx) {
    return !tx.occurredAt.isBefore(monthStart) &&
        tx.occurredAt.isBefore(nextMonth);
  }).toList();
  final income = monthTransactions
      .where((tx) => tx.type == 'income')
      .fold<int>(0, (sum, tx) => sum + tx.amount);
  final expense = monthTransactions
      .where((tx) => tx.type == 'expense')
      .fold<int>(0, (sum, tx) => sum + tx.amount);
  final today = DateTime(now.year, now.month, now.day);
  final todayTransactions = monthTransactions.where((tx) {
    final occurredAt = tx.occurredAt;
    return occurredAt.year == today.year &&
        occurredAt.month == today.month &&
        occurredAt.day == today.day;
  }).toList();
  final todayExpense = todayTransactions
      .where((tx) => tx.type == 'expense')
      .fold<int>(0, (sum, tx) => sum + tx.amount);
  final totalBudget =
      budgets.fold<int>(0, (sum, budget) => sum + budget.amountLimit);
  final spendPace = _buildMonthlySpendPace(
    monthExpense: expense,
    totalBudget: totalBudget,
    now: now,
  );
  final repeatSuggestions = <Transaction>[];
  final seenKeys = <String>{};
  final rawRecurringSpendInsight = detectRecurringSpendInsight(
    lookbackTransactions,
    now: now,
  );
  final recurringSpendInsight = _filterRecurringSpendInsight(
    rawRecurringSpendInsight,
    excludedRecurringGroupKeys,
  );
  final excludedRecurringSpendGroups = _excludedRecurringSpendGroups(
    rawRecurringSpendInsight,
    excludedRecurringGroupKeys,
  );

  for (final tx in recentTransactions) {
    if (tx.type == 'transfer') {
      continue;
    }

    final key =
        '${tx.type}|${tx.accountId ?? ''}|${tx.categoryId ?? ''}|${tx.memo ?? tx.merchantName ?? ''}|${tx.amount}';
    if (seenKeys.contains(key)) {
      continue;
    }

    seenKeys.add(key);
    repeatSuggestions.add(tx);

    if (repeatSuggestions.length >= 3) {
      break;
    }
  }

  return DashboardSummary(
    monthIncome: income,
    monthExpense: expense,
    todayExpense: todayExpense,
    todayTransactionCount: todayTransactions.length,
    remainingBudget: totalBudget - expense,
    totalBudget: totalBudget,
    netCashflow: income - expense,
    recentTransactions: recentTransactions.take(5).toList(),
    repeatSuggestions: repeatSuggestions,
    recurringSpendInsight: recurringSpendInsight,
    spendPace: spendPace,
    excludedRecurringSpendGroups: excludedRecurringSpendGroups,
  );
}

MonthlySpendPace _buildMonthlySpendPace({
  required int monthExpense,
  required int totalBudget,
  required DateTime now,
}) {
  final nextMonth = DateTime(now.year, now.month + 1, 1);
  final daysInMonth = nextMonth.subtract(const Duration(days: 1)).day;
  final elapsedDays = now.day.clamp(1, daysInMonth);
  final monthProgress = elapsedDays / daysInMonth;
  final projectedMonthExpense =
      monthProgress <= 0 ? monthExpense : (monthExpense / monthProgress).round();

  if (totalBudget <= 0) {
    return MonthlySpendPace(
      status: MonthlySpendPaceStatus.noBudget,
      elapsedDays: elapsedDays,
      daysInMonth: daysInMonth,
      projectedMonthExpense: projectedMonthExpense,
      projectedBudgetUsageRate: null,
    );
  }

  final projectedBudgetUsageRate = projectedMonthExpense / totalBudget;
  final status = projectedBudgetUsageRate >= 1.05
      ? MonthlySpendPaceStatus.overspending
      : projectedBudgetUsageRate >= 0.9
          ? MonthlySpendPaceStatus.watch
          : MonthlySpendPaceStatus.steady;

  return MonthlySpendPace(
    status: status,
    elapsedDays: elapsedDays,
    daysInMonth: daysInMonth,
    projectedMonthExpense: projectedMonthExpense,
    projectedBudgetUsageRate: projectedBudgetUsageRate,
  );
}

List<RecurringSpendGroup> _excludedRecurringSpendGroups(
  RecurringSpendInsight insight,
  Set<String> excludedRecurringGroupKeys,
) {
  if (excludedRecurringGroupKeys.isEmpty) {
    return const [];
  }

  final groups = insight.groups
      .where((group) => excludedRecurringGroupKeys.contains(group.groupKey))
      .toList();

  groups.sort((a, b) {
    final latestA = a.transactions
        .map((tx) => tx.occurredAt)
        .reduce((first, second) => first.isAfter(second) ? first : second);
    final latestB = b.transactions
        .map((tx) => tx.occurredAt)
        .reduce((first, second) => first.isAfter(second) ? first : second);
    final dateCompare = latestB.compareTo(latestA);
    if (dateCompare != 0) {
      return dateCompare;
    }

    return b.currentMonthAmount.compareTo(a.currentMonthAmount);
  });

  return groups;
}

RecurringSpendInsight _filterRecurringSpendInsight(
  RecurringSpendInsight insight,
  Set<String> excludedRecurringGroupKeys,
) {
  if (excludedRecurringGroupKeys.isEmpty) {
    return insight;
  }

  final groups = insight.groups
      .where((group) => !excludedRecurringGroupKeys.contains(group.groupKey))
      .toList();

  return RecurringSpendInsight(
    groups: groups,
    totalCurrentMonthAmount: groups.fold<int>(
      0,
      (sum, group) => sum + group.currentMonthAmount,
    ),
    totalPreviousMonthAmount: groups.fold<int>(
      0,
      (sum, group) => sum + group.previousMonthAmount,
    ),
  );
}

Stream<R> _combine4<A, B, C, D, R>(
  Stream<A> a,
  Stream<B> b,
  Stream<C> c,
  Stream<D> d,
  R Function(A a, B b, C c, D d) combiner,
) {
  late A latestA;
  late B latestB;
  late C latestC;
  late D latestD;
  var hasA = false;
  var hasB = false;
  var hasC = false;
  var hasD = false;

  final controller = StreamController<R>.broadcast();
  late StreamSubscription<A> subA;
  late StreamSubscription<B> subB;
  late StreamSubscription<C> subC;
  late StreamSubscription<D> subD;

  void emitIfReady() {
    if (hasA && hasB && hasC && hasD) {
      controller.add(combiner(latestA, latestB, latestC, latestD));
    }
  }

  subA = a.listen(
    (value) {
      latestA = value;
      hasA = true;
      emitIfReady();
    },
    onError: controller.addError,
  );

  subB = b.listen(
    (value) {
      latestB = value;
      hasB = true;
      emitIfReady();
    },
    onError: controller.addError,
  );

  subC = c.listen(
    (value) {
      latestC = value;
      hasC = true;
      emitIfReady();
    },
    onError: controller.addError,
  );

  subD = d.listen(
    (value) {
      latestD = value;
      hasD = true;
      emitIfReady();
    },
    onError: controller.addError,
  );

  controller.onCancel = () async {
    await subA.cancel();
    await subB.cancel();
    await subC.cancel();
    await subD.cancel();
  };

  return controller.stream;
}
