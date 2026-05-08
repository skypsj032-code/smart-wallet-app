import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wallet_app/core/database/app_database.dart';
import 'package:smart_wallet_app/features/dashboard/presentation/upcoming_recurring_transactions_card.dart';

void main() {
  test('dashboard recurring semantics helpers describe manage action and item',
      () {
    final item = _monthlyExpense();

    expect(
      dashboardRecurringManageSemanticLabel(),
      'Open recurring expenses. Manage all scheduled recurring transactions.',
    );
    expect(
      dashboardRecurringPreviewSemanticLabel(item),
      'Recurring transaction preview. Phone bill. 매달 10일. Amount ₩55,000. Opens recurring expenses.',
    );
  });

  testWidgets('upcoming recurring card exposes manage and item semantics',
      (tester) async {
    final item = _monthlyExpense();
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: UpcomingRecurringTransactionsCard(
              items: [item],
            ),
          ),
        ),
        GoRoute(
          path: '/recurring-expenses',
          builder: (context, state) => const SizedBox.shrink(),
        ),
      ],
    );
    addTearDown(router.dispose);
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsLabel(dashboardRecurringManageSemanticLabel()),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(dashboardRecurringPreviewSemanticLabel(item)),
      findsOneWidget,
    );

    semantics.dispose();
  });
}

RecurringExpense _monthlyExpense() {
  return RecurringExpense(
    localId: 'rec_monthly',
    name: 'Phone bill',
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
