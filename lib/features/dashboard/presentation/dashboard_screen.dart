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
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/app_section_intro.dart';
import '../../../shared/widgets/app_status_chip.dart';
import '../../../shared/widgets/wealth_hero_backdrop.dart';
import '../../budgets/application/budget_provider.dart';
import '../../transactions/application/quick_entry_form_provider.dart';
import '../application/dashboard_summary_provider.dart';
import '../application/recurring_spend_detector.dart';
import '../application/recurring_spend_override_store.dart';
import '../application/wealth_hero_motion.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final totalBalanceAsync = ref.watch(totalActiveAccountBalanceProvider);

    return AppScaffold(
      title: '홈',
      body: summaryAsync.when(
        data: (summary) {
          final totalBalance = totalBalanceAsync.valueOrNull ?? 0;

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              144,
            ),
            children: [
              _OverviewHero(summary: summary, totalBalance: totalBalance),
              const SizedBox(height: AppSpacing.md),
              Row(
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
              const SizedBox(height: AppSpacing.md),
              const AppSectionIntro(
                title: '가계부 둘러보기',
              ),
              const SizedBox(height: AppSpacing.sm),
              _LedgerAxisShortcutCard(
                onOpenCalendar: () => context.push('/calendar'),
                onOpenStatistics: () => context.push('/statistics'),
                onOpenAccounts: () => context.push('/accounts'),
              ),
              const SizedBox(height: AppSpacing.md),
              const AppSectionIntro(
                title: '예산 흐름',
              ),
              const SizedBox(height: AppSpacing.sm),
              _BudgetStatusCard(summary: summary),
              const SizedBox(height: AppSpacing.md),
              const AppSectionIntro(
                title: '최근 거래',
              ),
              const SizedBox(height: AppSpacing.sm),
              _RecentTransactionsSection(
                transactions: summary.recentTransactions,
                onOpenTimeline: () => context.push('/timeline'),
              ),
              if (summary.repeatSuggestions.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                _RepeatSuggestionSection(
                  suggestions: summary.repeatSuggestions,
                  onRepeat: (transaction) {
                    ref
                        .read(quickEntryFormProvider.notifier)
                        .loadTemplate(transaction);
                    context.push('/quick-entry');
                  },
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              _TodayLoopCard(
                summary: summary,
                onQuickEntry: () {
                  ref.read(quickEntryFormProvider.notifier).reset();
                  context.push('/quick-entry');
                },
              ),
              if (summary.recurringSpendInsight.groups.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                const AppSectionIntro(
                  title: '반복적으로 나가는 돈',
                ),
                const SizedBox(height: AppSpacing.sm),
                _RecurringSpendInsightCard(summary: summary),
              ] else if (summary.excludedRecurringSpendGroups.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                const AppSectionIntro(
                  title: '반복지출 복구',
                  subtitle: '지금은 숨긴 반복지출만 남아 있어요. 필요하면 바로 다시 포함할 수 있어요.',
                ),
                const SizedBox(height: AppSpacing.sm),
                _RecurringRecoveryEntryCard(summary: summary),
              ],
              const SizedBox(height: AppSpacing.md),
              const AppSectionIntro(
                title: '이번 달 소비 페이스',
              ),
              const SizedBox(height: AppSpacing.sm),
              _MonthlySpendPaceCard(summary: summary),
              if (_homeUpcomingRecurringGroups(summary).isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                const AppSectionIntro(
                  title: '곧 나갈 돈',
                ),
                const SizedBox(height: AppSpacing.sm),
                _UpcomingRecurringCard(summary: summary),
              ],
              const SizedBox(height: AppSpacing.md),
              const _CategoryPressureSection(),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text('요약 정보를 불러오지 못했습니다.\n$error'),
          ),
        ),
      ),
    );
  }
}

// ignore: unused_element
class _LegacyOverviewHero extends StatelessWidget {
  const _LegacyOverviewHero({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final mood = Theme.of(context).extension<AppMood>()!;
    final netPositive = summary.netCashflow >= 0;
    final headlineText = netPositive
        ? '이번 달은 지금까지 안정적으로 흘러가고 있어요.'
        : '이번 달은 조금 빠르게 빠져나간 구간이 있었어요.';
    final helperText = summary.todayTransactionCount > 0
        ? '오늘 기록 ${summary.todayTransactionCount}건, 지출 ${formatCurrency(summary.todayExpense)}까지 반영되어 있어요.'
        : '오늘 기록은 아직 비어 있어요. 한 건만 적어도 흐름이 훨씬 또렷해집니다.';
    final monthLabel =
        '${DateTime.now().year}.${DateTime.now().month.toString().padLeft(2, '0')}';

    return RepaintBoundary(
      child: AppHeroPanel(
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
                caption: summary.totalBudget > 0
                    ? '지금 속도로 보면 얼마나 여유가 있는지 보여줘요'
                    : '예산을 정하면 흐름이 더 선명하게 보여요',
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
                caption: netPositive
                    ? '지금은 크게 무리 없는 흐름이에요'
                    : '한 번 더 확인해보면 마음이 놓일 수 있어요',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewHero extends StatefulWidget {
  const _OverviewHero({
    required this.summary,
    required this.totalBalance,
  });

  final DashboardSummary summary;
  final int totalBalance;

  @override
  State<_OverviewHero> createState() => _OverviewHeroState();
}

class _OverviewHeroState extends State<_OverviewHero>
    with SingleTickerProviderStateMixin {
  late WealthVisualState _visualState;
  WealthReaction? _reaction;
  late final AnimationController _reactionController;

  @override
  void initState() {
    super.initState();
    _visualState = buildWealthVisualState(widget.totalBalance);
    _reactionController = AnimationController(
      vsync: this,
      duration: _durationFor(WealthReactionIntensity.small),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() {
            _reaction = null;
          });
        }
      });
  }

  @override
  void didUpdateWidget(covariant _OverviewHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.totalBalance == widget.totalBalance) {
      return;
    }

    final reaction = classifyWealthReaction(
      previousBalance: oldWidget.totalBalance,
      nextBalance: widget.totalBalance,
    );

    setState(() {
      _visualState = buildWealthVisualState(widget.totalBalance);
      _reaction = reaction;
    });

    if (reaction != null) {
      _reactionController.duration = _durationFor(reaction.intensity);
      _reactionController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _reactionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final summary = widget.summary;
    final mood = Theme.of(context).extension<AppMood>()!;
    final netPositive = summary.netCashflow >= 0;
    final headlineText = netPositive
        ? '이번 달 흐름은 비교적 안정적으로 이어지고 있어요.'
        : '이번 달 흐름이 조금 빠르게 빠져나간 구간이 있었어요.';
    final helperText = summary.todayTransactionCount > 0
        ? '오늘 기록 ${summary.todayTransactionCount}건이 반영됐어요. 변화가 생길 때마다 자산 분위기도 같이 움직여요.'
        : '오늘 기록은 아직 비어 있어요. 한 건만 적어도 지금 자산 분위기가 바로 살아납니다.';
    final monthLabel =
        '${DateTime.now().year}.${DateTime.now().month.toString().padLeft(2, '0')}';

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _reactionController,
        builder: (context, child) {
          return AppHeroPanel(
            animatedBackdrop: WealthHeroBackdrop(
              coinDensity: _visualState.coinDensity,
              billDensity: _visualState.billDensity,
              vaultIntensity: _visualState.assetIntensity,
              direction:
                  _reaction?.direction == WealthReactionDirection.decrease
                      ? WealthBackdropDirection.decrease
                      : WealthBackdropDirection.increase,
              reactionIntensity: _mapReactionIntensity(
                _reaction?.intensity ?? WealthReactionIntensity.tiny,
              ),
              progress: _reactionController.value,
              reducedMotion:
                  MediaQuery.maybeOf(context)?.disableAnimations ?? false,
            ),
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
                    caption: '자산 배경은 활성 계좌 잔액 합계를 기준으로 천천히 쌓여요.',
                    emphasize: true,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppMetricStrip(
                    label: '자산 단계',
                    value: _stageLabel(_visualState.stage),
                    caption: '돈이 들어오고 빠질 때마다 양과 빛이 함께 달라져요.',
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Duration _durationFor(WealthReactionIntensity intensity) {
    return switch (intensity) {
      WealthReactionIntensity.tiny => const Duration(milliseconds: 450),
      WealthReactionIntensity.small => const Duration(milliseconds: 650),
      WealthReactionIntensity.medium => const Duration(milliseconds: 900),
      WealthReactionIntensity.large => const Duration(milliseconds: 1200),
    };
  }

  WealthBackdropReactionIntensity _mapReactionIntensity(
    WealthReactionIntensity intensity,
  ) {
    return switch (intensity) {
      WealthReactionIntensity.tiny => WealthBackdropReactionIntensity.tiny,
      WealthReactionIntensity.small => WealthBackdropReactionIntensity.small,
      WealthReactionIntensity.medium => WealthBackdropReactionIntensity.medium,
      WealthReactionIntensity.large => WealthBackdropReactionIntensity.large,
    };
  }
}

String _stageLabel(WealthStage stage) {
  return switch (stage) {
    WealthStage.coins => '동전 중심',
    WealthStage.coinsAndBills => '지폐 확장',
    WealthStage.coinsBillsAndAssets => '자산 축적',
  };
}

String _recurringInsightCaption(RecurringSpendInsight insight) {
  final delta = insight.monthDelta;
  final newCount =
      insight.groups.where((group) => group.previousMonthAmount == 0).length;
  final hasLifestyle = insight.groups.any(
    (group) => group.kind == RecurringSpendKind.lifestyle,
  );

  if (newCount > 0) {
    return '이번 달 새로 보이는 반복 지출이 $newCount건 있어요.';
  }

  if (delta != null && delta > 0) {
    return '지난달보다 ${formatCurrency(delta)} 늘었어요.';
  }

  if (delta != null && delta < 0) {
    return '지난달보다 ${formatCurrency(delta.abs())} 줄었어요.';
  }

  if (hasLifestyle) {
    return '생활 속에서 자주 반복되는 지출이 보여요.';
  }

  return '고정적으로 이어지는 지출이 먼저 보여요.';
}

String _recurringKindLabel(RecurringSpendKind kind) {
  return switch (kind) {
    RecurringSpendKind.fixed => '고정비',
    RecurringSpendKind.subscription => '구독',
    RecurringSpendKind.lifestyle => '생활 반복',
  };
}

class _RecurringSpendInsightCard extends StatelessWidget {
  const _RecurringSpendInsightCard({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final insight = summary.recurringSpendInsight;
    final share = summary.monthExpense <= 0
        ? null
        : ((insight.totalCurrentMonthAmount / summary.monthExpense) * 100)
            .round();
    final groups = insight.groups.take(3).toList();
    final hiddenCount = summary.excludedRecurringSpendGroups.length;

    return InkWell(
      key: const Key('recurring-spend-insight-card'),
      borderRadius: BorderRadius.circular(28),
      onTap: () {
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (context) => _RecurringSpendBottomSheet(
            initialSummary: summary,
          ),
        );
      },
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppStatusChip(
                label: '반복지출',
                dotColor: AppColors.warning,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                formatCurrency(insight.totalCurrentMonthAmount),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                share == null
                    ? '이번 달 반복적으로 나가는 돈부터 먼저 정리해드릴게요.'
                    : '이번 달 지출의 $share%가 반복적으로 나가는 돈이에요.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                _recurringInsightCaption(insight),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (hiddenCount > 0) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '제외한 항목 $hiddenCount개',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                TextButton(
                  key: const Key('recurring-hidden-count-button'),
                  onPressed: () {
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) => _ExcludedRecurringSpendBottomSheet(
                        initialSummary: summary,
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    '관리하기',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              for (var index = 0; index < groups.length; index++) ...[
                _RecurringSpendGroupTile(group: groups[index]),
                if (index != groups.length - 1)
                  const Divider(height: AppSpacing.lg),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RecurringRecoveryEntryCard extends StatelessWidget {
  const _RecurringRecoveryEntryCard({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final excludedCount = summary.excludedRecurringSpendGroups.length;

    return InkWell(
      key: const Key('recurring-recovery-entry-card'),
      borderRadius: BorderRadius.circular(28),
      onTap: () {
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (context) => _ExcludedRecurringSpendBottomSheet(
            initialSummary: summary,
          ),
        );
      },
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.undo_rounded,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '제외한 반복지출 $excludedCount개',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '복구가 필요하면 여기서 바로 다시 포함할 수 있어요.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecurringSpendGroupTile extends StatelessWidget {
  const _RecurringSpendGroupTile({required this.group});

  final RecurringSpendGroup group;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                group.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _recurringKindLabel(group.kind),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          formatCurrency(group.currentMonthAmount),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _RecurringSpendBottomSheet extends ConsumerWidget {
  const _RecurringSpendBottomSheet({required this.initialSummary});

  final DashboardSummary initialSummary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary =
        ref.watch(dashboardSummaryProvider).valueOrNull ?? initialSummary;
    final theme = Theme.of(context);
    final newGroups = summary.recurringSpendInsight.groups
        .where((group) => group.previousMonthAmount == 0)
        .map(_RecurringSheetGroupView.fromGroup)
        .toList()
      ..sort((a, b) => b.latestDate.compareTo(a.latestDate));
    final upcomingGroups = summary.recurringSpendInsight.groups
        .where((group) => group.previousMonthAmount != 0)
        .map(_RecurringSheetGroupView.fromGroup)
        .toList()
      ..sort((a, b) {
        final dateCompare = a.nextExpectedDate.compareTo(b.nextExpectedDate);
        if (dateCompare != 0) {
          return dateCompare;
        }

        return b.group.currentMonthAmount.compareTo(a.group.currentMonthAmount);
      });
    final excludedGroups = summary.excludedRecurringSpendGroups
        .map(_RecurringSheetGroupView.fromGroup)
        .toList()
      ..sort((a, b) => b.latestDate.compareTo(a.latestDate));

    return SafeArea(
      child: Material(
        key: const Key('recurring-spend-bottom-sheet'),
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.lg,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '반복적으로 나가는 돈',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            formatCurrency(
                              summary.recurringSpendInsight
                                  .totalCurrentMonthAmount,
                            ),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '곧 다시 이어질 수 있는 지출부터 보여드릴게요.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (newGroups.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  const AppSectionIntro(
                    title: '새로 보이는 반복지출',
                    subtitle: '이번 달 처음 잡힌 반복 흐름을 먼저 확인해보세요.',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        children: [
                          for (var index = 0;
                              index < newGroups.length;
                              index++) ...[
                            _RecurringBottomSheetTile(
                              item: newGroups[index],
                              emphasisLabel: '이번 달 새로 보였어요',
                            ),
                            if (index != newGroups.length - 1)
                              const Divider(height: AppSpacing.lg),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
                if (upcomingGroups.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  const AppSectionIntro(
                    title: '다가오는 반복지출',
                    subtitle: '최근 흐름을 기준으로 다시 이어질 가능성이 높은 순서예요.',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        children: [
                          for (var index = 0;
                              index < upcomingGroups.length;
                              index++) ...[
                            _RecurringBottomSheetTile(
                                item: upcomingGroups[index]),
                            if (index != upcomingGroups.length - 1)
                              const Divider(height: AppSpacing.lg),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
                if (excludedGroups.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      key: const Key('recurring-excluded-manage-button'),
                      onPressed: () {
                        showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          builder: (context) =>
                              _ExcludedRecurringSpendBottomSheet(
                            initialSummary: summary,
                          ),
                        );
                      },
                      icon: const Icon(Icons.visibility_off_outlined),
                      label: Text('제외한 항목 ${excludedGroups.length}개 관리'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecurringSheetGroupView {
  const _RecurringSheetGroupView({
    required this.group,
    required this.latestDate,
    required this.nextExpectedDate,
  });

  final RecurringSpendGroup group;
  final DateTime latestDate;
  final DateTime nextExpectedDate;

  factory _RecurringSheetGroupView.fromGroup(RecurringSpendGroup group) {
    final latestDate = group.transactions
        .map((tx) => tx.occurredAt)
        .reduce((a, b) => a.isAfter(b) ? a : b);

    return _RecurringSheetGroupView(
      group: group,
      latestDate: latestDate,
      nextExpectedDate: switch (group.kind) {
        RecurringSpendKind.fixed || RecurringSpendKind.subscription => DateTime(
            latestDate.year,
            latestDate.month + 1,
            latestDate.day,
            latestDate.hour,
            latestDate.minute,
          ),
        RecurringSpendKind.lifestyle => latestDate,
      },
    );
  }
}

List<_RecurringSheetGroupView> _homeUpcomingRecurringGroups(
  DashboardSummary summary,
) {
  final groups = summary.recurringSpendInsight.groups
      .where(
        (group) =>
            group.kind == RecurringSpendKind.fixed ||
            group.kind == RecurringSpendKind.subscription,
      )
      .map(_RecurringSheetGroupView.fromGroup)
      .toList()
    ..sort((a, b) {
      final dateCompare = a.nextExpectedDate.compareTo(b.nextExpectedDate);
      if (dateCompare != 0) {
        return dateCompare;
      }

      return b.group.currentMonthAmount.compareTo(a.group.currentMonthAmount);
    });

  return groups.take(3).toList();
}

class _RecurringBottomSheetTile extends StatelessWidget {
  const _RecurringBottomSheetTile({
    required this.item,
    this.emphasisLabel,
  });

  final _RecurringSheetGroupView item;
  final String? emphasisLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      key: Key('recurring-item-${item.group.groupKey}'),
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (context) => _RecurringSpendDetailSheet(item: item),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.group.displayName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _recurringKindLabel(item.group.kind),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    emphasisLabel ?? _recurringTimingLabel(item),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _recurringDeltaLabel(item.group),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              formatCurrency(item.group.currentMonthAmount),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExcludedRecurringSpendBottomSheet extends ConsumerWidget {
  const _ExcludedRecurringSpendBottomSheet({required this.initialSummary});

  final DashboardSummary initialSummary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary =
        ref.watch(dashboardSummaryProvider).valueOrNull ?? initialSummary;
    final theme = Theme.of(context);
    final excludedGroups = summary.excludedRecurringSpendGroups
        .map(_RecurringSheetGroupView.fromGroup)
        .toList()
      ..sort((a, b) => b.latestDate.compareTo(a.latestDate));

    return SafeArea(
      child: Material(
        key: const Key('recurring-excluded-bottom-sheet'),
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.lg,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '제외한 반복지출',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '반복 아님으로 제외한 항목을 다시 반복지출 해석에 넣을 수 있어요.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                if (excludedGroups.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Text(
                        '지금은 제외된 반복지출이 없어요.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  )
                else
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        children: [
                          for (var index = 0;
                              index < excludedGroups.length;
                              index++) ...[
                            _ExcludedRecurringSpendTile(
                              item: excludedGroups[index],
                              isLastItem: excludedGroups.length == 1,
                            ),
                            if (index != excludedGroups.length - 1)
                              const Divider(height: AppSpacing.lg),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExcludedRecurringSpendTile extends ConsumerWidget {
  const _ExcludedRecurringSpendTile({
    required this.item,
    required this.isLastItem,
  });

  final _RecurringSheetGroupView item;
  final bool isLastItem;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final overrideStore = ref.read(recurringSpendOverrideStoreProvider);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.group.displayName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _recurringKindLabel(item.group.kind),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _monthDayLabel(item.latestDate),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatCurrency(item.group.currentMonthAmount),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextButton(
              key: Key('recurring-restore-button-${item.group.groupKey}'),
              onPressed: () async {
                await overrideStore
                    .unmarkGroupNotRecurring(item.group.groupKey);
                if (context.mounted) {
                  if (isLastItem) {
                    Navigator.of(context).pop();
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('다시 반복지출에 포함했어요.'),
                      action: SnackBarAction(
                        label: '실행 취소',
                        onPressed: () {
                          overrideStore.markGroupNotRecurring(
                            item.group.groupKey,
                          );
                        },
                      ),
                    ),
                  );
                }
              },
              child: const Text('다시 포함'),
            ),
          ],
        ),
      ],
    );
  }
}

class _RecurringSpendDetailSheet extends ConsumerWidget {
  const _RecurringSpendDetailSheet({required this.item});

  final _RecurringSheetGroupView item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final overrideStore = ref.read(recurringSpendOverrideStoreProvider);
    final reasons = _recurringEvidenceBullets(item.group);
    final transactions = [...item.group.transactions]
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

    return SafeArea(
      child: Material(
        key: const Key('recurring-spend-detail-sheet'),
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.lg,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.group.displayName,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '${_recurringKindLabel(item.group.kind)} · ${formatCurrency(item.group.currentMonthAmount)}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                const AppSectionIntro(
                  title: '반복으로 본 이유',
                  subtitle: '반복지출로 판단한 근거를 먼저 보여드릴게요.',
                ),
                const SizedBox(height: AppSpacing.sm),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _recurringConfidenceLabel(item.group.confidence),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        for (final reason in reasons) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 6),
                                child: Icon(Icons.circle, size: 8),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  reason,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const AppSectionIntro(
                  title: '최근 거래 내역',
                  subtitle: '묶인 거래 흐름을 최신 순으로 보여드려요.',
                ),
                const SizedBox(height: AppSpacing.sm),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      children: [
                        for (var index = 0;
                            index < transactions.length;
                            index++) ...[
                          _RecurringTransactionHistoryTile(
                            transaction: transactions[index],
                          ),
                          if (index != transactions.length - 1)
                            const Divider(height: AppSpacing.lg),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const AppSectionIntro(
                  title: '요약 정보',
                  subtitle: '최근 결제일과 다음 예상 시점까지 같이 봐요.',
                ),
                const SizedBox(height: AppSpacing.sm),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_recurringTimingLabel(item)),
                        const SizedBox(height: AppSpacing.xs),
                        Text(_recurringDeltaLabel(item.group)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    key: const Key('recurring-not-recurring-button'),
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          key: const Key('recurring-not-recurring-dialog'),
                          title: const Text('이 항목을 반복지출에서 제외할까요?'),
                          content: const Text(
                            '이후에는 이 항목이 반복지출 카드와 목록에 보이지 않아요. 거래 자체가 삭제되지는 않아요.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(false),
                              child: const Text('취소'),
                            ),
                            FilledButton.tonal(
                              key: const Key(
                                'recurring-not-recurring-confirm-button',
                              ),
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(true),
                              child: const Text('반복 아님으로 제외'),
                            ),
                          ],
                        ),
                      );

                      if (confirmed != true) {
                        return;
                      }

                      await overrideStore.markGroupNotRecurring(
                        item.group.groupKey,
                      );
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('반복지출에서 제외했어요.'),
                            action: SnackBarAction(
                              label: '실행 취소',
                              onPressed: () {
                                overrideStore.unmarkGroupNotRecurring(
                                  item.group.groupKey,
                                );
                              },
                            ),
                          ),
                        );
                      }
                    },
                    child: const Text('반복 아님'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecurringTransactionHistoryTile extends StatelessWidget {
  const _RecurringTransactionHistoryTile({required this.transaction});

  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _monthDayLabel(transaction.occurredAt),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                transaction.merchantName ?? transaction.memo ?? '',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Text(formatCurrency(transaction.amount)),
      ],
    );
  }
}

String _recurringTimingLabel(_RecurringSheetGroupView item) {
  final label = switch (item.group.kind) {
    RecurringSpendKind.fixed || RecurringSpendKind.subscription => '?ㅼ쓬 ?덉긽',
    RecurringSpendKind.lifestyle => '理쒓렐 寃곗젣',
  };

  return '$label ${_monthDayLabel(item.nextExpectedDate)}';
}

String _recurringDeltaLabel(RecurringSpendGroup group) {
  if (group.previousMonthAmount == 0) {
    return '?댁쟾 ?ъ뿉???좎궗 ???듬쓣 ?ㅼ븯吏 紐삵뻽?댁슂.';
  }

  final delta = group.currentMonthAmount - group.previousMonthAmount;
  if (delta > 0) {
    return '吏?쒕떖蹂대떎 ${formatCurrency(delta)} ?섏뿀?댁슂.';
  }
  if (delta < 0) {
    return '吏?쒕떖蹂대떎 ${formatCurrency(delta.abs())} 以꾩뿀?댁슂.';
  }

  return '吏?쒕떖怨??숈씪???섏쐞?먯슂.';
}

String _monthDayLabel(DateTime date) {
  return '${date.month}/${date.day}';
}

// ignore: unused_element
List<String> _recurringReasonBullets(RecurringSpendGroup group) {
  return switch (group.kind) {
    RecurringSpendKind.fixed => [
        '월간 간격이 비슷하게 이어졌어요.',
        '비슷한 금액으로 반복돼서 고정비 흐름으로 봤어요.',
      ],
    RecurringSpendKind.subscription => [
        '구독/정기결제처럼 보이는 이름이 반복됐어요.',
        '비슷한 금액으로 다시 결제돼 반복지출로 판단했어요.',
      ],
    RecurringSpendKind.lifestyle => [
        '최근 45일 안에 여러 번 반복해서 보여요.',
        '비슷한 금액과 같은 흐름이 이어져 생활 반복지출로 봤어요.',
      ],
  };
}

List<String> _recurringEvidenceBullets(RecurringSpendGroup group) {
  return group.evidenceCodes.map(_recurringEvidenceLabel).toList();
}

String _recurringConfidenceLabel(RecurringSpendConfidence confidence) {
  return switch (confidence) {
    RecurringSpendConfidence.high => '높은 신뢰',
    RecurringSpendConfidence.medium => '보통 신뢰',
  };
}

String _recurringEvidenceLabel(RecurringSpendEvidenceCode code) {
  return switch (code) {
    RecurringSpendEvidenceCode.monthlyCadence => '월간 간격이 비슷하게 이어졌어요.',
    RecurringSpendEvidenceCode.stableAmount => '비슷한 금액으로 반복돼 정기 지출처럼 보여요.',
    RecurringSpendEvidenceCode.subscriptionKeyword =>
      '구독이나 멤버십으로 보이는 이름이 반복해서 나타났어요.',
    RecurringSpendEvidenceCode.recentRepeatCount =>
      '최근 45일 안에 여러 번 반복된 소비 흐름이 보여요.',
    RecurringSpendEvidenceCode.sameCategoryPattern =>
      '같은 카테고리 안에서 비슷한 패턴이 이어졌어요.',
    RecurringSpendEvidenceCode.sameAccountPattern =>
      '같은 결제 수단에서 같은 흐름으로 반복되고 있어요.',
  };
}

class _TodayLoopCard extends StatelessWidget {
  const _TodayLoopCard({
    required this.summary,
    required this.onQuickEntry,
  });

  final DashboardSummary summary;
  final VoidCallback onQuickEntry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasTodayEntry = summary.todayTransactionCount > 0;

    return Card(
      key: const Key('today-loop-card'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppStatusChip(
              label: '오늘 흐름',
              dotColor: hasTodayEntry ? AppColors.income : AppColors.warning,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              hasTodayEntry ? '오늘은 이미 기록 흐름이 이어지고 있어요' : '오늘 흐름은 아직 비어 있어요',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              hasTodayEntry
                  ? '이제는 빠뜨린 거래가 없는지만 가볍게 확인하면 충분해요.'
                  : '지출이든 수입이든 한 건만 적어도 오늘의 감각이 훨씬 선명해집니다.',
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
                  key: const Key('today-loop-quick-entry-button'),
                  onPressed: onQuickEntry,
                  child: Text(hasTodayEntry ? '한 건 더 기록하기' : '지금 기록 시작하기'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LedgerAxisShortcutCard extends StatelessWidget {
  const _LedgerAxisShortcutCard({
    required this.onOpenCalendar,
    required this.onOpenStatistics,
    required this.onOpenAccounts,
  });

  final VoidCallback onOpenCalendar;
  final VoidCallback onOpenStatistics;
  final VoidCallback onOpenAccounts;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const Key('ledger-axis-shortcuts-card'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            Expanded(
              child: _LedgerAxisShortcutTile(
                key: const Key('dashboard-shortcut-calendar'),
                icon: Icons.calendar_month_rounded,
                label: '달력',
                caption: '월 흐름 보기',
                onTap: onOpenCalendar,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _LedgerAxisShortcutTile(
                key: const Key('dashboard-shortcut-statistics'),
                icon: Icons.insert_chart_rounded,
                label: '통계',
                caption: '분류별 보기',
                onTap: onOpenStatistics,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _LedgerAxisShortcutTile(
                key: const Key('dashboard-shortcut-accounts'),
                icon: Icons.account_balance_wallet_rounded,
                label: '자산',
                caption: '계좌 상태 보기',
                onTap: onOpenAccounts,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LedgerAxisShortcutTile extends StatelessWidget {
  const _LedgerAxisShortcutTile({
    super.key,
    required this.icon,
    required this.label,
    required this.caption,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String caption;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
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

class _RecentTransactionsSection extends StatelessWidget {
  const _RecentTransactionsSection({
    required this.transactions,
    required this.onOpenTimeline,
  });

  final List<Transaction> transactions;
  final VoidCallback onOpenTimeline;

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return const _EmptyRecentTransactions();
    }

    final visibleTransactions = transactions.take(3).toList();

    return Card(
      key: const Key('recent-transactions-card'),
      child: Column(
        children: [
          for (var index = 0; index < visibleTransactions.length; index++) ...[
            _RecentTransactionTile(transaction: visibleTransactions[index]),
            if (index != visibleTransactions.length - 1)
              const Divider(height: 1),
          ],
          const Divider(height: 1),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              key: const Key('recent-transactions-open-timeline-button'),
              onPressed: onOpenTimeline,
              child: const Text('전체 보기'),
            ),
          ),
        ],
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
        ),
        const SizedBox(height: AppSpacing.sm),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              children: [
                for (var index = 0; index < suggestions.length; index++) ...[
                  _RepeatSuggestionTile(
                    transaction: suggestions[index],
                    onTap: () => onRepeat(suggestions[index]),
                  ),
                  if (index != suggestions.length - 1)
                    const Divider(height: AppSpacing.md),
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_typeLabel(transaction.type)} · ${formatCurrency(transaction.amount)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            IntrinsicWidth(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 10,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: onTap,
                child: const Text('불러오기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthlySpendPaceCard extends StatelessWidget {
  const _MonthlySpendPaceCard({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pace = summary.spendPace;
    final accent = switch (pace.status) {
      MonthlySpendPaceStatus.steady => AppColors.income,
      MonthlySpendPaceStatus.watch => AppColors.warning,
      MonthlySpendPaceStatus.overspending => AppColors.expense,
      MonthlySpendPaceStatus.noBudget => AppColors.primary,
    };

    final badgeLabel = pace.projectedBudgetUsageRate == null
        ? '월말 예상 지출'
        : '예산 대비 ${(pace.projectedBudgetUsageRate! * 100).round()}% 예상';

    return Card(
      key: const Key('monthly-spend-pace-card'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppStatusChip(
              label: '소비 속도',
              dotColor: accent,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _paceHeadline(pace),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '오늘은 ${pace.daysInMonth}일 중 ${pace.elapsedDays}일째예요. 지금까지 ${formatCurrency(summary.monthExpense)} 썼고, 이 속도면 약 ${formatCurrency(pace.projectedMonthExpense)} 정도가 될 것 같아요.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _PaceMetaChip(
                  label: badgeLabel,
                  accent: accent,
                ),
                _PaceMetaChip(
                  label: '지금까지 ${formatCurrency(summary.monthExpense)}',
                  accent: theme.colorScheme.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _paceHeadline(MonthlySpendPace pace) {
    return switch (pace.status) {
      MonthlySpendPaceStatus.steady => '지금 속도면 이번 달도 무리 없이 가고 있어요',
      MonthlySpendPaceStatus.watch => '지출 속도가 조금 빠른 편이에요',
      MonthlySpendPaceStatus.overspending => '이 속도면 이번 달 예산을 넘길 수 있어요',
      MonthlySpendPaceStatus.noBudget => '이달 지출 흐름을 기준으로 월말 예상치를 잡아봤어요',
    };
  }
}

class _UpcomingRecurringCard extends StatelessWidget {
  const _UpcomingRecurringCard({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = _homeUpcomingRecurringGroups(summary);

    return InkWell(
      key: const Key('upcoming-recurring-card'),
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (context) =>
              _RecurringSpendBottomSheet(initialSummary: summary),
        );
      },
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const AppStatusChip(
                    label: '다가오는 결제',
                    dotColor: AppColors.primary,
                  ),
                  const Spacer(),
                  Text(
                    '${items.length}건',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              for (var index = 0; index < items.length; index++) ...[
                _UpcomingRecurringRow(item: items[index]),
                if (index != items.length - 1)
                  const Divider(height: AppSpacing.md),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _UpcomingRecurringRow extends StatelessWidget {
  const _UpcomingRecurringRow({required this.item});

  final _RecurringSheetGroupView item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      key: Key('upcoming-recurring-item-${item.group.groupKey}'),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.group.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _monthDayLabel(item.nextExpectedDate),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            formatCurrency(item.group.currentMonthAmount),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryPressureSection extends ConsumerWidget {
  const _CategoryPressureSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetSummaryAsync = ref.watch(budgetSummaryProvider);
    final summary = budgetSummaryAsync.valueOrNull;
    final insight = summary == null ? null : deriveCategoryPressure(summary);
    if (insight == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionIntro(
          title: '카테고리 압박',
        ),
        const SizedBox(height: AppSpacing.sm),
        _CategoryPressureCard(insight: insight),
      ],
    );
  }
}

class _CategoryPressureCard extends StatelessWidget {
  const _CategoryPressureCard({required this.insight});

  final CategoryPressureInsight insight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = switch (insight.status) {
      CategoryPressureStatus.spending => AppColors.primary,
      CategoryPressureStatus.watch => AppColors.warning,
      CategoryPressureStatus.overspending => AppColors.expense,
    };

    final badgeLabel = insight.progress == null
        ? '이번 달 최다 지출 카테고리'
        : '예산 대비 ${(insight.progress! * 100).round()}%';

    return Card(
      key: const Key('category-pressure-card'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppStatusChip(
              label: '카테고리',
              dotColor: accent,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _headlineForCategoryPressure(insight),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${insight.label}에 ${formatCurrency(insight.spentAmount)} 나갔어요.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _PaceMetaChip(
              label: badgeLabel,
              accent: accent,
            ),
          ],
        ),
      ),
    );
  }

  String _headlineForCategoryPressure(CategoryPressureInsight insight) {
    return switch (insight.status) {
      CategoryPressureStatus.overspending =>
        '이번 달은 ${insight.label}가 가장 빠르게 커졌어요',
      CategoryPressureStatus.watch =>
        '이번 달은 ${insight.label}를 조금 더 자주 보게 될 것 같아요',
      CategoryPressureStatus.spending =>
        '이번 달은 ${insight.label}가 가장 크게 나가고 있어요',
    };
  }
}

class _PaceMetaChip extends StatelessWidget {
  const _PaceMetaChip({
    required this.label,
    required this.accent,
  });

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: accent,
              fontWeight: FontWeight.w700,
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
    final progress = summary.totalBudget <= 0
        ? 0.0
        : summary.budgetUsageRate.clamp(0, 1).toDouble();
    final progressColor = summary.totalBudget <= 0
        ? AppColors.primary
        : summary.budgetUsageRate >= 1
            ? AppColors.expense
            : summary.budgetUsageRate >= 0.8
                ? AppColors.warning
                : AppColors.income;

    final caption = summary.totalBudget <= 0
        ? '예산을 정하면 이번 달 흐름이 훨씬 더 선명하게 보여요.'
        : summary.budgetUsageRate >= 1
            ? '예산을 거의 다 썼어요. 남은 흐름만 차분히 보면 충분합니다.'
            : summary.budgetUsageRate >= 0.8
                ? '예산의 대부분이 이미 반영됐어요. 남은 며칠만 조금 더 살펴보면 좋아요.'
                : '예산 안에서 비교적 안정적으로 흐르고 있어요.';

    return Card(
      key: const Key('budget-status-card'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppStatusChip(
              label: '예산 흐름',
              dotColor: progressColor,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              summary.totalBudget <= 0
                  ? '이번 달 예산은 아직 비어 있어요'
                  : '이번 달 지출 ${formatCurrency(summary.monthExpense)}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                color: progressColor,
                backgroundColor:
                    theme.colorScheme.outline.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: Text(
                    summary.totalBudget <= 0
                        ? '예산 없음'
                        : '${(summary.budgetUsageRate * 100).clamp(0, 999).toStringAsFixed(0)}%',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: progressColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      formatCurrency(summary.remainingBudget),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
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
    final title = transaction.merchantName?.trim().isNotEmpty == true
        ? transaction.merchantName!
        : transaction.memo?.trim().isNotEmpty == true
            ? transaction.memo!
            : _typeLabel(transaction.type);
    final subtitle = transaction.memo?.trim().isNotEmpty == true &&
            transaction.memo != transaction.merchantName
        ? '${_typeLabel(transaction.type)} · ${transaction.memo}'
        : _typeLabel(transaction.type);

    return ListTile(
      key: Key('recent-transaction-tile-${transaction.localId}'),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      leading: CircleAvatar(
        backgroundColor: accent.withValues(alpha: 0.12),
        child: Icon(icon, color: accent),
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 128),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatCurrency(transaction.amount),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '${transaction.occurredAt.month.toString().padLeft(2, '0')}.${transaction.occurredAt.day.toString().padLeft(2, '0')}',
              style: Theme.of(context).textTheme.bodySmall,
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
              '첫 기록 하나만 남겨도 오늘과 이번 달의 흐름이 훨씬 또렷해집니다.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
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
