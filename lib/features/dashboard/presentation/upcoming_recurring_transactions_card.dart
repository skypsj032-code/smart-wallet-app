import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../recurring_expenses/application/recurring_expense_service.dart';

class UpcomingRecurringTransactionsCard extends StatelessWidget {
  const UpcomingRecurringTransactionsCard({
    super.key,
    required this.items,
  });

  final List<RecurringExpense> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onCard = theme.colorScheme.onSurface;
    final previewItems = sortRecurringExpensesByNextDueDate(
      items,
      today: DateTime.now(),
    ).take(3).toList();

    return GlassCard(
      key: const Key('dashboard-recurring-preview'),
      blur: 16,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '\uC608\uC815\uB41C \uC815\uAE30 \uAC70\uB798',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: onCard,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                key: const Key('dashboard-recurring-manage'),
                onPressed: () => context.push('/recurring-expenses'),
                child: const Text('\uAD00\uB9AC'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (var index = 0; index < previewItems.length; index++) ...[
            _UpcomingRecurringTransactionTile(item: previewItems[index]),
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

class _UpcomingRecurringTransactionTile extends StatelessWidget {
  const _UpcomingRecurringTransactionTile({required this.item});

  final RecurringExpense item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onCard = theme.colorScheme.onSurface;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => context.push('/recurring-expenses'),
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
                    _scheduleLabel(item),
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
                color:
                    item.type == 'income' ? AppColors.income : AppColors.expense,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _scheduleLabel(RecurringExpense recurring) {
    if (recurring.cadence == 'weekly') {
      return '\uB9E4\uC8FC ${_weekdayLabel(recurring.weekday ?? DateTime.monday)}';
    }

    return '\uB9E4\uB2EC ${recurring.dayOfMonth ?? 1}\uC77C';
  }
}

String _weekdayLabel(int weekday) {
  switch (weekday) {
    case DateTime.monday:
      return '\uC6D4\uC694\uC77C';
    case DateTime.tuesday:
      return '\uD654\uC694\uC77C';
    case DateTime.wednesday:
      return '\uC218\uC694\uC77C';
    case DateTime.thursday:
      return '\uBAA9\uC694\uC77C';
    case DateTime.friday:
      return '\uAE08\uC694\uC77C';
    case DateTime.saturday:
      return '\uD1A0\uC694\uC77C';
    case DateTime.sunday:
      return '\uC77C\uC694\uC77C';
    default:
      return '\uC694\uC77C';
  }
}
