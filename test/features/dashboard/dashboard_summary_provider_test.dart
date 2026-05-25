import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet_app/core/database/app_database.dart';
import 'package:smart_wallet_app/features/dashboard/application/dashboard_summary_provider.dart';
import 'package:smart_wallet_app/features/dashboard/application/recurring_spend_detector.dart';

void main() {
  test(
      'buildDashboardSummary includes recurring spend insight in month summary',
      () {
    final now = DateTime(2026, 5, 22, 9);
    final lookbackTransactions = [
      _tx(
        'insurance-apr',
        amount: 86000,
        occurredAt: DateTime(2026, 4, 5, 10),
        merchantName: '삼성화재',
        categoryId: 'insurance',
        accountId: 'card-1',
      ),
      _tx(
        'insurance-may',
        amount: 86000,
        occurredAt: DateTime(2026, 5, 5, 10),
        merchantName: '삼성화재',
        categoryId: 'insurance',
        accountId: 'card-1',
      ),
      _tx(
        'netflix-apr',
        amount: 17000,
        occurredAt: DateTime(2026, 4, 10, 8),
        merchantName: 'NETFLIX',
        categoryId: 'subscription',
        accountId: 'card-1',
      ),
      _tx(
        'netflix-may',
        amount: 17000,
        occurredAt: DateTime(2026, 5, 10, 8),
        merchantName: 'NETFLIX',
        categoryId: 'subscription',
        accountId: 'card-1',
      ),
      _tx(
        'salary-may',
        type: 'income',
        amount: 3000000,
        occurredAt: DateTime(2026, 5, 1, 9),
        merchantName: '월급',
        accountId: 'bank-1',
      ),
    ];

    final summary = buildDashboardSummary(
      lookbackTransactions: lookbackTransactions,
      budgets: [
        Budget(
          localId: 'budget-1',
          monthKey: '2026-05',
          categoryId: null,
          amountLimit: 500000,
          alert50Enabled: true,
          alert80Enabled: true,
          alert100Enabled: true,
          createdAt: now,
          lastModifiedAt: now,
        ),
      ],
      recentTransactions: lookbackTransactions.reversed.toList(),
      now: now,
    );

    expect(summary.monthIncome, 3000000);
    expect(summary.monthExpense, 103000);
    expect(summary.recurringSpendInsight.totalCurrentMonthAmount, 103000);
    expect(summary.recurringSpendInsight.groups, hasLength(2));
    expect(
      summary.recurringSpendInsight.groups.map((group) => group.kind),
      containsAll([RecurringSpendKind.fixed, RecurringSpendKind.subscription]),
    );
  });

  test('buildDashboardSummary excludes recurring groups marked not recurring',
      () {
    final now = DateTime(2026, 5, 22, 9);
    final lookbackTransactions = [
      _tx(
        'insurance-apr',
        amount: 86000,
        occurredAt: DateTime(2026, 4, 5, 10),
        merchantName: '?쇱꽦?붿옱',
        categoryId: 'insurance',
        accountId: 'card-1',
      ),
      _tx(
        'insurance-may',
        amount: 86000,
        occurredAt: DateTime(2026, 5, 5, 10),
        merchantName: '?쇱꽦?붿옱',
        categoryId: 'insurance',
        accountId: 'card-1',
      ),
      _tx(
        'netflix-apr',
        amount: 17000,
        occurredAt: DateTime(2026, 4, 10, 8),
        merchantName: 'NETFLIX',
        categoryId: 'subscription',
        accountId: 'card-1',
      ),
      _tx(
        'netflix-may',
        amount: 17000,
        occurredAt: DateTime(2026, 5, 10, 8),
        merchantName: 'NETFLIX',
        categoryId: 'subscription',
        accountId: 'card-1',
      ),
    ];

    final excludedKey = detectRecurringSpendInsight(
      lookbackTransactions,
      now: now,
    ).groups.firstWhere((group) => group.displayName == '?쇱꽦?붿옱').groupKey;

    final summary = buildDashboardSummary(
      lookbackTransactions: lookbackTransactions,
      budgets: const [],
      recentTransactions: lookbackTransactions.reversed.toList(),
      now: now,
      excludedRecurringGroupKeys: {excludedKey},
    );

    expect(summary.recurringSpendInsight.groups, hasLength(1));
    expect(
      summary.recurringSpendInsight.groups.single.displayName,
      'NETFLIX',
    );
    expect(summary.recurringSpendInsight.totalCurrentMonthAmount, 17000);
  });
}

Transaction _tx(
  String localId, {
  String type = 'expense',
  required int amount,
  required DateTime occurredAt,
  String? accountId,
  String? categoryId,
  String? merchantName,
}) {
  return Transaction(
    localId: localId,
    type: type,
    amount: amount,
    occurredAt: occurredAt,
    accountId: accountId,
    fromAccountId: null,
    toAccountId: null,
    categoryId: categoryId,
    merchantName: merchantName,
    paymentMethod: 'card',
    memo: null,
    tagJson: null,
    createdAt: occurredAt,
    lastModifiedAt: occurredAt,
    deletedAt: null,
  );
}
