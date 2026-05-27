import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_opacity.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_sizes.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../../../shared/widgets/app_metric_strip.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/app_section_intro.dart';
import '../../../shared/widgets/app_status_chip.dart';
import '../../transactions/application/quick_entry_form_provider.dart';
import '../../transactions/data/transaction_repository.dart';
import '../application/timeline_provider.dart';

class TimelineScreen extends ConsumerStatefulWidget {
  const TimelineScreen({super.key});

  @override
  ConsumerState<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends ConsumerState<TimelineScreen> {
  @override
  Widget build(BuildContext context) {
    final timelineAsync = ref.watch(timelineTransactionsProvider);
    final selectedType = ref.watch(timelineSelectedTypeProvider);

    return AppScaffold(
      title: '내역',
      body: timelineAsync.when(
        data: (snapshot) {
          final items = snapshot.items;

          // 필터된 항목의 수입/지출 합계
          int totalIncome = 0;
          int totalExpense = 0;
          for (final tx in items) {
            if (tx.type == 'income') totalIncome += tx.amount;
            if (tx.type == 'expense') totalExpense += tx.amount;
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              144,
            ),
            children: [
              _TimelineSummaryCard(
                totalCount: snapshot.totalCount,
                visibleCount: items.length,
                selectedType: selectedType,
                totalIncome: totalIncome,
                totalExpense: totalExpense,
              ),
              const SizedBox(height: AppSpacing.md),
              AppSectionIntro(
                title: '필터',
                trailing: items.isEmpty
                    ? null
                    : AppStatusChip(
                        label: '${items.length}건',
                        dotColor: AppColors.primary,
                      ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Semantics(
                container: true,
                label: 'Timeline filters',
                hint: 'Choose a transaction type filter',
                child: _TypeFilterBar(
                  selectedType: selectedType,
                  onSelected: (type) =>
                      ref.read(timelineControllerProvider.notifier).selectType(type),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const AppSectionIntro(
                title: '최근 내역',
              ),
              const SizedBox(height: AppSpacing.sm),
              items.isEmpty
                  ? _TimelineEmptyState(selectedType: selectedType)
                  : _TimelineList(
                      items: items,
                      onEdit: (tx) {
                        ref
                            .read(quickEntryFormProvider.notifier)
                            .loadTransaction(tx);
                        context.pushNamed('quick-entry');
                      },
                      onDelete: (tx) => _deleteTransaction(context, tx),
                    ),
              if (snapshot.hasMore) ...[
                const SizedBox(height: AppSpacing.md),
                _TimelineLoadMoreButton(
                  loadedCount: items.length,
                  totalCount: snapshot.totalCount,
                  onPressed: () =>
                      ref.read(timelineControllerProvider.notifier).loadMore(),
                ),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text('내역을 불러오지 못했습니다.\n$error'),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteTransaction(BuildContext context, dynamic tx) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('거래를 숨길까요?'),
          content: const Text('이 거래를 숨기겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('숨기기'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    final repo = ref.read(transactionRepositoryProvider);
    await repo.softDeleteTransaction(tx.localId);

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('거래를 숨겼습니다.'),
          action: SnackBarAction(
            label: '되돌리기',
            onPressed: () => repo.undoDeleteTransaction(tx.localId),
          ),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}

class _TimelineSummaryCard extends StatelessWidget {
  const _TimelineSummaryCard({
    required this.totalCount,
    required this.visibleCount,
    required this.selectedType,
    required this.totalIncome,
    required this.totalExpense,
  });

  final int totalCount;
  final int visibleCount;
  final String? selectedType;
  final int totalIncome;
  final int totalExpense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final net = totalIncome - totalExpense;
    final netColor = net >= 0 ? AppColors.income : AppColors.expense;

    return Semantics(
      container: true,
      label: _timelineSummarySemanticLabel(
        totalCount: totalCount,
        visibleCount: visibleCount,
        selectedType: selectedType,
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        net: net,
      ),
      child: Card(
        child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppStatusChip(
              label: 'LEDGER VIEW',
              dotColor: AppColors.primary,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: AppMetricStrip(
                    label: '수입',
                    value: '+${formatCurrency(totalIncome)}',
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppMetricStrip(
                    label: '지출',
                    value: '-${formatCurrency(totalExpense)}',
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '순수익',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${net >= 0 ? '+' : ''}${formatCurrency(net)}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: netColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              selectedType == null
                  ? '전체 $totalCount건'
                  : '$visibleCount건 표시 중 (전체 $totalCount건)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _TypeFilterBar extends StatelessWidget {
  const _TypeFilterBar({
    required this.selectedType,
    required this.onSelected,
  });

  final String? selectedType;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChipButton(
            label: '전체',
            selected: selectedType == null,
            onTap: () => onSelected(null),
          ),
          const SizedBox(width: 8),
          _FilterChipButton(
            label: '지출',
            selected: selectedType == 'expense',
            onTap: () => onSelected('expense'),
          ),
          const SizedBox(width: 8),
          _FilterChipButton(
            label: '수입',
            selected: selectedType == 'income',
            onTap: () => onSelected('income'),
          ),
          const SizedBox(width: 8),
          _FilterChipButton(
            label: '이체',
            selected: selectedType == 'transfer' ||
                selectedType == 'transfer_reserved',
            onTap: () => onSelected('transfer'),
          ),
        ],
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FilterChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      selectedColor: theme.colorScheme.primary.withValues(alpha: AppOpacity.focused),
      side: BorderSide(
        color: selected
            ? theme.colorScheme.primary.withValues(alpha: AppOpacity.dragged)
            : theme.dividerColor,
      ),
      labelStyle: theme.textTheme.bodyMedium?.copyWith(
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        color: selected ? theme.colorScheme.primary : null,
      ),
      onSelected: (_) => onTap(),
    );
  }
}

class _TimelineEmptyState extends StatelessWidget {
  const _TimelineEmptyState({required this.selectedType});

  final String? selectedType;

  @override
  Widget build(BuildContext context) {
    final isFiltered = selectedType != null;
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Icon(
              isFiltered ? Icons.filter_alt_off : Icons.receipt_long_outlined,
              size: 32,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              isFiltered ? '조건에 맞는 거래가 없어요' : '거래 내역이 없어요',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineList extends StatelessWidget {
  const _TimelineList({
    required this.items,
    required this.onEdit,
    required this.onDelete,
  });

  final List<dynamic> items;
  final ValueChanged<dynamic> onEdit;
  final ValueChanged<dynamic> onDelete;

  @override
  Widget build(BuildContext context) {
    // 날짜별 그룹화 (순서 유지)
    final groupedItems = <String, List<dynamic>>{};
    for (final tx in items) {
      final key = _dateKey(tx.occurredAt);
      groupedItems.putIfAbsent(key, () => []).add(tx);
    }
    final dateKeys = groupedItems.keys.toList();

    return Column(
      children: List.generate(dateKeys.length, (groupIndex) {
        final key = dateKeys[groupIndex];
        final transactions = groupedItems[key]!;

        // 일간 소계 계산 (이체 제외)
        int dayIncome = 0;
        int dayExpense = 0;
        for (final tx in transactions) {
          if (tx.type == 'income') dayIncome += tx.amount as int;
          if (tx.type == 'expense') dayExpense += tx.amount as int;
        }

        return Padding(
          padding: EdgeInsets.only(
              bottom: groupIndex < dateKeys.length - 1 ? AppSpacing.sm : 0),
          child: Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 날짜 헤더 + 일간 소계
                _DayGroupHeader(
                  date: transactions.first.occurredAt as DateTime,
                  dayIncome: dayIncome,
                  dayExpense: dayExpense,
                ),
                const Divider(height: 1),
                // 거래 목록
                ...List.generate(transactions.length, (index) {
                  final tx = transactions[index];
                  return Column(
                    children: [
                      _SwipeableTile(
                        key: ValueKey(tx.localId),
                        transaction: tx,
                        onEdit: () => onEdit(tx),
                        onDelete: () => onDelete(tx),
                      ),
                      if (index != transactions.length - 1)
                        const Divider(height: 1, indent: 54),
                    ],
                  );
                }),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _TimelineLoadMoreButton extends StatelessWidget {
  const _TimelineLoadMoreButton({
    required this.loadedCount,
    required this.totalCount,
    required this.onPressed,
  });

  final int loadedCount;
  final int totalCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      label: 'Load more timeline items',
      value: '$loadedCount of $totalCount items loaded',
      hint: 'Double tap to load more transactions',
      child: Card(
        child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Text(
              '$loadedCount / $totalCount',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(
              key: const Key('timeline-load-more-button'),
              onPressed: onPressed,
              child: const Text('더 보기'),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _DayGroupHeader extends StatelessWidget {
  const _DayGroupHeader({
    required this.date,
    required this.dayIncome,
    required this.dayExpense,
  });

  final DateTime date;
  final int dayIncome;
  final int dayExpense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      header: true,
      label: _dayGroupSemanticLabel(date, dayIncome, dayExpense),
      child: Padding(
        padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 10,
      ),
      child: Row(
        children: [
          // 날짜 레이블
          Text(
            _sectionDateLabel(date),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          // 수입 소계
          if (dayIncome > 0) ...[
            Text(
              '+${formatCurrency(dayIncome)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.income,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          // 지출 소계
          if (dayExpense > 0) ...[
            if (dayIncome > 0) const SizedBox(width: 8),
            Text(
              '-${formatCurrency(dayExpense)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.expense,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
      ),
    );
  }
}

// ── 스와이프 래퍼 ─────────────────────────────────────────────────────────

class _SwipeableTile extends StatelessWidget {
  const _SwipeableTile({
    super.key,
    required this.transaction,
    required this.onEdit,
    required this.onDelete,
  });

  final dynamic transaction;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      label: _transactionSemanticLabel(transaction),
      hint: 'Swipe left to delete. Use the menu for more actions.',
      child: Dismissible(
        key: ValueKey('dismissible_${transaction.localId}'),
        direction: DismissDirection.endToStart,
        background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        color: theme.colorScheme.errorContainer,
        child: Icon(
          Icons.delete_outline_rounded,
          color: theme.colorScheme.onErrorContainer,
        ),
      ),
      confirmDismiss: (direction) async {
        HapticFeedback.mediumImpact();
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('거래 숨기기'),
            content: const Text('이 거래를 목록에서 숨길까요?\n설정에서 복원할 수 있습니다.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('취소'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                ),
                child: const Text('숨기기'),
              ),
            ],
          ),
        );
        return confirmed ?? false;
      },
      onDismissed: (_) {
        HapticFeedback.lightImpact();
        onDelete();
      },
        child: _TimelineTile(
          transaction: transaction,
          onEdit: onEdit,
          onDelete: onDelete,
        ),
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({
    required this.transaction,
    required this.onEdit,
    required this.onDelete,
  });

  final dynamic transaction;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTransfer = transaction.type == 'transfer' ||
        transaction.type == 'transfer_reserved';
    final accentColor = isTransfer
        ? AppColors.primary
        : transaction.type == 'expense'
            ? AppColors.expense
            : AppColors.income;
    final icon = isTransfer
        ? Icons.swap_horiz_rounded
        : transaction.type == 'expense'
            ? Icons.arrow_downward_rounded
            : Icons.arrow_upward_rounded;

    final iconBg = isTransfer
        ? AppColors.primary.withValues(alpha: AppOpacity.hovered)
        : AppColors.transactionTint(
            isIncome: transaction.type == 'income',
            isDark: isDark,
          );

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      leading: Container(
        width: AppSizes.avatarMD,
        height: AppSizes.avatarMD,
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Icon(icon, size: AppSizes.iconSM, color: accentColor),
      ),
      title: Text(
        _primaryLabel(transaction),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          _secondaryLabel(transaction),
          style: Theme.of(context).textTheme.bodySmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      trailing: SizedBox(
        width: 120,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatAmount(transaction.type, transaction.amount),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _timeLabel(transaction.occurredAt),
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'More actions',
              onSelected: (value) {
                if (value == 'edit') {
                  onEdit();
                } else if (value == 'delete') {
                  onDelete();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem<String>(
                  value: 'edit',
                  child: Text('수정'),
                ),
                PopupMenuItem<String>(
                  value: 'delete',
                  child: Text('숨기기'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _timelineSummarySemanticLabel({
  required int totalCount,
  required int visibleCount,
  required String? selectedType,
  required int totalIncome,
  required int totalExpense,
  required int net,
}) {
  final filterLabel =
      selectedType == null ? 'all transactions' : 'filtered transactions';
  return 'Timeline summary. Showing $visibleCount of $totalCount items for '
      '$filterLabel. Income ${formatCurrency(totalIncome)}. Expense '
      '${formatCurrency(totalExpense)}. Net ${formatCurrency(net)}.';
}

String _dayGroupSemanticLabel(DateTime date, int dayIncome, int dayExpense) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return 'Transactions for ${date.year}-$month-$day. Income '
      '${formatCurrency(dayIncome)}. Expense ${formatCurrency(dayExpense)}.';
}

String _transactionSemanticLabel(dynamic tx) {
  final label = _primaryLabel(tx);
  final amount = _formatAmount(tx.type as String, tx.amount as int);
  final time = _timeLabel(tx.occurredAt as DateTime);
  return 'Transaction. $label. Amount $amount. Time $time.';
}

String _typeLabel(String type) {
  switch (type) {
    case 'expense':
      return '지출';
    case 'income':
      return '수입';
    case 'transfer':
    case 'transfer_reserved':
      return '이체';
    default:
      return type;
  }
}

String _primaryLabel(dynamic tx) {
  if ((tx.merchantName as String?)?.trim().isNotEmpty ?? false) {
    return tx.merchantName as String;
  }
  if ((tx.memo as String?)?.trim().isNotEmpty ?? false) {
    return tx.memo as String;
  }
  return _typeLabel(tx.type as String);
}

String _secondaryLabel(dynamic tx) {
  final type = _typeLabel(tx.type as String);
  final memo = (tx.memo as String?)?.trim() ?? '';
  final merchant = (tx.merchantName as String?)?.trim() ?? '';

  if (memo.isNotEmpty && memo != merchant) {
    return '$type · $memo';
  }
  return type;
}

String _formatAmount(String type, int amount) {
  final formatted = formatCurrency(amount);
  switch (type) {
    case 'expense':
      return '-$formatted';
    case 'income':
      return '+$formatted';
    default:
      return formatted;
  }
}

String _timeLabel(DateTime dateTime) {
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _dateKey(DateTime dateTime) {
  final month = dateTime.month.toString().padLeft(2, '0');
  final day = dateTime.day.toString().padLeft(2, '0');
  return '${dateTime.year}-$month-$day';
}

String _sectionDateLabel(DateTime dateTime) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(dateTime.year, dateTime.month, dateTime.day);
  final difference = today.difference(target).inDays;

  if (difference == 0) {
    return '오늘';
  }
  if (difference == 1) {
    return '어제';
  }

  final month = dateTime.month.toString().padLeft(2, '0');
  final day = dateTime.day.toString().padLeft(2, '0');
  return '${dateTime.year}년 $month월 $day일';
}
