import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_opacity.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_sizes.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/providers/database_providers.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../../../shared/widgets/app_metric_strip.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/app_status_chip.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../calendar/application/calendar_provider.dart';
import '../../recurring_expenses/application/recurring_transaction_suggestion.dart';
import '../../statistics/application/statistics_provider.dart';
import '../../recurring_expenses/application/recurring_expense_service.dart';
import '../application/dashboard_narrative.dart';
import '../application/dashboard_summary_provider.dart';
import '../application/recurring_transaction_suggestion_provider.dart';
import 'dashboard_home_links_card.dart';
import 'dashboard_narrative_card.dart';
import 'detected_recurring_spend_section.dart';
import 'recurring_transaction_suggestion_card.dart';
import 'upcoming_recurring_transactions_card.dart';

final dashboardPendingNotificationCountProvider = StreamProvider<int>((ref) {
  return ref.watch(appDatabaseProvider).watchNotificationHistories().map(
        (histories) =>
            histories.where((item) => item.status == 'pending').length,
      );
});

String dashboardTodayLoopActionSemanticLabel({
  required bool hasTodayEntry,
}) {
  if (hasTodayEntry) {
    return 'Open quick entry. Today already has recorded transactions, so you can add one more entry.';
  }
  return 'Open quick entry. No transaction has been recorded today, so you can start the first entry now.';
}

String dashboardTimelineActionSemanticLabel() {
  return 'Open timeline. Review the recent transaction history for today.';
}

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key, this.showNotificationFeatures = true});

  final bool showNotificationFeatures;

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with WidgetsBindingObserver {
  Timer? _midnightTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refreshDateAndScheduleTimer();
    });
  }

  void _refreshDateAndScheduleTimer() {
    final now = ref.read(dashboardNowProvider)();
    final date = DateTime(now.year, now.month, now.day);
    if (ref.read(dashboardDateProvider) != date) {
      ref.read(dashboardDateProvider.notifier).state = date;
    }
    _midnightTimer?.cancel();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    _midnightTimer = Timer(
      nextMidnight.difference(now) + const Duration(milliseconds: 50),
      () {
        if (mounted) _refreshDateAndScheduleTimer();
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _refreshDateAndScheduleTimer();
    }
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final totalBalanceAsync = ref.watch(totalActiveAccountBalanceProvider);
    final recurringAsync = ref.watch(activeRecurringExpensesProvider);
    final recurringSuggestionAsync =
        ref.watch(recurringTransactionSuggestionProvider);
    final calendarSummaryAsync = ref.watch(calendarHomeSummaryProvider);
    final calendarPreviewAsync = ref.watch(calendarHomeMonthPreviewProvider);
    final statisticsPreviewAsync = ref.watch(statisticsHomePreviewProvider);
    final AsyncValue<int> pendingNotifications = widget.showNotificationFeatures
        ? ref.watch(dashboardPendingNotificationCountProvider)
        : const AsyncData(0);

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
              if (widget.showNotificationFeatures) ...[
                SliverToBoxAdapter(
                  child: _NotificationHistoryEntry(
                    pendingCount: pendingNotifications,
                    onOpen: () => context.push('/notification-history'),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
              ],
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
                        label: '기록 기준 계좌 잔액',
                        value: formatCurrency(totalBalance),
                        emphasize: true,
                      ),
                    ),
                  ],
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
              SliverToBoxAdapter(
                child: _RecentTransactionsSection(
                  transactions: summary.recentTransactions,
                  onOpenTimeline: () => context.go('/timeline'),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
              SliverToBoxAdapter(child: _BudgetStatusCard(summary: summary)),
              const SliverToBoxAdapter(child: DetectedRecurringSpendSection()),
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
              const SliverToBoxAdapter(child: SizedBox(height: 110)),
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

class _NotificationHistoryEntry extends StatelessWidget {
  const _NotificationHistoryEntry({
    required this.pendingCount,
    required this.onOpen,
  });

  final AsyncValue<int> pendingCount;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final description = pendingCount.when(
      data: (count) => '확인 대기 중인 알림 $count건',
      loading: () => '알림 내역을 불러오는 중이에요',
      error: (_, __) => '알림 내역을 열어 확인해 주세요',
    );

    return Semantics(
      key: const Key('dashboard-open-notification-history'),
      button: true,
      label: '알림 수신 이력. $description.',
      onTap: onOpen,
      excludeSemantics: true,
      child: GlassCard(
        blur: 16,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onOpen,
            borderRadius: BorderRadius.circular(AppRadius.xxl),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Icon(Icons.notifications_outlined,
                      color: theme.colorScheme.primary),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '알림 수신 이력',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OverviewHero extends StatelessWidget {
  const _OverviewHero({required this.summary, required this.totalBalance});

  final DashboardSummary summary;
  final int totalBalance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final foreground = dark ? const Color(0xFFF5FAFF) : const Color(0xFF183F61);
    final weather = buildDashboardWeatherSummary(summary.narrative);
    final isClear = weather.kind == DashboardWeatherKind.budgetInRange;
    final isRainy = weather.kind == DashboardWeatherKind.budgetReached ||
        weather.kind == DashboardWeatherKind.budgetExceeded;
    final budgetText = summary.totalBudget <= 0
        ? '예산을 설정하면 남은 금액도 볼 수 있어요'
        : summary.remainingBudget < 0
            ? '예산보다 ${formatCurrency(-summary.remainingBudget)} 더 썼어요'
            : '예산에서 ${formatCurrency(summary.remainingBudget)} 남았어요';

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 22),
        child: Column(
          children: [
            Text(
              '${DateTime.now().month}월의 소비 날씨',
              style: theme.textTheme.titleSmall?.copyWith(
                color: foreground.withValues(alpha: .82), fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ExcludeSemantics(
              child: SizedBox(
                height: 54,
                width: 78,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      right: 5, top: 0,
                      child: Icon(
                        isRainy ? Icons.cloud_rounded : Icons.wb_sunny_rounded,
                        size: 42,
                        color: isRainy ? const Color(0xFF9EBBD4) : const Color(0xFFFFDB82),
                      ),
                    ),
                    if (!isClear)
                      Positioned(
                        left: 2, bottom: 0,
                        child: Icon(
                          isRainy ? Icons.cloudy_snowing : Icons.cloud_rounded,
                          size: 54,
                          color: dark ? const Color(0xFFD6EBFA) : Colors.white,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text('이번 달 지출', style: theme.textTheme.titleSmall?.copyWith(
              color: foreground.withValues(alpha: .84), fontWeight: FontWeight.w600)),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(formatCurrency(summary.monthExpense), maxLines: 1,
                style: theme.textTheme.displayLarge?.copyWith(
                  color: foreground, fontWeight: FontWeight.w700,
                  letterSpacing: -1.6, height: 1.12)),
            ),
            const SizedBox(height: 8),
            Text(budgetText, textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: foreground.withValues(alpha: .85), fontWeight: FontWeight.w600)),
          ],
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
            label: '오늘 현황',
            dotColor: hasTodayEntry ? AppColors.income : AppColors.warning,
            backgroundColor: onCard.withValues(alpha: AppOpacity.hovered),
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
              Semantics(
                button: true,
                label: dashboardTodayLoopActionSemanticLabel(
                  hasTodayEntry: hasTodayEntry,
                ),
                child: FilledButton(
                  onPressed: onQuickEntry,
                  child: Text(hasTodayEntry ? '한 건 더 기록하기' : '지금 기록 시작하기'),
                ),
              ),
              Semantics(
                button: true,
                label: dashboardTimelineActionSemanticLabel(),
                child: OutlinedButton(
                  onPressed: onOpenTimeline,
                  child: const Text('최근 내역 보기'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


class _RecentTransactionsSection extends StatelessWidget {
  const _RecentTransactionsSection({required this.transactions, required this.onOpenTimeline});

  final List<Transaction> transactions;
  final VoidCallback onOpenTimeline;

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
          Row(
            children: [
              Expanded(child: Text(
                '최근 거래',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: onCard, fontWeight: FontWeight.w700),
              )),
              TextButton(onPressed: onOpenTimeline, child: const Text('전체 보기')),
            ],
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
                      color: onCard.withValues(alpha: AppOpacity.focused),
                    ),
                ],
              ],
            ),
        ],
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
            label: '예산 현황',
            dotColor: progressColor,
            backgroundColor: onCard.withValues(alpha: AppOpacity.hovered),
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
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              color: progressColor,
              backgroundColor: progressColor.withValues(alpha: AppOpacity.focused),
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
    final isDark = theme.brightness == Brightness.dark;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 0,
        vertical: AppSpacing.xs,
      ),
      leading: Container(
        width: AppSizes.avatarMD,
        height: AppSizes.avatarMD,
        decoration: BoxDecoration(
          color: isExpense || isIncome
              ? AppColors.transactionTint(isIncome: isIncome, isDark: isDark)
              : AppColors.primary.withValues(alpha: AppOpacity.hovered),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Icon(icon, color: accent, size: AppSizes.iconMD),
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
    return const AppEmptyState(
      icon: Icons.auto_stories_outlined,
      title: '아직 거래가 없어요',
      subtitle: '첫 거래를 기록하면 오늘 내역이 시작돼요.',
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
