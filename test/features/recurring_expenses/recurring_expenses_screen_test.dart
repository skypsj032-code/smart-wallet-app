import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet_app/app/theme/app_theme.dart';
import 'package:smart_wallet_app/core/database/app_database.dart';
import 'package:smart_wallet_app/features/accounts/application/accounts_provider.dart';
import 'package:smart_wallet_app/features/budgets/application/budget_provider.dart';
import 'package:smart_wallet_app/features/recurring_expenses/application/recurring_expense_service.dart';
import 'package:smart_wallet_app/features/recurring_expenses/presentation/recurring_expenses_screen.dart';

void main() {
  testWidgets('editor supports income expense and weekly monthly cadence',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeRecurringExpensesProvider.overrideWith(
            (ref) => Stream.value(const <RecurringExpense>[]),
          ),
          accountsStreamProvider.overrideWith(
            (ref) => Stream.value(
              [
                Account(
                  localId: 'bank_main',
                  name: '주거래',
                  type: 'bank',
                  includeInNetWorth: true,
                  isActive: true,
                  createdAt: DateTime(2026, 5, 1),
                  lastModifiedAt: DateTime(2026, 5, 1),
                ),
              ],
            ),
          ),
          budgetCategoryOptionsProvider.overrideWith(
            (ref) => Stream.value(
              const [
                BudgetCategoryOption(id: 'expense-telecom', name: '통신비'),
              ],
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          home: const RecurringExpensesScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('정기 거래 추가'));
    await tester.pumpAndSettle();

    expect(find.text('수입'), findsOneWidget);
    expect(find.text('지출'), findsOneWidget);
    expect(find.text('매주'), findsOneWidget);
    expect(find.text('매달'), findsOneWidget);
  });
}
