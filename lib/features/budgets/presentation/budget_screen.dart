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
                          color: AppColors.primary,
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
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Text(
                        categorizedItems.isEmpty
                            ? '어디에 얼마나 쓰는지 나눠보면 확실히 보여요.'
                            : '${categorizedItems.length}개 항목을 나눠서 보고 있어요.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    if (categorizedItems.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '아직 카테고리 예산이 없어요',
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                '식비, 교통비처럼 관리가 필요한 항목부터 추가해 보세요.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
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
          return StatefulBuilder(
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
    return AppColors.primary;
  }

  String _overallBudgetMessage(int totalBudget, int totalSpent) {
    if (totalBudget <= 0) {
      return '전체 예산부터 정하면, 나눠 쓰기가 훨씬 편해져요.';
    }

    final progress = totalSpent / totalBudget;
    if (progress >= 1) {
      return '이번 달 예산을 넘었어요. 한도를 다시 한번 봐요.';
    }
    if (progress >= 0.8) {
      return '거의 다 썼어요. 남은 날들을 조금만 더 아껴봐요.';
    }

    return '잘 하고 있어요. 이 속도면 충분해요.';
  }

  String _categoryBudgetMessage(double progress) {
    if (progress >= 1) {
      return '이 항목은 예산을 넘었어요';
    }
    if (progress >= 0.8) {
      return '거의 다 왔어요, 조심히 써요';
    }
    if (progress <= 0) {
      return '아직 한 번도 안 썼어요';
    }

    return '예산 안에서 잘 쓰고 있어요';
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
