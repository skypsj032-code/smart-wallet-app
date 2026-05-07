import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/providers/database_providers.dart';

enum CalendarViewMode {
  week,
  day,
  month,
  year,
}

enum CalendarTransactionFilter {
  all,
  income,
  expense,
}

enum CalendarTransactionSortOrder {
  newestFirst,
  oldestFirst,
}

class CalendarDaySummary {
  const CalendarDaySummary({
    required this.date,
    required this.income,
    required this.expense,
    this.transactionCount = 0,
    this.matchCount = 0,
  });

  final DateTime date;
  final int income;
  final int expense;
  final int transactionCount;
  final int matchCount;
}

class CalendarMonthSummary {
  const CalendarMonthSummary({
    required this.monthStart,
    required this.income,
    required this.expense,
  });

  final DateTime monthStart;
  final int income;
  final int expense;

  int get net => income - expense;
}

class CalendarSnapshot {
  const CalendarSnapshot({
    required this.mode,
    required this.anchorDate,
    required this.periodStart,
    required this.periodEnd,
    required this.days,
    required this.totalIncome,
    required this.totalExpense,
  });

  final CalendarViewMode mode;
  final DateTime anchorDate;
  final DateTime periodStart;
  final DateTime periodEnd;
  final List<CalendarDaySummary> days;
  final int totalIncome;
  final int totalExpense;
}

class CalendarHomeSummary {
  const CalendarHomeSummary({
    required this.date,
    required this.transactionCount,
    required this.income,
    required this.expense,
  });

  final DateTime date;
  final int transactionCount;
  final int income;
  final int expense;
}

class CalendarHomeMonthPreview {
  const CalendarHomeMonthPreview({
    required this.monthStart,
    required this.days,
  });

  final DateTime monthStart;
  final List<CalendarDaySummary> days;
}

final calendarViewModeProvider =
    StateProvider<CalendarViewMode>((ref) => CalendarViewMode.month);

final calendarTypeFilterProvider =
    StateProvider<CalendarTransactionFilter>((ref) {
  return CalendarTransactionFilter.all;
});

final calendarSearchQueryProvider = StateProvider<String>((ref) => '');

final calendarTransactionSortOrderProvider =
    StateProvider<CalendarTransactionSortOrder>(
  (ref) => CalendarTransactionSortOrder.newestFirst,
);

final _calendarTodayTickProvider = StreamProvider<DateTime>((ref) async* {
  while (true) {
    final now = DateTime.now();
    yield _normalizeDate(now);
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    await Future<void>.delayed(
      nextMidnight.difference(now) + const Duration(seconds: 1),
    );
  }
});

final calendarTodayProvider = Provider<DateTime>((ref) {
  return ref.watch(_calendarTodayTickProvider).valueOrNull ??
      _normalizeDate(DateTime.now());
});

final visibleCalendarDateProvider = StateProvider<DateTime>((ref) {
  return _normalizeDate(DateTime.now());
});

final calendarSnapshotProvider = StreamProvider<CalendarSnapshot>((ref) {
  final mode = ref.watch(calendarViewModeProvider);
  final anchorDate = ref.watch(visibleCalendarDateProvider);
  final filter = ref.watch(calendarTypeFilterProvider);
  final query = ref.watch(calendarSearchQueryProvider);
  final database = ref.watch(appDatabaseProvider);
  final periodStart = _periodStart(anchorDate, mode);
  final periodEnd = _periodEnd(periodStart, mode);

  final transactions = (database.select(database.transactions)
        ..where((t) =>
            t.deletedAt.isNull() &
            t.occurredAt.isBiggerOrEqualValue(periodStart) &
            t.occurredAt.isSmallerThanValue(periodEnd))
        ..orderBy([(t) => OrderingTerm.asc(t.occurredAt)]))
      .watch();
  final categories = database.select(database.categories).watch();

  return transactions.combineLatest(categories, (rows, categoryRows) {
    final categoryNames = {
      for (final category in categoryRows) category.localId: category.name,
    };
    final grouped = <DateTime, CalendarDaySummary>{};
    var totalIncome = 0;
    var totalExpense = 0;

    for (final tx in rows) {
      if (!_matchesTransactionType(tx, filter)) {
        continue;
      }

      final key =
          DateTime(tx.occurredAt.year, tx.occurredAt.month, tx.occurredAt.day);
      final current = grouped[key] ??
          CalendarDaySummary(
            date: key,
            income: 0,
            expense: 0,
          );
      final nextTransactionCount = current.transactionCount + 1;

      if (!_matchesSearchQuery(tx, query, categoryNames)) {
        grouped[key] = CalendarDaySummary(
          date: key,
          income: current.income,
          expense: current.expense,
          transactionCount: nextTransactionCount,
          matchCount: current.matchCount,
        );
        continue;
      }

      final nextIncome =
          tx.type == 'income' ? current.income + tx.amount : current.income;
      final nextExpense =
          tx.type == 'expense' ? current.expense + tx.amount : current.expense;

      if (tx.type == 'income') {
        totalIncome += tx.amount;
      } else if (tx.type == 'expense') {
        totalExpense += tx.amount;
      }

      grouped[key] = CalendarDaySummary(
        date: key,
        income: nextIncome,
        expense: nextExpense,
        transactionCount: nextTransactionCount,
        matchCount: current.matchCount + 1,
      );
    }

    final days = grouped.values.where((day) => day.matchCount > 0).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return CalendarSnapshot(
      mode: mode,
      anchorDate: anchorDate,
      periodStart: periodStart,
      periodEnd: periodEnd,
      days: days,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
    );
  });
});

final calendarMonthSummariesProvider =
    Provider<List<CalendarMonthSummary>>((ref) {
  final snapshot = ref.watch(calendarSnapshotProvider).valueOrNull;
  if (snapshot == null || snapshot.mode != CalendarViewMode.year) {
    return const <CalendarMonthSummary>[];
  }

  final monthMap = <int, CalendarMonthSummary>{};
  for (var month = 1; month <= 12; month++) {
    monthMap[month] = CalendarMonthSummary(
      monthStart: DateTime(snapshot.periodStart.year, month, 1),
      income: 0,
      expense: 0,
    );
  }

  for (final day in snapshot.days) {
    final month = day.date.month;
    final current = monthMap[month]!;
    monthMap[month] = CalendarMonthSummary(
      monthStart: current.monthStart,
      income: current.income + day.income,
      expense: current.expense + day.expense,
    );
  }

  return monthMap.values.toList()
    ..sort((a, b) => a.monthStart.compareTo(b.monthStart));
});

final selectedCalendarDateProvider = StateProvider<DateTime?>((ref) => null);

final selectedCalendarDayProvider = Provider<CalendarDaySummary?>((ref) {
  final snapshot = ref.watch(calendarSnapshotProvider).valueOrNull;
  final selected = ref.watch(selectedCalendarDateProvider);

  if (snapshot == null || selected == null) {
    return null;
  }

  for (final day in snapshot.days) {
    if (_isSameDate(day.date, selected)) {
      return day;
    }
  }

  return null;
});

final selectedCalendarTransactionsProvider =
    StreamProvider<List<Transaction>>((ref) {
  final selected = ref.watch(selectedCalendarDateProvider);
  final filter = ref.watch(calendarTypeFilterProvider);
  final query = ref.watch(calendarSearchQueryProvider);
  final sortOrder = ref.watch(calendarTransactionSortOrderProvider);
  if (selected == null) {
    return Stream.value(const <Transaction>[]);
  }

  final database = ref.watch(appDatabaseProvider);
  final dayStart = DateTime(selected.year, selected.month, selected.day);
  final nextDay = dayStart.add(const Duration(days: 1));

  final transactions = (database.select(database.transactions)
        ..where((t) =>
            t.deletedAt.isNull() &
            t.occurredAt.isBiggerOrEqualValue(dayStart) &
            t.occurredAt.isSmallerThanValue(nextDay))
        ..orderBy([
          if (sortOrder == CalendarTransactionSortOrder.newestFirst) ...[
            (t) => OrderingTerm.desc(t.occurredAt),
            (t) => OrderingTerm.desc(t.createdAt),
          ] else ...[
            (t) => OrderingTerm.asc(t.occurredAt),
            (t) => OrderingTerm.asc(t.createdAt),
          ],
        ]))
      .watch();
  final categories = database.select(database.categories).watch();

  return transactions.combineLatest(categories, (rows, categoryRows) {
    final categoryNames = {
      for (final category in categoryRows) category.localId: category.name,
    };

    return [
      for (final row in rows)
        if (_matchesTransactionType(row, filter) &&
            _matchesSearchQuery(row, query, categoryNames))
          row,
    ];
  });
});

final calendarHomeSummaryProvider = StreamProvider<CalendarHomeSummary>((ref) {
  final database = ref.watch(appDatabaseProvider);
  final today = ref.watch(calendarTodayProvider);
  final start = DateTime(today.year, today.month, today.day);
  final end = start.add(const Duration(days: 1));

  return (database.select(database.transactions)
        ..where((t) =>
            t.deletedAt.isNull() &
            t.occurredAt.isBiggerOrEqualValue(start) &
            t.occurredAt.isSmallerThanValue(end)))
      .watch()
      .map((rows) {
    var income = 0;
    var expense = 0;

    for (final row in rows) {
      if (row.type == 'income') {
        income += row.amount;
      } else if (row.type == 'expense') {
        expense += row.amount;
      }
    }

    return CalendarHomeSummary(
      date: start,
      transactionCount: rows.length,
      income: income,
      expense: expense,
    );
  });
});

final calendarHomeMonthPreviewProvider =
    StreamProvider<CalendarHomeMonthPreview>((ref) {
  final database = ref.watch(appDatabaseProvider);
  final today = ref.watch(calendarTodayProvider);
  final monthStart = DateTime(today.year, today.month, 1);
  final monthEnd = DateTime(today.year, today.month + 1, 1);

  return (database.select(database.transactions)
        ..where((t) =>
            t.deletedAt.isNull() &
            t.occurredAt.isBiggerOrEqualValue(monthStart) &
            t.occurredAt.isSmallerThanValue(monthEnd))
        ..orderBy([(t) => OrderingTerm.asc(t.occurredAt)]))
      .watch()
      .map((rows) {
    final grouped = <DateTime, CalendarDaySummary>{};

    for (final row in rows) {
      if (row.type == 'transfer') {
        continue;
      }

      final key = DateTime(
        row.occurredAt.year,
        row.occurredAt.month,
        row.occurredAt.day,
      );
      final current = grouped[key] ??
          CalendarDaySummary(
            date: key,
            income: 0,
            expense: 0,
          );

      grouped[key] = CalendarDaySummary(
        date: key,
        income: row.type == 'income' ? current.income + row.amount : current.income,
        expense:
            row.type == 'expense' ? current.expense + row.amount : current.expense,
        transactionCount: current.transactionCount + 1,
        matchCount: current.matchCount + 1,
      );
    }

    final days = grouped.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return CalendarHomeMonthPreview(
      monthStart: monthStart,
      days: days,
    );
  });
});

void refreshCalendarData(WidgetRef ref) {
  ref.invalidate(calendarSnapshotProvider);
  ref.invalidate(selectedCalendarTransactionsProvider);
}

DateTime _periodStart(DateTime anchorDate, CalendarViewMode mode) {
  switch (mode) {
    case CalendarViewMode.week:
      final normalized =
          DateTime(anchorDate.year, anchorDate.month, anchorDate.day);
      return normalized.subtract(Duration(days: normalized.weekday - 1));
    case CalendarViewMode.day:
      return DateTime(anchorDate.year, anchorDate.month, anchorDate.day);
    case CalendarViewMode.month:
      return DateTime(anchorDate.year, anchorDate.month, 1);
    case CalendarViewMode.year:
      return DateTime(anchorDate.year, 1, 1);
  }
}

DateTime _periodEnd(DateTime periodStart, CalendarViewMode mode) {
  switch (mode) {
    case CalendarViewMode.week:
      return periodStart.add(const Duration(days: 7));
    case CalendarViewMode.day:
      return periodStart.add(const Duration(days: 1));
    case CalendarViewMode.month:
      return DateTime(periodStart.year, periodStart.month + 1, 1);
    case CalendarViewMode.year:
      return DateTime(periodStart.year + 1, 1, 1);
  }
}

bool _isSameDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

bool _matchesTransactionType(
  Transaction row,
  CalendarTransactionFilter filter,
) {
  final matchesType = switch (filter) {
    CalendarTransactionFilter.all => true,
    CalendarTransactionFilter.income => row.type == 'income',
    CalendarTransactionFilter.expense => row.type == 'expense',
  };

  if (!matchesType) {
    return false;
  }

  return true;
}

bool _matchesSearchQuery(
  Transaction row,
  String query,
  Map<String, String> categoryNames,
) {
  final normalized = query.trim().toLowerCase();
  if (normalized.isEmpty) {
    return true;
  }

  final haystacks = <String>[
    row.memo ?? '',
    row.merchantName ?? '',
    if (row.categoryId != null) categoryNames[row.categoryId] ?? '',
  ];

  return haystacks.any((value) => value.toLowerCase().contains(normalized));
}

DateTime _normalizeDate(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

extension _CombineLatestExtension<A> on Stream<A> {
  Stream<R> combineLatest<B, R>(
    Stream<B> other,
    R Function(A a, B b) combiner,
  ) {
    late A latestA;
    late B latestB;
    var hasA = false;
    var hasB = false;

    final controller = StreamController<R>.broadcast();
    late StreamSubscription<A> subA;
    late StreamSubscription<B> subB;

    void emitIfReady() {
      if (hasA && hasB) {
        controller.add(combiner(latestA, latestB));
      }
    }

    subA = listen(
      (value) {
        latestA = value;
        hasA = true;
        emitIfReady();
      },
      onError: controller.addError,
      onDone: () async {
        await subB.cancel();
        await controller.close();
      },
    );

    subB = other.listen(
      (value) {
        latestB = value;
        hasB = true;
        emitIfReady();
      },
      onError: controller.addError,
    );

    controller.onCancel = () async {
      await subA.cancel();
      await subB.cancel();
    };

    return controller.stream;
  }
}
