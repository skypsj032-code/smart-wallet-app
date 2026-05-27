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
  test('recurring expense action semantics label includes purpose', () {
    final label = recurringExpenseActionSemanticLabel();

    expect(
      label,
      'Add recurring transaction. Open the editor to prepare repeating income or expense.',
    );
  });

  test('recurring expense item semantics label summarizes the schedule', () {
    final item = RecurringExpense(
      localId: 'rec-1',
      name: '월세',
      type: 'expense',
      amount: 500000,
      cadence: 'monthly',
      dayOfMonth: 25,
      weekday: null,
      accountId: 'bank_main',
      categoryId: 'expense-housing',
      isActive: true,
      lastSuggestedCycleKey: null,
      lastCompletedCycleKey: null,
      lastDismissedCycleKey: null,
      createdAt: DateTime(2026, 5, 1),
      lastModifiedAt: DateTime(2026, 5, 1),
    );

    final label = recurringExpenseItemSemanticLabel(item);

    expect(label, contains('Recurring transaction item.'));
    expect(label, contains('월세'));
    expect(label, contains('expense'));
    expect(label, contains('every month on day 25'));
    expect(label, contains('500,000원'));
  });

  testWidgets('recurring expenses screen exposes action and item semantics',
      (tester) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeRecurringExpensesProvider.overrideWith(
            (ref) => Stream.value(
              [
                RecurringExpense(
                  localId: 'rec-1',
                  name: '월세',
                  type: 'expense',
                  amount: 500000,
                  cadence: 'monthly',
                  dayOfMonth: 25,
                  weekday: null,
                  accountId: 'bank_main',
                  categoryId: 'expense-housing',
                  isActive: true,
                  lastSuggestedCycleKey: null,
                  lastCompletedCycleKey: null,
                  lastDismissedCycleKey: null,
                  createdAt: DateTime(2026, 5, 1),
                  lastModifiedAt: DateTime(2026, 5, 1),
                ),
              ],
            ),
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
                BudgetCategoryOption(id: 'expense-housing', name: '주거'),
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

    expect(
      find.bySemanticsLabel(
        'Add recurring transaction. Open the editor to prepare repeating income or expense.',
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(
        'Recurring transaction item. 월세. expense. every month on day 25. 500,000원.',
      ),
      findsOneWidget,
    );

    semantics.dispose();
  });
}
