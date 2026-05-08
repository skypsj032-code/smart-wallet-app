import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet_app/core/database/app_database.dart';
import 'package:smart_wallet_app/features/budgets/presentation/budget_setup_dialog.dart';

void main() {
  test('budget setup semantics helpers describe the form controls', () {
    expect(
      budgetSetupCategorySemanticLabel(categoryName: null),
      'Budget category selector. Current selection: all categories.',
    );
    expect(
      budgetSetupCategorySemanticLabel(categoryName: 'Groceries'),
      'Budget category selector. Current selection: Groceries.',
    );
    expect(
      budgetSetupAmountSemanticLabel(),
      'Budget amount input. Enter the monthly budget amount in won.',
    );
    expect(
      budgetSetupSaveSemanticLabel(),
      'Save budget. Create or update the monthly budget for the selected category.',
    );
  });

  testWidgets('budget setup dialog exposes category, amount, and save semantics',
      (tester) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BudgetSetupDialog(
            initialCategories: [_category()],
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(
      find.bySemanticsLabel(
        'Budget category selector. Current selection: all categories.',
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(
        'Budget amount input. Enter the monthly budget amount in won.',
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(
        'Save budget. Create or update the monthly budget for the selected category.',
      ),
      findsOneWidget,
    );

    semantics.dispose();
  });
}

Category _category() {
  final now = DateTime(2026, 5, 8);
  return Category(
    localId: 'expense-food',
    name: 'Groceries',
    type: 'expense',
    iconName: null,
    colorHex: null,
    isDefault: false,
    isActive: true,
    sortOrder: 0,
    createdAt: now,
    lastModifiedAt: now,
  );
}
