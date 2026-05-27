import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../shared/widgets/app_ledger_axis_intro.dart';
import '../../../shared/widgets/app_ledger_axis_navigation.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/app_section.dart';
import '../../transactions/application/quick_entry_form_provider.dart';
import '../application/calendar_provider.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  static const weekdayLabels = ['월', '화', '수', '목', '금', '토', '일'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotAsync = ref.watch(calendarSnapshotProvider);
    final selectedDate = ref.watch(selectedCalendarDateProvider);
    final selectedDay = ref.watch(selectedCalendarDayProvider);
    final selectedTransactionsAsync =
        ref.watch(selectedCalendarTransactionsProvider);
    final viewMode = ref.watch(calendarViewModeProvider);
    final yearMonths = ref.watch(calendarMonthSummariesProvider);

    return AppScaffold(
      title: '달력',
      body: snapshotAsync.when(
        data: (snapshot) {
          final monthCells = viewMode == CalendarViewMode.month
              ? _buildMonthCells(snapshot)
              : const <_CalendarCellData>[];
          final weekCells = viewMode == CalendarViewMode.week
              ? _buildWeekCells(snapshot)
              : const <_CalendarCellData>[];

          return ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  0,
                ),
                child: AppLedgerAxisNavigation(
                  currentAxis: LedgerAxis.calendar,
                  onOpenCalendar: () {},
                  onOpenStatistics: () => context.push('/statistics'),
                  onOpenAccounts: () => context.push('/accounts'),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.md,
                  0,
                ),
                child: AppLedgerAxisIntro(
                  label: '달력',
                  headline: '날짜 흐름',
                  body: '주·월·연 보기',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppSection(
                title: '보기',
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '기간을 고르세요',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '주간, 월간, 연간으로 볼 수 있어요.',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.60),
                                  ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            _ViewModeChip(
                              label: '주간',
                              selected: viewMode == CalendarViewMode.week,
                              onSelected: () => _changeViewMode(
                                ref,
                                CalendarViewMode.week,
                                snapshot.anchorDate,
                              ),
                            ),
                            _ViewModeChip(
                              label: '월간',
                              selected: viewMode == CalendarViewMode.month,
                              onSelected: () => _changeViewMode(
                                ref,
                                CalendarViewMode.month,
                                snapshot.anchorDate,
                              ),
                            ),
                            _ViewModeChip(
                              label: '연간',
                              selected: viewMode == CalendarViewMode.year,
                              onSelected: () => _changeViewMode(
                                ref,
                                CalendarViewMode.year,
                                snapshot.anchorDate,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppSection(
                title: _periodTitle(viewMode),
                action: _CalendarPeriodSwitcher(
                  label: _periodLabel(snapshot),
                  onPrevious: () => _movePeriod(
                    ref,
                    viewMode,
                    snapshot.anchorDate,
                    -1,
                  ),
                  onNext: () => _movePeriod(
                    ref,
                    viewMode,
                    snapshot.anchorDate,
                    1,
                  ),
                ),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: switch (viewMode) {
                      CalendarViewMode.week => _WeekCalendarView(
                          cells: weekCells,
                          selectedDate: selectedDate,
                          onSelectDate: (date) {
                            ref
                                .read(selectedCalendarDateProvider.notifier)
                                .state = date;
                          },
                        ),
                      CalendarViewMode.month => _MonthCalendarView(
                          cells: monthCells,
                          selectedDate: selectedDate,
                          onSelectDate: (date) {
                            ref
                                .read(selectedCalendarDateProvider.notifier)
                                .state = date;
                          },
                        ),
                      CalendarViewMode.year => _YearCalendarView(
                          months: yearMonths,
                          onTapMonth: (month) {
                            ref
                                .read(visibleCalendarDateProvider.notifier)
                                .state = month;
                            ref.read(calendarViewModeProvider.notifier).state =
                                CalendarViewMode.month;
                            ref
                                .read(selectedCalendarDateProvider.notifier)
                                .state = null;
                          },
                        ),
                    },
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppSection(
                title: viewMode == CalendarViewMode.year ? '기간' : '하루',
                child: _CalendarInsightCard(
                  viewMode: viewMode,
                  snapshot: snapshot,
                  selectedDate: selectedDate,
                  selectedDay: selectedDay,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppSection(
                title: '이동',
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: () => context.push('/statistics'),
                          icon: const Icon(Icons.pie_chart_outline),
                          style: FilledButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 10,
                            ),
                          ),
                          label: const Text('통계'),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: () => _openQuickEntry(context, ref),
                          icon: const Icon(Icons.add_circle_outline),
                          style: FilledButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 10,
                            ),
                          ),
                          label: const Text('입력'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (viewMode != CalendarViewMode.year) ...[
                const SizedBox(height: AppSpacing.md),
                AppSection(
                  title: '거래',
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: selectedTransactionsAsync.when(
                        data: (transactions) {
                          if (selectedDate == null) {
                            return const _CalendarEmptyMessage(
                              title: '날짜를 고르세요.',
                              body: '거래를 봐요.',
                            );
                          }

                          if (transactions.isEmpty) {
                            return const _CalendarEmptyMessage(
                              title: '이 날 기록은 비어 있어요.',
                              body: '여기서 바로 입력해요.',
                            );
                          }

                          return Column(
                            children: [
                              for (var index = 0;
                                  index < transactions.length;
                                  index++) ...[
                                _EditableTransactionRow(
                                  transaction: transactions[index],
                                  onTap: () => _openQuickEntry(
                                    context,
                                    ref,
                                    transaction: transactions[index],
                                  ),
                                ),
                                if (index != transactions.length - 1)
                                  const Divider(height: AppSpacing.lg),
                              ],
                            ],
                          );
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (error, stackTrace) => Text(
                          '거래를 불러오지 못했어요. $error',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text('달력을 불러오지 못했어요. $error'),
        ),
      ),
    );
  }

  Future<void> _openQuickEntry(
    BuildContext context,
    WidgetRef ref, {
    Transaction? transaction,
  }) async {
    if (transaction != null) {
      ref.read(quickEntryFormProvider.notifier).loadTransaction(transaction);
    }

    await context.push('/quick-entry');
    if (!context.mounted) {
      return;
    }

    refreshCalendarData(ref);
  }

  void _changeViewMode(
    WidgetRef ref,
    CalendarViewMode mode,
    DateTime anchorDate,
  ) {
    ref.read(calendarViewModeProvider.notifier).state = mode;
    ref.read(visibleCalendarDateProvider.notifier).state = anchorDate;
    ref.read(selectedCalendarDateProvider.notifier).state = null;
  }

  void _movePeriod(
    WidgetRef ref,
    CalendarViewMode mode,
    DateTime anchorDate,
    int direction,
  ) {
    final nextAnchor = switch (mode) {
      CalendarViewMode.week => anchorDate.add(Duration(days: 7 * direction)),
      CalendarViewMode.month =>
        DateTime(anchorDate.year, anchorDate.month + direction, 1),
      CalendarViewMode.year =>
        DateTime(anchorDate.year + direction, anchorDate.month, anchorDate.day),
    };

    ref.read(visibleCalendarDateProvider.notifier).state = nextAnchor;
    ref.read(selectedCalendarDateProvider.notifier).state = null;
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

  String _periodTitle(CalendarViewMode mode) {
    switch (mode) {
      case CalendarViewMode.week:
        return '주간 달력';
      case CalendarViewMode.month:
        return '월간 달력';
      case CalendarViewMode.year:
        return '연간 흐름';
    }
  }

  String _periodLabel(CalendarSnapshot snapshot) {
    switch (snapshot.mode) {
      case CalendarViewMode.week:
        final endDate = snapshot.periodEnd.subtract(const Duration(days: 1));
        return '${snapshot.periodStart.month}.${snapshot.periodStart.day} - ${endDate.month}.${endDate.day}';
      case CalendarViewMode.month:
        return '${snapshot.periodStart.year}.${snapshot.periodStart.month.toString().padLeft(2, '0')}';
      case CalendarViewMode.year:
        return '${snapshot.periodStart.year}년';
    }
  }

  static String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  static bool isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static String formatCurrency(int amount) {
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
}

class _CalendarInsightCard extends StatelessWidget {
  const _CalendarInsightCard({
    required this.viewMode,
    required this.snapshot,
    required this.selectedDate,
    required this.selectedDay,
  });

  final CalendarViewMode viewMode;
  final CalendarSnapshot snapshot;
  final DateTime? selectedDate;
  final CalendarDaySummary? selectedDay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final title = _title();
    final body = _body();

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _SummaryTile(
                    label: '수입',
                    value: CalendarScreen.formatCurrency(
                      viewMode == CalendarViewMode.year
                          ? snapshot.totalIncome
                          : (selectedDay?.income ?? 0),
                    ),
                    color: AppColors.income,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _SummaryTile(
                    label: '지출',
                    value: CalendarScreen.formatCurrency(
                      viewMode == CalendarViewMode.year
                          ? snapshot.totalExpense
                          : (selectedDay?.expense ?? 0),
                    ),
                    color: AppColors.expense,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              body,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _title() {
    if (viewMode == CalendarViewMode.year) {
      return '${snapshot.periodStart.year}년 전체';
    }

    if (selectedDate == null) {
      return '날짜를 고르세요';
    }

    return '${selectedDate!.month}월 ${selectedDate!.day}일';
  }

  String _body() {
    if (viewMode == CalendarViewMode.year) {
      final net = snapshot.totalIncome - snapshot.totalExpense;
      if (snapshot.totalIncome == 0 && snapshot.totalExpense == 0) {
        return '기록이 아직 적어요.';
      }
      if (net >= 0) {
        return '수입이 먼저 보여요.';
      }
      return '지출이 먼저 보여요.';
    }

    if (selectedDate == null) {
      return '거래를 봐요.';
    }

    final income = selectedDay?.income ?? 0;
    final expense = selectedDay?.expense ?? 0;
    if (income == 0 && expense == 0) {
      return '기록 없음';
    }
    if (income >= expense) {
      return '수입이 큰 날';
    }
    return '지출이 큰 날';
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
        const SizedBox(height: AppSpacing.xs),
        Text(
          body,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.52),
              ),
        ),
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

class _ViewModeChip extends StatelessWidget {
  const _ViewModeChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      showCheckmark: false,
    );
  }
}

class _CalendarPeriodSwitcher extends StatelessWidget {
  const _CalendarPeriodSwitcher({
    required this.label,
    required this.onPrevious,
    required this.onNext,
  });

  final String label;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left_rounded),
          visualDensity: VisualDensity.compact,
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        IconButton(
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right_rounded),
          visualDensity: VisualDensity.compact,
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
                  child: _CalendarDayCell(
                    cell: cell,
                    isSelected: selectedDate != null &&
                        cell.date != null &&
                        CalendarScreen.isSameDate(cell.date!, selectedDate!),
                    onTap: cell.date == null ? null : () => onSelectDate(cell.date!),
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
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            childAspectRatio: 0.8,
          ),
          itemBuilder: (context, index) {
            final cell = cells[index];
            if (cell.date == null) {
              return const SizedBox.shrink();
            }

            final isSelected = selectedDate != null &&
                CalendarScreen.isSameDate(cell.date!, selectedDate!);

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
                  '수입 ${CalendarScreen.formatCurrency(month.income)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.income,
                      ),
                ),
                Text(
                  '지출 ${CalendarScreen.formatCurrency(month.expense)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.expense,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '잔액 ${CalendarScreen.formatCurrency(month.net)}',
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

    return Material(
      color: isSelected
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
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
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const Spacer(),
              if (hasIncome)
                Text(
                  '+${_compactAmount(summary!.income)}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.income,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              if (hasExpense)
                Text(
                  '-${_compactAmount(summary!.expense)}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.expense,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              if (!hasIncome && !hasExpense)
                Text(
                  '기록 없음',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _compactAmount(int amount) {
    if (amount >= 10000) {
      final tenThousand = amount / 10000;
      return '${tenThousand.toStringAsFixed(tenThousand >= 10 ? 0 : 1)}만';
    }

    return '$amount원';
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
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: accentColor.withValues(alpha: 0.12),
                child: Icon(
                  icon,
                  size: 16,
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
                    const SizedBox(height: 2),
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
                    CalendarScreen.formatCurrency(transaction.amount),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: accentColor,
                          fontWeight: FontWeight.w800,
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

