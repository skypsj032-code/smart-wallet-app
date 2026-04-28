import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_mood.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../../../shared/widgets/app_hero_panel.dart';
import '../../../shared/widgets/app_metric_strip.dart';
import '../../../shared\widgets/app_scaffold.dart';
import '../../../shared\widgets/app_section_intro.dart';
import '../../../shared\widgets/app_status_chip.dart';
import '../../transactions/application/quick_entry_form_provider.dart';
import '../application/dashboard_summary_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);

    return AppScaffold(
      title: '홈',
      body: summaryAsync.when(
        data: (summary) => ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            260,
          ),
          children: [
            _AnimatedBlock(
              delay: 0,
              child: _OverviewHero(summary: summary),
            ),
            const SizedBox(height: AppSpacing.lg),
            _AnimatedBlock(
              delay: 40,
              child: Row(
                children: [
                  Expanded(
                    child: AppMetricStrip(
                      label: '이번 달 수입',
                      value: formatCurrency(summary.monthIncome),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppMetricStrip(
                      label: '이번 달 지출',
                      value: formatCurrency(summary.monthExpense),
                      emphasize: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _AnimatedBlock(
              delay: 80,
              child: _TodayLoopCard(
                summary: summary,
                onQuickEntry: () {
                  ref.read(quickEntryFormProvider.notifier).reset();
                  context.push('/quick-entry');
                },
                onOpenTimeline: () => context.push('/timeline'),
              ),
            ),
            if (summary.repeatSuggestions.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              _AnimatedBlock(
                delay: 120,
                child: _RepeatSuggestionSection(
                  suggestions: summary.repeatSuggestions,
                  onRepeat: (transaction) {
                    ref.read(quickEntryFormProvider.notifier).loadTemplate(transaction);
                    context.push('/quick-entry');
                  },
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            _AnimatedBlock(
              delay: 160,
              child: AppSectionIntro(
                title: '예산 흐름',
                subtitle: summary.totalBudget > 0
                    ? '이번 달 예산 ${formatCurrency(summary.totalBudget)} 기준'
                    : '아직 예산이 설정되지 않았어요.',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _AnimatedBlock(
              delay: 200,
              child: _BudgetStatusCard(summary: summary),
            ),
            const SizedBox(height: AppSpacing.lg),
            const _AnimatedBlock(
              delay: 240,
              child: AppSectionIntro(
                title: '최근 거래',
                subtitle: '가장 최근에 기록한 흐름을 차분하게 훑어보세요.',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _AnimatedBlock(
              delay: 280,
              child: summary.recentTransactions.isEmpty
                  ? const _EmptyRecentTransactions()
                  : Card(
                      child: Column(
                        children: [
                          for (var index = 0; index < summary.recentTransactions.length; index++) ...[
                            _RecentTransactionTile(
                              transaction: summary.recentTransactions[index],
                            ),
                            if (index != summary.recentTransactions.length - 1)
                              const Divider(height: 1),
                          ],
                        ],
                      ),
                    ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text('홈 요약을 불러오지 못했습니다.\n$error'),
          ),
        ),
      ),
    );
  }
}

class _OverviewHero extends StatelessWidget {
  const _OverviewHero({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final mood = Theme.of(context).extension<AppMood>()!;
    final netPositive = summary.netCashflow >= 0;
    final headlineText = netPositive
        ? '이번 달은 숨을 고르며 안정적으로 가고 있어요'
        : '이번 달은 조금 더 의식적으로 살펴보면 좋아요';
    final helperText = summary.todayTransactionCount > 0
        ? '오늘 기록 ${summary.todayTransactionCount}건, 지출 ${formatCurrency(summary.todayExpense)}'
        : '오늘 기록이 아직 없어요. 한 건만 남겨도 하루가 또렷해집니다.';
    final monthLabel =
        '${DateTime.now().year}.${DateTime.now().month.toString().padLeft(2, '0')}';

    return AppHeroPanel(
      eyebrow: AppStatusChip(
        label: monthLabel,
        dotColor: netPositive ? mood.positiveAccent : mood.warningAccent,
        backgroundColor: Colors.white.withValues(alpha: 0.06),
        foregroundColor: Colors.white,
      ),
      title: formatCurrency(summary.netCashflow),
      body: '$headlineText\n$helperText',
      footer: Row(
        children: [
          Expanded(
            child: AppMetricStrip(
              label: '남은 예산',
              value: summary.totalBudget > 0
                  ? formatCurrency(summary.remainingBudget)
                  : '미설정',
              caption: summary.totalBudget > 0 ? '지금의 속도를 보여줘요' : '설정 후 흐름을 볼 수 있어요',
              emphasize: true,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: AppMetricStrip(
              label: '예산 사용률',
              value: summary.totalBudget > 0
                  ? '${(summary.budgetUsageRate * 100).clamp(0, 999).toStringAsFixed(0)}%'
                  : '-',
              caption: netPositive ? '지출 압박이 낮은 편이에요' : '조금 더 의식적으로 보면 좋아요',
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayLoopCard extends StatelessWidget {
  const _TodayLoopCard({
    required this.summary,
    required this.onQuickEntry,
    required this.onOpenTimeline,
  });

  final DashboardSummary summary;
  final VoidCallback onQuickEntry;
  final VoidCallback onOpenTimeline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasTodayEntry = summary.todayTransactionCount > 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppStatusChip(
              label: 'TODAY LOOP',
              dotColor: hasTodayEntry ? AppColors.income : AppColors.warning,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              hasTodayEntry ? '오늘의 기록이 이어지고 있어요' : '오늘의 흐름을 남길 차례예요',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              hasTodayEntry
                  ? '이미 ${summary.todayTransactionCount}건을 기록했어요. 남은 건 틀린 부분이 없는지만 차분히 보는 거예요.'
                  : '지출, 수입, 이체 중 한 건만 남겨도 오늘의 상태가 훨씬 또렷해집니다.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                FilledButton(
                  onPressed: onQuickEntry,
                  child: Text(hasTodayEntry ? '한 건 더 기록하기' : '지금 기록 시작하기'),
                ),
                OutlinedButton(
                  onPressed: onOpenTimeline,
                  child: const Text('최근 내역 보기'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RepeatSuggestionSection extends StatelessWidget {
  const _RepeatSuggestionSection({
    required this.suggestions,
    required this.onRepeat,
  });

  final List<Transaction> suggestions;
  final ValueChanged<Transaction> onRepeat;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionIntro(
          title: '다시 기록하기',
          subtitle: '반복되는 흐름은 한 번 더 탭하는 것만으로 충분해요.',
        ),
        const SizedBox(height: AppSpacing.sm),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                for (var index = 0; index < suggestions.length; index++) ...[
                  _RepeatSuggestionTile(
                    transaction: suggestions[index],
                    onTap: () => onRepeat(suggestions[index]),
                  ),
                  if (index != suggestions.length - 1)
                    const Divider(height: AppSpacing.lg),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RepeatSuggestionTile extends StatelessWidget {
  const _RepeatSuggestionTile({
    required this.transaction,
    required this.onTap,
  });

  final Transaction transaction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.type == 'expense';
    final accent = isExpense ? AppColors.expense : AppColors.income;
    final title = transaction.memo?.trim().isNotEmpty == true
        ? transaction.memo!
        : transaction.merchantName?.trim().isNotEmpty == true
            ? transaction.merchantName!
            : isExpense
                ? '같은 지출 다시 기록'
                : '같은 수입 다시 기록';

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: accent.withValues(alpha: 0.12),
              child: Icon(
                isExpense ? Icons.remove_rounded : Icons.add_rounded,
                color: accent,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_typeLabel(transaction.type)} · ${formatCurrency(transaction.amount)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: onTap,
              child: const Text('불러오기'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetStatusCard extends StatelessWidget {
  const _BudgetStatusCard({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress =
        summary.totalBudget <= 0 ? 0.0 : summary.budgetUsageRate.clamp(0, 1).toDouble();
    final progressColor = summary.totalBudget <= 0
        ? AppColors.primary
        : summary.budgetUsageRate >= 1
            ? AppColors.expense
            : summary.budgetUsageRate >= 0.8
                ? AppColors.warning
                : AppColors.income;

    final caption = summary.totalBudget <= 0
        ? '예산을 정하면 남은 여유와 압박을 더 선명하게 볼 수 있어요.'
        : summary.budgetUsageRate >= 1
            ? '이번 달 예산을 모두 사용했어요. 남은 소비를 더 조심스럽게 보세요.'
            : summary.budgetUsageRate >= 0.8
                ? '예산의 대부분을 사용했어요. 남은 며칠의 리듬을 조금만 조절해도 좋아집니다.'
                : '예산 안에서 안정적으로 가고 있어요.';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppStatusChip(
              label: 'BUDGET PRESSURE',
              dotColor: progressColor,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              summary.totalBudget <= 0
                  ? '이번 달 예산이 아직 없어요'
                  : '이번 달 지출 ${formatCurrency(summary.monthExpense)}',
              style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                color: progressColor,
                backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              caption,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentTransactionTile extends StatelessWidget {
  const _RecentTransactionTile({required this.transaction});

  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.type == 'expense';
    final isIncome = transaction.type == 'income';
    final accent = isExpense
        ? AppColors.expense
        : isIncome
            ? AppColors.income
            : AppColors.primary;
    final icon = isExpense
        ? Icons.arrow_downward_rounded
        : isIncome
            ? Icons.arrow_upward_rounded
            : Icons.swap_horiz_rounded;
    final title = transaction.memo?.trim().isNotEmpty == true
        ? transaction.memo!
        : transaction.merchantName?.trim().isNotEmpty == true
            ? transaction.merchantName!
            : _typeLabel(transaction.type);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      leading: CircleAvatar(
        backgroundColor: accent.withValues(alpha: 0.12),
        child: Icon(icon, color: accent),
      ),
      title: Text(title),
      subtitle: Text(
        '${transaction.occurredAt.year}.${transaction.occurredAt.month.toString().padLeft(2, '0')}.${transaction.occurredAt.day.toString().padLeft(2, '0')} · ${_typeLabel(transaction.type)}',
      ),
      trailing: Text(
        formatCurrency(transaction.amount),
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: accent,
            ),
      ),
    );
  }
}

class _EmptyRecentTransactions extends StatelessWidget {
  const _EmptyRecentTransactions();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Icon(
              Icons.auto_stories_outlined,
              size: 30,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '아직 쌓인 거래가 없어요',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '첫 기록을 남기면 오늘과 이번 달의 분위기가 여기에 차분히 모이기 시작합니다.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedBlock extends StatelessWidget {
  const _AnimatedBlock({
    required this.delay,
    required this.child,
  });

  final int delay;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 420 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, widget) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 18),
            child: widget,
          ),
        );
      },
      child: child,
    );
  }
}

String _typeLabel(String type) {
  switch (type) {
    case 'income':
      return '수입';
    case 'expense':
      return '지출';
    case 'transfer':
      return '이체';
    default:
      return type;
  }
}
