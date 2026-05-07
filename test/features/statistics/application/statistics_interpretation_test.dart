import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet_app/features/statistics/application/statistics_interpretation.dart';
import 'package:smart_wallet_app/features/statistics/application/statistics_provider.dart';

void main() {
  group('buildStatisticsInterpretation', () {
    test('returns empty interpretation for all filter with no transactions', () {
      const snapshot = StatisticsSnapshot(
        totalExpense: 0,
        totalIncome: 0,
        balance: 0,
        transactionCount: 0,
        incomeTransactionCount: 0,
        expenseTransactionCount: 0,
        periodLabel: '2026.05',
        allCategories: <CategoryStat>[],
        incomeCategories: <CategoryStat>[],
        expenseCategories: <CategoryStat>[],
      );

      final interpretation = buildStatisticsInterpretation(
        snapshot,
        StatisticsTypeFilter.all,
      );

      expect(interpretation.headline, '아직 이 기간의 돈 흐름은 조금 더 쌓여야 보여요.');
      expect(
        interpretation.evidence,
        '수입과 지출 기록이 더 모이면 어디에 무게가 실렸는지 읽기 쉬워져요.',
      );
    });

    test('returns balance-led interpretation for all filter', () {
      const snapshot = StatisticsSnapshot(
        totalExpense: 120000,
        totalIncome: 300000,
        balance: 180000,
        transactionCount: 7,
        incomeTransactionCount: 2,
        expenseTransactionCount: 5,
        periodLabel: '2026.05',
        allCategories: <CategoryStat>[
          CategoryStat(label: '급여', amount: 260000, share: 0.62),
          CategoryStat(label: '식비', amount: 42000, share: 0.10),
        ],
        incomeCategories: <CategoryStat>[
          CategoryStat(label: '급여', amount: 260000, share: 0.87),
        ],
        expenseCategories: <CategoryStat>[
          CategoryStat(label: '식비', amount: 42000, share: 0.35),
        ],
      );

      final interpretation = buildStatisticsInterpretation(
        snapshot,
        StatisticsTypeFilter.all,
      );

      expect(interpretation.headline, '이번 기간엔 수입이 지출보다 여유 있게 앞서고 있어요.');
      expect(
        interpretation.evidence,
        '총수입 300,000원, 총지출 120,000원이 기록됐어요.',
      );
    });

    test('returns focused interpretation for dominant income category', () {
      const snapshot = StatisticsSnapshot(
        totalExpense: 0,
        totalIncome: 500000,
        balance: 500000,
        transactionCount: 3,
        incomeTransactionCount: 3,
        expenseTransactionCount: 0,
        periodLabel: '2026.05',
        allCategories: <CategoryStat>[
          CategoryStat(label: '급여', amount: 420000, share: 0.84),
        ],
        incomeCategories: <CategoryStat>[
          CategoryStat(label: '급여', amount: 420000, share: 0.84),
          CategoryStat(label: '부수입', amount: 80000, share: 0.16),
        ],
        expenseCategories: <CategoryStat>[],
      );

      final interpretation = buildStatisticsInterpretation(
        snapshot,
        StatisticsTypeFilter.income,
      );

      expect(interpretation.headline, '이번 기간엔 급여 쪽 수입이 가장 크게 모였어요.');
      expect(
        interpretation.evidence,
        '수입의 84%가 급여에 모였고, 총 3건이 기록됐어요.',
      );
    });

    test('returns focused interpretation for dominant expense category', () {
      const snapshot = StatisticsSnapshot(
        totalExpense: 100000,
        totalIncome: 0,
        balance: -100000,
        transactionCount: 5,
        incomeTransactionCount: 0,
        expenseTransactionCount: 5,
        periodLabel: '2026.05',
        allCategories: <CategoryStat>[
          CategoryStat(label: '식비', amount: 42000, share: 0.42),
          CategoryStat(label: '교통', amount: 18000, share: 0.18),
        ],
        incomeCategories: <CategoryStat>[],
        expenseCategories: <CategoryStat>[
          CategoryStat(label: '식비', amount: 42000, share: 0.42),
          CategoryStat(label: '교통', amount: 18000, share: 0.18),
        ],
      );

      final interpretation = buildStatisticsInterpretation(
        snapshot,
        StatisticsTypeFilter.expense,
      );

      expect(interpretation.headline, '이번 기간엔 식비 쪽 지출이 가장 크게 모였어요.');
      expect(
        interpretation.evidence,
        '지출의 42%가 식비에 모였고, 총 5건이 기록됐어요.',
      );
    });
  });
}
