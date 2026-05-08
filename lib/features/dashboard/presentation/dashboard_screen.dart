import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_mood.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../../../shared/widgets/app_metric_strip.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/app_status_chip.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/wealth_hero_backdrop.dart';
import '../../calendar/application/calendar_provider.dart';
import '../../recurring_expenses/application/recurring_transaction_suggestion.dart';
import '../../statistics/application/statistics_provider.dart';
import '../../transactions/application/quick_entry_form_provider.dart';
import '../../recurring_expenses/application/recurring_expense_service.dart';
import '../application/dashboard_summary_provider.dart';
import '../application/recurring_transaction_suggestion_provider.dart';
import '../application/wealth_hero_motion.dart';
import 'dashboard_home_links_card.dart';
import 'dashboard_narrative_card.dart';
import 'recurring_transaction_suggestion_card.dart';
import 'upcoming_recurring_transactions_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final totalBalanceAsync = ref.watch(totalActiveAccountBalanceProvider);
    final recurringAsync = ref.watch(activeRecurringExpensesProvider);
    final recurringSuggestionAsync =
        ref.watch(recurringTransactionSuggestionProvider);
    final calendarSummaryAsync = ref.watch(calendarHomeSummaryProvider);
    final calendarPreviewAsync = ref.watch(calendarHomeMonthPreviewProvider);
    final statisticsPreviewAsync = ref.watch(statisticsHomePreviewProvider);

    return AppScaffold(
      hideAppBar: true,
      title: '홈',
      body: summaryAsync.when(
        data: (summary) {
          final totalBalance = totalBalanceAsync.valueOrNull ?? 0;

          return CustomScrollView(
            slivers: [
              _OverviewHero(summary: summary, totalBalance: totalBalance),
              SliverToBoxAdapter(
                child: DashboardNarrativeCard(snapshot: summary.narrative),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
              SliverToBoxAdapter(
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
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
              SliverToBoxAdapter(
                child: DashboardHomeLinksCard(
                  onOpenCalendar: () => context.push('/calendar'),
                  onOpenStatistics: () => context.push('/statistics'),
                  calendarSummary: calendarSummaryAsync.valueOrNull,
                  calendarMonthPreview: calendarPreviewAsync.valueOrNull,
                  monthIncome: summary.monthIncome,
                  monthExpense: summary.monthExpense,
                  topExpenseCategories: statisticsPreviewAsync.valueOrNull ?? const [],
                  topExpenseCategoryLabel:
                      summary.narrative.topExpenseCategoryLabel,
                ),
              ),
              if (recurringSuggestionAsync.valueOrNull case final suggestion?) ...[
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.md),
                ),
                SliverToBoxAdapter(
                  child: RecurringTransactionSuggestionCard(
                    suggestion: suggestion,
                    onCreate: () => _createRecurringSuggestion(
                      ref,
                      suggestion,
                    ),
                    onDismiss: () => _dismissRecurringSuggestion(
                      ref,
                      suggestion,
                    ),
                  ),
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
              SliverToBoxAdapter(
                child: _TodayLoopCard(
                  summary: summary,
                  onQuickEntry: () {
                    ref.read(quickEntryFormProvider.notifier).reset();
                    context.push('/quick-entry');
                  },
                  onOpenTimeline: () => context.push('/timeline'),
                ),
              ),
              if (recurringAsync.valueOrNull?.isNotEmpty == true) ...[
                const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.md)),
                SliverToBoxAdapter(
                  child: UpcomingRecurringTransactionsCard(
                    items: recurringAsync.valueOrNull!,
                  ),
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
              SliverToBoxAdapter(
                child: _RecentTransactionsSection(
                  transactions: summary.recentTransactions,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
              SliverToBoxAdapter(child: _BudgetStatusCard(summary: summary)),
              const SliverToBoxAdapter(child: SizedBox(height: 148)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text('요약을 불러오지 못했어요.\n$error'),
          ),
        ),
      ),
    );
  }

  Future<void> _createRecurringSuggestion(
    WidgetRef ref,
    RecurringTransactionSuggestion suggestion,
  ) async {
    await ref.read(recurringExpenseServiceProvider).createTransactionFromSuggestion(
          recurringId: suggestion.transaction.localId,
          today: DateTime.now(),
        );
  }

  Future<void> _dismissRecurringSuggestion(
    WidgetRef ref,
    RecurringTransactionSuggestion suggestion,
  ) async {
    await ref.read(recurringExpenseServiceProvider).dismissSuggestion(
          recurringId: suggestion.transaction.localId,
          cycleKey: suggestion.cycleKey,
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final reducedMotion =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      if (reducedMotion) {
        return;
      }

      setState(() {
        _reaction = const WealthReaction(
          direction: WealthReactionDirection.increase,
          intensity: WealthReactionIntensity.small,
          deltaAmount: 0,
        );
      });

      _reactionController.duration =
          _durationFor(WealthReactionIntensity.small);
      _reactionController.forward(from: 0);
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
    final monthLabel =
        '${DateTime.now().year}.${DateTime.now().month.toString().padLeft(2, '0')}';

    return AnimatedBuilder(
      animation: _reactionController,
      builder: (context, child) {
        return SliverPersistentHeader(
          pinned: true,
          delegate: _OverviewHeroDelegate(
            summary: widget.summary,
            totalBalance: widget.totalBalance,
            monthLabel: monthLabel,
            visualState: _visualState,
            reaction: _reaction,
            reactionProgress: _reactionController.value,
            reducedMotion:
                MediaQuery.maybeOf(context)?.disableAnimations ?? false,
          ),
        );
      },
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
}

class _OverviewHeroDelegate extends SliverPersistentHeaderDelegate {
  _OverviewHeroDelegate({
    required this.summary,
    required this.totalBalance,
    required this.monthLabel,
    required this.visualState,
    required this.reaction,
    required this.reactionProgress,
    required this.reducedMotion,
  });

  final DashboardSummary summary;
  final int totalBalance;
  final String monthLabel;
  final WealthVisualState visualState;
  final WealthReaction? reaction;
  final double reactionProgress;
  final bool reducedMotion;

  @override
  double get minExtent => 112;

  @override
  double get maxExtent => 368;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final theme = Theme.of(context);
    final mood = theme.extension<AppMood>()!;
    final isDark = theme.brightness == Brightness.dark;
    final collapse = Curves.easeOutCubic
        .transform((shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0));

    // Positions — number drifts up as header collapses (weather-app float style)
    final amountTop = _mix(52, 10, collapse);
    final amountScale = _mix(1.0, 0.62, collapse);
    final infoOpacity = (1.0 - collapse * 2.4).clamp(0.0, 1.0);
    final infoTop = _mix(168, 58, collapse);

    // No card wrapper — number floats directly on the AppFrame background
    // Collapsed header gets an opaque background so scrolled content doesn't bleed through
    final bgOpacity = Curves.easeOutCubic.transform(collapse);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Opaque background layer — fades in as the header collapses
        if (bgOpacity > 0)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: mood.frameTopColor.withValues(alpha: bgOpacity),
              ),
            ),
          ),
        // Subtle atmospheric backdrop — purely decorative, no border clip
        WealthHeroBackdrop(
          coinDensity: visualState.coinDensity,
          billDensity: visualState.billDensity,
          vaultIntensity: visualState.assetIntensity,
          direction: reaction?.direction == WealthReactionDirection.decrease
              ? WealthBackdropDirection.decrease
              : WealthBackdropDirection.increase,
          reactionIntensity: _mapReactionIntensity(
            reaction?.intensity ?? WealthReactionIntensity.tiny,
          ),
          progress: reactionProgress,
          reducedMotion: reducedMotion,
          collapseProgress: collapse,
          showSkySymbol: false,
          borderRadius: BorderRadius.zero,
        ),
        if (!isDark)
          Positioned(
            left: 0,
            top: 0,
            bottom: maxExtent * 0.30,
            width: 360,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      const Color(0xFFF9F3E8).withValues(alpha: 0.88),
                      const Color(0xFFF9F3E8).withValues(alpha: 0.52),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.58, 1.0],
                  ),
                ),
              ),
            ),
          ),
        // Big amount — floats on the sky, no card behind it
        Positioned(
          left: AppSpacing.lg,
          top: amountTop,
          right: 0,
          child: Transform.scale(
            alignment: Alignment.topLeft,
            scale: amountScale,
            child: Text(
              formatCurrency(totalBalance),
              maxLines: 1,
              overflow: TextOverflow.clip,
              style: theme.textTheme.displayLarge?.copyWith(
                color: mood.heroForeground,
                fontWeight: isDark ? FontWeight.w300 : FontWeight.w500,
                height: 0.92,
                letterSpacing: -2.4,
                shadows: isDark
                    ? [
                        Shadow(
                            color: Colors.black.withValues(alpha: 0.22),
                            blurRadius: 20)
                      ]
                    : [
                        Shadow(
                          color: Colors.white.withValues(alpha: 0.84),
                          blurRadius: 12,
                        ),
                      ],
              ),
            ),
          ),
        ),
        // Companion text — income / expense / month, fades out on scroll
        Positioned(
          left: AppSpacing.lg,
          top: infoTop,
          right: AppSpacing.lg,
          child: Opacity(
            opacity: infoOpacity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '↑ ${formatCurrency(summary.monthIncome)}  /  ↓ ${formatCurrency(summary.monthExpense)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: isDark
                        ? mood.heroForeground.withValues(alpha: 0.90)
                        : mood.heroForeground,
                    fontWeight: FontWeight.w600,
                    shadows: isDark
                        ? [
                            Shadow(
                                color: Colors.black.withValues(alpha: 0.18),
                                blurRadius: 10)
                          ]
                        : null,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  monthLabel,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? mood.heroForeground.withValues(alpha: 0.62)
                        : mood.heroMutedForeground,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  bool shouldRebuild(covariant _OverviewHeroDelegate oldDelegate) {
    return oldDelegate.summary != summary ||
        oldDelegate.totalBalance != totalBalance ||
        oldDelegate.monthLabel != monthLabel ||
        oldDelegate.visualState != visualState ||
        oldDelegate.reaction != reaction ||
        oldDelegate.reactionProgress != reactionProgress ||
        oldDelegate.reducedMotion != reducedMotion;
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
    final actionTitle = hasTodayEntry ? '오늘 기록이 있어요' : '오늘 기록이 비어 있어요';
    final theme = Theme.of(context);
    final onCard = theme.colorScheme.onSurface;

    return GlassCard(
      blur: 16,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppStatusChip(
            label: 'TODAY LOOP',
            dotColor: hasTodayEntry ? AppColors.income : AppColors.warning,
            backgroundColor: onCard.withValues(alpha: 0.10),
            foregroundColor: onCard,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            actionTitle,
            style: theme.textTheme.titleLarge?.copyWith(
              color: onCard,
              fontWeight: FontWeight.w700,
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
    );
  }
}

// ignore: unused_element
class _UpcomingRecurringExpenseCard extends ConsumerWidget {
  const _UpcomingRecurringExpenseCard({required this.items});

  final List<RecurringExpense> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final onCard = theme.colorScheme.onSurface;
    final previewItems = sortRecurringExpensesByNextDueDate(
      items,
      today: DateTime.now(),
    ).take(3).toList();

    return GlassCard(
      blur: 16,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '다가오는 고정 지출',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: onCard,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => context.push('/recurring-expenses'),
                child: const Text('관리'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (var index = 0; index < previewItems.length; index++) ...[
            _UpcomingRecurringExpenseTile(item: previewItems[index]),
            if (index != previewItems.length - 1)
              Divider(
                height: 18,
                color: onCard.withValues(alpha: 0.12),
              ),
          ],
        ],
      ),
    );
  }
}

class _UpcomingRecurringExpenseTile extends ConsumerWidget {
  const _UpcomingRecurringExpenseTile({required this.item});

  final RecurringExpense item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final onCard = theme.colorScheme.onSurface;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () async {
        final created =
            await ref.read(recurringExpenseServiceProvider).materializeForMonth(
                  recurringId: item.localId,
                  month: DateTime.now(),
                );
        if (!context.mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(created ? '이번 달 거래로 기록했습니다.' : '이미 이번 달 거래로 기록했습니다.'),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: onCard.withValues(alpha: 0.10),
              child: const Icon(Icons.event_repeat_rounded),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '매월 ${item.dayOfMonth}일',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              formatCurrency(item.amount),
              style: theme.textTheme.titleSmall?.copyWith(
                color: AppColors.expense,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentTransactionsSection extends StatelessWidget {
  const _RecentTransactionsSection({required this.transactions});

  final List<Transaction> transactions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onCard = theme.colorScheme.onSurface;

    return GlassCard(
      blur: 16,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '최근 거래',
            style: theme.textTheme.titleLarge?.copyWith(
              color: onCard,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (transactions.isEmpty)
            const _EmptyRecentTransactions()
          else
            Column(
              children: [
                for (var index = 0; index < transactions.length; index++) ...[
                  _RecentTransactionTile(transaction: transactions[index]),
                  if (index != transactions.length - 1)
                    Divider(
                      height: 18,
                      color: onCard.withValues(alpha: 0.12),
                    ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _RepeatSuggestionSection extends StatelessWidget {
  const _RepeatSuggestionSection({
    required this.suggestions,
    required this.onRepeat,
  });

  final List<Transaction> suggestions;
  final ValueChanged<Transaction> onRepeat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onCard = theme.colorScheme.onSurface;

    return GlassCard(
      blur: 16,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '다시 기록하기',
            style: theme.textTheme.titleLarge?.copyWith(
              color: onCard,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (var index = 0; index < suggestions.length; index++) ...[
            _RepeatSuggestionTile(
              transaction: suggestions[index],
              onTap: () => onRepeat(suggestions[index]),
            ),
            if (index != suggestions.length - 1)
              Divider(
                height: 18,
                color: onCard.withValues(alpha: 0.12),
              ),
          ],
        ],
      ),
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
    final theme = Theme.of(context);
    final onCard = theme.colorScheme.onSurface;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: onCard.withValues(alpha: 0.10),
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
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: onCard,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_typeLabel(transaction.type)} · ${formatCurrency(transaction.amount)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            SizedBox(
              width: 96,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(96, 42),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                onPressed: onTap,
                child: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '불러오기',
                    softWrap: false,
                  ),
                ),
              ),
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

    final theme = Theme.of(context);
    final onCard = theme.colorScheme.onSurface;

    return GlassCard(
      blur: 16,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppStatusChip(
            label: 'BUDGET PRESSURE',
            dotColor: progressColor,
            backgroundColor: onCard.withValues(alpha: 0.10),
            foregroundColor: onCard,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            summary.totalBudget <= 0
                ? '이번 달 예산이 아직 비어 있어요'
                : '이번 달 지출 ${formatCurrency(summary.monthExpense)}',
            style: theme.textTheme.titleMedium?.copyWith(
              color: onCard,
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
              backgroundColor: onCard.withValues(alpha: 0.12),
            ),
          ),
        ],
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

    final theme = Theme.of(context);
    final onCard = theme.colorScheme.onSurface;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 0,
        vertical: AppSpacing.xs,
      ),
      leading: CircleAvatar(
        backgroundColor: onCard.withValues(alpha: 0.10),
        child: Icon(icon, color: accent),
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleMedium?.copyWith(
          color: onCard,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
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
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: onCard,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${transaction.occurredAt.month.toString().padLeft(2, '0')}.${transaction.occurredAt.day.toString().padLeft(2, '0')}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
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
    final onCard = theme.colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        children: [
          Icon(
            Icons.auto_stories_outlined,
            size: 30,
            color: onCard.withValues(alpha: 0.50),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '아직 거래가 없어요',
            style: theme.textTheme.titleSmall?.copyWith(
              color: onCard,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '첫 거래를 기록하면 오늘 내역이 시작돼요.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

double _mix(double start, double end, double t) => start + ((end - start) * t);

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
