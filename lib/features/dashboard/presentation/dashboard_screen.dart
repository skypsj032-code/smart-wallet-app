import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../../../shared/widgets/app_scaffold.dart';
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
                    child: _MiniSummaryCard(
                      label: '이번 달 수입',
                      value: formatCurrency(summary.monthIncome),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _MiniSummaryCard(
                      label: '이번 달 지출',
                      value: formatCurrency(summary.monthExpense),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _AnimatedBlock(
              delay: 70,
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
                delay: 95,
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
              delay: 120,
              child: _SectionHeader(
                title: '예산 흐름',
                subtitle: summary.totalBudget <= 0
                    ? null
                    : '예산 ${formatCurrency(summary.totalBudget)}',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _AnimatedBlock(
              delay: 160,
              child: _BudgetStatusCard(summary: summary),
            ),
            const SizedBox(height: AppSpacing.lg),
            const _AnimatedBlock(
              delay: 200,
              child: _SectionHeader(
                title: '최근 거래',
                subtitle: '가장 최근에 적은 거래를 바로 훑어볼 수 있어요.',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _AnimatedBlock(
              delay: 240,
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
            child: Text('요약 정보를 불러오지 못했습니다. $error'),
          ),
        ),
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
    final hasTodayEntry = summary.todayTransactionCount > 0;
    final theme = Theme.of(context);
    final title = hasTodayEntry
        ? '오늘은 이미 잘 기록하고 있어요'
        : '오늘 기록은 아직 비어 있어요';
    final subtitle = hasTodayEntry
        ? '오늘 ${summary.todayTransactionCount}건을 적었고, 지출은 ${formatCurrency(summary.todayExpense)}입니다.'
        : '하나만 적어도 충분해요. 오늘 쓴 금액부터 가볍게 남겨보세요.';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(color: theme.colorScheme.outline),
              ),
              child: Text(
                '오늘 기록',
                style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.mutedInk,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                FilledButton(
                  onPressed: onQuickEntry,
                  child: Text(hasTodayEntry ? '한 건 더 기록' : '지금 기록하기'),
                ),
                FilledButton.tonal(
                  onPressed: onOpenTimeline,
                  child: const Text('내역 보기'),
                ),
              ],
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
        const _SectionHeader(
          title: '빠르게 다시 입력',
          subtitle: '자주 쓰는 거래는 다시 고르기만 해도 충분해요.',
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
                  if (index != suggestions.length - 1) const Divider(height: AppSpacing.lg),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _OverviewHero extends StatelessWidget {
  const _OverviewHero({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final netPositive = summary.netCashflow >= 0;
    final headlineText = netPositive ? '이번 달은 숨이 트이는 편이에요' : '이번 달은 조금 더 아껴야 해요';
    final headlineValue =
        netPositive ? summary.netCashflow : summary.monthExpense - summary.monthIncome;
    final monthLabel =
        '${DateTime.now().year}.${DateTime.now().month.toString().padLeft(2, '0')}';
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.colorScheme.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 7,
                height: 7,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                monthLabel,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            headlineText,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            formatCurrency(headlineValue),
            style: theme.textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _PillMetric(
                  label: '남은 예산',
                  value: formatCurrency(summary.remainingBudget),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _PillMetric(
                  label: '예산 사용률',
                  value: summary.totalBudget <= 0
                      ? '미설정'
                      : '${(summary.budgetUsageRate * 100).toStringAsFixed(0)}%',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PillMetric extends StatelessWidget {
  const _PillMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniSummaryCard extends StatelessWidget {
  const _MiniSummaryCard({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 24,
                  height: 18,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: Border.all(color: theme.colorScheme.outline),
                  ),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ],
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
        ? '예산을 정해두면 흐름이 눈에 들어와요.'
        : summary.budgetUsageRate >= 1
            ? '이번 달 예산을 다 썼어요. 잠깐 멈춰봐요.'
            : summary.budgetUsageRate >= 0.8
                ? '거의 다 왔어요. 마지막 며칠이 중요해요.'
                : '지금 이 속도면 충분히 괜찮아요.';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.softHighlight,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text(
                '월간 체크',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.primaryDark,
                    ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              summary.totalBudget <= 0
                  ? '예산 없이 달리는 중이에요'
                  : '이번 달 지출 ${formatCurrency(summary.monthExpense)}',
              style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                color: progressColor,
                backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.85),
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

class _EmptyRecentTransactions extends StatelessWidget {
  const _EmptyRecentTransactions();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xl,
        ),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                color: AppColors.primary,
                size: 26,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '아직 아무것도 없어요',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '오늘 뭔가 썼다면, 가볍게 남겨봐요.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
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
                ? '같은 지출 다시 입력'
                : '같은 수입 다시 입력';

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.xl),
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
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.mutedInk,
                        ),
                  ),
                ],
              ),
            ),
            FilledButton.tonal(
              onPressed: onTap,
              child: const Text('다시 입력'),
            ),
          ],
        ),
      ),
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'income':
        return '수입';
      case 'expense':
        return '지출';
      default:
        return type;
    }
  }
}
