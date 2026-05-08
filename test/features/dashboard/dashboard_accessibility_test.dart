import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wallet_app/app/theme/app_theme.dart';
import 'package:smart_wallet_app/core/database/app_database.dart';
import 'package:smart_wallet_app/features/calendar/application/calendar_provider.dart';
import 'package:smart_wallet_app/features/dashboard/application/dashboard_narrative.dart';
import 'package:smart_wallet_app/features/dashboard/application/dashboard_summary_provider.dart';
import 'package:smart_wallet_app/features/dashboard/application/recurring_transaction_suggestion_provider.dart';
import 'package:smart_wallet_app/features/dashboard/application/wealth_hero_motion.dart';
import 'package:smart_wallet_app/features/dashboard/presentation/dashboard_narrative_card.dart';
import 'package:smart_wallet_app/features/dashboard/presentation/dashboard_screen.dart';
import 'package:smart_wallet_app/features/recurring_expenses/application/recurring_expense_service.dart';
import 'package:smart_wallet_app/features/statistics/application/statistics_provider.dart';

void main() {
  test('dashboard narrative semantics label includes headline and evidence', () {
    const snapshot = DashboardNarrativeSnapshot(
      topExpenseCategoryLabel: '식비',
      topExpenseCategoryShare: 0.42,
      expenseTransactionCount: 6,
      averageExpenseAmount: 43000,
      recentExpenseMomentum: RecentExpenseMomentum.steady,
      budgetPressureLevel: BudgetPressureLevel.none,
      loggingConsistencyLevel: LoggingConsistencyLevel.active,
      dominantPattern: DashboardDominantPattern.categoryFocused,
      evidenceParts: <String>[
        '42%가 식비에 모였어요.',
        '오늘 기록도 이어졌어요.',
      ],
      monthExpense: 260000,
      totalBudget: 1000000,
      todayTransactionCount: 3,
    );

    final label = dashboardNarrativeSemanticLabel(snapshot);

    expect(label, contains('Dashboard insight.'));
    expect(label, contains('식비'));
    expect(label, contains('42%가 식비에 모였어요.'));
  });

  test('today loop action semantics label reflects the current state', () {
    final label = dashboardTodayLoopActionSemanticLabel(hasTodayEntry: true);

    expect(
      label,
      'Open quick entry. Today already has recorded transactions, so you can add one more entry.',
    );
  });

  testWidgets('dashboard exposes narrative and today loop semantics',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final router = _buildRouter();
    addTearDown(router.dispose);
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(_DashboardAccessibilityApp(router: router));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('최근 내역 보기'));
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsLabel(
        RegExp(r'Dashboard insight\..*식비.*42%가 식비에 모였어요\.'),
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(
        'Open quick entry. Today already has recorded transactions, so you can add one more entry.',
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(
        'Open timeline. Review the recent transaction history for today.',
      ),
      findsOneWidget,
    );

    semantics.dispose();
  });
}

class _DashboardAccessibilityApp extends StatelessWidget {
  const _DashboardAccessibilityApp({
    required this.router,
  });

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        dashboardSummaryProvider.overrideWith(
          (ref) => Stream.value(_fakeDashboardSummary()),
        ),
        totalActiveAccountBalanceProvider.overrideWith(
          (ref) => const AsyncData(0),
        ),
        activeRecurringExpensesProvider.overrideWith(
          (ref) => Stream.value(const <RecurringExpense>[]),
        ),
        recurringTransactionSuggestionProvider.overrideWith(
          (ref) => Future.value(null),
        ),
        calendarHomeSummaryProvider.overrideWith(
          (ref) => Stream.value(
            CalendarHomeSummary(
              date: DateTime(2026, 5, 5),
              transactionCount: 3,
              income: 100000,
              expense: 23000,
            ),
          ),
        ),
        calendarHomeMonthPreviewProvider.overrideWith(
          (ref) => Stream.value(
            CalendarHomeMonthPreview(
              monthStart: DateTime(2026, 5, 1),
              days: [
                CalendarDaySummary(
                  date: DateTime(2026, 5, 5),
                  income: 100000,
                  expense: 23000,
                  transactionCount: 3,
                  matchCount: 3,
                ),
              ],
            ),
          ),
        ),
        statisticsHomePreviewProvider.overrideWith(
          (ref) => Stream.value(
            const [
              CategoryStat(label: '식비', amount: 120000, share: 0.46),
              CategoryStat(label: '교통', amount: 60000, share: 0.23),
              CategoryStat(label: '쇼핑', amount: 40000, share: 0.15),
            ],
          ),
        ),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        routerConfig: router,
      ),
    );
  }
}

GoRouter _buildRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/calendar',
        builder: (context, state) => const SizedBox.shrink(),
      ),
      GoRoute(
        path: '/statistics',
        builder: (context, state) => const SizedBox.shrink(),
      ),
      GoRoute(
        path: '/timeline',
        builder: (context, state) => const SizedBox.shrink(),
      ),
      GoRoute(
        path: '/quick-entry',
        builder: (context, state) => const SizedBox.shrink(),
      ),
    ],
  );
}

DashboardSummary _fakeDashboardSummary() {
  return const DashboardSummary(
    monthIncome: 3200000,
    monthExpense: 260000,
    todayExpense: 23000,
    todayTransactionCount: 3,
    remainingBudget: 740000,
    totalBudget: 1000000,
    netCashflow: 2940000,
    recentTransactions: <Transaction>[],
    narrative: DashboardNarrativeSnapshot(
      topExpenseCategoryLabel: '식비',
      topExpenseCategoryShare: 0.42,
      expenseTransactionCount: 6,
      averageExpenseAmount: 43000,
      recentExpenseMomentum: RecentExpenseMomentum.steady,
      budgetPressureLevel: BudgetPressureLevel.none,
      loggingConsistencyLevel: LoggingConsistencyLevel.active,
      dominantPattern: DashboardDominantPattern.categoryFocused,
      evidenceParts: <String>[
        '42%가 식비에 모였어요.',
        '오늘 기록도 이어졌어요.',
      ],
      monthExpense: 260000,
      totalBudget: 1000000,
      todayTransactionCount: 3,
    ),
  );
}
