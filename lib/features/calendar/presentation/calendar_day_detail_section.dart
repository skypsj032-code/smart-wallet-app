import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/database/app_database.dart';
import '../application/calendar_provider.dart';

class CalendarDayDetailSection extends StatelessWidget {
  const CalendarDayDetailSection({
    super.key,
    required this.snapshot,
    required this.selectedDate,
    required this.selectedDay,
    required this.transactionsAsync,
    required this.sortOrder,
    required this.onChangeSortOrder,
    required this.onEditTransaction,
  });

  final CalendarSnapshot snapshot;
  final DateTime? selectedDate;
  final CalendarDaySummary? selectedDay;
  final AsyncValue<List<Transaction>> transactionsAsync;
  final CalendarTransactionSortOrder sortOrder;
  final ValueChanged<CalendarTransactionSortOrder> onChangeSortOrder;
  final ValueChanged<Transaction> onEditTransaction;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('calendar-day-detail-section'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color:
                Theme.of(context).colorScheme.outline.withValues(alpha: 0.18),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            selectedDate == null ? '기간 흐름' : _selectedDateLabel(selectedDate!),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (selectedDate == null)
            _CalendarYearSummaryCard(snapshot: snapshot)
          else
            _CalendarSelectedDayBody(
              key: const Key('calendar-selected-day-card'),
              selectedDate: selectedDate,
              selectedDay: selectedDay,
              transactionsAsync: transactionsAsync,
              sortOrder: sortOrder,
              onChangeSortOrder: onChangeSortOrder,
              onEditTransaction: onEditTransaction,
            ),
        ],
      ),
    );
  }
}

class _CalendarSelectedDayBody extends StatelessWidget {
  const _CalendarSelectedDayBody({
    super.key,
    required this.selectedDate,
    required this.selectedDay,
    required this.transactionsAsync,
    required this.sortOrder,
    required this.onChangeSortOrder,
    required this.onEditTransaction,
  });

  final DateTime? selectedDate;
  final CalendarDaySummary? selectedDay;
  final AsyncValue<List<Transaction>> transactionsAsync;
  final CalendarTransactionSortOrder sortOrder;
  final ValueChanged<CalendarTransactionSortOrder> onChangeSortOrder;
  final ValueChanged<Transaction> onEditTransaction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: transactionsAsync.when(
        data: (transactions) {
          if (selectedDate == null) {
            return const _CalendarEmptyMessage(
              title: '날짜를 선택하세요',
              body: '',
            );
          }

          if (transactions.isEmpty) {
            return const _CalendarEmptyMessage(
              title: '이 날의 거래가 없어요',
              body: '',
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: SegmentedButton<CalendarTransactionSortOrder>(
                  key: const Key('calendar-transaction-sort-toggle'),
                  segments: const [
                    ButtonSegment<CalendarTransactionSortOrder>(
                      value: CalendarTransactionSortOrder.newestFirst,
                      icon: Icon(Icons.south_rounded),
                      label: Text('최신순'),
                    ),
                    ButtonSegment<CalendarTransactionSortOrder>(
                      value: CalendarTransactionSortOrder.oldestFirst,
                      icon: Icon(Icons.north_rounded),
                      label: Text('오래된순'),
                    ),
                  ],
                  selected: {sortOrder},
                  onSelectionChanged: (selection) =>
                      onChangeSortOrder(selection.first),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (selectedDay != null) ...[
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    _CompactSummaryChip(
                      key: const Key('calendar-selected-summary-income'),
                      label: '수입',
                      value: _formatCurrency(selectedDay!.income),
                      color: AppColors.income,
                    ),
                    _CompactSummaryChip(
                      key: const Key('calendar-selected-summary-expense'),
                      label: '지출',
                      value: _formatCurrency(selectedDay!.expense),
                      color: AppColors.expense,
                    ),
                    _CompactSummaryChip(
                      key: const Key('calendar-selected-summary-count'),
                      label: '거래',
                      value: '${selectedDay!.transactionCount}건',
                      color: AppColors.primary,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              for (var index = 0; index < transactions.length; index++) ...[
                _EditableTransactionRow(
                  transaction: transactions[index],
                  onTap: () => onEditTransaction(transactions[index]),
                ),
                if (index != transactions.length - 1)
                  const Divider(height: AppSpacing.lg),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Text('거래를 불러오지 못했어요. $error'),
      ),
    );
  }
}

class _CalendarYearSummaryCard extends StatelessWidget {
  const _CalendarYearSummaryCard({
    required this.snapshot,
  });

  final CalendarSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          _SummaryTile(
            label: '총수입',
            value: _formatCurrency(snapshot.totalIncome),
            color: AppColors.income,
          ),
          _SummaryTile(
            label: '총지출',
            value: _formatCurrency(snapshot.totalExpense),
            color: AppColors.expense,
          ),
        ],
      ),
    );
  }
}

class _CalendarEmptyMessage extends StatelessWidget {
  const _CalendarEmptyMessage({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        if (body.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            body,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.62),
                ),
          ),
        ],
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _CompactSummaryChip extends StatelessWidget {
  const _CompactSummaryChip({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            value,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _EditableTransactionRow extends StatelessWidget {
  const _EditableTransactionRow({
    required this.transaction,
    required this.onTap,
  });

  final Transaction transaction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.type == 'expense';
    final isIncome = transaction.type == 'income';
    final typeLabel = {
          'expense': '지출',
          'income': '수입',
          'transfer': '이체',
        }[transaction.type] ??
        transaction.type;

    final merchant = transaction.merchantName?.trim();
    final memo = transaction.memo?.trim();
    final title = merchant?.isNotEmpty == true
        ? merchant!
        : memo?.isNotEmpty == true
            ? memo!
            : typeLabel;

    final supportingParts = <String>[
      if (memo?.isNotEmpty == true && memo != merchant) memo!,
      typeLabel,
      '${transaction.occurredAt.hour.toString().padLeft(2, '0')}:${transaction.occurredAt.minute.toString().padLeft(2, '0')}',
    ];

    final icon = isExpense
        ? Icons.arrow_downward_rounded
        : (isIncome ? Icons.arrow_upward_rounded : Icons.swap_horiz_rounded);
    final accentColor = isExpense
        ? AppColors.expense
        : (isIncome ? AppColors.income : AppColors.primary);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: accentColor.withValues(alpha: 0.12),
                child: Icon(
                  icon,
                  size: 18,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      supportingParts.join(' · '),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatCurrency(transaction.amount),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: accentColor,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _selectedDateLabel(DateTime date) {
  return '${date.month}월 ${date.day}일';
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
