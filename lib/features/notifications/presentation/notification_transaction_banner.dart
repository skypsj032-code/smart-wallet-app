import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../../transactions/application/quick_entry_form_provider.dart';
import '../../transactions/application/quick_entry_options_provider.dart';
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
      key: ValueKey(transaction.detectedAt),
      transaction: transaction,
      onTap: () => _openQuickEntry(context, ref, transaction),
      onDismiss: () {
        ref.read(detectedNotificationTransactionProvider.notifier).state = null;
      },
    );
  }

  Future<void> _openQuickEntry(
    BuildContext context,
    WidgetRef ref,
    ParsedNotificationTransaction tx,
  ) async {
    // 배너 닫기
    ref.read(detectedNotificationTransactionProvider.notifier).state = null;

    final entryType = tx.type == 'income'
        ? TransactionEntryType.income
        : TransactionEntryType.expense;

    // 퀵 입력 폼에 파싱 결과 채우기
    final notifier = ref.read(quickEntryFormProvider.notifier);
    notifier.reset();
    notifier.setType(entryType);
    notifier.setAmount(tx.amount.toString());
    if (tx.merchant.isNotEmpty) {
      notifier.setMemo(tx.merchant);
    }

    // 카테고리 자동 추측 — 키워드로 DB 카테고리 이름 부분 매칭
    final keyword = tx.suggestedCategoryKeyword;
    if (keyword != null && tx.type != 'transfer') {
      final categoryType = tx.type == 'income' ? 'income' : 'expense';
      final categories = ref
          .read(quickEntryCategoriesProvider(categoryType))
          .asData
          ?.value;
      if (categories != null) {
        final match = categories.firstWhere(
          (c) => c.name.contains(keyword),
          orElse: () => categories.first,
        );
        // firstWhere with orElse never returns null — only set when name actually matches
        if (match.name.contains(keyword)) {
          notifier.setCategory(match.id);
        }
      }
    }

    if (context.mounted) {
      context.push('/quick-entry');
    }
  }
}

class _BannerCard extends StatefulWidget {
  const _BannerCard({
    super.key,
    required this.transaction,
    required this.onTap,
    required this.onDismiss,
  });

  final ParsedNotificationTransaction transaction;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  @override
  State<_BannerCard> createState() => _BannerCardState();
}

class _BannerCardState extends State<_BannerCard> {
  static const _autoDismissDuration = Duration(seconds: 6);

  Timer? _timer;
  // 진행 표시줄용 (0.0 → 1.0)
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    final startTime = DateTime.now();
    _timer = Timer.periodic(const Duration(milliseconds: 50), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      final elapsed = DateTime.now().difference(startTime);
      final p = elapsed.inMilliseconds / _autoDismissDuration.inMilliseconds;
      if (p >= 1.0) {
        t.cancel();
        widget.onDismiss();
      } else {
        setState(() => _progress = p);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isExpense = widget.transaction.type == 'expense';
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
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
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
                                if (widget.transaction.cardName != null) ...[
                                  const SizedBox(width: 6),
                                  Text(
                                    widget.transaction.cardName!,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color:
                                          theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ],
 