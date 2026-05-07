import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../../../shared/widgets/app_status_chip.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../calendar/application/calendar_provider.dart';
import '../../statistics/application/statistics_provider.dart';

class DashboardHomeLinksCard extends StatefulWidget {
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
  State<DashboardHomeLinksCard> createState() => _DashboardHomeLinksCardState();
}

class _DashboardHomeLinksCardState extends State<DashboardHomeLinksCard> {
  bool _calendarExpanded = false;
  bool _statisticsExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onCard = theme.colorScheme.onSurface;

    return GlassCard(
      blur: 16,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppStatusChip(
            label: 'HOME PREVIEW',
            dotColor: AppColors.primary,
            backgroundColor: onCard.withValues(alpha: 0.10),
            foregroundColor: onCard,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '달력과 통계',
            style: theme.textTheme.titleLarge?.copyWith(
              color: onCard,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _FoldTile(
            key: const Key('dashboard-calendar-fold'),
            title: '달력',
            icon: Icons.calendar_month_rounded,
            expanded: _calendarExpanded,
            onToggle: () {
              setState(() {
                _calendarExpanded = !_calendarExpanded;
              });
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CalendarPreview(
                  preview: widget.calendarMonthPreview,
                  summary: widget.calendarSummary,
                ),
                const SizedBox(height: AppSpacing.sm),
                FilledButton.icon(
                  key: const Key('dashboard-open-calendar'),
                  onPressed: widget.onOpenCalendar,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  icon: const Icon(Icons.open_in_full_rounded),
                  label: const Text('달력 크게 보기'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _FoldTile(
            key: const Key('dashboard-statistics-fold'),
            title: '통계',
            icon: Icons.bar_chart_rounded,
            expanded: _statisticsExpanded,
            onToggle: () {
              setState(() {
                _statisticsExpanded = !_statisticsExpanded;
              });
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatisticsPreview(
                  monthIncome: widget.monthIncome,
                  monthExpense: widget.monthExpense,
                  topExpenseCategories: widget.topExpenseCategories,
                  topExpenseCategoryLabel: widget.topExpenseCategoryLabel,
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  key: const Key('dashboard-open-statistics'),
                  onPressed: widget.onOpenStatistics,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  icon: const Icon(Icons.open_in_full_rounded),
                  label: const Text('통계 자세히 보기'),
                ),
              ],
            ),
          ),
        ],
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
        '이번 달 달력 미리보기를 준비하는 중이에요.',
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
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            if (summary != null)
              Text(
                '오늘 ${summary!.transactionCount}건',
                key: const Key('dashboard-calendar-count'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        _MiniMonthCalendar(preview: preview!),
        const SizedBox(height: 6),
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
  const _MiniMonthCalendar({required this.preview});

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
            childAspectRatio: 1.18,
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

    return Container(
      decoration: BoxDecoration(
        color: hasFlow
            ? theme.colorScheme.onSurface.withValues(alpha: 0.06)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isToday
              ? AppColors.primary.withValues(alpha: 0.65)
              : theme.colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$dayNumber',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          if (hasFlow)
            Text(
              '${summary!.transactionCount}건',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
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
        const SizedBox(height: 6),
        if (topExpenseCategories.isEmpty)
          Text(
            '아직 데이터가 없어요.',
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
                    bottom: index == topExpenseCategories.length - 1
                        ? 0
                        : 6,
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
        vertical: 7,
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
          const SizedBox(width: AppSpacing.sm),
          Text(
            formatCurrency(stat.amount),
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _FoldTile extends StatelessWidget {
  const _FoldTile({
    super.key,
    required this.title,
    required this.icon,
    required this.expanded,
    required this.onToggle,
    required this.child,
  });

  final String title;
  final IconData icon;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 12,
              ),
              child: Row(
                children: [
                  Icon(icon, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                12,
                0,
                12,
                12,
              ),
              child: child,
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
        color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
