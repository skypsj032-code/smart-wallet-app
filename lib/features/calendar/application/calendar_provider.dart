import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/providers/database_providers.dart';

enum CalendarViewMode {
  week,
  month,
  year,
}

class CalendarDaySummary {
  const CalendarDaySummary({
    required this.date,
    required this.income,
    required this.expense,
  });

  final DateTime date;
  final int income;
  final int expense;
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

final calendarViewModeProvider =
    StateProvider<CalendarViewMode>((ref) => CalendarViewMode.month);

final visibleCalendarDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

final calendarSnapshotProvider = StreamProvider<CalendarSnapshot>((ref) {
  final mode = ref.watch(calendarViewModeProvider);
  final anchorDate = ref.watch(visibleCalendarDateProvider);
  final database = ref.watch(appDatabaseProvider);
  final periodStart = _periodStart(anchorDate, mode);
  final periodEnd = _periodEnd(periodStart, mode);

  return (database.select(database.transactions)
        ..where((t) =>
            t.deletedAt.isNull() &
            t.occurredAt.isBiggerOrEqualValue(periodStart) &
            t.occurredAt.isSmallerThanValue(periodEnd))
        ..orderBy([(t) => OrderingTerm.asc(t.occurredAt)]))
      .watch()
      .map((rows) {
    final grouped = <DateTime, CalendarDaySummary>{};
    var totalIncome = 0;
    var totalExpense = 0;

    for (final tx in rows) {
      final key =
          DateTime(tx.occurredAt.year, tx.occurredAt.month, tx.occurredAt.day);
      final current =
          grouped[key] ?? CalendarDaySummary(date: key, income: 0, expense: 0);

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
      );
    }

    final days = grouped.values.toList()
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
  if (selected == null) {
    return Stream.value(const <Transaction>[]);
  }

  final database = ref.watch(appDatabaseProvider);
  final dayStart = DateTime(selected.year, selected.month, selected.day);
  final nextDay = dayStart.add(const Duration(days: 1));

  return (database.select(database.transactions)
        ..where((t) =>
            t.deletedAt.isNull() &
            t.occurredAt.isBiggerOrEqualValue(dayStart) &
            t.occurredAt.isSmallerThanValue(nextDay))
        ..orderBy([
          (t) => OrderingTerm.desc(t.occurredAt),
          (t) => OrderingTerm.desc(t.createdAt),
        ]))
      .watch();
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
    case CalendarViewMode.month:
      return DateTime(periodStart.year, periodStart.month + 1, 1);
    case CalendarViewMode.year:
      return DateTime(periodStart.year + 1, 1, 1);
  }
}

bool _isSameDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
