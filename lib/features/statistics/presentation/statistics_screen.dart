import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/app_section.dart';
import '../application/statistics_interpretation.dart';
import '../application/statistics_provider.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotAsync = ref.watch(statisticsProvider);
    final range = ref.watch(statisticsRangeProvider);
    final filter = ref.watch(statisticsTypeFilterProvider);
    final currentMonth = ref.watch(statisticsMonthProvider);

    return AppScaffold(
      title: '통계',
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        children: [
          _ControlsPanel(
            key: const Key('statistics-controls-panel'),
            range: range,
            filter: filter,
            currentMonth: currentMonth,
            onRangeChanged: (selection) {
              ref.read(statisticsRangeProvider.notifier).state = selection.first;
            },
            onFilterChanged: (selection) {
              ref.read(statisticsTypeFilterProvider.notifier).state =
                  selection.first;
            },
            onPreviousMonth: () {
              ref.read(statisticsMonthProvider.notifier).state =
                  DateTime(currentMonth.year, currentMonth.month - 1, 1);
            },
            onNextMonth: () {
              ref.read(statisticsMonthProvider.notifier).state =
                  DateTime(currentMonth.year, currentMonth.month + 1, 1);
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          snapshotAsync.when(
            data: (snapshot) => Column(
              children: [
                AppSection(
                  title: _insightSectionTitle(filter),
                  child: _InsightPanel(snapshot: snapshot, filter: filter),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppSection(
                  title: _categorySectionTitle(filter),
                  child: _CategoryInsightPanel(
                    snapshot: snapshot,
                    filter: filter,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppSection(
                  title: '핵심 숫자',
                  child: _OverviewPanel(snapshot: snapshot, filter: filter),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppSection(
                  title: '차트로 다시 보기',
                  child: _ChartsPanel(snapshot: snapshot, filter: filter),
                ),
              ],
            ),
            loading: () => const Padding(
              padding: EdgeInsets.only(top: AppSpacing.xl),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stackTrace) => _StatisticsError(error: error),
          ),
        ],
      ),
    );
  }
}

class _ControlsPanel extends StatelessWidget {
  const _ControlsPanel({
    super.key,
    required this.range,
    required this.filter,
    required this.currentMonth,
    required this.onRangeChanged,
    required this.onFilterChanged,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  final StatisticsRange range;
  final StatisticsTypeFilter filter;
  final DateTime currentMonth;
  final ValueChanged<Set<StatisticsRange>> onRangeChanged;
  final ValueChanged<Set<StatisticsTypeFilter>> onFilterChanged;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SegmentedButton<StatisticsRange>(
              segments: const [
                ButtonSegment(
                  value: StatisticsRange.month,
                  label: Text('이번 달'),
                ),
                ButtonSegment(
                  value: StatisticsRange.quarter,
                  label: Text('최근 3개월'),
                ),
                ButtonSegment(
                  value: StatisticsRange.all,
                  label: Text('전체'),
                ),
              ],
              selected: {range},
              onSelectionChanged: onRangeChanged,
            ),
            if (range != StatisticsRange.all) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.softHighlight.withValues(alpha: 0.44),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: onPreviousMonth,
                      icon: const Icon(Icons.chevron_left_rounded),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          '${currentMonth.year}.${currentMonth.month.toString().padLeft(2, '0')} 기준',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: onNextMonth,
                      icon: const Icon(Icons.chevron_right_rounded),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            SegmentedButton<StatisticsTypeFilter>(
              key: const Key('statistics-type-filter'),
              segments: const [
                ButtonSegment(
                  value: StatisticsTypeFilter.all,
                  label: Text('\uC804\uCCB4'),
                ),
                ButtonSegment(
                  value: StatisticsTypeFilter.income,
                  label: Text('\uC218\uC785'),
                ),
                ButtonSegment(
                  value: StatisticsTypeFilter.expense,
                  label: Text('\uC9C0\uCD9C'),
                ),
              ],
              selected: {filter},
              onSelectionChanged: onFilterChanged,
            ),
          ],
        ),
      ),
    );
  }
}

// ignore: unused_element
class _TypeFilterPanel extends StatelessWidget {
  const _TypeFilterPanel({
    required this.filter,
    required this.onChanged,
  });

  final StatisticsTypeFilter filter;
  final ValueChanged<Set<StatisticsTypeFilter>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SegmentedButton<StatisticsTypeFilter>(
              key: const Key('statistics-type-filter'),
              segments: const [
                ButtonSegment(
                  value: StatisticsTypeFilter.all,
                  label: Text('전체'),
                ),
                ButtonSegment(
                  value: StatisticsTypeFilter.income,
                  label: Text('수입'),
                ),
                ButtonSegment(
                  value: StatisticsTypeFilter.expense,
                  label: Text('지출'),
                ),
              ],
              selected: {filter},
              onSelectionChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightPanel extends StatelessWidget {
  const _InsightPanel({
    required this.snapshot,
    required this.filter,
  });

  final StatisticsSnapshot snapshot;
  final StatisticsTypeFilter filter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final interpretation = buildStatisticsInterpretation(snapshot, filter);
    final highlightColor = _highlightColorForFilter(snapshot, filter);
    final primaryCategory = snapshot.topCategoryFor(filter);

    return Card(
      elevation: 0,
      color: highlightColor.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _insightSectionTitle(filter),
              style: theme.textTheme.labelLarge?.copyWith(
                color: highlightColor,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: highlightColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                snapshot.periodLabel,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: highlightColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              interpretation.headline,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              interpretation.evidence,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _MiniHighlightChip(
                  label: '기간',
                  value: snapshot.periodLabel,
                  accent: highlightColor,
                ),
                _MiniHighlightChip(
                  label: _countLabelForFilter(filter),
                  value: '${snapshot.transactionCountFor(filter)}건',
                  accent: AppColors.primaryDark,
                ),
                if (primaryCategory != null)
                  _MiniHighlightChip(
                    label: _topCategoryLabelForFilter(filter),
                    value: primaryCategory.label,
                    accent: AppColors.warning,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewPanel extends StatelessWidget {
  const _OverviewPanel({
    required this.snapshot,
    required this.filter,
  });

  final StatisticsSnapshot snapshot;
  final StatisticsTypeFilter filter;

  @override
  Widget build(BuildContext context) {
    final items = _overviewItemsFor(snapshot, filter);

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: items
          .map(
            (item) => _MetricTile(
              title: item.title,
              value: item.value,
              accent: item.accent,
            ),
          )
          .toList(),
    );
  }
}

class _CategoryInsightPanel extends StatelessWidget {
  const _CategoryInsightPanel({
    required this.snapshot,
    required this.filter,
  });

  final StatisticsSnapshot snapshot;
  final StatisticsTypeFilter filter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = snapshot.categoriesFor(filter);

    if (categories.isEmpty) {
      return Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _emptyCategoryHeadline(filter),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final topCategory = categories.first;
    final topShare = (topCategory.share * 100).toStringAsFixed(0);
    final visibleCategories = categories.take(4).toList();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _topCategorySummary(topCategory.label, topShare, filter),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            for (var i = 0; i < visibleCategories.length; i++) ...[
              _CategoryRow(
                index: i,
                item: visibleCategories[i],
                shareLabel: _shareLabelForFilter(filter),
              ),
              if (i != visibleCategories.length - 1)
                const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChartsPanel extends StatelessWidget {
  const _ChartsPanel({
    required this.snapshot,
    required this.filter,
  });

  final StatisticsSnapshot snapshot;
  final StatisticsTypeFilter filter;

  @override
  Widget build(BuildContext context) {
    final categories = snapshot.categoriesFor(filter);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _barLabelFor(filter, value.toInt()),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: _buildBarGroups(snapshot, filter),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Card(
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: SizedBox(
                    height: 180,
                    child: PieChart(
                      PieChartData(
                        centerSpaceRadius: 42,
                        sectionsSpace: 4,
                        sections: _buildCategorySections(categories),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: categories.take(3).toList().asMap().entries.map(
                      (entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _LegendRow(
                            item: entry.value,
                            color:
                                _categoryPalette[entry.key % _categoryPalette.length],
                          ),
                        );
                      },
                    ).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniHighlightChip extends StatelessWidget {
  const _MiniHighlightChip({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.56),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              color: accent,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.title,
    required this.value,
    required this.accent,
  });

  final String title;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final width =
        ((MediaQuery.sizeOf(context).width - (AppSpacing.sm * 3)) / 2)
            .clamp(140.0, 260.0)
            .toDouble();

    return SizedBox(
      width: width,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.index,
    required this.item,
    required this.shareLabel,
  });

  final int index;
  final CategoryStat item;
  final String shareLabel;

  @override
  Widget build(BuildContext context) {
    const colors = _categoryPalette;
    final color = colors[index % colors.length];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                item.label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            Text(
              _formatCurrency(item.amount),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: item.share.clamp(0, 1),
            minHeight: 10,
            backgroundColor: color.withValues(alpha: 0.10),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$shareLabel ${(item.share * 100).toStringAsFixed(1)}%',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.56),
              ),
        ),
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.item,
    required this.color,
  });

  final CategoryStat item;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${(item.share * 100).toStringAsFixed(0)}%',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _StatisticsError extends StatelessWidget {
  const _StatisticsError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '통계를 불러오지 못했습니다.',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '$error',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewItem {
  const _OverviewItem({
    required this.title,
    required this.value,
    required this.accent,
  });

  final String title;
  final String value;
  final Color accent;
}

List<_OverviewItem> _overviewItemsFor(
  StatisticsSnapshot snapshot,
  StatisticsTypeFilter filter,
) {
  switch (filter) {
    case StatisticsTypeFilter.all:
      return [
        _OverviewItem(
          title: '총수입',
          value: _formatCurrency(snapshot.totalIncome),
          accent: AppColors.income,
        ),
        _OverviewItem(
          title: '총지출',
          value: _formatCurrency(snapshot.totalExpense),
          accent: AppColors.expense,
        ),
        _OverviewItem(
          title: '수지 차이',
          value: _formatCurrency(snapshot.balance),
          accent: snapshot.balance >= 0 ? AppColors.income : AppColors.expense,
        ),
        _OverviewItem(
          title: '거래 수',
          value: '${snapshot.transactionCount}건',
          accent: AppColors.primaryDark,
        ),
      ];
    case StatisticsTypeFilter.income:
      return [
        _OverviewItem(
          title: '총수입',
          value: _formatCurrency(snapshot.totalIncome),
          accent: AppColors.income,
        ),
        _OverviewItem(
          title: '수입 건수',
          value: '${snapshot.incomeTransactionCount}건',
          accent: AppColors.primaryDark,
        ),
        _OverviewItem(
          title: '평균 수입',
          value: _formatCurrency(
            snapshot.averageAmountFor(StatisticsTypeFilter.income),
          ),
          accent: Colors.teal,
        ),
        _OverviewItem(
          title: '1위 수입',
          value: snapshot.topCategoryFor(StatisticsTypeFilter.income)?.label ??
              '-',
          accent: AppColors.warning,
        ),
      ];
    case StatisticsTypeFilter.expense:
      return [
        _OverviewItem(
          title: '총지출',
          value: _formatCurrency(snapshot.totalExpense),
          accent: AppColors.expense,
        ),
        _OverviewItem(
          title: '지출 건수',
          value: '${snapshot.expenseTransactionCount}건',
          accent: AppColors.primaryDark,
        ),
        _OverviewItem(
          title: '평균 지출',
          value: _formatCurrency(
            snapshot.averageAmountFor(StatisticsTypeFilter.expense),
          ),
          accent: Colors.teal,
        ),
        _OverviewItem(
          title: '1위 지출',
          value: snapshot.topCategoryFor(StatisticsTypeFilter.expense)?.label ??
              '-',
          accent: AppColors.warning,
        ),
      ];
  }
}

String _insightSectionTitle(StatisticsTypeFilter filter) {
  switch (filter) {
    case StatisticsTypeFilter.all:
      return '이번 기간 흐름 해석';
    case StatisticsTypeFilter.income:
      return '이번 기간 수입 해석';
    case StatisticsTypeFilter.expense:
      return '이번 기간 소비 해석';
  }
}

String _categorySectionTitle(StatisticsTypeFilter filter) {
  switch (filter) {
    case StatisticsTypeFilter.all:
      return '상위 흐름 카테고리';
    case StatisticsTypeFilter.income:
      return '상위 수입 카테고리';
    case StatisticsTypeFilter.expense:
      return '상위 지출 카테고리';
  }
}

String _countLabelForFilter(StatisticsTypeFilter filter) {
  switch (filter) {
    case StatisticsTypeFilter.all:
      return '거래 건수';
    case StatisticsTypeFilter.income:
      return '수입 건수';
    case StatisticsTypeFilter.expense:
      return '지출 건수';
  }
}

String _topCategoryLabelForFilter(StatisticsTypeFilter filter) {
  switch (filter) {
    case StatisticsTypeFilter.all:
      return '1위 흐름';
    case StatisticsTypeFilter.income:
      return '1위 수입';
    case StatisticsTypeFilter.expense:
      return '1위 지출';
  }
}

String _emptyCategoryHeadline(StatisticsTypeFilter filter) {
  switch (filter) {
    case StatisticsTypeFilter.all:
      return '아직 이 기간의 흐름 카테고리는 더 쌓여야 보여요.';
    case StatisticsTypeFilter.income:
      return '아직 이 기간의 수입 카테고리는 더 쌓여야 보여요.';
    case StatisticsTypeFilter.expense:
      return '아직 이 기간의 지출 카테고리는 더 쌓여야 보여요.';
  }
}

String _topCategorySummary(
  String label,
  String share,
  StatisticsTypeFilter filter,
) {
  switch (filter) {
    case StatisticsTypeFilter.all:
      return '$label 항목이 전체 흐름의 $share%로 가장 크게 보이고 있어요.';
    case StatisticsTypeFilter.income:
      return '$label 수입이 전체 수입의 $share%로 가장 크게 보이고 있어요.';
    case StatisticsTypeFilter.expense:
      return '$label 지출이 전체 지출의 $share%로 가장 크게 보이고 있어요.';
  }
}

String _shareLabelForFilter(StatisticsTypeFilter filter) {
  switch (filter) {
    case StatisticsTypeFilter.all:
      return '전체 흐름의';
    case StatisticsTypeFilter.income:
      return '전체 수입의';
    case StatisticsTypeFilter.expense:
      return '전체 지출의';
  }
}

String _barLabelFor(StatisticsTypeFilter filter, int index) {
  switch (filter) {
    case StatisticsTypeFilter.all:
      switch (index) {
        case 0:
          return '수입';
        case 1:
          return '지출';
        default:
          return '';
      }
    case StatisticsTypeFilter.income:
      return index == 0 ? '수입' : '';
    case StatisticsTypeFilter.expense:
      return index == 0 ? '지출' : '';
  }
}

Color _highlightColorForFilter(
  StatisticsSnapshot snapshot,
  StatisticsTypeFilter filter,
) {
  switch (filter) {
    case StatisticsTypeFilter.all:
      return snapshot.balance >= 0 ? AppColors.income : AppColors.expense;
    case StatisticsTypeFilter.income:
      return AppColors.income;
    case StatisticsTypeFilter.expense:
      return AppColors.expense;
  }
}

List<BarChartGroupData> _buildBarGroups(
  StatisticsSnapshot snapshot,
  StatisticsTypeFilter filter,
) {
  switch (filter) {
    case StatisticsTypeFilter.all:
      return [
        BarChartGroupData(
          x: 0,
          barRods: [
            BarChartRodData(
              toY: snapshot.totalIncome.toDouble(),
              color: AppColors.income,
              width: 32,
              borderRadius: BorderRadius.circular(10),
            ),
          ],
        ),
        BarChartGroupData(
          x: 1,
          barRods: [
            BarChartRodData(
              toY: snapshot.totalExpense.toDouble(),
              color: AppColors.expense,
              width: 32,
              borderRadius: BorderRadius.circular(10),
            ),
          ],
        ),
      ];
    case StatisticsTypeFilter.income:
      return [
        BarChartGroupData(
          x: 0,
          barRods: [
            BarChartRodData(
              toY: snapshot.totalIncome.toDouble(),
              color: AppColors.income,
              width: 32,
              borderRadius: BorderRadius.circular(10),
            ),
          ],
        ),
      ];
    case StatisticsTypeFilter.expense:
      return [
        BarChartGroupData(
          x: 0,
          barRods: [
            BarChartRodData(
              toY: snapshot.totalExpense.toDouble(),
              color: AppColors.expense,
              width: 32,
              borderRadius: BorderRadius.circular(10),
            ),
          ],
        ),
      ];
  }
}

List<PieChartSectionData> _buildCategorySections(List<CategoryStat> categories) {
  if (categories.isEmpty) {
    return [
      PieChartSectionData(
        value: 1,
        title: '',
        radius: 40,
        color: AppColors.borderLight,
      ),
    ];
  }

  return List.generate(categories.length, (index) {
    final item = categories[index];
    return PieChartSectionData(
      value: item.amount.toDouble(),
      title: item.share >= 0.12 ? '${(item.share * 100).toStringAsFixed(0)}%' : '',
      radius: 40,
      color: _categoryPalette[index % _categoryPalette.length],
      titleStyle: const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    );
  });
}

String _formatCurrency(int amount) {
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

const _categoryPalette = <Color>[
  AppColors.primary,
  AppColors.expense,
  AppColors.warning,
  AppColors.info,
  Colors.teal,
  Colors.orange,
  Colors.pink,
  Colors.indigo,
];
