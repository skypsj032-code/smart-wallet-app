import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet_app/features/budgets/application/budget_provider.dart';

void main() {
  test('deriveCategoryPressure prefers the most budget-constrained category', () {
    final summary = BudgetSummary(
      monthKey: '2026-05',
      totalBudget: 500000,
      totalSpent: 330000,
      remaining: 170000,
      items: const [
        BudgetSummaryItem(
          categoryId: null,
          label: '전체 예산',
          limitAmount: 500000,
          spentAmount: 330000,
        ),
        BudgetSummaryItem(
          categoryId: 'food',
          label: '식비',
          limitAmount: 200000,
          spentAmount: 120000,
        ),
        BudgetSummaryItem(
          categoryId: 'transport',
          label: '교통',
          limitAmount: 50000,
          spentAmount: 45000,
        ),
      ],
    );

    final insight = deriveCategoryPressure(summary);

    expect(insight, isNotNull);
    expect(insight!.label, '교통');
    expect(insight.status, CategoryPressureStatus.watch);
    expect(insight.progress, 0.9);
  });

  test('deriveCategoryPressure falls back to the largest spending category', () {
    final summary = BudgetSummary(
      monthKey: '2026-05',
      totalBudget: 0,
      totalSpent: 210000,
      remaining: -210000,
      items: const [
        BudgetSummaryItem(
          categoryId: 'food',
          label: '식비',
          limitAmount: 0,
          spentAmount: 160000,
        ),
        BudgetSummaryItem(
          categoryId: 'shopping',
          label: '쇼핑',
          limitAmount: 0,
          spentAmount: 50000,
        ),
      ],
    );

    final insight = deriveCategoryPressure(summary);

    expect(insight, isNotNull);
    expect(insight!.label, '식비');
    expect(insight.status, CategoryPressureStatus.spending);
    expect(insight.progress, isNull);
  });
}
