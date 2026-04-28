import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../shared\widgets/app_metric_strip.dart';
import '../../../shared\widgets/app_scaffold.dart';
import '../../../shared\widgets/app_section_intro.dart';
import '../../../shared\widgets/app_status_chip.dart';
import '../../../shared\utils\currency_formatter.dart';
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
                    return tx.type == 'transfer' || tx.type == 'transfer_reserved';
                  }
                  return tx.type == _selectedType;
                }).toList();

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              _TimelineSummaryCard(
                totalCount: items.length,
                visibleCount: filteredItems.length,
                selectedType: _selectedType,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppSectionIntro(
                title: '필터',
                subtitle: '보고 싶은 흐름만 골라 차분히 훑어보세요.',
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
              const SizedBox(height: AppSpacing.lg),
              const AppSectionIntro(
                title: '최근 내역',
                subtitle: '정리된 레저처럼 빠르게 읽고, 필요하면 바로 수정할 수 있어야 합니다.',
              ),
              const SizedBox(height: AppSpacing.sm),
              filteredItems.isEmpty
                  ? _TimelineEmptyState(selectedType: _selectedType)
                  : _TimelineList(
                      items: filteredItems,
                      onEdit: (tx) {
                        ref.read(quickEntryFormProvider.notifier).loadTransaction(tx);
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
          content: const Text('이 거래는 타임라인에서 숨겨지고, 나중에 다시 복원할 수 있습니다.'),
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

    await ref.read(transactionRepositoryProvider).softDeleteTransaction(tx.localId);

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('거래가 타임라인에서 숨겨졌습니다.')),
    );
  }
}

class _TimelineSummaryCard extends StatelessWidget {
  const _TimelineSummaryCard({
    required this.totalCount,
    required this.visibleCount,
    required this.selectedType,
  });

  final int totalCount;
  final int visibleCount;
  final String? selectedType;

  @override
  Widget build(BuildContext context) {
    final helperText = selectedType == null
        ? '최신 거래를 시간순으로 정리해 보여줍니다.'
        : '${_typeLabel(selectedType!)}만 골라 보고 있어요.';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppStatusChip(
              label: 'LEDGER VIEW',
              dotColor: AppColors.primary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '빠르게 읽고 바로 고칠 수 있는 기록 화면',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              helperText,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: AppMetricStrip(
                    label: '전체',
                    value: '$totalCount건',
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppMetricStrip(
                    label: '현재 보기',
                    value: '$visibleCount건',
                    emphasize: true,
                  ),
                ),
              ],
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
            selected: selectedType == 'transfer' || selectedType == 'transfer_reserved',
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
              isFiltered ? '선택한 조건에 맞는 내역이 아직 없어요' : '기록이 쌓이면 여기에 시간의 흐름이 정리돼요',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              isFiltered
                  ? '필터를 바꾸면 다른 기록을 볼 수 있어요.'
                  : '첫 기록이 남겨지는 순간부터 내역은 신뢰할 수 있는 레저가 됩니다.',
              style: theme.textTheme.bodySmall,
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
    final groupedItems = <String, List<dynamic>>{};
    for (final tx in items) {
      final key = _dateKey(tx.occurredAt);
      groupedItems.putIfAbsent(key, () => []).add(tx);
    }

    final dateKeys = groupedItems.keys.toList();

    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: dateKeys.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, groupIndex) {
          final key = dateKeys[groupIndex];
          final transactions = groupedItems[key]!;

          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _sectionDateLabel(transactions.first.occurredAt),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
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
                        const Divider(height: 1, indent: 56),
                    ],
                  );
                }),
              ],
            ),
          );
        },
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
    final isTransfer = transaction.type == 'transfer' || transaction.type == 'transfer_reserved';
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
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: accentColor.withValues(alpha: 0.12),
        child: Icon(icon, size: 18, color: accentColor),
      ),
      title: Text(
        transaction.merchantName ?? transaction.memo ?? _typeLabel(transaction.type),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          '${_typeLabel(transaction.type)} · ${_timeLabel(transaction.occurredAt)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
      trailing: SizedBox(
        width: 132,
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
                    _counterpartyLabel(transaction),
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              tooltip: '더보기',
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

String _counterpartyLabel(dynamic tx) {
  if ((tx.memo as String?)?.trim().isNotEmpty ?? false) {
    return tx.memo as String;
  }
  if ((tx.merchantName as String?)?.trim().isNotEmpty ?? false) {
    return tx.merchantName as String;
  }
  return '메모 없음';
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
