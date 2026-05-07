import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../recurring_expenses/application/recurring_expense_service.dart';
import '../../recurring_expenses/application/recurring_transaction_suggestion.dart';

final recurringTransactionSuggestionProvider =
    FutureProvider<RecurringTransactionSuggestion?>((ref) async {
  final service = ref.watch(recurringExpenseServiceProvider);
  ref.watch(activeRecurringExpensesProvider);

  return service.selectDueSuggestion(today: DateTime.now());
});
