import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/app_section.dart';
import '../../transactions/application/quick_entry_form_provider.dart';
import '../application/calendar_provider.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  static const weekdayLabels = ['월', '화', '수', '목', '금', '토', '일'];

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  bool _explorerExpanded = false;
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
    final viewMode = ref.watch(calendarViewModeProvider);
    final yearMonths = ref.watch(calendarMonthSummariesProvider);
    final transactionSortOrder =
        ref.watch(calendarTransactionSortOrderProvider);

    return AppScaffold(
      title: '달력',
      body: snapshotAsync.when(
        data: (snapshot) {
          final effectiveSelectedDate = switch (viewMode) {
            CalendarViewMode.day => snapshot.anchorDate,
            CalendarViewMode.week => selectedDate ?? snapshot.anchorDate,
            CalendarViewMode.month => selectedDate,
            CalendarViewMode.year => null,
          };
          final effectiveSelectedDay = effectiveSelectedDate == null
              ? null
              : _summaryForDate(snapshot.days, effectiveSelectedDate);
          final weekCells = viewMode == CalendarViewMode.week
              ? _buildWeekCells(snapshot)
              : const <_CalendarCellData>[];
          final monthCells = viewMode == CalendarViewMode.month
              ? _buildMonthCells(snapshot)
              : const <_CalendarCellData>[];

          return ListView(
            controller: _scrollController,
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  0,
                ),
                child: _ExplorerHandle(
                  expanded: _explorerExpanded,
                  onToggle: () {
                    setState(() {
                      _explorerExpanded = !_explorerExpanded;
                    });
                  },
                  onDragDirection: (delta) {
                    if (delta > 0 && !_explorerExpanded) {
                      setState(() {
                        _explorerExpanded = true;
                      });
                    } else if (delta < 0 && _explorerExpanded) {
                      setState(() {
                        _explorerExpanded = false;
                      });
                    }
                  },
                ),
              ),
              if (_explorerExpanded) ...[
                const SizedBox(height: AppSpacing.sm),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: _CalendarExplorerPanel(),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: _CalendarHeaderBar(
                  label: _formatMonth(displayedMonth),
                  onTapLabel: () {
                    ref.read(calendarMonthPickerOpenProvider.notifier).state =
                        true;
                  },
                  onPrevious: () => _moveDisplayedMonth(-1),
                  onNext: () => _moveDisplayedMonth(1),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: isMonthPickerOpen
                        ? _InlineMonthPicker(
                            displayedMonth: displayedMonth,
                            onPreviousYear: () => _movePickerYear(-1),
                            onNextYear: () => _movePickerYear(1),
                            onSelectMonth: (month) =>
                                _selectDisplayedMonth(month),
                          )
                        : switch (viewMode) {
                            CalendarViewMode.week => _WeekCalendarView(
                                cells: weekCells,
                                selectedDate: selectedDate,
                                onSelectDate: _selectDate,
                              ),
                            CalendarViewMode.day => _DayCalendarView(
                                date: snapshot.anchorDate,
                                summary: effectiveSelectedDay,
                              ),
                            CalendarViewMode.month => _MonthCalendarContent(
                                snapshot: snapshot,
                                cells: monthCells,
                                selectedDate: selectedDate,
                                onSelectDate: _selectDate,
                              ),
                            CalendarViewMode.year => _YearCalendarView(
                                months: yearMonths,
                                onTapMonth: (month) {
                                  ref
                                      .read(visibleCalendarDateProvider.notifier)
                                      .state = month;
                                  ref
                                      .read(calendarViewModeProvider.notifier)
                                      .state = CalendarViewMode.month;
                                  ref
                                      .read(selectedCalendarDateProvider.notifier)
                                      .state = null;
                                  setState(() {
                                    _explorerExpanded = false;
                                  });
                                },
                              ),
                          },
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (viewMode != CalendarViewMode.year && effectiveSelectedDate != null)
                AppSection(
                  title: viewMode == CalendarViewMode.day
                      ? '기록'
                      : _selectedDateLabel(effectiveSelectedDate),
                  child: _CalendarSelectedDayCard(
                    selectedDate: effectiveSelectedDate,
                    selectedDay: viewMode == CalendarViewMode.day
                        ? null
                        : effectiveSelectedDay,
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
                )
              else
                AppSection(
                  title: '기간 흐름',
                  child: _CalendarYearSummaryCard(
                    snapshot: snapshot,
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text('달력을 불러오지 못했어요.\n$error'),
          ),
        ),
      ),
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

    ref.read(displayedCalendarMonthProvider.notifier).state = nextMonth;
    ref.read(visibleCalendarDateProvider.notifier).state = nextMonth;
    ref.read(selectedCalendarDateProvider.notifier).state = null;
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

    ref.read(displayedCalendarMonthProvider.notifier).state = nextMonth;
    ref.read(visibleCalendarDateProvider.notifier).state = nextMonth;
    ref.read(selectedCalendarDateProvider.notifier).state = null;
    ref.read(calendarMonthPickerOpenProvider.notifier).state = false;
    _scrollToTop();
  }

  void _selectDate(DateTime date) {
    ref.read(selectedCalendarDateProvider.notifier).state = date;
    setState(() {
      _explorerExpanded = false;
    });
  }

  void _scrollToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      _scrollController.jumpTo(0);
    });
  }

  List<_CalendarCellData> _buildMonthCells(CalendarSnapshot snapshot) {
    final firstDay =
        DateTime(snapshot.periodStart.year, snapshot.periodStart.month, 1);
    final lastDay =
        DateTime(snapshot.periodStart.year, snapshot.periodStart.month + 1, 0);
    final leadingEmptyCount = firstDay.weekday - 1;
    final summaryByDay = {
      for (final day in snapshot.days) day.date.day: day,
    };

    final cells = <_CalendarCellData>[
      for (var i = 0; i < leadingEmptyCount; i++)
        const _CalendarCellData.empty(),
    ];

    for (var day = 1; day <= lastDay.day; day++) {
      final date =
          DateTime(snapshot.periodStart.year, snapshot.periodStart.month, day);
      cells.add(
        _CalendarCellData(
          date: date,
          summary: summaryByDay[day],
        ),
      );
    }

    while (cells.length % 7 != 0) {
      cells.add(const _CalendarCellData.empty());
    }

    return cells;
  }

  List<_CalendarCellData> _buildWeekCells(CalendarSnapshot snapshot) {
    final summaryByKey = {
      for (final day in snapshot.days) _dateKey(day.date): day,
    };

    return [
      for (var offset = 0; offset < 7; offset++)
        _CalendarCellData(
          date: snapshot.periodStart.add(Duration(days: offset)),
          summary: summaryByKey[
              _dateKey(snapshot.periodStart.add(Duration(days: offset)))],
        ),
    ];
  }

  String _formatMonth(DateTime month) {
    return '${month.year}.${month.month.toString().padLeft(2, '0')}';
  }

  String _selectedDateLabel(DateTime date) {
    return '${date.month}월 ${date.day}일';
  }

  CalendarDaySummary? _summaryForDate(
    List<CalendarDaySummary> days,
    DateTime date,
  ) {
    for (final day in days) {
      if (isSameDate(day.date, date)) {
        return day;
      }
    }
    return null;
  }
}

class _ExplorerHandle extends StatelessWidget {
  const _ExplorerHandle({
    required this.expanded,
    required this.onToggle,
    required this.onDragDirection,
  });

  final bool expanded;
  final VoidCallback onToggle;
  final ValueChanged<double> onDragDirection;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const Key('calendar-explorer-handle'),
      onTap: onToggle,
      onVerticalDragUpdate: (details) {
        final delta = details.primaryDelta;
        if (delta == null || delta == 0) {
          return;
        }
        onDragDirection(delta);
      },
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: expanded ? 64 : 48,
          height: 6,
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .onSurfaceVariant
                .withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}

class _CalendarExplorerPanel extends ConsumerWidget {
  const _CalendarExplorerPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(calendarTypeFilterProvider);
    final query = ref.watch(calendarSearchQueryProvider);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '탐색',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              key: const Key('calendar-search-field'),
              onChanged: (value) {
                ref.read(calendarSearchQueryProvider.notifier).state = value;
              },
              controller: TextEditingController(text: query)
                ..selection = TextSelection.collapsed(offset: query.length),
              decoration: const InputDecoration(
                hintText: '이름, 메모, 카테고리 검색',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _TransactionFilterChip(
                  key: const Key('calendar-filter-all'),
                  label: '전체',
                  selected: filter == CalendarTransactionFilter.all,
                  onTap: () {
                    ref.read(calendarTypeFilterProvider.notifier).state =
                        CalendarTransactionFilter.all;
                  },
                ),
                _TransactionFilterChip(
                  key: const Key('calendar-filter-income'),
                  label: '수입',
                  selected: filter == CalendarTransactionFilter.income,
                  onTap: () {
                    ref.read(calendarTypeFilterProvider.notifier).state =
                        CalendarTransactionFilter.income;
                  },
                ),
                _TransactionFilterChip(
                  key: const Key('calendar-filter-expense'),
                  label: '지출',
                  selected: filter == CalendarTransactionFilter.expense,
                  onTap: () {
                    ref.read(calendarTypeFilterProvider.notifier).state =
                        CalendarTransactionFilter.expense;
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DayCalendarView extends StatelessWidget {
  const _DayCalendarView({
    required this.date,
    required this.summary,
  });

  final DateTime date;
  final CalendarDaySummary? summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${date.month}월 ${date.day}일',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${CalendarScreen.weekdayLabels[date.weekday - 1]}요일',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _SummaryTile(
                label: '수입',
                value: formatCurrency(summary?.income ?? 0),
                color: AppColors.income,
              ),
              _SummaryTile(
                label: '지출',
                value: formatCurrency(summary?.expense ?? 0),
                color: AppColors.expense,
              ),
              _SummaryTile(
                label: '거래',
                value: '${summary?.transactionCount ?? 0}건',
                color: AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TransactionFilterChip extends StatelessWidget {
  const _TransactionFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
    );
  }
}

class _CalendarHeaderBar extends StatelessWidget {
  const _CalendarHeaderBar({
    required this.label,
    required this.onTapLabel,
    required this.onPrevious,
    required this.onNext,
  });

  final String label;
  final VoidCallback onTapLabel;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            key: const Key('calendar-month-label'),
            borderRadius: BorderRadius.circular(12),
            onTap: onTapLabel,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Text(
                label,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ),
        ),
        IconButton(
          key: const Key('calendar-previous-period'),
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left_rounded),
          visualDensity: VisualDensity.compact,
        ),
        IconButton(
          key: const Key('calendar-next-period'),
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right_rounded),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}

class _MonthCalendarContent extends StatelessWidget {
  const _MonthCalendarContent({
    required this.snapshot,
    required this.cells,
    required this.selectedDate,
    required this.onSelectDate,
  });

  final CalendarSnapshot snapshot;
  final List<_CalendarCellData> cells;
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onSelectDate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MonthSummaryBlock(snapshot: snapshot),
        const SizedBox(height: AppSpacing.md),
        Container(
          key: const Key('calendar-month-grid-shell'),
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(20),
          ),
          child: _MonthCalendarView(
            cells: cells,
            selectedDate: selectedDate,
            onSelectDate: onSelectDate,
          ),
        ),
      ],
    );
  }
}

class _MonthSummaryBlock extends StatelessWidget {
  const _MonthSummaryBlock({
    required this.snapshot,
  });

  final CalendarSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        );
    final valueStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
        );

    return Container(
      key: const Key('calendar-month-summary-block'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MonthSummaryEntry(
            label: '지출',
            value: formatCurrency(snapshot.totalExpense),
            color: AppColors.expense,
            labelStyle: labelStyle,
            valueStyle: valueStyle,
          ),
          const SizedBox(height: AppSpacing.xs),
          _MonthSummaryEntry(
            label: '수입',
            value: formatCurrency(snapshot.totalIncome),
            color: AppColors.income,
            labelStyle: labelStyle,
            valueStyle: valueStyle,
          ),
        ],
      ),
    );
  }
}

class _MonthSummaryEntry extends StatelessWidget {
  const _MonthSummaryEntry({
    required this.label,
    required this.value,
    required this.color,
    required this.labelStyle,
    required this.valueStyle,
  });

  final String label;
  final String value;
  final Color color;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 28,
          child: Text(label, style: labelStyle),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: valueStyle?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

class _WeekCalendarView extends StatelessWidget {
  const _WeekCalendarView({
    required this.cells,
    required this.selectedDate,
    required this.onSelectDate,
  });

  final List<_CalendarCellData> cells;
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onSelectDate;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            for (final label in CalendarScreen.weekdayLabels)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                ),
              ),
          ],
        ),
        Row(
          children: [
            for (final cell in cells)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: AspectRatio(
                    aspectRatio: 0.76,
                    child: _CalendarDayCell(
                      cell: cell,
                      isSelected: selectedDate != null &&
                          cell.date != null &&
                          isSameDate(cell.date!, selectedDate!),
                      onTap: cell.date == null
                          ? null
                          : () => onSelectDate(cell.date!),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _MonthCalendarView extends StatelessWidget {
  const _MonthCalendarView({
    required this.cells,
    required this.selectedDate,
    required this.onSelectDate,
  });

  final List<_CalendarCellData> cells;
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onSelectDate;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('calendar-month-grid'),
      children: [
        Row(
          children: [
            for (final label in CalendarScreen.weekdayLabels)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                ),
              ),
          ],
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cells.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: AppSpacing.xs,
            crossAxisSpacing: AppSpacing.xs,
            childAspectRatio: 0.74,
          ),
          itemBuilder: (context, index) {
            final cell = cells[index];
            if (cell.date == null) {
              return const SizedBox.shrink();
            }

            final isSelected =
                selectedDate != null && isSameDate(cell.date!, selectedDate!);

            return _CalendarDayCell(
              cell: cell,
              isSelected: isSelected,
              onTap: () => onSelectDate(cell.date!),
            );
          },
        ),
      ],
    );
  }
}

class _YearCalendarView extends StatelessWidget {
  const _YearCalendarView({
    required this.months,
    required this.onTapMonth,
  });

  final List<CalendarMonthSummary> months;
  final ValueChanged<DateTime> onTapMonth;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: months.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
        childAspectRatio: 1.38,
      ),
      itemBuilder: (context, index) {
        final month = months[index];
        return InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => onTapMonth(month.monthStart),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${month.monthStart.month}월',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const Spacer(),
                Text(
                  '수입 ${formatCurrency(month.income)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.income,
                      ),
                ),
                Text(
                  '지출 ${formatCurrency(month.expense)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.expense,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '차이 ${formatCurrency(month.net)}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CalendarSelectedDayCard extends StatelessWidget {
  const _CalendarSelectedDayCard({
    required this.selectedDate,
    required this.selectedDay,
    required this.transactionsAsync,
    required this.sortOrder,
    required this.onChangeSortOrder,
    required this.onEditTransaction,
  });

  final DateTime? selectedDate;
  final CalendarDaySummary? selectedDay;
  final AsyncValue<List<Transaction>> transactionsAsync;
  final CalendarTransactionSortOrder sortOrder;
  final ValueChanged<CalendarTransactionSortOrder> onChangeSortOrder;
  final ValueChanged<Transaction> onEditTransaction;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: transactionsAsync.when(
          data: (transactions) {
            if (selectedDate == null) {
              return const _CalendarEmptyMessage(
                title: '날짜를 선택하세요',
                body: '',
              );
            }

            if (transactions.isEmpty) {
              return const _CalendarEmptyMessage(
                title: '이 날의 거래가 없어요',
                body: '',
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: SegmentedButton<CalendarTransactionSortOrder>(
                    segments: const [
                      ButtonSegment<CalendarTransactionSortOrder>(
                        value: CalendarTransactionSortOrder.newestFirst,
                        icon: Icon(Icons.south_rounded),
                        label: Text('최신순'),
                      ),
                      ButtonSegment<CalendarTransactionSortOrder>(
                        value: CalendarTransactionSortOrder.oldestFirst,
                        icon: Icon(Icons.north_rounded),
                        label: Text('오래된순'),
                      ),
                    ],
                    selected: {sortOrder},
                    onSelectionChanged: (selection) =>
                        onChangeSortOrder(selection.first),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (selectedDay != null) ...[
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      _CompactSummaryChip(
                        key: const Key('calendar-selected-summary-income'),
                        label: '수입',
                        value: formatCurrency(selectedDay!.income),
                        color: AppColors.income,
                      ),
                      _CompactSummaryChip(
                        key: const Key('calendar-selected-summary-expense'),
                        label: '지출',
                        value: formatCurrency(selectedDay!.expense),
                        color: AppColors.expense,
                      ),
                      _CompactSummaryChip(
                        key: const Key('calendar-selected-summary-count'),
                        label: '거래',
                        value: '${selectedDay!.transactionCount}건',
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                for (var index = 0; index < transactions.length; index++) ...[
                  _EditableTransactionRow(
                    transaction: transactions[index],
                    onTap: () => onEditTransaction(transactions[index]),
                  ),
                  if (index != transactions.length - 1)
                    const Divider(height: AppSpacing.lg),
                ],
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) =>
              Text('거래를 불러오지 못했어요. $error'),
        ),
      ),
    );
  }
}

class _CalendarYearSummaryCard extends StatelessWidget {
  const _CalendarYearSummaryCard({
    required this.snapshot,
  });

  final CalendarSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _SummaryTile(
                  label: '총수입',
                  value: formatCurrency(snapshot.totalIncome),
                  color: AppColors.income,
                ),
                _SummaryTile(
                  label: '총지출',
                  value: formatCurrency(snapshot.totalExpense),
                  color: AppColors.expense,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarEmptyMessage extends StatelessWidget {
  const _CalendarEmptyMessage({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        if (body.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            body,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.62),
                ),
          ),
        ],
      ],
    );
  }
}

class _CalendarCellData {
  const _CalendarCellData({
    required this.date,
    required this.summary,
  });

  const _CalendarCellData.empty()
      : date = null,
        summary = null;

  final DateTime? date;
  final CalendarDaySummary? summary;
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.cell,
    required this.isSelected,
    required this.onTap,
  });

  final _CalendarCellData cell;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final summary = cell.summary;
    final hasIncome = (summary?.income ?? 0) > 0;
    final hasExpense = (summary?.expense ?? 0) > 0;
    final cellKey = cell.date == null
        ? null
        : Key('calendar-day-${_dateKey(cell.date!)}');

    return Material(
      key: cellKey,
      color: isSelected
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
            child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.15),
            ),
            borderRadius: BorderRadius.circular(16),
          ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${cell.date!.day}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontSize: 11,
                      height: 1,
                      fontWeight: FontWeight.w800,
                    ),
                ),
                const SizedBox(height: 2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: _CalendarAmountLine(
                          text: hasIncome ? '+${_fullAmount(summary!.income)}' : '',
                          color: AppColors.income,
                        ),
                      ),
                      Expanded(
                        child: _CalendarAmountLine(
                          text: hasExpense ? '-${_fullAmount(summary!.expense)}' : '',
                          color: AppColors.expense,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }

  String _fullAmount(int amount) {
    final raw = amount.abs().toString();
    final buffer = StringBuffer();

    for (var i = 0; i < raw.length; i++) {
      final reverseIndex = raw.length - i;
      buffer.write(raw[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write(',');
      }
    }

    return buffer.toString();
  }
}

class _InlineMonthPicker extends StatelessWidget {
  const _InlineMonthPicker({
    required this.displayedMonth,
    required this.onPreviousYear,
    required this.onNextYear,
    required this.onSelectMonth,
  });

  final DateTime displayedMonth;
  final VoidCallback onPreviousYear;
  final VoidCallback onNextYear;
  final ValueChanged<int> onSelectMonth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = AppSpacing.sm;
        final cellWidth = ((constraints.maxWidth - (spacing * 2)) / 3)
            .clamp(0.0, constraints.maxWidth);

        return Column(
          key: const Key('calendar-inline-month-picker'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '${displayedMonth.year}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: onPreviousYear,
                  icon: const Icon(Icons.chevron_left_rounded),
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  onPressed: onNextYear,
                  icon: const Icon(Icons.chevron_right_rounded),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: List.generate(12, (index) {
                final month = index + 1;
                final isSelected = month == displayedMonth.month;

                return SizedBox(
                  width: cellWidth,
                  child: OutlinedButton(
                    onPressed: () => onSelectMonth(month),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      backgroundColor: isSelected
                          ? Theme.of(context).colorScheme.primaryContainer
                          : null,
                    ),
                    child: Text('$month월'),
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }
}

class _CalendarAmountLine extends StatelessWidget {
  const _CalendarAmountLine({
    required this.text,
    required this.color,
  });

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) {
      return const SizedBox.expand();
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          maxLines: 1,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 7,
                height: 1,
                color: color,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _CompactSummaryChip extends StatelessWidget {
  const _CompactSummaryChip({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            value,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _EditableTransactionRow extends StatelessWidget {
  const _EditableTransactionRow({
    required this.transaction,
    required this.onTap,
  });

  final Transaction transaction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.type == 'expense';
    final isIncome = transaction.type == 'income';
    final typeLabel = {
          'expense': '지출',
          'income': '수입',
          'transfer': '이체',
        }[transaction.type] ??
        transaction.type;

    final merchant = transaction.merchantName?.trim();
    final memo = transaction.memo?.trim();
    final title = merchant?.isNotEmpty == true
        ? merchant!
        : memo?.isNotEmpty == true
            ? memo!
            : typeLabel;

    final supportingParts = <String>[
      if (memo?.isNotEmpty == true && memo != merchant) memo!,
      typeLabel,
      '${transaction.occurredAt.hour.toString().padLeft(2, '0')}:${transaction.occurredAt.minute.toString().padLeft(2, '0')}',
    ];

    final icon = isExpense
        ? Icons.arrow_downward_rounded
        : (isIncome ? Icons.arrow_upward_rounded : Icons.swap_horiz_rounded);
    final accentColor = isExpense
        ? AppColors.expense
        : (isIncome ? AppColors.income : AppColors.primary);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: accentColor.withValues(alpha: 0.12),
                child: Icon(
                  icon,
                  size: 18,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      supportingParts.join(' · '),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatCurrency(transaction.amount),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: accentColor,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '눌러서 수정',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _dateKey(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

bool isSameDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String formatCurrency(int amount) {
  final sign = amount < 0 ? '-' : '';
  final raw = amount.abs().toString();
  final buffer = StringBuffer();

  for (var i = 0; i < raw.length; i++) {
    final reverseIndex = raw.length - i;
    buffer.write(raw[i]);
    if (reverseIndex > 1 && reverseIndex % 3 == 1) {
      buffer.write(',');
    }
  }

  return '$sign$buffer원';
}

