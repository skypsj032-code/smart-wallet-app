import 'statistics_provider.dart';

class StatisticsCategoryInterpretation {
  const StatisticsCategoryInterpretation({
    required this.headline,
    required this.evidence,
  });

  final String headline;
  final String evidence;
}

StatisticsCategoryInterpretation buildStatisticsCategoryInterpretation(
  StatisticsSnapshot snapshot,
) {
  return buildStatisticsInterpretation(snapshot, StatisticsTypeFilter.expense);
}

StatisticsCategoryInterpretation buildStatisticsInterpretation(
  StatisticsSnapshot snapshot,
  StatisticsTypeFilter filter,
) {
  switch (filter) {
    case StatisticsTypeFilter.all:
      return _buildAllInterpretation(snapshot);
    case StatisticsTypeFilter.income:
      return _buildIncomeInterpretation(snapshot);
    case StatisticsTypeFilter.expense:
      return _buildExpenseInterpretation(snapshot);
  }
}

StatisticsCategoryInterpretation _buildAllInterpretation(
  StatisticsSnapshot snapshot,
) {
  if (snapshot.transactionCount <= 0) {
    return const StatisticsCategoryInterpretation(
      headline: '아직 이 기간의 돈 흐름은 조금 더 쌓여야 보여요.',
      evidence: '수입과 지출 기록이 더 모이면 어디에 무게가 실렸는지 읽기 쉬워져요.',
    );
  }

  if (snapshot.totalIncome <= 0 && snapshot.totalExpense > 0) {
    return StatisticsCategoryInterpretation(
      headline: '이번 기간엔 지출만 먼저 쌓이고 있어요.',
      evidence:
          '총 ${snapshot.expenseTransactionCount}건의 지출이 기록됐고, 아직 잡힌 수입은 없어요.',
    );
  }

  if (snapshot.totalExpense <= 0 && snapshot.totalIncome > 0) {
    return StatisticsCategoryInterpretation(
      headline: '이번 기간엔 수입이 먼저 들어오고 있어요.',
      evidence:
          '총 ${snapshot.incomeTransactionCount}건의 수입이 기록됐고, 아직 잡힌 지출은 없어요.',
    );
  }

  if (snapshot.balance >= 0) {
    return StatisticsCategoryInterpretation(
      headline: '이번 기간엔 수입이 지출보다 여유 있게 앞서고 있어요.',
      evidence:
          '총수입 ${_formatCompactCurrency(snapshot.totalIncome)}, 총지출 ${_formatCompactCurrency(snapshot.totalExpense)}이 기록됐어요.',
    );
  }

  return StatisticsCategoryInterpretation(
    headline: '이번 기간엔 지출이 수입보다 더 크게 나갔어요.',
    evidence:
        '총지출 ${_formatCompactCurrency(snapshot.totalExpense)}가 총수입 ${_formatCompactCurrency(snapshot.totalIncome)}보다 크게 보이고 있어요.',
  );
}

StatisticsCategoryInterpretation _buildIncomeInterpretation(
  StatisticsSnapshot snapshot,
) {
  if (snapshot.totalIncome <= 0 ||
      snapshot.incomeTransactionCount <= 0 ||
      snapshot.incomeCategories.isEmpty) {
    return const StatisticsCategoryInterpretation(
      headline: '아직 이 기간의 수입 흐름은 조금 더 쌓여야 보여요.',
      evidence: '지금은 수입 카테고리별로 읽을 만큼 기록이 많지 않아요.',
    );
  }

  final topCategory = snapshot.incomeCategories.first;
  final topSharePercent = (topCategory.share * 100).round();

  if (topCategory.share >= 0.6) {
    return StatisticsCategoryInterpretation(
      headline: '이번 기간엔 ${topCategory.label} 쪽 수입이 가장 크게 모였어요.',
      evidence:
          '수입의 $topSharePercent%가 ${topCategory.label}에 모였고, 총 ${snapshot.incomeTransactionCount}건이 기록됐어요.',
    );
  }

  final secondCategory =
      snapshot.incomeCategories.length > 1 ? snapshot.incomeCategories[1].label : null;
  final evidence = secondCategory == null
      ? '${topCategory.label} 비중이 가장 크게 보이고 있어요.'
      : '${topCategory.label} 비중이 가장 크고, $secondCategory 쪽 흐름도 함께 보이고 있어요.';

  return StatisticsCategoryInterpretation(
    headline: '이번 기간엔 여러 수입이 나뉘어 들어오고 있어요.',
    evidence: evidence,
  );
}

StatisticsCategoryInterpretation _buildExpenseInterpretation(
  StatisticsSnapshot snapshot,
) {
  if (snapshot.totalExpense <= 0 ||
      snapshot.expenseTransactionCount <= 0 ||
      snapshot.expenseCategories.isEmpty) {
    return const StatisticsCategoryInterpretation(
      headline: '아직 이 기간의 지출 흐름은 조금 더 쌓여야 보여요.',
      evidence: '지금은 카테고리별로 읽을 만큼 지출 기록이 많지 않아요.',
    );
  }

  final topCategory = snapshot.expenseCategories.first;
  final topSharePercent = (topCategory.share * 100).round();

  if (topCategory.share >= 0.35) {
    return StatisticsCategoryInterpretation(
      headline: '이번 기간엔 ${topCategory.label} 쪽 지출이 가장 크게 모였어요.',
      evidence:
          '지출의 $topSharePercent%가 ${topCategory.label}에 모였고, 총 ${snapshot.expenseTransactionCount}건이 기록됐어요.',
    );
  }

  final secondCategory = snapshot.expenseCategories.length > 1
      ? snapshot.expenseCategories[1].label
      : null;
  final evidence = secondCategory == null
      ? '${topCategory.label} 비중이 가장 크게 보이고 있어요.'
      : '${topCategory.label} 비중이 가장 크고, $secondCategory 비중도 함께 보이고 있어요.';

  return StatisticsCategoryInterpretation(
    headline: '이번 기간엔 ${topCategory.label} 쪽 지출이 먼저 보이고 있어요.',
    evidence: evidence,
  );
}

String _formatCompactCurrency(int amount) {
  final raw = amount.toString();
  final buffer = StringBuffer();

  for (var i = 0; i < raw.length; i++) {
    final reverseIndex = raw.length - i;
    buffer.write(raw[i]);
    if (reverseIndex > 1 && reverseIndex % 3 == 1) {
      buffer.write(',');
    }
  }

  return '$buffer원';
}
