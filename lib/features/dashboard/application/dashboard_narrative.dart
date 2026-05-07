import '../../../core/database/app_database.dart';

enum RecentExpenseMomentum {
  increasing,
  steady,
  light,
  none,
}

enum BudgetPressureLevel {
  none,
  watch,
  high,
  overflow,
}

enum LoggingConsistencyLevel {
  none,
  started,
  active,
}

enum DashboardDominantPattern {
  categoryFocused,
  smallFrequent,
  largeSparse,
  balanced,
  insufficientData,
}

class DashboardNarrativeSnapshot {
  const DashboardNarrativeSnapshot({
    required this.topExpenseCategoryLabel,
    required this.topExpenseCategoryShare,
    required this.expenseTransactionCount,
    required this.averageExpenseAmount,
    required this.recentExpenseMomentum,
    required this.budgetPressureLevel,
    required this.loggingConsistencyLevel,
    required this.dominantPattern,
    required this.evidenceParts,
    required this.monthExpense,
    required this.totalBudget,
    required this.todayTransactionCount,
  });

  final String topExpenseCategoryLabel;
  final double topExpenseCategoryShare;
  final int expenseTransactionCount;
  final int averageExpenseAmount;
  final RecentExpenseMomentum recentExpenseMomentum;
  final BudgetPressureLevel budgetPressureLevel;
  final LoggingConsistencyLevel loggingConsistencyLevel;
  final DashboardDominantPattern dominantPattern;
  final List<String> evidenceParts;
  final int monthExpense;
  final int totalBudget;
  final int todayTransactionCount;
}

class DashboardNarrativeCopy {
  const DashboardNarrativeCopy({
    required this.headline,
    required this.evidence,
  });

  final String headline;
  final String evidence;
}

DashboardNarrativeSnapshot buildDashboardNarrativeSnapshot({
  required List<Transaction> monthlyTransactions,
  required List<Category> categories,
  required int totalBudget,
  required DateTime today,
}) {
  final expenseTransactions = monthlyTransactions
      .where((tx) => tx.type == 'expense')
      .toList()
    ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

  final todayTransactions = monthlyTransactions.where((tx) {
    final occurredAt = tx.occurredAt;
    return occurredAt.year == today.year &&
        occurredAt.month == today.month &&
        occurredAt.day == today.day;
  }).toList();

  if (expenseTransactions.isEmpty) {
    return DashboardNarrativeSnapshot(
      topExpenseCategoryLabel: '미분류',
      topExpenseCategoryShare: 0,
      expenseTransactionCount: 0,
      averageExpenseAmount: 0,
      recentExpenseMomentum: RecentExpenseMomentum.none,
      budgetPressureLevel: _budgetPressureLevel(
        monthExpense: 0,
        totalBudget: totalBudget,
      ),
      loggingConsistencyLevel: _loggingConsistencyLevel(
        todayTransactionCount: todayTransactions.length,
      ),
      dominantPattern: DashboardDominantPattern.insufficientData,
      evidenceParts: [
        '이번 달 지출이 아직 없어요.',
        if (todayTransactions.isNotEmpty) '오늘 기록은 먼저 시작됐어요.',
      ],
      monthExpense: 0,
      totalBudget: totalBudget,
      todayTransactionCount: todayTransactions.length,
    );
  }

  final monthExpense =
      expenseTransactions.fold<int>(0, (sum, tx) => sum + tx.amount);
  final categoryNames = {
    for (final category in categories.where((c) => c.isActive))
      category.localId: category.name,
  };
  final expenseByCategory = <String, int>{};
  for (final transaction in expenseTransactions) {
    final key = transaction.categoryId == null
        ? '미분류'
        : (categoryNames[transaction.categoryId] ?? '미분류');
    expenseByCategory[key] = (expenseByCategory[key] ?? 0) + transaction.amount;
  }

  final topCategoryEntry = expenseByCategory.entries.reduce(
    (best, current) => current.value > best.value ? current : best,
  );
  final topExpenseCategoryShare =
      monthExpense <= 0 ? 0.0 : topCategoryEntry.value / monthExpense;
  final averageExpenseAmount =
      (monthExpense / expenseTransactions.length).round();
  final recentExpenseMomentum = _recentExpenseMomentum(
    expenseTransactions: expenseTransactions,
    today: today,
  );
  final budgetPressureLevel = _budgetPressureLevel(
    monthExpense: monthExpense,
    totalBudget: totalBudget,
  );
  final loggingConsistencyLevel = _loggingConsistencyLevel(
    todayTransactionCount: todayTransactions.length,
    expenseTransactionCount: expenseTransactions.length,
  );
  final dominantPattern = _dominantPattern(
    expenseTransactionCount: expenseTransactions.length,
    topExpenseCategoryShare: topExpenseCategoryShare,
    averageExpenseAmount: averageExpenseAmount,
  );

  final evidenceParts = expenseTransactions.length < 3
      ? <String>[
          '이번 달 지출 ${expenseTransactions.length}건이 기록됐어요.',
          if (expenseTransactions.length == 1)
            '아직은 소비 흐름을 단정하긴 일러요.'
          else
            '${topCategoryEntry.key} 쪽이 먼저 보이지만 아직 단정하긴 일러요.',
          if (todayTransactions.isNotEmpty) '오늘 기록도 이어졌어요.',
        ]
      : <String>[
          '${_sharePercent(topExpenseCategoryShare)}가 ${topCategoryEntry.key}에 모였어요.',
          '이번 달 지출 ${expenseTransactions.length}건이 기록됐어요.',
          if (budgetPressureLevel == BudgetPressureLevel.watch ||
              budgetPressureLevel == BudgetPressureLevel.high ||
              budgetPressureLevel == BudgetPressureLevel.overflow)
            '예산의 ${_budgetPercent(monthExpense: monthExpense, totalBudget: totalBudget)}를 사용했어요.',
          if (todayTransactions.isNotEmpty) '오늘 기록도 이어졌어요.',
        ];

  return DashboardNarrativeSnapshot(
    topExpenseCategoryLabel: topCategoryEntry.key,
    topExpenseCategoryShare: topExpenseCategoryShare,
    expenseTransactionCount: expenseTransactions.length,
    averageExpenseAmount: averageExpenseAmount,
    recentExpenseMomentum: recentExpenseMomentum,
    budgetPressureLevel: budgetPressureLevel,
    loggingConsistencyLevel: loggingConsistencyLevel,
    dominantPattern: dominantPattern,
    evidenceParts: evidenceParts,
    monthExpense: monthExpense,
    totalBudget: totalBudget,
    todayTransactionCount: todayTransactions.length,
  );
}

DashboardNarrativeCopy buildDashboardNarrative(
  DashboardNarrativeSnapshot snapshot,
) {
  switch (snapshot.dominantPattern) {
    case DashboardDominantPattern.insufficientData:
      return DashboardNarrativeCopy(
        headline: '아직 이번 달 소비 흐름은 조금 더 쌓여야 보여요.',
        evidence: _joinEvidence(snapshot.evidenceParts),
      );
    case DashboardDominantPattern.categoryFocused:
      return DashboardNarrativeCopy(
        headline: '이번 달은 ${snapshot.topExpenseCategoryLabel} 쪽 지출이 먼저 커졌어요.',
        evidence: _joinEvidence(snapshot.evidenceParts),
      );
    case DashboardDominantPattern.smallFrequent:
      return DashboardNarrativeCopy(
        headline: '작게 자주 쓰는 흐름이 이어지고 있어요.',
        evidence: _joinEvidence([
          '이번 달 지출 ${snapshot.expenseTransactionCount}건이 기록됐어요.',
          '건당 평균 ${_compactCurrency(snapshot.averageExpenseAmount)} 정도예요.',
          if (snapshot.todayTransactionCount > 0) '오늘 기록도 이어졌어요.',
        ]),
      );
    case DashboardDominantPattern.largeSparse:
      return DashboardNarrativeCopy(
        headline: '큰 금액 위주로 드문드문 나가는 달이에요.',
        evidence: _joinEvidence([
          '이번 달 지출 ${snapshot.expenseTransactionCount}건이 기록됐어요.',
          '건당 평균 ${_compactCurrency(snapshot.averageExpenseAmount)} 정도예요.',
          if (snapshot.todayTransactionCount > 0) '오늘 기록도 이어졌어요.',
        ]),
      );
    case DashboardDominantPattern.balanced:
      if (snapshot.budgetPressureLevel == BudgetPressureLevel.overflow) {
        return DashboardNarrativeCopy(
          headline: '이번 달은 예산보다 지출이 조금 앞서고 있어요.',
          evidence: _joinEvidence([
            '예산의 ${_budgetPercent(monthExpense: snapshot.monthExpense, totalBudget: snapshot.totalBudget)}를 사용했어요.',
            if (snapshot.todayTransactionCount > 0) '오늘 기록도 이어졌어요.',
          ]),
        );
      }
      if (snapshot.budgetPressureLevel == BudgetPressureLevel.high) {
        return DashboardNarrativeCopy(
          headline: '이번 달은 예산에 가까워지는 흐름이 보여요.',
          evidence: _joinEvidence([
            '예산의 ${_budgetPercent(monthExpense: snapshot.monthExpense, totalBudget: snapshot.totalBudget)}를 사용했어요.',
            '이번 달 지출 ${snapshot.expenseTransactionCount}건이 기록됐어요.',
          ]),
        );
      }
      if (snapshot.loggingConsistencyLevel == LoggingConsistencyLevel.started) {
        return DashboardNarrativeCopy(
          headline: '이번 달 소비 흐름이 이제 막 보이기 시작했어요.',
          evidence: _joinEvidence(snapshot.evidenceParts),
        );
      }
      if (snapshot.loggingConsistencyLevel == LoggingConsistencyLevel.active) {
        return DashboardNarrativeCopy(
          headline: '이번 달 소비 흐름이 차분하게 이어지고 있어요.',
          evidence: _joinEvidence(snapshot.evidenceParts),
        );
      }
      return DashboardNarrativeCopy(
        headline: '이번 달 소비가 한쪽으로 치우치지 않고 이어지고 있어요.',
        evidence: _joinEvidence(snapshot.evidenceParts),
      );
  }
}

DashboardDominantPattern _dominantPattern({
  required int expenseTransactionCount,
  required double topExpenseCategoryShare,
  required int averageExpenseAmount,
}) {
  if (expenseTransactionCount < 3) {
    return DashboardDominantPattern.insufficientData;
  }
  if (topExpenseCategoryShare >= 0.45) {
    return DashboardDominantPattern.categoryFocused;
  }
  if (expenseTransactionCount >= 5 && averageExpenseAmount <= 30000) {
    return DashboardDominantPattern.smallFrequent;
  }
  if (expenseTransactionCount <= 3 && averageExpenseAmount >= 120000) {
    return DashboardDominantPattern.largeSparse;
  }
  return DashboardDominantPattern.balanced;
}

RecentExpenseMomentum _recentExpenseMomentum({
  required List<Transaction> expenseTransactions,
  required DateTime today,
}) {
  if (expenseTransactions.isEmpty) {
    return RecentExpenseMomentum.none;
  }

  final recentSevenDays = expenseTransactions.where((tx) {
    final difference = today.difference(tx.occurredAt).inDays;
    return difference >= 0 && difference < 7;
  }).length;

  if (recentSevenDays >= 4) {
    return RecentExpenseMomentum.increasing;
  }
  if (recentSevenDays >= 2) {
    return RecentExpenseMomentum.steady;
  }
  if (recentSevenDays == 1) {
    return RecentExpenseMomentum.light;
  }
  return RecentExpenseMomentum.none;
}

BudgetPressureLevel _budgetPressureLevel({
  required int monthExpense,
  required int totalBudget,
}) {
  if (totalBudget <= 0) {
    return BudgetPressureLevel.none;
  }

  final usage = monthExpense / totalBudget;
  if (usage >= 1) {
    return BudgetPressureLevel.overflow;
  }
  if (usage >= 0.85) {
    return BudgetPressureLevel.high;
  }
  if (usage >= 0.65) {
    return BudgetPressureLevel.watch;
  }
  return BudgetPressureLevel.none;
}

LoggingConsistencyLevel _loggingConsistencyLevel({
  required int todayTransactionCount,
  int expenseTransactionCount = 0,
}) {
  if (expenseTransactionCount <= 0 && todayTransactionCount <= 0) {
    return LoggingConsistencyLevel.none;
  }
  if (expenseTransactionCount <= 2 && todayTransactionCount <= 1) {
    return LoggingConsistencyLevel.started;
  }
  return LoggingConsistencyLevel.active;
}

String _joinEvidence(List<String> parts) {
  final filtered =
      parts.where((part) => part.trim().isNotEmpty).take(2).toList();
  return filtered.join(' ');
}

String _sharePercent(double share) {
  return '${(share * 100).round()}%';
}

String _budgetPercent({
  required int monthExpense,
  required int totalBudget,
}) {
  if (totalBudget <= 0) {
    return '0%';
  }
  return '${((monthExpense / totalBudget) * 100).round()}%';
}

String _compactCurrency(int amount) {
  if (amount >= 10000) {
    final raw = (amount / 10000).toStringAsFixed(amount % 10000 == 0 ? 0 : 1);
    return '$raw만원';
  }
  return '$amount원';
}
