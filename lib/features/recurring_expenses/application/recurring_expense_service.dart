import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/providers/database_providers.dart';
import 'recurring_transaction_suggestion.dart';

const _uuid = Uuid();

class RecurringExpenseService {
  RecurringExpenseService(this._database);

  final AppDatabase _database;

  Future<String> createRecurringTransaction({
    required String name,
    required String type,
    required int amount,
    required String cadence,
    required int? dayOfMonth,
    required int? weekday,
    required String accountId,
    String? categoryId,
  }) async {
    _validateDraft(
      name: name,
      type: type,
      amount: amount,
      cadence: cadence,
      dayOfMonth: dayOfMonth,
      weekday: weekday,
      accountId: accountId,
    );

    final now = DateTime.now();
    final id = 'rec_${now.microsecondsSinceEpoch}';
    await _database.into(_database.recurringExpenses).insert(
          RecurringExpensesCompanion.insert(
            localId: id,
            name: name.trim(),
            type: type,
            amount: amount,
            cadence: cadence,
            dayOfMonth: Value(dayOfMonth),
            weekday: Value(weekday),
            accountId: accountId,
            categoryId: Value(categoryId),
            createdAt: now,
            lastModifiedAt: now,
          ),
        );
    return id;
  }

  Future<void> updateRecurringTransaction({
    required String localId,
    required String name,
    required String type,
    required int amount,
    required String cadence,
    required int? dayOfMonth,
    required int? weekday,
    required String accountId,
    String? categoryId,
  }) async {
    _validateDraft(
      name: name,
      type: type,
      amount: amount,
      cadence: cadence,
      dayOfMonth: dayOfMonth,
      weekday: weekday,
      accountId: accountId,
    );

    await (_database.update(_database.recurringExpenses)
          ..where((tbl) => tbl.localId.equals(localId)))
        .write(
      RecurringExpensesCompanion(
        name: Value(name.trim()),
        type: Value(type),
        amount: Value(amount),
        cadence: Value(cadence),
        dayOfMonth: Value(dayOfMonth),
        weekday: Value(weekday),
        accountId: Value(accountId),
        categoryId: Value(categoryId),
        lastModifiedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deactivate(String localId) async {
    await (_database.update(_database.recurringExpenses)
          ..where((tbl) => tbl.localId.equals(localId)))
        .write(
      RecurringExpensesCompanion(
        isActive: const Value(false),
        lastModifiedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> dismissSuggestion({
    required String recurringId,
    required String cycleKey,
  }) async {
    final now = DateTime.now();
    await (_database.update(_database.recurringExpenses)
          ..where((tbl) => tbl.localId.equals(recurringId)))
        .write(
      RecurringExpensesCompanion(
        lastSuggestedCycleKey: Value(cycleKey),
        lastDismissedCycleKey: Value(cycleKey),
        lastModifiedAt: Value(now),
      ),
    );
  }

  Future<bool> createTransactionFromSuggestion({
    required String recurringId,
    required DateTime today,
  }) async {
    final recurring = await _activeRecurringById(recurringId);
    if (recurring == null || !_isDueToday(recurring, today: today)) {
      return false;
    }

    final cycleKey = recurringCycleKey(
      cadence: recurring.cadence,
      date: today,
    );
    if (_isCycleClosed(recurring, cycleKey)) {
      return false;
    }

    final now = DateTime.now();
    final occurredAt = dateOnly(today);
    await _database.transaction(() async {
      await _database.into(_database.transactions).insert(
            TransactionsCompanion.insert(
              localId: 'tx_${_uuid.v4()}',
              type: recurring.type,
              amount: recurring.amount,
              occurredAt: occurredAt,
              accountId: Value(recurring.accountId),
              categoryId: Value(recurring.categoryId),
              memo: Value(recurring.name),
              createdAt: now,
              lastModifiedAt: now,
            ),
          );

      await (_database.update(_database.recurringExpenses)
            ..where((tbl) => tbl.localId.equals(recurring.localId)))
          .write(
        RecurringExpensesCompanion(
          lastSuggestedCycleKey: Value(cycleKey),
          lastCompletedCycleKey: Value(cycleKey),
          lastModifiedAt: Value(now),
        ),
      );
    });

    return true;
  }

  Future<bool> materializeForMonth({
    required String recurringId,
    required DateTime month,
  }) {
    return createTransactionFromSuggestion(
      recurringId: recurringId,
      today: month,
    );
  }

  Future<RecurringTransactionSuggestion?> selectDueSuggestion({
    required DateTime today,
  }) async {
    final items = await (_database.select(_database.recurringExpenses)
          ..where((tbl) => tbl.isActive.equals(true)))
        .get();

    final dueSuggestions = items
        .where((item) => _isDueToday(item, today: today))
        .map((item) {
          final cycleKey = recurringCycleKey(
            cadence: item.cadence,
            date: today,
          );
          if (_isCycleClosed(item, cycleKey)) {
            return null;
          }

          return RecurringTransactionSuggestion(
            transaction: item,
            cycleKey: cycleKey,
            dueDate: recurringDueDateForCycle(item, today: today),
          );
        })
        .nonNulls
        .toList()
      ..sort((a, b) {
        final dueComparison = a.dueDate.compareTo(b.dueDate);
        if (dueComparison != 0) {
          return dueComparison;
        }

        final amountComparison = b.transaction.amount.compareTo(
          a.transaction.amount,
        );
        if (amountComparison != 0) {
          return amountComparison;
        }

        return a.transaction.createdAt.compareTo(b.transaction.createdAt);
      });

    if (dueSuggestions.isEmpty) {
      return null;
    }

    return dueSuggestions.first;
  }

  void _validateDraft({
    required String name,
    required String type,
    required int amount,
    required String cadence,
    required int? dayOfMonth,
    required int? weekday,
    required String accountId,
  }) {
    if (name.trim().isEmpty) {
      throw ArgumentError('name is required');
    }
    if (type != 'income' && type != 'expense') {
      throw ArgumentError('type must be income or expense');
    }
    if (amount <= 0) {
      throw ArgumentError('amount must be greater than zero');
    }
    if (cadence != 'weekly' && cadence != 'monthly') {
      throw ArgumentError('cadence must be weekly or monthly');
    }
    if (cadence == 'monthly') {
      if (dayOfMonth == null || dayOfMonth < 1 || dayOfMonth > 31) {
        throw ArgumentError('dayOfMonth must be between 1 and 31');
      }
    } else {
      if (weekday == null || weekday < 1 || weekday > 7) {
        throw ArgumentError('weekday must be between 1 and 7');
      }
    }
    if (accountId.trim().isEmpty) {
      throw ArgumentError('accountId is required');
    }
  }

  Future<RecurringExpense?> _activeRecurringById(String recurringId) {
    return (_database.select(_database.recurringExpenses)
          ..where((tbl) =>
              tbl.localId.equals(recurringId) & tbl.isActive.equals(true)))
        .getSingleOrNull();
  }

  bool _isDueToday(
    RecurringExpense recurring, {
    required DateTime today,
  }) {
    final normalizedToday = dateOnly(today);
    switch (recurring.cadence) {
      case 'weekly':
        return recurring.weekday == normalizedToday.weekday;
      case 'monthly':
        final dayOfMonth = recurring.dayOfMonth;
        if (dayOfMonth == null) {
          return false;
        }
        final dueDate = scheduledRecurringDateForMonth(normalizedToday, dayOfMonth);
        return dueDate.year == normalizedToday.year &&
            dueDate.month == normalizedToday.month &&
            dueDate.day == normalizedToday.day;
      default:
        return false;
    }
  }

  bool _isCycleClosed(RecurringExpense recurring, String cycleKey) {
    return recurring.lastCompletedCycleKey == cycleKey ||
        recurring.lastDismissedCycleKey == cycleKey;
  }
}

List<RecurringExpense> sortRecurringExpensesByNextDueDate(
  Iterable<RecurringExpense> items, {
  required DateTime today,
}) {
  final sorted = items.toList();
  sorted.sort((a, b) {
    final dueComparison = nextRecurringExpenseDueDate(a, today: today)
        .compareTo(nextRecurringExpenseDueDate(b, today: today));
    if (dueComparison != 0) {
      return dueComparison;
    }

    final amountComparison = b.amount.compareTo(a.amount);
    if (amountComparison != 0) {
      return amountComparison;
    }

    return a.createdAt.compareTo(b.createdAt);
  });
  return sorted;
}

final recurringExpenseServiceProvider = Provider<RecurringExpenseService>((ref) {
  return RecurringExpenseService(ref.watch(appDatabaseProvider));
});

final activeRecurringExpensesProvider =
    StreamProvider<List<RecurringExpense>>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return (database.select(database.recurringExpenses)
        ..where((tbl) => tbl.isActive.equals(true))
        ..orderBy([
          (tbl) => OrderingTerm.asc(tbl.createdAt),
          (tbl) => OrderingTerm.asc(tbl.name),
        ]))
      .watch();
});
