import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet_app/features/dashboard/application/dashboard_narrative.dart';
import 'package:smart_wallet_app/features/dashboard/presentation/dashboard_narrative_card.dart';

void main() {
  testWidgets('DashboardNarrativeCard shows a headline and evidence narrative',
      (WidgetTester tester) async {
    const snapshot = DashboardNarrativeSnapshot(
      topExpenseCategoryLabel: '생활비가 아주 길게 표시되는 카테고리 이름',
      topExpenseCategoryShare: 0.48,
      expenseTransactionCount: 6,
      averageExpenseAmount: 28000,
      recentExpenseMomentum: RecentExpenseMomentum.steady,
      budgetPressureLevel: BudgetPressureLevel.none,
      loggingConsistencyLevel: LoggingConsistencyLevel.active,
      dominantPattern: DashboardDominantPattern.categoryFocused,
      evidenceParts: [
        '48%가 생활비가 아주 길게 표시되는 카테고리 이름에 모였어요.',
        '이번 달 지출 6건이 기록됐어요.',
      ],
      monthExpense: 168000,
      totalBudget: 400000,
      todayTransactionCount: 1,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: EdgeInsets.all(24),
            child: DashboardNarrativeCard(snapshot: snapshot),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(
      find.text('이번 달은 생활비가 아주 길게 표시되는 카테고리 이름 쪽 지출이 먼저 커졌어요.'),
      findsOneWidget,
    );
    expect(
      find.text(
        '48%가 생활비가 아주 길게 표시되는 카테고리 이름에 모였어요. 이번 달 지출 6건이 기록됐어요.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
