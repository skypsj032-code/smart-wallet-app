import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/providers/database_providers.dart';

class RecurringExpenseService {
  RecurringExpenseService(this._database);

  final AppDatabase _database;

  Future<String> createFixedMonthly({
    required String name,
    required int amount,
    required int dayOfMonth,
    required String accountId,
    String? categoryId,
  }) async {
    _validateDraft(
      name: name,
      amount: amount,
      dayOfMonth: dayOfMonth,
      accountId: accountId,
    );

    final now = DateTime.now();
    final id = 'rec_${now.microsecondsSinceEpoch}';
    await _database.into(_database.recurringExpenses).insert(
          RecurringExpensesCompanion.insert(
            localId: id,
            name: name.trim(),
            amount: amount,
            dayOfMonth: dayOfMonth,
            accountId: accountId,
            categoryId: Value(categoryId),
            createdAt: now,
            lastModifiedAt: now,
          ),
        );
    return id;
  }

  Future<void> updateFixedMonthly({
    required String localId,
    required String name,
    required int amount,
    required int dayOfMonth,
    required String accountId,
    String? categoryId,
  }) async {
    _validateDraft(
      name: name,
      amount: amount,
      dayOfMonth: dayOfMonth,
      accountId: accountId,
    );

    await (_database.update(_database.recurringExpenses)
          ..where((tbl) => tbl.localId.equals(localId)))
        .write(
      RecurringExpensesCompanion(
        name: Value(name.trim()),
        amount: Value(amount),
        dayOfMonth: Value(dayOfMonth),
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

  Future<bool> materializeForMonth({
    required String recurringId,
    required DateTime month,
  }) async {
    final recurring = await (_database.select(_database.recurringExpenses)
          ..where((tbl) =>
              tbl.localId.equals(recurringId) & tbl.isActive.equals(true)))
        .getSingleOrNull();
    if (recurring == null) {
      return false;
    }

    final monthKey = _monthKey(month);
    if (recurring.lastCreatedMonthKey == monthKey) {
      return false;
    }

    final now = DateTime.now();
    final occurredAt =
        scheduledRecurringExpenseDateForMonth(month, recurring.dayOfMonth);

    await _database.transaction(() async {
      await _database.into(_database.transactions).insert(
            TransactionsCompanion.insert(
              localId: 'tx_${now.microsecondsSinceEpoch}',
              type: 'expense',
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
          lastCreatedMonthKey: Value(monthKey),
          lastModifiedAt: Value(now),
        ),
      );
    });

    return true;
  }

  void _validateDraft({
    required String name,
    required int amount,
    required int dayOfMonth,
    required String accountId,
  }) {
    if (name.trim().isEmpty) {
      throw ArgumentError('name is required');
    }
    if (amount <= 0) {
      throw ArgumentError('amount must be greater than zero');
    }
    if (dayOfMonth < 1 || dayOfMonth > 31) {
      throw ArgumentError('dayOfMonth must be between 1 and 31');
    }
    if (accountId.trim().isEmpty) {
      throw ArgumentError('accountId is required');
    }
  }

  String _monthKey(DateTime month) {
    return '${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}';
  }
}

List<RecurringExpense> sortRecurringExpensesByNextDueDate(
  Iterable<RecurringExpense> items, {
  required DateTime today,
}) {
  final sorted = items.toList();
  sorted.sort((a, b) {
    final dueComparison = nextRecurringExpenseDueDate(a.dayOfMonth, today: today)
        .compareTo(nextRecurringExpenseDueDate(b.dayOfMonth, today: today));
    if (dueComparison != 0) {
      return dueComparison;
    }

    return a.createdAt.compareTo(b.createdAt);
  });
  return sorted;
}

DateTime nextRecurringExpenseDueDate(
  int dayOfMonth, {
  required DateTime today,
}) {
  final currentMonthDue =
      scheduledRecurringExpenseDateForMonth(today, dayOfMonth);
  final todayDateOnly = DateTime(today.year, today.month, today.day);
  if (!currentMonthDue.isBefore(todayDateOnly)) {
    return currentMonthDue;
  }

  return scheduledRecurringExpenseDateForMonth(
    DateTime(today.year, today.month + 1),
    dayOfMonth,
  );
}

DateTime scheduledRecurringExpenseDateForMonth(
  DateTime month,
  int dayOfMonth,
) {
  final lastDay = DateTime(month.year, month.month + 1, 0).day;
  final clampedDay = dayOfMonth > lastDay ? lastDay : dayOfMonth;
  return DateTime(month.year, month.month, clampedDay);
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
          (tbl) => OrderingTerm.asc(tbl.dayOfMonth),
          (tbl) => OrderingTerm.asc(tbl.createdAt),
        ]))
      .watch();
});
