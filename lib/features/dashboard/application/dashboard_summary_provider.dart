import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/providers/database_providers.dart';
import 'dashboard_narrative.dart';

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
    required this.narrative,
  });

  final int monthIncome;
  final int monthExpense;
  final int todayExpense;
  final int todayTransactionCount;
  final int remainingBudget;
  final int totalBudget;
  final int netCashflow;
  final List<Transaction> recentTransactions;
  final DashboardNarrativeSnapshot narrative;

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
  final monthKey =
      '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';

  final monthlyTransactions = (database.select(database.transactions)
        ..where((t) =>
            t.deletedAt.isNull() &
            t.occurredAt.isBiggerOrEqualValue(monthStart) &
            t.occurredAt.isSmallerThanValue(nextMonth)))
      .watch();

  final monthlyBudgets = (database.select(database.budgets)
        ..where((b) => b.monthKey.equals(monthKey)))
      .watch();

  final activeCategories = (database.select(database.categories)
        ..where((c) => c.isActive.equals(true)))
      .watch();

  final recentTransactions = (database.select(database.transactions)
        ..where((t) => t.deletedAt.isNull())
        ..orderBy([
          (t) => OrderingTerm.desc(t.occurredAt),
          (t) => OrderingTerm.desc(t.createdAt),
        ])
        ..limit(12))
      .watch();

  return _combine4(
    monthlyTransactions,
    monthlyBudgets,
    activeCategories,
    recentTransactions,
    (txs, budgets, categories, recent) {
      final income = txs
          .where((tx) => tx.type == 'income')
          .fold<int>(0, (sum, tx) => sum + tx.amount);
      final expense = txs
          .where((tx) => tx.type == 'expense')
          .fold<int>(0, (sum, tx) => sum + tx.amount);
      final today = DateTime(now.year, now.month, now.day);
      final todayTransactions = txs.where((tx) {
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
      final narrative = buildDashboardNarrativeSnapshot(
        monthlyTransactions: txs,
        categories: categories,
        totalBudget: totalBudget,
        today: today,
      );

      return DashboardSummary(
        monthIncome: income,
        monthExpense: expense,
        todayExpense: todayExpense,
        todayTransactionCount: todayTransactions.length,
        remainingBudget: totalBudget - expense,
        totalBudget: totalBudget,
        netCashflow: income - expense,
        recentTransactions: recent.take(5).toList(),
        narrative: narrative,
      );
    },
  );
});

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
