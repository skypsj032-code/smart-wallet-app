import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/providers/database_providers.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../transactions/application/quick_entry_exit_coordinator.dart';
import '../../transactions/application/quick_entry_form_provider.dart';
import '../application/notification_provider.dart';

final _notificationHistoryProvider =
    StreamProvider<List<NotificationHistory>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  // Do not hide older pending candidates behind a latest-N history limit.
  return (db.select(db.notificationHistories)
        ..orderBy([(h) => OrderingTerm.desc(h.detectedAt)]))
      .watch();
});

/// Protect against repeated taps while a candidate is being opened.
final _openingHistoryIds = <int>{};

class NotificationHistoryScreen extends ConsumerWidget {
  const NotificationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keep the draft alive while category lookup and status checks are pending.
    ref.watch(quickEntryFormProvider);
    final historyAsync = ref.watch(_notificationHistoryProvider);
    final droppedCount = ref.watch(notificationDroppedCountProvider);
    final captureError = ref.watch(notificationCaptureErrorProvider);

    return AppScaffold(
      title: '알림 확인',
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('알림 이력을 불러오지 못했어요.')),
        data: (items) {
          final ordered = [...items]..sort((a, b) {
              final rankComparison = _statusRank(a.status).compareTo(_statusRank(b.status));
              return rankComparison != 0
                  ? rankComparison
                  : b.detectedAt.compareTo(a.detectedAt);
            });
          final pendingCount = items.where((item) => item.status == 'pending').length;
          if (items.isEmpty && droppedCount == 0 && !captureError) {
            return const _EmptyHistoryView();
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            itemCount: ordered.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (captureError)
                      const Padding(
                        padding: EdgeInsets.only(bottom: AppSpacing.md),
                        child: Card(
                          child: Padding(
                            padding: EdgeInsets.all(AppSpacing.md),
                            child: Text('알림을 불러오지 못했어요. 잠시 후 다시 확인해 주세요.'),
                          ),
                        ),
                      ),
                    if (droppedCount > 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Text(
                              '대기 공간이 가득 차 알림 $droppedCount건을 놓쳤어요. '
                              '카드·은행 앱에서 확인해 주세요.',
                            ),
                          ),
                        ),
                      ),
                    if (items.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Text('확인이 필요한 알림 $pendingCount건',
                            style: Theme.of(context).textTheme.titleSmall),
                      ),
                  ],
                );
              }
              final item = ordered[index - 1];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: _HistoryTile(
                  item: item,
                  onTap: () => openNotificationHistoryItem(context, ref, item.id),
                  onToggleIgnored: item.status == 'pending' || item.status == 'ignored'
                      ? () => _toggleIgnored(context, ref, item)
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

int _statusRank(String status) => switch (status) {
      'pending' => 0,
      'legacy' => 1,
      'recorded' => 2,
      _ => 3,
    };

Future<void> _toggleIgnored(
    BuildContext context, WidgetRef ref, NotificationHistory item) async {
  final db = ref.read(appDatabaseProvider);
  final nextStatus = item.status == 'pending' ? 'ignored' : 'pending';
  try {
    // Conditional update prevents a stale screen from undoing a saved record.
    await (db.update(db.notificationHistories)
          ..where((h) => h.id.equals(item.id) & h.status.equals(item.status)))
        .write(NotificationHistoriesCompanion(status: Value(nextStatus)));
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('알림 상태를 바꾸지 못했어요. 다시 시도해 주세요.')),
      );
    }
  }
}

Future<NotificationHistory?> _currentHistory(AppDatabase db, int id) =>
    (db.select(db.notificationHistories)..where((h) => h.id.equals(id)))
        .getSingleOrNull();

String _merchantKey(String? merchant) =>
    (merchant ?? '').trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

Future<bool> _hasSimilarRecordedPayment(AppDatabase db, NotificationHistory item) async {
  final merchantKey = _merchantKey(item.merchant);
  if (item.amount <= 0 || merchantKey.length < 2 ||
      (item.type != 'expense' && item.type != 'income')) {
    return false;
  }
  final begin = item.detectedAt.subtract(const Duration(minutes: 5));
  final end = item.detectedAt.add(const Duration(minutes: 5));
  final rows = await (db.select(db.notificationHistories)
        ..where((h) =>
            h.status.equals('recorded') &
            h.amount.equals(item.amount) &
            h.type.equals(item.type) &
            h.detectedAt.isBiggerOrEqualValue(begin) &
            h.detectedAt.isSmallerOrEqualValue(end)))
      .get();
  if (rows.any((row) => row.id != item.id && _merchantKey(row.merchant) == merchantKey)) {
    return true;
  }

  // A manually entered or OCR transaction might have no corresponding
  // notification history. Match the whole merchant name or memo rather than
  // a substring, and never use deleted transactions as evidence.
  final transactions = await (db.select(db.transactions)
        ..where((t) =>
            t.deletedAt.isNull() &
            t.amount.equals(item.amount) &
            t.type.equals(item.type) &
            t.occurredAt.isBiggerOrEqualValue(begin) &
            t.occurredAt.isSmallerOrEqualValue(end)))
      .get();
  return transactions.any((tx) =>
      _merchantKey(tx.merchantName) == merchantKey ||
      _merchantKey(tx.memo) == merchantKey);
}

Future<bool> _confirmNotice(
  BuildContext context, {
  required String title,
  required String message,
  required String continueLabel,
}) async {
  return await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(continueLabel),
            ),
          ],
        ),
      ) ??
      false;
}

/// Don't silently replace an unfinished new entry or an existing edit.
Future<bool> confirmReplacingQuickEntryDraft(BuildContext context, WidgetRef ref) async {
  if (ref.read(quickEntrySubmitStateProvider)) return false;
  final draft = ref.read(quickEntryFormProvider);
  if (draft.editingId != null) {
    return ref.read(quickEntryExitCoordinatorProvider).confirmExit();
  }
  final hasDraft = draft.amount.trim().isNotEmpty || draft.memo.trim().isNotEmpty ||
      draft.occurredAt != null || draft.type != TransactionEntryType.expense ||
      draft.notificationHistoryId != null;
  if (!hasDraft) return true;
  final confirmed = await _confirmNotice(
    context,
    title: '작성 중인 내용을 버리고 알림을 열까요?',
    message: '지금 작성 중인 거래 내용은 저장되지 않아요.',
    continueLabel: '알림 열기',
  );
  return confirmed && context.mounted &&
      !ref.read(quickEntrySubmitStateProvider) &&
      identical(draft, ref.read(quickEntryFormProvider));
}

/// Opens the same durable candidate from either the list or the transient banner.
/// The final status check prevents a stale banner from reopening a saved item.
Future<bool> openNotificationHistoryItem(
    BuildContext context, WidgetRef ref, int historyId) async {
  if (!_openingHistoryIds.add(historyId)) return false;
  try {
    final router = GoRouter.of(context);
    final startingLocation = router.routeInformationProvider.value.uri;
    bool stillHere() => context.mounted &&
        router.routeInformationProvider.value.uri == startingLocation;
    if (ref.read(quickEntrySubmitStateProvider)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('기록을 저장 중이에요. 잠시 후 다시 시도해 주세요.')),
      );
      return false;
    }
    final db = ref.read(appDatabaseProvider);
    final item = await _currentHistory(db, historyId);
    if (!stillHere()) return false;
    if (item == null || item.status == 'recorded' || item.status == 'ignored') {
      final text = item?.status == 'recorded'
          ? '이미 기록한 알림이에요.'
          : item?.status == 'ignored'
              ? '제외한 알림이에요. 이력에서 다시 확인할 수 있어요.'
              : '알림을 찾을 수 없어요.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
      return false;
    }
    if (item.status != 'pending' && item.status != 'legacy') return false;

    final hasSimilarPayment = await _hasSimilarRecordedPayment(db, item);
    if (!stillHere()) return false;
    final isOldPending = item.status == 'pending' &&
        DateTime.now().difference(item.detectedAt) >= const Duration(days: 1);
    if (item.status == 'legacy') {
      final confirmed = await _confirmNotice(
        context,
        title: '이전 알림 확인',
        message: hasSimilarPayment
            ? '이전 버전에서는 기록 여부를 저장하지 않았어요. 이미 기록한 거래나 알림과 '
                '금액·상호·시간이 비슷하니 가계부 내역을 먼저 확인해 주세요.'
            : '이전 버전에서는 기록 여부를 저장하지 않아 이미 등록한 결제일 수 있어요. '
                '가계부 내역을 먼저 확인해 주세요.',
        continueLabel: '확인 후 기록',
      );
      if (!confirmed || !stillHere()) return false;
    } else if (hasSimilarPayment) {
      final confirmed = await _confirmNotice(
        context,
        title: '비슷한 결제가 있어요',
        message: '이미 기록한 거래나 알림과 금액·상호·시간이 비슷해요. '
            '같은 결제인지 확인한 뒤 진행해 주세요.',
        continueLabel: '확인 후 계속',
      );
      if (!confirmed || !stillHere()) return false;
    } else if (isOldPending) {
      final confirmed = await _confirmNotice(
        context,
        title: '오래된 알림 확인',
        message: '알림을 받은 지 하루 이상 지났어요. 이미 직접 기록한 결제일 수 있으니 '
            '가계부 내역을 먼저 확인해 주세요.',
        continueLabel: '확인 후 계속',
      );
      if (!confirmed || !stillHere()) return false;
    }
    if (item.amount <= 0 || (item.type != 'expense' && item.type != 'income')) {
      final confirmed = await _confirmNotice(
        context,
        title: '거래 정보 확인',
        message: '알림에서 금액이나 지출·수입을 확실히 읽지 못했어요. '
            '카드·은행 앱에서 금액과 취소 여부를 확인한 뒤 직접 입력해 주세요.',
        continueLabel: '직접 확인하기',
      );
      if (!confirmed || !stillHere()) return false;
    }
    if (ref.read(quickEntrySubmitStateProvider)) return false;
    final allowed = await confirmReplacingQuickEntryDraft(context, ref);
    if (!allowed || !stillHere()) return false;
    if (ref.read(quickEntrySubmitStateProvider)) return false;

    final snapshot = ref.read(quickEntryFormProvider);
    final type = item.type == 'income' ? 'income' : 'expense';
    final category = item.type == 'expense' || item.type == 'income'
        ? await findNotificationCategory(db, item.merchant, type, item.suggestedCategory)
        : null;
    if (!stillHere() || ref.read(quickEntrySubmitStateProvider) ||
        !identical(snapshot, ref.read(quickEntryFormProvider))) return false;
    final latest = await _currentHistory(db, historyId);
    if (!stillHere() || ref.read(quickEntrySubmitStateProvider) ||
        !identical(snapshot, ref.read(quickEntryFormProvider))) return false;
    if (latest == null || latest.status != item.status) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('알림 상태가 바뀌었어요. 다시 확인해 주세요.')),
      );
      return false;
    }

    final alreadyEditingPage = GoRouterState.of(context).uri.path == '/quick-entry';
    final notifier = ref.read(quickEntryFormProvider.notifier);
    notifier.reset();
    notifier.setType(type == 'income' ? TransactionEntryType.income : TransactionEntryType.expense);
    notifier.setAmount(item.amount > 0 ? item.amount.toString() : '');
    notifier.setOccurredAt(item.detectedAt);
    notifier.setNotificationOrigin(item.id, item.merchant);
    if (item.merchant?.trim().isNotEmpty == true) notifier.setMemo(item.merchant!.trim());
    if (category != null) notifier.setCategory(category);
    if (!alreadyEditingPage) context.push('/quick-entry');
    return true;
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('알림을 열지 못했어요. 다시 시도해 주세요.')),
      );
    }
    return false;
  } finally {
    _openingHistoryIds.remove(historyId);
  }
}

class _EmptyHistoryView extends StatelessWidget {
  const _EmptyHistoryView();

  @override
  Widget build(BuildContext context) {
    return const AppEmptyState(
      icon: Icons.notifications_none_rounded,
      title: '확인할 알림이 없어요',
      subtitle: '카드·은행 알림이 감지되면\n이곳에서 확인할 수 있어요.',
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.item, required this.onTap, this.onToggleIgnored});

  final NotificationHistory item;
  final VoidCallback onTap;
  final VoidCallback? onToggleIgnored;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final knownType = item.type == 'expense' || item.type == 'income';
    final isExpense = item.type == 'expense';
    final color = knownType
        ? (isExpense ? AppColors.expense : AppColors.income)
        : theme.colorScheme.onSurfaceVariant;
    final sign = isExpense ? '−' : '+';
    final dt = item.detectedAt.toLocal();
    final date = '${dt.year}/${dt.month}/${dt.day} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    final status = _statusLabel(item.status);

    return Card(
      margin: EdgeInsets.zero,
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              container: true,
              button: true,
              label: notificationHistorySemanticLabel(item),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: ExcludeSemantics(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Row(
                      children: [
                        Icon(knownType
                            ? (isExpense ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded)
                            : Icons.help_outline_rounded, color: color),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.merchant?.isNotEmpty == true ? item.merchant! : '카드·은행 알림',
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text('$date · $status', style: theme.textTheme.labelSmall),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Flexible(
                          child: Text(
                            item.amount <= 0
                                ? '금액 확인 필요'
                                : knownType
                                    ? '$sign${formatCurrency(item.amount)}'
                                    : formatCurrency(item.amount),
                            textAlign: TextAlign.right,
                            style: theme.textTheme.titleSmall?.copyWith(color: color, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (onToggleIgnored != null)
            IconButton(
              tooltip: item.status == 'ignored' ? '다시 확인하기' : '이 알림 제외',
              onPressed: onToggleIgnored,
              icon: Icon(item.status == 'ignored' ? Icons.undo_rounded : Icons.remove_circle_outline_rounded),
            ),
        ],
      ),
    );
  }
}

String _statusLabel(String status) => switch (status) {
      'pending' => '확인 필요',
      'recorded' => '기록됨',
      'ignored' => '제외됨',
      'legacy' => '이전 이력 · 등록 여부 미확인',
      _ => '상태 확인 필요',
    };

String notificationHistorySemanticLabel(NotificationHistory item) {
  final typeLabel = item.type == 'income' ? 'income' : item.type == 'expense' ? 'expense' : 'unknown type';
  final parts = <String>[
    'Notification history item',
    typeLabel,
    item.amount > 0 ? '${formatCurrency(item.amount)} won' : 'amount needs review',
    _statusLabel(item.status),
  ];
  if (item.merchant case final merchant?) parts.add('merchant $merchant');
  if (item.suggestedCategory case final suggestedCategory?) parts.add('suggested category $suggestedCategory');
  if (item.status == 'recorded') return '${parts.join(', ')}, already recorded.';
  if (item.status == 'ignored') return '${parts.join(', ')}, ignored.';
  return '${parts.join(', ')}, double tap to open quick entry.';
}
