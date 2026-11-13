import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../../../shared/widgets/glass_card.dart';
import '../application/detected_recurring_spend_provider.dart';
import '../application/recurring_spend_override_store.dart';

/// Estimates recurring spending from transactions; it does not create bills.
class DetectedRecurringSpendSection extends StatelessWidget {
  const DetectedRecurringSpendSection({super.key});

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return const SizedBox.shrink();
    return const _ActiveDetectedRecurringSpendSection();
  }
}

class _ActiveDetectedRecurringSpendSection extends ConsumerStatefulWidget {
  const _ActiveDetectedRecurringSpendSection();

  @override
  ConsumerState<_ActiveDetectedRecurringSpendSection> createState() =>
      _ActiveDetectedRecurringSpendSectionState();
}

class _ActiveDetectedRecurringSpendSectionState
    extends ConsumerState<_ActiveDetectedRecurringSpendSection>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      ref.invalidate(detectedRecurringClockProvider);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final insight = ref.watch(detectedRecurringSpendProvider);
    return insight.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const Padding(
        padding: EdgeInsets.only(top: AppSpacing.md),
        child: Text('반복 지출 분석을 불러오지 못했어요.'),
      ),
      data: (snapshot) {
        if (snapshot.groups.isEmpty && snapshot.excludedKeys.isEmpty) {
          return const SizedBox.shrink();
        }
        final theme = Theme.of(context);
        final excludedKeys = snapshot.excludedKeys.toList()..sort();
        return Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          child: GlassCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '거래에서 감지한 반복 지출',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '과거 기록을 바탕으로 추정했어요.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                for (final group in snapshot.groups)
                  Row(
                    key: ValueKey('recurring-spend-visible-${group.groupKey}'),
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(group.displayName),
                            Text(
                              '${_accountLabel(group.transactions.first.accountId, snapshot.accountNames)} · 이번 달 기록',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(formatCurrency(group.currentMonthAmount)),
                      Semantics(
                        button: true,
                        excludeSemantics: true,
                        label: '${group.displayName}, ${_accountLabel(group.transactions.first.accountId, snapshot.accountNames)}, 반복 지출에서 제외',
                        child: IconButton(
                          tooltip: '반복 지출에서 제외',
                          onPressed: () => _updateExclusion(
                            context, ref, group.groupKey, exclude: true,
                          ),
                          icon: const Icon(Icons.visibility_off_outlined),
                        ),
                      ),
                    ],
                  ),
                if (excludedKeys.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text('숨긴 반복 지출', style: theme.textTheme.titleSmall),
                  for (final key in excludedKeys)
                    Row(
                      children: [
                        Expanded(child: Text(_readableGroupName(key, snapshot.accountNames))),
                        Semantics(
                          button: true,
                          excludeSemantics: true,
                          label: '${_readableGroupName(key, snapshot.accountNames)}, 반복 지출 복구',
                          child: IconButton(
                            tooltip: '반복 지출 복구',
                            onPressed: () => _updateExclusion(
                              context, ref, key, exclude: false,
                            ),
                            icon: const Icon(Icons.restore_rounded),
                          ),
                        ),
                      ],
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  static String _readableGroupName(String key, Map<String, String> accountNames) {
    final separator = key.indexOf('|');
    final name = separator < 0 ? key : key.substring(separator + 1);
    final accountId = separator < 0 ? null : key.substring(0, separator);
    return '${name.isEmpty ? '이름 없는 항목' : name} · ${_accountLabel(accountId, accountNames)}';
  }

  static String _accountLabel(String? id, Map<String, String> names) {
    if (id == null || id.isEmpty) return '계좌 미지정';
    return names[id] ?? '계좌 $id';
  }

  static Future<void> _updateExclusion(
    BuildContext context,
    WidgetRef ref,
    String key, {
    required bool exclude,
  }) async {
    try {
      final store = ref.read(recurringSpendOverrideStoreProvider);
      if (exclude) {
        await store.markGroupNotRecurring(key);
      } else {
        await store.unmarkGroupNotRecurring(key);
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('변경 내용을 저장하지 못했어요.')),
        );
      }
    }
  }
}
