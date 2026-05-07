import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../../transactions/application/quick_entry_form_provider.dart';
import '../application/notification_parser.dart';
import '../application/notification_provider.dart';

/// 카드/은행 알림이 감지되면 화면 상단에 표시되는 배너.
/// 탭하면 금액·유형이 채워진 퀵 입력 화면으로 이동.
class NotificationTransactionBanner extends ConsumerWidget {
  const NotificationTransactionBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 리스너 구독 유지 (side-effect provider)
    ref.watch(notificationListenerProvider);

    final transaction = ref.watch(detectedNotificationTransactionProvider);
    if (transaction == null) return const SizedBox.shrink();

    return _BannerCard(
      transaction: transaction,
      onTap: () => _openQuickEntry(context, ref, transaction),
      onDismiss: () {
        ref.read(detectedNotificationTransactionProvider.notifier).state = null;
      },
    );
  }

  void _openQuickEntry(
    BuildContext context,
    WidgetRef ref,
    ParsedNotificationTransaction tx,
  ) {
    // 배너 닫기
    ref.read(detectedNotificationTransactionProvider.notifier).state = null;

    // 퀵 입력 폼에 파싱 결과 채우기
    final notifier = ref.read(quickEntryFormProvider.notifier);
    notifier.reset();
    notifier.setType(
      tx.type == 'income'
          ? TransactionEntryType.income
          : TransactionEntryType.expense,
    );
    notifier.setAmount(tx.amount.toString());
    if (tx.merchant.isNotEmpty) {
      notifier.setMemo(tx.merchant);
    }

    context.push('/quick-entry');
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({
    required this.transaction,
    required this.onTap,
    required this.onDismiss,
  });

  final ParsedNotificationTransaction transaction;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isExpense = transaction.type == 'expense';
    final accentColor = isExpense ? AppColors.expense : AppColors.income;
    final typeLabel = isExpense ? '지출' : '수입';

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          0,
        ),
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(16),
          color: theme.colorScheme.surface,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  // 유형 아이콘
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isExpense
                          ? Icons.arrow_downward_rounded
                          : Icons.arrow_upward_rounded,
                      color: accentColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  // 내용
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Text(
                              '$typeLabel 감지',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: accentColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (transaction.cardName != null) ...[
                              const SizedBox(width: 6),
                              Text(
                                transaction.cardName!,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              formatCurrency(transaction.amount),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            if (transaction.merchant.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  transaction.merchant,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  // 기록하기 버튼
                  TextButton(
                    onPressed: onTap,
                    style: TextButton.styleFrom(
                      foregroundColor: accentColor,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    child: const Text(
                      '기록',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  // 닫기
                  IconButton(
                    onPressed: onDismiss,
                    icon: const Icon(Icons.close_rounded, size: 18),
                    color: theme.colorScheme.onSurfaceVariant,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
