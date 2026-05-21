import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/providers/database_providers.dart';
import 'recurring_spend_detector.dart';

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

  double get budgetUsageRate {
    if (totalBudget <= 0) {
      return 0;
    }

    return monthExpense / totalBudget;
  }
}

final dashboardSummaryProvider = StreamProvider<DashboardSummary>((ref) {
  final database = ref.watch(appDatabaseProvider);
  final now = DateTime.now();
  final monthStart = DateTime(now.year, now.month, 1);
  final nextMonth = DateTime(now.year, now.month + 1, 1);
  final lookbackStart = now.subtract(const Duration(days: 90));
  final monthKey =
      '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';

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

  return _combine3(
    lookbackTransactions,
    monthlyBudgets,
    recentTransactions,
    (lookback, budgets, recent) {
      return buildDashboardSummary(
        lookbackTransactions: lookback,
        budgets: budgets,
        recentTransactions: recent,
        now: now,
      );
    },
  );
});

DashboardSummary buildDashboardSummary({
  required List<Transaction> lookbackTransactions,
  required List<Budget> budgets,
  required List<Transaction> recentTransactions,
  required DateTime now,
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
  final repeatSuggestions = <Transaction>[];
  final seenKeys = <String>{};
  final recurringSpendInsight = detectRecurringSpendInsight(
    lookbackTransactions,
    now: now,
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
  );
}

Stream<R> _combine3<A, B, C, R>(
  Stream<A> a,
  Stream<B> b,
  Stream<C> c,
  R Function(A a, B b, C c) combiner,
) {
  late A latestA;
  late B latestB;
  late C latestC;
  var hasA = false;
  var hasB = false;
  var hasC = false;

  final controller = StreamController<R>.broadcast();
  late StreamSubscription<A> subA;
  late StreamSubscription<B> subB;
  late StreamSubscription<C> subC;

  void emitIfReady() {
    if (hasA && hasB && hasC) {
      controller.add(combiner(latestA, latestB, latestC));
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

  controller.onCancel = () async {
    await subA.cancel();
    await subB.cancel();
    await subC.cancel();
  };

  return controller.stream;
}
