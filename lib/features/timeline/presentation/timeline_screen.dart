import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
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
  String? _selectedType;

  @override
  Widget build(BuildContext context) {
    final timelineAsync = ref.watch(timelineTransactionsProvider);

    return AppScaffold(
      title: '내역',
      body: timelineAsync.when(
        data: (items) {
          final filteredItems = _selectedType == null
              ? items
              : items.where((tx) {
                  if (_selectedType == 'transfer') {
                    return tx.type == 'transfer' ||
                        tx.type == 'transfer_reserved';
                  }
                  return tx.type == _selectedType;
                }).toList();

          // 필터된 항목의 수입/지출 합계
          int totalIncome = 0;
          int totalExpense = 0;
          for (final tx in filteredItems) {
            if (tx.type == 'income') totalIncome += (tx.amount as int);
            if (tx.type == 'expense') totalExpense += (tx.amount as int);
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
                totalCount: items.length,
                visibleCount: filteredItems.length,
                selectedType: _selectedType,
                totalIncome: totalIncome,
                totalExpense: totalExpense,
              ),
              const SizedBox(height: AppSpacing.md),
              AppSectionIntro(
                title: '필터',
                trailing: filteredItems.isEmpty
                    ? null
                    : AppStatusChip(
                        label: '${filteredItems.length}건',
                        dotColor: AppColors.primary,
                      ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _TypeFilterBar(
                selectedType: _selectedType,
                onSelected: (type) => setState(() => _selectedType = type),
              ),
              const SizedBox(height: AppSpacing.md),
              const AppSectionIntro(
                title: '최근 내역',
              ),
              const SizedBox(height: AppSpacing.sm),
              filteredItems.isEmpty
                  ? _TimelineEmptyState(selectedType: _selectedType)
                  : _TimelineList(
                      items: filteredItems,
                      onEdit: (tx) {
                        ref
                            .read(quickEntryFormProvider.notifier)
                            .loadTransaction(tx);
                        context.pushNamed('quick-entry');
                      },
                      onDelete: (tx) => _deleteTransaction(context, tx),
                    ),
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

    await ref
        .read(transactionRepositoryProvider)
        .softDeleteTransaction(tx.localId);

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('거래를 타임라인에서 숨겼습니다.')),
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

    return Card(
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
                  ? '전체 ${totalCount}건'
                  : '${visibleCount}건 표시 중 (전체 ${totalCount}건)',
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
      selectedColor: theme.colorScheme.primary.withValues(alpha: 0.12),
      side: BorderSide(
        color: selected
            ? theme.colorScheme.primary.withValues(alpha: 0.2)
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
          if (tx.type == 'income') dayIncome += (tx.amount as int);
          if (tx.type == 'expense') dayExpense += (tx.amount as int);
        }

        return Padding(
          padding: EdgeInsets.only(bottom: groupIndex < dateKeys.length - 1 ? AppSpacing.sm : 0),
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
                      _TimelineTile(
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

    return Padding(
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

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: accentColor.withValues(alpha: 0.12),
        child: Icon(icon, size: 18, color: accentColor),
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
            Expan