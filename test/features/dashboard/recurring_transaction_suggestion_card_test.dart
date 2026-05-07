import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet_app/core/database/app_database.dart';
import 'package:smart_wallet_app/features/dashboard/presentation/recurring_transaction_suggestion_card.dart';
import 'package:smart_wallet_app/features/recurring_expenses/application/recurring_transaction_suggestion.dart';

void main() {
  testWidgets(
      'renders recurring transaction suggestion card with create and dismiss',
      (tester) async {
    var created = false;
    var dismissed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RecurringTransactionSuggestionCard(
            suggestion: _suggestion(name: '통신비', amount: 55000),
            onCreate: () => created = true,
            onDismiss: () => dismissed = true,
          ),
        ),
      ),
    );

    expect(find.text('오늘 처리할 정기 거래가 있어요'), findsOneWidget);
    expect(find.textContaining('통신비'), findsOneWidget);
    expect(find.textContaining('55,000'), findsOneWidget);
    expect(find.text('생성'), findsOneWidget);
    expect(find.text('이번엔 닫기'), findsOneWidget);

    await tester.tap(find.text('생성'));
    await tester.pump();
    expect(created, isTrue);

    await tester.tap(find.text('이번엔 닫기'));
    await tester.pump();
    expect(dismissed, isTrue);
  });
}

RecurringTransactionSuggestion _suggestion({
  required String name,
  required int amount,
}) {
  return RecurringTransactionSuggestion(
    transaction: RecurringExpense(
      localId: 'rec_phone',
      name: name,
      type: 'expense',
      amount: amount,
      cadence: 'monthly',
      dayOfMonth: 10,
      weekday: null,
      accountId: 'card_main',
      categoryId: 'expense-telecom',
      isActive: true,
      createdAt: DateTime(2026, 5, 1),
      lastModifiedAt: DateTime(2026, 5, 1),
    ),
    cycleKey: '2026-05',
    dueDate: DateTime(2026, 5, 10),
  );
}
