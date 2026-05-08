import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../transactions/application/quick_entry_form_provider.dart';
import '../application/calendar_provider.dart';
import 'calendar_day_detail_section.dart';
import 'calendar_month_surface.dart';
import 'calendar_reference_tabs.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snapshotAsync = ref.watch(calendarSnapshotProvider);
    final displayedMonth = ref.watch(displayedCalendarMonthProvider);
    final isMonthPickerOpen = ref.watch(calendarMonthPickerOpenProvider);
    final selectedDate = ref.watch(selectedCalendarDateProvider);
    final selectedTransactionsAsync =
        ref.watch(selectedCalendarTransactionsProvider);
    final transactionSortOrder =
        ref.watch(calendarTransactionSortOrderProvider);
    final scheme = Theme.of(context).colorScheme;

    final screen = AppScaffold(
      title: '달력',
      backgroundColor: scheme.surface,
      appBarBackgroundColor: scheme.surface,
      contentPadding: EdgeInsets.zero,
      body: snapshotAsync.when(
        data: (snapshot) {
          final monthCells = _buildMonthCells(snapshot);
          final selectedDay = selectedDate == null
              ? null
              : _summaryForDate(snapshot.days, selectedDate);

          return KeyedSubtree(
            key: const Key('calendar-reference-page'),
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CalendarReferenceTabs(
                    onOpenTimeline: () => context.go('/timeline'),
                    onOpenStatistics: () => context.go('/statistics'),
                  ),
                  CalendarMonthSurface(
                    displayedMonth: displayedMonth,
                    monthIncome: snapshot.totalIncome,
                    monthExpense: snapshot.totalExpense,
                    isMonthPickerOpen: isMonthPickerOpen,
                    onOpenPicker: () {
                      ref.read(calendarMonthPickerOpenProvider.notifier).state =
                          true;
                    },
                    onPreviousMonth: () => _moveDisplayedMonth(-1),
                    onNextMonth: () => _moveDisplayedMonth(1),
                    onPreviousYear: () => _movePickerYear(-1),
                    onNextYear: () => _movePickerYear(1),
                    onSelectMonth: _selectDisplayedMonth,
                    onSelectDay: _selectDate,
                    selectedDay: selectedDate,
                    cells: monthCells,
                  ),
                  CalendarDayDetailSection(
                    snapshot: snapshot,
                    selectedDate: selectedDate,
                    selectedDay: selectedDay,
                    transactionsAsync: selectedTransactionsAsync,
                    sortOrder: transactionSortOrder,
                    onChangeSortOrder: (sortOrder) {
                      ref
                          .read(calendarTransactionSortOrderProvider.notifier)
                          .state = sortOrder;
                    },
                    onEditTransaction: (transaction) => _openQuickEntry(
                      context,
                      transaction: transaction,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('달력을 불러오지 못했어요.\n$error'),
          ),
        ),
      ),
    );

    if (Router.maybeOf(context) == null) {
      return screen;
    }

    return BackButtonListener(
      onBackButtonPressed: () async {
        if (!isMonthPickerOpen) {
          return false;
        }

        ref.read(calendarMonthPickerOpenProvider.notifier).state = false;
        return true;
      },
      child: screen,
    );
  }

  Future<void> _openQuickEntry(
    BuildContext context, {
    Transaction? transaction,
  }) async {
    if (transaction != null) {
      ref.read(quickEntryFormProvider.notifier).loadTransaction(transaction);
    } else {
      ref.read(quickEntryFormProvider.notifier).reset();
    }

    await context.push('/quick-entry');
    if (!context.mounted) {
      return;
    }

    refreshCalendarData(ref);
  }

  void _moveDisplayedMonth(int direction) {
    final displayedMonth = ref.read(displayedCalendarMonthProvider);
    final nextMonth =
        DateTime(displayedMonth.year, displayedMonth.month + direction, 1);
    final nextSelectedDate = _selectedDateForMonth(nextMonth);

    ref.read(displayedCalendarMonthProvider.notifier).state = nextMonth;
    ref.read(visibleCalendarDateProvider.notifier).state =
        nextSelectedDate ?? nextMonth;
    ref.read(selectedCalendarDateProvider.notifier).state = nextSelectedDate;
    ref.read(calendarMonthPickerOpenProvider.notifier).state = false;
    _scrollToTop();
  }

  void _movePickerYear(int direction) {
    final displayedMonth = ref.read(displayedCalendarMonthProvider);
    ref.read(displayedCalendarMonthProvider.notifier).state = DateTime(
      displayedMonth.year + direction,
      displayedMonth.month,
      1,
    );
  }

  void _selectDisplayedMonth(int month) {
    final displayedMonth = ref.read(displayedCalendarMonthProvider);
    final nextMonth = DateTime(displayedMonth.year, month, 1);
    final nextSelectedDate = _selectedDateForMonth(nextMonth);

    ref.read(displayedCalendarMonthProvider.notifier).state = nextMonth;
    ref.read(visibleCalendarDateProvider.notifier).state =
        nextSelectedDate ?? nextMonth;
    ref.read(selectedCalendarDateProvider.notifier).state = nextSelectedDate;
    ref.read(calendarMonthPickerOpenProvider.notifier).state = false;
    _scrollToTop();
  }

  void _selectDate(DateTime date) {
    ref.read(visibleCalendarDateProvider.notifier).state = date;
    ref.read(selectedCalendarDateProvider.notifier).state = date;
  }

  void _scrollToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      _scrollController.jumpTo(0);
    });
  }

  DateTime? _selectedDateForMonth(DateTime month) {
    final selectedDate = ref.read(selectedCalendarDateProvider);
    if (selectedDate == null) {
      return null;
    }

    final lastDayOfMonth = DateTime(month.year, month.month + 1, 0).day;
    final selectedDay = selectedDate.day > lastDayOfMonth
        ? lastDayOfMonth
        : selectedDate.day;

    return DateTime(month.year, month.month, selectedDay);
  }

  List<CalendarMonthCellData> _buildMonthCells(CalendarSnapshot snapshot) {
    final firstDay =
        DateTime(snapshot.periodStart.year, snapshot.periodStart.month, 1);
    final lastDay =
        DateTime(snapshot.periodStart.year, snapshot.periodStart.month + 1, 0);
    final leadingEmptyCount = firstDay.weekday - 1;
    final summaryByDay = {
      for (final day in snapshot.days) day.date.day: day,
    };

    final cells = <CalendarMonthCellData>[
      for (var i = 0; i < leadingEmptyCount; i++)
        const CalendarMonthCellData.empty(),
    ];

    for (var day = 1; day <= lastDay.day; day++) {
      final date =
          DateTime(snapshot.periodStart.year, snapshot.periodStart.month, day);
      cells.add(
        CalendarMonthCellData(
          date: date,
          summary: summaryByDay[day],
        ),
      );
    }

    while (cells.length % 7 != 0) {
      cells.add(const CalendarMonthCellData.empty());
    }

    return cells;
  }

  CalendarDaySummary? _summaryForDate(
    List<CalendarDaySummary> days,
    DateTime date,
  ) {
    for (final day in days) {
      if (_isSameDate(day.date, date)) {
        return day;
      }
    }
    return null;
  }
}

bool _isSameDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
