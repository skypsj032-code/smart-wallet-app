import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../calendar/application/calendar_provider.dart';
import '../../statistics/application/statistics_provider.dart';

class DashboardHomeLinksCard extends StatelessWidget {
  const DashboardHomeLinksCard({
    super.key,
    required this.onOpenCalendar,
    required this.onOpenStatistics,
    this.calendarSummary,
    this.calendarMonthPreview,
    required this.monthIncome,
    required this.monthExpense,
    required this.topExpenseCategories,
    required this.topExpenseCategoryLabel,
  });

  final VoidCallback onOpenCalendar;
  final VoidCallback onOpenStatistics;
  final CalendarHomeSummary? calendarSummary;
  final CalendarHomeMonthPreview? calendarMonthPreview;
  final int monthIncome;
  final int monthExpense;
  final List<CategoryStat> topExpenseCategories;
  final String topExpenseCategoryLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PreviewSurface(
          key: const Key('dashboard-open-calendar'),
          onTap: onOpenCalendar,
          child: _CalendarPreview(
            preview: calendarMonthPreview,
            summary: calendarSummary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _PreviewSurface(
          key: const Key('dashboard-open-statistics'),
          onTap: onOpenStatistics,
          child: _StatisticsPreview(
            monthIncome: monthIncome,
            monthExpense: monthExpense,
            topExpenseCategories: topExpenseCategories,
            topExpenseCategoryLabel: topExpenseCategoryLabel,
          ),
        ),
      ],
    );
  }
}

class _PreviewSurface extends StatelessWidget {
  const _PreviewSurface({
    super.key,
    required this.onTap,
    required this.child,
  });

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassCard(
      blur: 16,
      padding: const EdgeInsets.all(12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _CalendarPreview extends StatelessWidget {
  const _CalendarPreview({
    required this.preview,
    required this.summary,
  });

  final CalendarHomeMonthPreview? preview;
  final CalendarHomeSummary? summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (preview == null) {
      return Text(
        '달력 미리보기를 준비하고 있어요.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '${preview!.monthStart.month}월',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            if (summary != null)
              Text(
                '오늘 ${summary!.transactionCount}건',
                key: const Key('dashboard-calendar-count'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _MiniMonthCalendar(preview: preview!),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _SummaryChip(
              key: const Key('dashboard-calendar-income'),
              label: '수입 ${formatCurrency(summary?.income ?? 0)}',
            ),
            _SummaryChip(
              key: const Key('dashboard-calendar-expense'),
              label: '지출 ${formatCurrency(summary?.expense ?? 0)}',
            ),
          ],
        ),
      ],
    );
  }
}

class _MiniMonthCalendar extends StatelessWidget {
  const _MiniMonthCalendar({
    required this.preview,
  });

  final CalendarHomeMonthPreview preview;

  static const _weekdayLabels = ['월', '화', '수', '목', '금', '토', '일'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final daysInMonth =
        DateTime(preview.monthStart.year, preview.monthStart.month + 1, 0).day;
    final leadingBlanks = preview.monthStart.weekday - 1;
    final dayMap = {
      for (final day in preview.days) day.date.day: day,
    };
    final today = DateTime.now();

    return Column(
      key: const Key('dashboard-calendar-preview-grid'),
      children: [
        Row(
          children: [
            for (final label in _weekdayLabels)
              Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: leadingBlanks + daysInMonth,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            childAspectRatio: 0.72,
          ),
          itemBuilder: (context, index) {
            if (index < leadingBlanks) {
              return const SizedBox.shrink();
            }

            final dayNumber = index - leadingBlanks + 1;
            final summary = dayMap[dayNumber];
            final isToday = today.year == preview.monthStart.year &&
                today.month == preview.monthStart.month &&
                today.day == dayNumber;

            return _MiniCalendarDayCell(
              key: Key('dashboard-calendar-day-$dayNumber'),
              dayNumber: dayNumber,
              summary: summary,
              isToday: isToday,
            );
          },
        ),
      ],
    );
  }
}

class _MiniCalendarDayCell extends StatelessWidget {
  const _MiniCalendarDayCell({
    super.key,
    required this.dayNumber,
    required this.summary,
    required this.isToday,
  });

  final int dayNumber;
  final CalendarDaySummary? summary;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasFlow = summary != null && summary!.transactionCount > 0;
    final incomeText =
        (summary?.income ?? 0) > 0 ? formatCurrency(summary!.income) : '';
    final expenseText =
        (summary?.expense ?? 0) > 0 ? formatCurrency(summary!.expense) : '';

    return Container(
      decoration: BoxDecoration(
        color: hasFlow
            ? theme.colorScheme.primary.withValues(alpha: 0.06)
            : theme.colorScheme.surface.withValues(alpha: 0.36),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isToday
              ? AppColors.primary.withValues(alpha: 0.72)
              : theme.colorScheme.outline.withValues(alpha: 0.10),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '$dayNumber',
            textAlign: TextAlign.center,
            style: theme.textTheme.labelMedium?.copyWith(
              fontSize: 10,
              height: 1,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      incomeText,
                      maxLines: 1,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.income,
                        fontWeight: FontWeight.w700,
                        fontSize: 6.6,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      expenseText,
                      maxLines: 1,
                      textAlign: TextAlign.right,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.expense,
                        fontWeight: FontWeight.w700,
                        fontSize: 6.6,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatisticsPreview extends StatelessWidget {
  const _StatisticsPreview({
    required this.monthIncome,
    required this.monthExpense,
    required this.topExpenseCategories,
    required this.topExpenseCategoryLabel,
  });

  final int monthIncome;
  final int monthExpense;
  final List<CategoryStat> topExpenseCategories;
  final String topExpenseCategoryLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      key: const Key('dashboard-statistics-preview-list'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _SummaryChip(
              key: const Key('dashboard-statistics-income'),
              label: '수입 ${formatCurrency(monthIncome)}',
            ),
            _SummaryChip(
              key: const Key('dashboard-statistics-expense'),
              label: '지출 ${formatCurrency(monthExpense)}',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (topExpenseCategories.isEmpty)
          Text(
            '아직 지출 흐름이 없어요.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else
          Column(
            children: [
              for (var index = 0; index < topExpenseCategories.length; index++)
                Padding(
                  padding: EdgeInsets.only(
                    bottom: index == topExpenseCategories.length - 1 ? 0 : 6,
                  ),
                  child: _StatisticPreviewRow(
                    key: Key('dashboard-stat-category-$index'),
                    index: index,
                    stat: topExpenseCategories[index],
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _StatisticPreviewRow extends StatelessWidget {
  const _StatisticPreviewRow({
    super.key,
    required this.index,
    required this.stat,
  });

  final int index;
  final CategoryStat stat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sharePercent = (stat.share * 100).round();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            child: Text(
              '${index + 1}',
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              stat.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '$sharePercent%',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    super.key,
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
