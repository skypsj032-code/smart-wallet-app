import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet_app/app/theme/app_theme.dart';
import 'package:smart_wallet_app/features/budgets/application/budget_provider.dart';
import 'package:smart_wallet_app/features/budgets/presentation/budget_screen.dart';

void main() {
  test('budget overview semantics label includes totals and progress', () {
    final label = budgetOverviewSemanticLabel(
      monthKey: '2026-05',
      totalBudget: 1000000,
      totalSpent: 260000,
      remaining: 740000,
    );

    expect(
      label,
      'Budget overview. Month 2026-05. Total budget ₩1,000,000. Spent ₩260,000. Remaining ₩740,000. Status 26% used.',
    );
  });

  test('budget category semantics label includes limit and remaining amount', () {
    final label = budgetCategoryItemSemanticLabel(
      const BudgetSummaryItem(
        categoryId: 'expense-food',
        label: '식비',
        limitAmount: 300000,
        spentAmount: 120000,
      ),
    );

    expect(
      label,
      'Budget category item. 식비. Limit ₩300,000. Spent ₩120,000. Remaining ₩180,000. Status 40% used.',
    );
  });

  testWidgets('budget screen exposes overview and category semantics',
      (tester) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          budgetSummaryProvider.overrideWith(
            (ref) => Stream.value(
              const BudgetSummary(
                monthKey: '2026-05',
                totalBudget: 1000000,
                totalSpent: 260000,
                remaining: 740000,
                items: [
                  BudgetSummaryItem(
                    categoryId: null,
                    label: '전체',
                    limitAmount: 1000000,
                    spentAmount: 260000,
                  ),
                  BudgetSummaryItem(
                    categoryId: 'expense-food',
                    label: '식비',
                    limitAmount: 300000,
                    spentAmount: 120000,
                  ),
                ],
              ),
            ),
          ),
          budgetCategoryOptionsProvider.overrideWith(
            (ref) => Stream.value(
              const [
                BudgetCategoryOption(id: 'expense-food', name: '식비'),
              ],
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          home: const BudgetScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.bySemanticsLabel(
        'Budget overview. Month 2026-05. Total budget ₩1,000,000. Spent ₩260,000. Remaining ₩740,000. Status 26% used.',
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(
        'Budget category item. 식비. Limit ₩300,000. Spent ₩120,000. Remaining ₩180,000. Status 40% used.',
      ),
      findsOneWidget,
    );

    semantics.dispose();
  });
}
