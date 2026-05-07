import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wallet_app/core/database/app_database.dart';
import 'package:smart_wallet_app/features/dashboard/presentation/upcoming_recurring_transactions_card.dart';

void main() {
  testWidgets('shows recurring preview rows and routes to recurring screen',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: UpcomingRecurringTransactionsCard(
              items: [_monthlyExpense(), _weeklyIncome()],
            ),
          ),
        ),
        GoRoute(
          path: '/recurring-expenses',
          builder: (context, state) =>
              const Scaffold(body: Text('recurring-screen')),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(routerConfig: router),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dashboard-recurring-preview')), findsOneWidget);
    expect(find.byKey(const Key('dashboard-recurring-manage')), findsOneWidget);
    expect(find.text('예정된 정기 거래'), findsOneWidget);
    expect(find.text('통신비'), findsOneWidget);
    expect(find.text('매달 10일'), findsOneWidget);
    expect(find.text('매주 월요일'), findsOneWidget);

    await tester.tap(find.byKey(const Key('dashboard-recurring-manage')));
    await tester.pumpAndSettle();

    expect(find.text('recurring-screen'), findsOneWidget);
  });
}

RecurringExpense _monthlyExpense() {
  return RecurringExpense(
    localId: 'rec_monthly',
    name: '통신비',
    type: 'expense',
    amount: 55000,
    cadence: 'monthly',
    dayOfMonth: 10,
    weekday: null,
    accountId: 'card_main',
    categoryId: 'expense-telecom',
    isActive: true,
    createdAt: DateTime(2026, 5, 1),
    lastModifiedAt: DateTime(2026, 5, 1),
  );
}

RecurringExpense _weeklyIncome() {
  return RecurringExpense(
    localId: 'rec_weekly',
    name: '주간 수당',
    type: 'income',
    amount: 30000,
    cadence: 'weekly',
    dayOfMonth: null,
    weekday: DateTime.monday,
    accountId: 'cash_wallet',
    categoryId: 'income-side',
    isActive: true,
    createdAt: DateTime(2026, 5, 1),
    lastModifiedAt: DateTime(2026, 5, 1),
  );
}
