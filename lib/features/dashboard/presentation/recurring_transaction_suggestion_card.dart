import 'package:flutter/material.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../../../shared/widgets/app_status_chip.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../recurring_expenses/application/recurring_transaction_suggestion.dart';

class RecurringTransactionSuggestionCard extends StatelessWidget {
  const RecurringTransactionSuggestionCard({
    super.key,
    required this.suggestion,
    required this.onCreate,
    required this.onDismiss,
  });

  final RecurringTransactionSuggestion suggestion;
  final VoidCallback onCreate;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final transaction = suggestion.transaction;
    final theme = Theme.of(context);
    final onCard = theme.colorScheme.onSurface;

    return GlassCard(
      key: const Key('dashboard-recurring-suggestion-card'),
      blur: 16,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppStatusChip(
            label: 'RECURRING',
            dotColor: transaction.type == 'income'
                ? const Color(0xFF2CA36D)
                : const Color(0xFFE07B5C),
            backgroundColor: onCard.withValues(alpha: 0.10),
            foregroundColor: onCard,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '오늘 처리할 정기 거래가 있어요',
            style: theme.textTheme.titleMedium?.copyWith(
              color: onCard,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${transaction.name} ${formatCurrency(transaction.amount)}',
            style: theme.textTheme.titleLarge?.copyWith(
              color: onCard,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _scheduleLabel(transaction),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              FilledButton(
                onPressed: onCreate,
                child: const Text('생성'),
              ),
              const SizedBox(width: AppSpacing.sm),
              TextButton(
                onPressed: onDismiss,
                child: const Text('이번엔 닫기'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _scheduleLabel(RecurringExpense transaction) {
    if (transaction.cadence == 'weekly') {
      return '매주 ${_weekdayLabel(transaction.weekday ?? DateTime.monday)}';
    }
    return '매달 ${transaction.dayOfMonth ?? 1}일';
  }
}

String _weekdayLabel(int weekday) {
  switch (weekday) {
    case DateTime.monday:
      return '월요일';
    case DateTime.tuesday:
      return '화요일';
    case DateTime.wednesday:
      return '수요일';
    case DateTime.thursday:
      return '목요일';
    case DateTime.friday:
      return '금요일';
    case DateTime.saturday:
      return '토요일';
    case DateTime.sunday:
      return '일요일';
    default:
      return '요일';
  }
}
