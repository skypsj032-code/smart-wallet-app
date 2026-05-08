import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../../../shared/widgets/app_section.dart';
import '../application/budget_provider.dart';
import 'budget_setup_dialog.dart';

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(budgetSummaryProvider);
    final categoryOptionsAsync = ref.watch(budgetCategoryOptionsProvider);

    return AppScaffold(
      title: '예산',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => BudgetSetupDialog.show(context),
        icon: const Icon(Icons.add),
        label: const Text('추가'),
      ),
      body: summaryAsync.when(
        data: (summary) {
          final theme = Theme.of(context);
          final categorizedItems = summary.items.where((item) => item.categoryId != null).toList();
          final overallBudgetAmount = _findBudgetAmount(summary.items, null);
          final totalProgress = summary.totalBudget <= 0
              ? 0.0
              : (summary.totalSpent / summary.totalBudget).clamp(0, 1).toDouble();

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              AppSection(
                title: '이번 달 예산',
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          summary.monthKey,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          formatCurrency(summary.totalBudget),
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          _overallBudgetMessage(summary.totalBudget, summary.totalSpent),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        LinearProgressIndicator(
                          value: totalProgress,
                          minHeight: 12,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                          color: _progressColor(totalProgress),
                          backgroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Expanded(
                              child: _BudgetStatTile(
                                label: '사용',
                                amount: formatCurrency(summary.totalSpent),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: _BudgetStatTile(
                                label: '남음',
                                amount: formatCurrency(summary.remaining),
                                valueColor: null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.tonalIcon(
                            onPressed: categoryOptionsAsync.hasValue
                                ? () => _openBudgetEditor(
                                      context,
                                      ref,
                                      monthKey: summary.monthKey,
                                      categories: categoryOptionsAsync.value!,
                                      initialCategoryId: null,
                                      initialAmount: overallBudgetAmount,
                                    )
                                : null,
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('전체 예산 수정'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppSection(
                title: '카테고리 예산',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.xs),
                    // 카테고리 예산 비교 차트 (2개 이상일 때만 표시)
                    if (categorizedItems.length >= 2) ...[
                      _CategoryBudgetChartCard(items: categorizedItems),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    if (categorizedItems.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '카테고리 예산 없음',
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              OutlinedButton.icon(
                                onPressed: categoryOptionsAsync.hasValue
                                    ? () => _openBudgetEditor(
                                          context,
                                          ref,
                                          monthKey: summary.monthKey,
                                          categories: categoryOptionsAsync.value!,
                                        )
                                    : null,
                                icon: const Icon(Icons.add),
                                label: const Text('카테고리 예산 추가'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    for (final item in categorizedItems) ...[
                      Card(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: categoryOptionsAsync.hasValue
                              ? () => _openBudgetEditor(
                                    context,
                                    ref,
                                    monthKey: summary.monthKey,
                                    categories: categoryOptionsAsync.value!,
                                    initialCategoryId: item.categoryId,
                                    initialAmount: item.limitAmount,
                                  )
                              : null,
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.label,
                                            style: theme.textTheme.titleMedium,
                                          ),
                                          const SizedBox(height: AppSpacing.xs),
                                          Text(
                                            _categoryBudgetMessage(item.progress),
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: theme.colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Text(
                                      formatCurrency(item.limitAmount),
                                      style: theme.textTheme.titleMedium,
                                    ),
                                    PopupMenuButton<String>(
                                      onSelected: (value) async {
                                        if (value == 'edit' && categoryOptionsAsync.hasValue) {
                                          _openBudgetEditor(
                                            context,
                                            ref,
                                            monthKey: summary.monthKey,
                                            categories: categoryOptionsAsync.value!,
                                            initialCategoryId: item.categoryId,
                                            initialAmount: item.limitAmount,
                                          );
                                          return;
                                        }

                                        if (value == 'delete') {
                                          final confirmed = await showDialog<bool>(
                                            context: context,
                                            builder: (dialogContext) {
                                              return AlertDialog(
                                                title: const Text('예산 삭제'),
                                                content: Text('${item.label} 예산을 삭제할까요?'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(dialogContext).pop(false),
                                                    child: const Text('취소'),
                                                  ),
                                                  FilledButton(
                                                    onPressed: () =>
                                                        Navigator.of(dialogContext).pop(true),
                                                    child: const Text('삭제'),
                                                  ),
                                                ],
                                              );
                                            },
                                          );

                                          if (confirmed != true || !context.mounted) {
                                            return;
                                          }

                                          await ref.read(budgetEditorServiceProvider).deleteBudget(
                                                monthKey: summary.monthKey,
                                                categoryId: item.categoryId,
                                              );

                                          if (!context.mounted) {
                                            return;
                                          }

                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('${item.label} 예산을 삭제했습니다.')),
                                          );
                                        }
                                      },
                                      itemBuilder: (context) => const [
                                        PopupMenuItem<String>(
                                          value: 'edit',
                                          child: Text('수정'),
                                        ),
                                        PopupMenuItem<String>(
                                          value: 'delete',
                                          child: Text('삭제'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.md),
                                LinearProgressIndicator(
                                  value: item.progress.clamp(0, 1),
                                  minHeight: 12,
                                  borderRadius: BorderRadius.circular(AppRadius.full),
                                  color: _progressColor(item.progress),
                                  backgroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _BudgetStatTile(
                                        label: '사용',
                                        amount: formatCurrency(item.spentAmount),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: _BudgetStatTile(
                                        label: '남음',
                                        amount: formatCurrency(item.remaining),
                                        valueColor: null,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text('예산 화면을 불러오지 못했습니다.\n$error'),
          ),
        ),
      ),
    );
  }

  Future<void> _openBudgetEditor(
    BuildContext context,
    WidgetRef ref, {
    required String monthKey,
    required List<BudgetCategoryOption> categories,
    String? initialCategoryId,
    int? initialAmount,
  }) async {
    final amountController =
        TextEditingController(text: initialAmount == null ? '' : initialAmount.toString());
    String? selectedCategoryId = initialCategoryId ?? (categories.isEmpty ? null : categories.first.id);
    var useOverallBudget = initialCategoryId == null;

    try {
      final result = await showDialog<_BudgetEditorResult>(
        context: context,
        builder: (dialogContext) {
          return AnimatedPadding(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(dialogContext).viewInsets.bottom,
            ),
            child: StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text(initialAmount == null ? '예산 추가' : '예산 수정'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SwitchListTile(
                        value: useOverallBudget,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('전체 예산으로 설정'),
                        onChanged: (value) {
                          setState(() {
                            useOverallBudget = value;
                          });
                        },
                      ),
                      if (!useOverallBudget) ...[
                        const SizedBox(height: AppSpacing.sm),
                        DropdownButtonFormField<String>(
                          initialValue: selectedCategoryId,
                          decoration: const InputDecoration(labelText: '카테고리'),
                          items: [
                            for (final category in categories)
                              DropdownMenuItem<String>(
                                value: category.id,
                                child: Text(category.name),
                              ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedCategoryId = value;
                            });
                          },
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: '예산 금액',
                          prefixText: '₩ ',
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('취소'),
                  ),
                  FilledButton(
                    onPressed: () {
                      final amount = int.tryParse(amountController.text.trim());
                      if (amount == null || amount <= 0) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(content: Text('0보다 큰 예산 금액을 입력해 주세요.')),
                        );
                        return;
                      }

                      if (!useOverallBudget && selectedCategoryId == null) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(content: Text('카테고리를 선택해 주세요.')),
                        );
                        return;
                      }

                      Navigator.of(dialogContext).pop(
                        _BudgetEditorResult(
                          categoryId: useOverallBudget ? null : selectedCategoryId,
                          amountLimit: amount,
                        ),
                      );
                    },
                    child: const Text('저장'),
                  ),
                ],
              );
            },
            ),
          );
        },
      );

      if (result == null) {
        return;
      }

      await ref.read(budgetEditorServiceProvider).saveBudget(
            monthKey: monthKey,
            categoryId: result.categoryId,
            amountLimit: result.amountLimit,
          );

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('예산이 저장되었습니다.')),
      );
    } finally {
      amountController.dispose();
    }
  }

  Color _progressColor(double progress) {
    if (progress >= 1) return AppColors.expense;
    if (progress >= 0.8) return AppColors.warning;
    return AppColors.primary;
  }

  String _overallBudgetMessage(int totalBudget, int totalSpent) {
    if (totalBudget <= 0) return '예산 미설정';
    final progress = totalSpent / totalBudget;
    if (progress >= 1) return '예산 초과';
    if (progress >= 0.8) return '80% 이상 사용';
    return '${(progress * 100).round()}% 사용';
  }

  String _categoryBudgetMessage(double progress) {
    if (progress >= 1) return '예산 초과';
    if (progress >= 0.8) return '80% 이상 사용';
    if (progress <= 0) return '미사용';
    return '${(progress * 100).round()}% 사용';
  }

  int? _findBudgetAmount(List<BudgetSummaryItem> items, String? categoryId) {
    for (final item in items) {
      if (item.categoryId == categoryId) {
        return item.limitAmount;
      }
    }

    return null;
  }
}

class _BudgetEditorResult {
  const _BudgetEditorResult({
    required this.categoryId,
    required this.amountLimit,
  });

  final String? categoryId;
  final int amountLimit;
}

/// 카테고리별 예산 사용량을 수평 막대 차트로 보여주는 요약 카드
class _CategoryBudgetChartCard extends StatelessWidget {
  const _CategoryBudgetChartCard({required this.items});

  final List<BudgetSummaryItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 사용률 내림차순 정렬
    final sorted = [...items]..sort((a, b) => b.progress.compareTo(a.progress));
    // 최대 limitAmount 기준으로 막대 너비 비율 산정
    final maxLimit = sorted.fold(1, (m, i) => i.limitAmount > m ? i.limitAmount : m);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '카테고리 비교',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ...sorted.map((item) {
              final barColor = _progressColor(item.progress);
              final spentRatio = (item.spentAmount / maxLimit).clamp(0.0, 1.0);
              final limitRatio = (item.limitAmount / maxLimit).clamp(0.0, 1.0);

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.label,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${formatCurrency(item.spentAmount)} / ${formatCurrency(item.limitAmount)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          item.progress >= 1
                              ? '초과!'
                              : '${(item.progress * 100).round()}%',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: barColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final totalWidth = constraints.maxWidth;
                        return Stack(
                          children: [
                            // 예산 한도 배경
                            Container(
                              width: totalWidth * limitRatio,
                              height: 8,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(AppRadius.full),
                              ),
                            ),
                            // 사용량 막대
                            Container(
                              width: totalWidth * spentRatio,
                              height: 8,
                              decoration: BoxDecoration(
                                color: barColor,
                                borderRadius: BorderRadius.circular(AppRadius.full),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Color _progressColor(double progress) {
    if (progress >= 1) return AppColors.expense;
    if (progress >= 0.8) return AppColors.warning;
    return AppColors.primary;
  }
}

class _BudgetStatTile extends StatelessWidget {
  const _BudgetStatTile({
    required this.label,
    required this.amount,
    this.valueColor,
  });

  final String label;
  final String amount;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              amount,
              style: theme.textTheme.titleMedium?.copyWith(color: valueColor),
            ),
          ],
        ),
      ),
    );
  }
}
