import '../../../core/database/app_database.dart';

class RecurringTransactionSuggestion {
  const RecurringTransactionSuggestion({
    required this.transaction,
    required this.cycleKey,
    required this.dueDate,
  });

  final RecurringExpense transaction;
  final String cycleKey;
  final DateTime dueDate;
}

String recurringCycleKey({
  required String cadence,
  required DateTime date,
}) {
  switch (cadence) {
    case 'weekly':
      final weekStart = dateOnly(date).subtract(Duration(days: date.weekday - 1));
      return _dateKey(weekStart);
    case 'monthly':
      return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}';
    default:
      throw ArgumentError('Unsupported cadence: $cadence');
  }
}

DateTime recurringDueDateForCycle(
  RecurringExpense transaction, {
  required DateTime today,
}) {
  final normalizedToday = dateOnly(today);
  switch (transaction.cadence) {
    case 'weekly':
      final weekday = transaction.weekday;
      if (weekday == null) {
        throw ArgumentError('Weekly recurring transaction requires weekday.');
      }
      final startOfWeek =
          normalizedToday.subtract(Duration(days: normalizedToday.weekday - 1));
      return startOfWeek.add(Duration(days: weekday - 1));
    case 'monthly':
      final dayOfMonth = transaction.dayOfMonth;
      if (dayOfMonth == null) {
        throw ArgumentError('Monthly recurring transaction requires dayOfMonth.');
      }
      return scheduledRecurringDateForMonth(normalizedToday, dayOfMonth);
    default:
      throw ArgumentError('Unsupported cadence: ${transaction.cadence}');
  }
}

DateTime nextRecurringExpenseDueDate(
  RecurringExpense transaction, {
  required DateTime today,
}) {
  final normalizedToday = dateOnly(today);
  final currentCycleDue = recurringDueDateForCycle(
    transaction,
    today: normalizedToday,
  );
  if (!currentCycleDue.isBefore(normalizedToday)) {
    return currentCycleDue;
  }

  switch (transaction.cadence) {
    case 'weekly':
      return currentCycleDue.add(const Duration(days: 7));
    case 'monthly':
      return recurringDueDateForCycle(
        transaction,
        today: DateTime(normalizedToday.year, normalizedToday.month + 1, 1),
      );
    default:
      throw ArgumentError('Unsupported cadence: ${transaction.cadence}');
  }
}

DateTime scheduledRecurringDateForMonth(
  DateTime month,
  int dayOfMonth,
) {
  final lastDay = DateTime(month.year, month.month + 1, 0).day;
  final clampedDay = dayOfMonth > lastDay ? lastDay : dayOfMonth;
  return DateTime(month.year, month.month, clampedDay);
}

DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

String _dateKey(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
