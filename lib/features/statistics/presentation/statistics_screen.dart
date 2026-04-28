import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
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
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          AppSection(
            title: '조회 기간',
            child: Card(
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
                      onSelectionChanged: (selection) {
                        ref.read(statisticsRangeProvider.notifier).state = selection.first;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (range != StatisticsRange.all)
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              ref.read(statisticsMonthProvider.notifier).state =
                                  DateTime(currentMonth.year, currentMonth.month - 1, 1);
                            },
                            icon: const Icon(Icons.chevron_left),
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                '${currentMonth.year}.${currentMonth.month.toString().padLeft(2, '0')} 기준',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              ref.read(statisticsMonthProvider.notifier).state =
                                  DateTime(currentMonth.year, currentMonth.month + 1, 1);
                            },
                            icon: const Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          snapshotAsync.when(
            data: (snapshot) => Column(
              children: [
                AppSection(
                  title: '한눈에 보기',
                  child: _OverviewPanel(
                    periodLabel: snapshot.periodLabel,
                    balance: _formatCurrency(snapshot.balance),
                    income: _formatCurrency(snapshot.totalIncome),
                    expense: _formatCurrency(snapshot.totalExpense),
                    transactionCount: snapshot.transactionCount,
                    savingsRate: snapshot.savingsRate,
                    highlightColor:
                        snapshot.balance >= 0 ? AppColors.income : AppColors.expense,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppSection(
                  title: '바로 이동',
                  child: _ShortcutPanel(
                    onOpenCalendar: () => context.push('/calendar'),
                    onOpenTimeline: () => context.push('/timeline'),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppSection(
                  title: '카테고리별 지출',
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: SizedBox(
                        height: 240,
                        child: PieChart(
                          PieChartData(
                            centerSpaceRadius: 48,
                            sectionsSpace: 4,
                            sections: _buildSections(snapshot),
                            pieTouchData: PieTouchData(enabled: true),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppSection(
                  title: '수입 / 지출 비교',
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: SizedBox(
                        height: 220,
                        child: BarChart(
                          BarChartData(
                            gridData: const FlGridData(show: false),
                            borderData: FlBorderData(show: false),
                            titlesData: FlTitlesData(
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: const AxisTitles(
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
                                        return const Text('수입');
                                      case 1:
                                        return const Text('지출');
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
                                    width: 28,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ],
                              ),
                              BarChartGroupData(
                                x: 1,
                                barRods: [
                                  BarChartRodData(
                                    toY: snapshot.totalExpense.toDouble(),
                                    color: AppColors.expense,
                                    width: 28,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppSection(
                  title: '카테고리 상세',
                  child: Column(
                    children: [
                      if (snapshot.topCategory != null)
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.emoji_events_outlined),
                            title: const Text('가장 큰 지출 카테고리'),
                            subtitle: Text(snapshot.topCategory!.label),
                            trailing: Text(_formatCurrency(snapshot.topCategory!.amount)),
                          ),
                        ),
                      if (snapshot.categories.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(AppSpacing.md),
                            child: Text('이 기간엔 지출이 없었어요. 잘 참았네요.'),
                          ),
                        ),
                      for (final item in snapshot.categories)
                        Card(
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.xs,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                              child: Text(
                                item.label.characters.first,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                            title: Text(item.label),
                            subtitle: Text('지출 비중 ${(item.share * 100).toStringAsFixed(1)}%'),
                            trailing: Text(_formatCurrency(item.amount)),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text('통계를 불러오지 못했습니다: $error'),
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildSections(StatisticsSnapshot snapshot) {
    if (snapshot.categories.isEmpty) {
      return [
        PieChartSectionData(
          value: 1,
          title: '',
          radius: 46,
          color: AppColors.borderLight,
        ),
      ];
    }

    final colors = [
      AppColors.primary,
      AppColors.expense,
      Colors.amber,
      Colors.blue,
      Colors.teal,
      Colors.orange,
      Colors.pink,
      Colors.indigo,
    ];

    return List.generate(snapshot.categories.length, (index) {
      final item = snapshot.categories[index];
      return PieChartSectionData(
        value: item.amount.toDouble(),
        title: '${(item.share * 100).toStringAsFixed(0)}%',
        radius: 46,
        color: colors[index % colors.length],
        titleStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
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

    return '$sign₩$buffer';
  }
}

class _OverviewPanel extends StatelessWidget {
  const _OverviewPanel({
    required this.periodLabel,
    required this.balance,
    required this.income,
    required this.expense,
    required this.transactionCount,
    required this.savingsRate,
    required this.highlightColor,
  });

  final String periodLabel;
  final String balance;
  final String income;
  final String expense;
  final int transactionCount;
  final double savingsRate;
  final Color highlightColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SummaryCard(
          title: '순수입',
          value: balance,
          subtitle: periodLabel,
          accent: highlightColor,
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _MetricTile(
              title: '총 수입',
              value: income,
              accent: AppColors.income,
            ),
            _MetricTile(
              title: '총 지출',
              value: expense,
              accent: AppColors.expense,
            ),
            _MetricTile(
              title: '거래 수',
              value: '$transactionCount건',
              accent: AppColors.primary,
            ),
            _MetricTile(
              title: '저축률',
              value: '${(savingsRate * 100).toStringAsFixed(0)}%',
              accent: Colors.teal,
            ),
          ],
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
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '통계만 보고 끝내지 않도록 바로 이어서 볼 수 있게 정리했어요.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                FilledButton.tonalIcon(
                  onPressed: onOpenCalendar,
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: const Text('달력 보기'),
                ),
                FilledButton.tonalIcon(
                  onPressed: onOpenTimeline,
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: const Text('내역 보기'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.accent,
  });

  final String title;
  final String value;
  final String subtitle;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(subtitle),
          ],
        ),
      ),
    );
  }
}

class _MiniSummaryCard extends StatelessWidget {
  const _MiniSummaryCard({
    required this.title,
    required this.value,
    required this.accent,
  });

  final String title;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
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
    final tileWidth =
        ((MediaQuery.sizeOf(context).width - (AppSpacing.md * 2) - AppSpacing.sm) / 2)
            .clamp(140.0, 240.0)
            .toDouble();

    return SizedBox(
      width: tileWidth,
      child: _MiniSummaryCard(
        title: title,
        value: value,
        accent: accent,
      ),
    );
  }
}
