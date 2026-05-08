import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../application/calendar_provider.dart';

class CalendarMonthSurface extends StatelessWidget {
  const CalendarMonthSurface({
    super.key,
    required this.displayedMonth,
    required this.monthIncome,
    required this.monthExpense,
    required this.isMonthPickerOpen,
    required this.onOpenPicker,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onPreviousYear,
    required this.onNextYear,
    required this.onSelectMonth,
    required this.onSelectDay,
    required this.selectedDay,
    required this.cells,
  });

  final DateTime displayedMonth;
  final int monthIncome;
  final int monthExpense;
  final bool isMonthPickerOpen;
  final VoidCallback onOpenPicker;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onPreviousYear;
  final VoidCallback onNextYear;
  final ValueChanged<int> onSelectMonth;
  final ValueChanged<DateTime> onSelectDay;
  final DateTime? selectedDay;
  final List<CalendarMonthCellData> cells;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('calendar-month-surface'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CalendarHeaderBar(
            label: _formatMonth(displayedMonth),
            onTapLabel: onOpenPicker,
            onPrevious: onPreviousMonth,
            onNext: onNextMonth,
          ),
          const SizedBox(height: AppSpacing.md),
          if (isMonthPickerOpen)
            _InlineMonthPicker(
              displayedMonth: displayedMonth,
              onPreviousYear: onPreviousYear,
              onNextYear: onNextYear,
              onSelectMonth: onSelectMonth,
            )
          else
            _MonthCalendarContent(
              monthIncome: monthIncome,
              monthExpense: monthExpense,
              cells: cells,
              selectedDate: selectedDay,
              onSelectDate: onSelectDay,
            ),
        ],
      ),
    );
  }
}

class CalendarMonthCellData {
  const CalendarMonthCellData({
    required this.date,
    required this.summary,
  });

  const CalendarMonthCellData.empty()
      : date = null,
        summary = null;

  final DateTime? date;
  final CalendarDaySummary? summary;
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
            key: const Key('calendar-month-title'),
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
          key: const Key('calendar-previous-month'),
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left_rounded),
          visualDensity: VisualDensity.compact,
        ),
        IconButton(
          key: const Key('calendar-next-month'),
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
    required this.monthIncome,
    required this.monthExpense,
    required this.cells,
    required this.selectedDate,
    required this.onSelectDate,
  });

  final int monthIncome;
  final int monthExpense;
  final List<CalendarMonthCellData> cells;
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onSelectDate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MonthSummaryBlock(
          monthIncome: monthIncome,
          monthExpense: monthExpense,
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          key: const Key('calendar-month-grid-shell'),
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.18),
              ),
              bottom: BorderSide(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.12),
              ),
            ),
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
    required this.monthIncome,
    required this.monthExpense,
  });

  final int monthIncome;
  final int monthExpense;

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
            value: _formatCurrency(monthExpense),
            color: AppColors.expense,
            labelStyle: labelStyle,
            valueStyle: valueStyle,
          ),
          const SizedBox(height: AppSpacing.xs),
          _MonthSummaryEntry(
            label: '수입',
            value: _formatCurrency(monthIncome),
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

class _MonthCalendarView extends StatelessWidget {
  const _MonthCalendarView({
    required this.cells,
    required this.selectedDate,
    required this.onSelectDate,
  });

  final List<CalendarMonthCellData> cells;
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onSelectDate;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('calendar-month-grid'),
      children: [
        Row(
          children: [
            for (final label in const ['월', '화', '수', '목', '금', '토', '일'])
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
                selectedDate != null && _isSameDate(cell.date!, selectedDate!);

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

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.cell,
    required this.isSelected,
    required this.onTap,
  });

  final CalendarMonthCellData cell;
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
                        text: hasIncome ? '+${_rawAmount(summary!.income)}' : '',
                        color: AppColors.income,
                      ),
                    ),
                    Expanded(
                      child: _CalendarAmountLine(
                        text:
                            hasExpense ? '-${_rawAmount(summary!.expense)}' : '',
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

String _formatMonth(DateTime month) {
  return '${month.year}.${month.month.toString().padLeft(2, '0')}';
}

String _dateKey(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

bool _isSameDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String _rawAmount(int amount) {
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

String _formatCurrency(int amount) => '${_rawAmount(amount)}원';
