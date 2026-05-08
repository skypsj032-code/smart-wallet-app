import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/providers/database_providers.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../transactions/application/quick_entry_form_provider.dart';
import '../../transactions/application/quick_entry_options_provider.dart';

final _notificationHistoryProvider =
    StreamProvider<List<NotificationHistory>>((ref) {
  return ref.watch(appDatabaseProvider).watchNotificationHistories();
});

class NotificationHistoryScreen extends ConsumerWidget {
  const NotificationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(_notificationHistoryProvider);

    return AppScaffold(
      title: '알림 수신 이력',
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (items) {
          if (items.isEmpty) {
            return const _EmptyHistoryView();
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            itemCount: items.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppSpacing.xs),
            itemBuilder: (context, index) => _HistoryTile(
              item: items[index],
              onTap: () => _openQuickEntry(context, ref, items[index]),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openQuickEntry(
    BuildContext context,
    WidgetRef ref,
    NotificationHistory item,
  ) async {
    final notifier = ref.read(quickEntryFormProvider.notifier);
    notifier.reset();
    notifier.setType(
      item.type == 'expense'
          ? TransactionEntryType.expense
          : TransactionEntryType.income,
    );
    notifier.setAmount(item.amount.toString());

    final keyword = item.suggestedCategory;
    if (keyword != null) {
      final typeStr = item.type == 'expense' ? 'expense' : 'income';
      final cats = ref
          .read(quickEntryCategoriesProvider(typeStr))
          .asData
          ?.value;
      if (cats != null) {
        final matched = cats.where((c) => c.name.contains(keyword));
        if (matched.isNotEmpty) {
          notifier.setCategory(matched.first.id);
        }
      }
    }

    if (item.merchant != null && item.merchant!.isNotEmpty) {
      notifier.setMemo(item.merchant!);
    }

    if (context.mounted) {
      context.push('/quick-entry');
    }
  }
}

// ── 빈 상태 ────────────────────────────────────────────────────────────────

class _EmptyHistoryView extends StatelessWidget {
  const _EmptyHistoryView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_none_rounded,
              size: 56,
              color: theme.colorScheme.outlineVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '수신된 알림이 없습니다',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '카드·은행 알림이 감지되면\n자동으로 이곳에 기록됩니다.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outlineVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 이력 타일 ───────────────────────────────────────────────────────────────

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.item, required this.onTap});

  final NotificationHistory item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isExpense = item.type == 'expense';
    final amountColor = isExpense ? AppColors.expense : AppColors.income;
    final amountSign = isExpense ? '−' : '+';

    final now = DateTime.now();
    final dt = item.detectedAt.toLocal();
    final isToday = dt.year == now.year &&
        dt.month == now.month &&
        dt.day == now.day;
    final isYesterday = dt.year == now.year &&
        dt.month == now.month &&
        dt.day == now.day - 1;

    String dateLabel;
    if (isToday) {
      dateLabel =
          '오늘 ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } else if (isYesterday) {
      dateLabel =
          '어제 ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } else {
      dateLabel =
          '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }

    return Semantics(
      container: true,
      button: true,
      label: notificationHistorySemanticLabel(item),
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: ExcludeSemantics(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
            children: [
              // 타입 아이콘
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: amountColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isExpense
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  size: 18,
                  color: amountColor,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // 상호명 + 날짜
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.merchant ??
                          (isExpense ? '지출' : '수입'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // 금액 + 카테고리 힌트
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$amountSign${formatCurrency(item.amount)}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: amountColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (item.suggestedCategory != null)
                    Text(
                      item.suggestedCategory!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: AppSpacing.xs),
              Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: theme.colorScheme.outlineVariant,
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

String notificationHistorySemanticLabel(NotificationHistory item) {
  final typeLabel = item.type == 'income' ? 'income' : 'expense';
  final parts = <String>[
    'Notification history item',
    typeLabel,
    '${formatCurrency(item.amount)} won',
  ];

  if (item.merchant case final merchant?) {
    parts.add('merchant $merchant');
  }
  if (item.suggestedCategory case final suggestedCategory?) {
    parts.add('suggested category $suggestedCategory');
  }

  return '${parts.join(', ')}, double tap to open quick entry.';
}
