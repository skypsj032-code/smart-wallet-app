import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet_app/core/database/app_database.dart';
import 'package:smart_wallet_app/features/dashboard/application/dashboard_narrative.dart';

void main() {
  group('buildDashboardNarrative', () {
    test('returns insufficient data copy when pattern is insufficient', () {
      const snapshot = DashboardNarrativeSnapshot(
        topExpenseCategoryLabel: '미분류',
        topExpenseCategoryShare: 0,
        expenseTransactionCount: 0,
        averageExpenseAmount: 0,
        recentExpenseMomentum: RecentExpenseMomentum.none,
        budgetPressureLevel: BudgetPressureLevel.none,
        loggingConsistencyLevel: LoggingConsistencyLevel.none,
        dominantPattern: DashboardDominantPattern.insufficientData,
        evidenceParts: ['이번 달 지출이 아직 없어요.'],
        monthExpense: 0,
        totalBudget: 0,
        todayTransactionCount: 0,
      );

      final copy = buildDashboardNarrative(snapshot);

      expect(copy.headline, '아직 이번 달 소비 흐름은 조금 더 쌓여야 보여요.');
      expect(copy.evidence, '이번 달 지출이 아직 없어요.');
    });

    test('returns category focused copy for dominant category spending', () {
      const snapshot = DashboardNarrativeSnapshot(
        topExpenseCategoryLabel: '식비',
        topExpenseCategoryShare: 0.52,
        expenseTransactionCount: 6,
        averageExpenseAmount: 22000,
        recentExpenseMomentum: RecentExpenseMomentum.increasing,
        budgetPressureLevel: BudgetPressureLevel.watch,
        loggingConsistencyLevel: LoggingConsistencyLevel.active,
        dominantPattern: DashboardDominantPattern.categoryFocused,
        evidenceParts: ['52%가 식비에 모였어요.', '이번 달 지출 6건이 기록됐어요.'],
        monthExpense: 132000,
        totalBudget: 220000,
        todayTransactionCount: 1,
      );

      final copy = buildDashboardNarrative(snapshot);

      expect(copy.headline, '이번 달은 식비 쪽 지출이 먼저 커졌어요.');
      expect(copy.evidence, '52%가 식비에 모였어요. 이번 달 지출 6건이 기록됐어요.');
    });

    test('returns small frequent copy when many small expenses repeat', () {
      const snapshot = DashboardNarrativeSnapshot(
        topExpenseCategoryLabel: '카페',
        topExpenseCategoryShare: 0.30,
        expenseTransactionCount: 8,
        averageExpenseAmount: 17000,
        recentExpenseMomentum: RecentExpenseMomentum.steady,
        budgetPressureLevel: BudgetPressureLevel.none,
        loggingConsistencyLevel: LoggingConsistencyLevel.active,
        dominantPattern: DashboardDominantPattern.smallFrequent,
        evidenceParts: ['30%가 카페에 모였어요.'],
        monthExpense: 136000,
        totalBudget: 300000,
        todayTransactionCount: 0,
      );

      final copy = buildDashboardNarrative(snapshot);

      expect(copy.headline, '작게 자주 쓰는 흐름이 이어지고 있어요.');
      expect(copy.evidence, '이번 달 지출 8건이 기록됐어요. 건당 평균 1.7만원 정도예요.');
    });

    test('keeps category focused priority over budget pressure', () {
      const snapshot = DashboardNarrativeSnapshot(
        topExpenseCategoryLabel: '고정지출',
        topExpenseCategoryShare: 0.61,
        expenseTransactionCount: 5,
        averageExpenseAmount: 98000,
        recentExpenseMomentum: RecentExpenseMomentum.steady,
        budgetPressureLevel: BudgetPressureLevel.overflow,
        loggingConsistencyLevel: LoggingConsistencyLevel.active,
        dominantPattern: DashboardDominantPattern.categoryFocused,
        evidenceParts: ['61%가 고정지출에 모였어요.', '예산의 108%를 사용했어요.'],
        monthExpense: 490000,
        totalBudget: 454000,
        todayTransactionCount: 0,
      );

      final copy = buildDashboardNarrative(snapshot);

      expect(copy.headline, '이번 달은 고정지출 쪽 지출이 먼저 커졌어요.');
      expect(copy.evidence, '61%가 고정지출에 모였어요. 예산의 108%를 사용했어요.');
    });

    test('does not mention today record when there is none', () {
      const snapshot = DashboardNarrativeSnapshot(
        topExpenseCategoryLabel: '교통',
        topExpenseCategoryShare: 0.28,
        expenseTransactionCount: 4,
        averageExpenseAmount: 14000,
        recentExpenseMomentum: RecentExpenseMomentum.light,
        budgetPressureLevel: BudgetPressureLevel.none,
        loggingConsistencyLevel: LoggingConsistencyLevel.started,
        dominantPattern: DashboardDominantPattern.balanced,
        evidenceParts: ['28%가 교통에 모였어요.', '이번 달 지출 4건이 기록됐어요.'],
        monthExpense: 56000,
        totalBudget: 240000,
        todayTransactionCount: 0,
      );

      final copy = buildDashboardNarrative(snapshot);

      expect(copy.evidence.contains('오늘 기록'), isFalse);
    });

    test('supports uncategorized spending label safely', () {
      const snapshot = DashboardNarrativeSnapshot(
        topExpenseCategoryLabel: '미분류',
        topExpenseCategoryShare: 0.47,
        expenseTransactionCount: 3,
        averageExpenseAmount: 43000,
        recentExpenseMomentum: RecentExpenseMomentum.light,
        budgetPressureLevel: BudgetPressureLevel.none,
        loggingConsistencyLevel: LoggingConsistencyLevel.started,
        dominantPattern: DashboardDominantPattern.categoryFocused,
        evidenceParts: ['47%가 미분류에 모였어요.', '이번 달 지출 3건이 기록됐어요.'],
        monthExpense: 129000,
        totalBudget: 260000,
        todayTransactionCount: 0,
      );

      final copy = buildDashboardNarrative(snapshot);

      expect(copy.headline, '이번 달은 미분류 쪽 지출이 먼저 커졌어요.');
      expect(copy.evidence, '47%가 미분류에 모였어요. 이번 달 지출 3건이 기록됐어요.');
    });

    test('small samples do not claim 100 percent category concentration', () {
      final now = DateTime(2026, 5, 5, 12);
      final snapshot = buildDashboardNarrativeSnapshot(
        monthlyTransactions: [
          Transaction(
            localId: 'tx-1',
            type: 'expense',
            amount: 15000,
            occurredAt: now,
            categoryId: 'food',
            createdAt: now,
            lastModifiedAt: now,
          ),
        ],
        categories: [
          Category(
            localId: 'food',
            name: '식비',
            type: 'expense',
            isDefault: false,
            isActive: true,
            sortOrder: 0,
            createdAt: now,
            lastModifiedAt: now,
          ),
        ],
        totalBudget: 0,
        today: now,
      );

      final copy = buildDashboardNarrative(snapshot);

      expect(snapshot.dominantPattern, DashboardDominantPattern.insufficientData);
      expect(copy.evidence, contains('1건'));
      expect(copy.evidence, contains('단정하긴 일러요'));
      expect(copy.evidence, isNot(contains('%')));
    });
  });
}
