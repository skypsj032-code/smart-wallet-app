import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../shared/widgets/app_ledger_axis_intro.dart';
import '../../../shared/widgets/app_ledger_axis_navigation.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/app_section.dart';
import '../application/statistics_provider.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotAsync = ref.watch(statisticsProvider);
    final range = ref.watch(statisticsRangeProvider);
    final currentMonth = ref.watch(statisticsMonthProvider);

    return AppScaffold(
      title: '통계',
      body: ListView(
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
              currentAxis: LedgerAxis.statistics,
              onOpenCalendar: () => context.push('/calendar'),
              onOpenStatistics: () {},
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
              label: '통계',
              headline: '돈 흐름',
              body: '월·3개월·전체 비교',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _RangePanel(
            range: range,
            currentMonth: currentMonth,
            onRangeChanged: (selection) {
              ref.read(statisticsRangeProvider.notifier).state = selection.first;
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
          const SizedBox(height: AppSpacing.md),
          snapshotAsync.when(
            data: (snapshot) => Column(
              children: [
                AppSection(
                  title: '요약',
                  child: _InsightPanel(snapshot: snapshot),
                ),
                const SizedBox(height: AppSpacing.md),
                AppSection(
                  title: '숫자',
                  child: _OverviewPanel(snapshot: snapshot),
                ),
                const SizedBox(height: AppSpacing.md),
                AppSection(
                  title: '카테고리',
                  child: _CategoryInsightPanel(snapshot: snapshot),
                ),
                const SizedBox(height: AppSpacing.md),
                AppSection(
                  title: '이동',
                  child: _ShortcutPanel(
                    onOpenCalendar: () => context.push('/calendar'),
                    onOpenTimeline: () => context.push('/timeline'),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppSection(
                  title: '차트',
                  child: _ChartsPanel(snapshot: snapshot),
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

class _RangePanel extends StatelessWidget {
  const _RangePanel({
    required this.range,
    required this.currentMonth,
    required this.onRangeChanged,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  final StatisticsRange range;
  final DateTime currentMonth;
  final ValueChanged<Set<StatisticsRange>> onRangeChanged;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '기간을 고르세요',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '이번 달, 최근 3개월, 전체로 볼 수 있어요.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.60),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
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
          ],
        ),
      ),
    );
  }
}

class _InsightPanel extends StatelessWidget {
  const _InsightPanel({required this.snapshot});

  final StatisticsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final insight = _buildInsight(snapshot);
    final highlightColor =
        snapshot.balance >= 0 ? AppColors.income : AppColors.expense;

    return Card(
      elevation: 0,
      color: highlightColor.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '이번 기간 한눈에 읽기',
              style: theme.textTheme.labelLarge?.copyWith(
                color: highlightColor,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
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
              insight.headline,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              insight.body,
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
                  label: '순흐름',
                  value: _formatCurrency(snapshot.balance),
                  accent: highlightColor,
                ),
                _MiniHighlightChip(
                  label: '기록 수',
                  value: '${snapshot.transactionCount}건',
                  accent: AppColors.primaryDark,
                ),
                if (snapshot.topCategory != null)
                  _MiniHighlightChip(
                    label: '최대 지출',
                    value: snapshot.topCategory!.label,
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
  const _OverviewPanel({required this.snapshot});

  final StatisticsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        _MetricTile(
          title: '총수입',
          value: _formatCurrency(snapshot.totalIncome),
          accent: AppColors.income,
        ),
        _MetricTile(
          title: '총지출',
          value: _formatCurrency(snapshot.totalExpense),
          accent: AppColors.expense,
        ),
        _MetricTile(
          title: '저축 여유',
          value: '${(snapshot.savingsRate * 100).toStringAsFixed(0)}%',
          accent: Colors.teal,
        ),
        _MetricTile(
          title: '거래 수',
          value: '${snapshot.transactionCount}건',
          accent: AppColors.primaryDark,
        ),
      ],
    );
  }
}

class _CategoryInsightPanel extends StatelessWidget {
  const _CategoryInsightPanel({required this.snapshot});

  final StatisticsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (snapshot.categories.isEmpty) {
      return Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '이 기간 지출은 아직 적어요.',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '기록이 더 모이면 흐름이 보이기 시작해요.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final topCategory = snapshot.topCategory!;
    final topShare = (topCategory.share * 100).toStringAsFixed(0);
    final visibleCategories = snapshot.categories.take(4).toList();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$topShare% · ${topCategory.label}',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            for (var i = 0; i < visibleCategories.length; i++) ...[
              _CategoryRow(
                index: i,
                item: visibleCategories[i],
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
  const _ChartsPanel({required this.snapshot});

  final StatisticsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
                          switch (value.toInt()) {
                            case 0:
                              return const Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Text('수입'),
                              );
                            case 1:
                              return const Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Text('지출'),
                              );
                            default:
                              return const SizedBox.shrink();
                          }
                        },
                      ),
                    ),
                  ),
                  barGroups: [
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
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
                        sections: _buildCategorySections(snapshot),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: snapshot.categories.take(3).toList().asMap().entries.map(
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

class _ShortcutPanel extends StatelessWidget {
  const _ShortcutPanel({
    required this.onOpenCalendar,
    required this.onOpenTimeline,
  });

  final VoidCallback onOpenCalendar;
  final VoidCallback onOpenTimeline;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                FilledButton.tonalIcon(
                  onPressed: onOpenCalendar,
                  icon: const Icon(Icons.calendar_month_outlined),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 10,
                    ),
                  ),
                  label: const Text('달력'),
                ),
                FilledButton.tonalIcon(
                  onPressed: onOpenTimeline,
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: const Text('내역'),
                ),
              ],
            ),
          ],
        ),
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
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
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.62),
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
  });

  final int index;
  final CategoryStat item;

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
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
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
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: item.share.clamp(0, 1),
            minHeight: 6,
            backgroundColor: color.withValues(alpha: 0.10),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          '전체 지출의 ${(item.share * 100).toStringAsFixed(1)}%',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.48),
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
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.66),
                ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${(item.share * 100).toStringAsFixed(0)}%',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.56),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '통계를 아직 불러오지 못했어요.',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '다시 열면 볼 수 있어요.\n$error',
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

class _InsightCopy {
  const _InsightCopy({
    required this.headline,
    required this.body,
  });

  final String headline;
  final String body;
}

_InsightCopy _buildInsight(StatisticsSnapshot snapshot) {
  if (snapshot.transactionCount == 0) {
    return const _InsightCopy(
      headline: '기록 적음',
      body: '기록 누적 필요',
    );
  }

  if (snapshot.totalExpense == 0) {
    return const _InsightCopy(
      headline: '수입 우세',
      body: '수입 확인',
    );
  }

  final topCategory = snapshot.topCategory;
  final categoryNote = topCategory == null
      ? '카테고리 확인 중'
      : '${topCategory.label} 비중 최대';

  if (snapshot.balance >= 0) {
    return _InsightCopy(
      headline: '흑자',
      body: '${snapshot.periodLabel} 수입 우세 · $categoryNote',
    );
  }

  return _InsightCopy(
    headline: '지출 우세',
    body: '${snapshot.periodLabel} 지출 우세 · $categoryNote',
  );
}

List<PieChartSectionData> _buildCategorySections(StatisticsSnapshot snapshot) {
  if (snapshot.categories.isEmpty) {
    return [
      PieChartSectionData(
        value: 1,
        title: '',
        radius: 40,
        color: AppColors.borderLight,
      ),
    ];
  }

  return List.generate(snapshot.categories.length, (index) {
    final item = snapshot.categories[index];
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



