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
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
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
        const SizedBox(height: AppSpacing.sm),
        Container(
          key: const Key('calendar-month-grid-shell'),
          width: double.infinity,
          padding: const EdgeInsets.only(top: AppSpacing.lg),
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
    final labelStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        );
    final valueStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
        );

    return Container(
      key: const Key('calendar-month-summary-block'),
      width: double.infinity,
      padding: const EdgeInsets.only(
        left: AppSpacing.xs,
        right: AppSpacing.xs,
        top: AppSpacing.sm,
        bottom: AppSpacing.sm,
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
          width: 30,
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
    final weekdayStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        );

    return Column(
      key: const Key('calendar-month-grid'),
      children: [
        Row(
          children: [
            for (final label in const ['일', '월', '화', '수', '목', '금', '토'])
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Text(label, style: weekdayStyle),
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
            crossAxisSpacing: AppSpacing.xs,
            childAspectRatio: 0.84,
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
    final scheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 72;
        final bubbleSize = compact ? 18.0 : 38.0;
        final amountLineHeight = compact ? 7.0 : 14.0;
        final amountFontSize = compact ? 5.5 : 8.0;
        final gap = compact ? 0.0 : AppSpacing.xs;

        return Material(
          key: cellKey,
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 2,
                vertical: compact ? 0 : 2,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: bubbleSize,
                    height: bubbleSize,
                    alignment: Alignment.center,
                    decoration: isSelected
                        ? BoxDecoration(
                            color: scheme.primary.withValues(alpha: 0.14),
                            shape: BoxShape.circle,
                          )
                        : null,
                    child: Text(
                      '${cell.date!.day}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            height: 1,
                            fontSize: compact ? 10 : 16,
                            fontWeight: FontWeight.w700,
                            color:
                                isSelected ? scheme.primary : scheme.onSurface,
                          ),
                    ),
                  ),
                  SizedBox(height: gap),
                  _CalendarAmountLine(
                    text: hasExpense ? '-${_rawAmount(summary!.expense)}' : '',
                    color: AppColors.expense,
                    height: amountLineHeight,
                    fontSize: amountFontSize,
                  ),
                  SizedBox(height: compact ? 0 : 2),
                  _CalendarAmountLine(
                    text: hasIncome ? '+${_rawAmount(summary!.income)}' : '',
                    color: AppColors.income,
                    height: amountLineHeight,
                    fontSize: amountFontSize,
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
        final scheme = Theme.of(context).colorScheme;

        return Column(
          key: const Key('calendar-inline-month-picker'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '${displayedMonth.year}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
                      side: BorderSide(
                        color: scheme.outline.withValues(alpha: 0.2),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      backgroundColor:
                          isSelected ? scheme.primaryContainer : null,
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
    required this.height,
    required this.fontSize,
  });

  final String text;
  final Color color;
  final double height;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) {
      return SizedBox(height: height);
    }

    return SizedBox(
      height: height,
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            text,
            maxLines: 1,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: fontSize,
                  height: 1,
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
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
