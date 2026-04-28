import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../application/quick_entry_category_actions_provider.dart';
import '../application/quick_entry_form_provider.dart';
import '../application/quick_entry_options_provider.dart';
import '../data/transaction_repository.dart';

class QuickEntryScreen extends ConsumerStatefulWidget {
  const QuickEntryScreen({super.key});

  @override
  ConsumerState<QuickEntryScreen> createState() => _QuickEntryScreenState();
}

class _QuickEntryScreenState extends ConsumerState<QuickEntryScreen> {
  late final TextEditingController _amountController;
  late final TextEditingController _memoController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _memoController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(quickEntryFormProvider);
    final isSubmitting = ref.watch(quickEntrySubmitStateProvider);
    final isEditing = form.editingId != null;
    final occurredAt = form.occurredAt ?? DateTime.now();
    final accountsAsync = ref.watch(quickEntryAccountsProvider);
    final categoriesAsync = ref.watch(
      quickEntryCategoriesProvider(_categoryTypeFor(form.type)),
    );

    _syncController(_amountController, form.amount);
    _syncController(_memoController, form.memo);

    accountsAsync.whenData((accounts) {
      if (accounts.isEmpty) {
        return;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final notifier = ref.read(quickEntryFormProvider.notifier);

        if (form.type == TransactionEntryType.transfer) {
          if (form.fromAccountId == null) {
            notifier.setFromAccount(accounts.first.id);
          }

          if (accounts.length > 1 && form.toAccountId == null) {
            notifier.setToAccount(accounts[1].id);
          }
          return;
        }

        if (form.accountId == null) {
          notifier.setAccount(accounts.first.id);
        }
      });
    });

    categoriesAsync.whenData((categories) {
      if (form.type != TransactionEntryType.transfer &&
          form.categoryId == null &&
          categories.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(quickEntryFormProvider.notifier).setCategory(categories.first.id);
        });
      }
    });

    final accountOptions = accountsAsync.asData?.value ?? const <QuickEntryAccountOption>[];
    final categoryOptions =
        categoriesAsync.asData?.value ?? const <QuickEntryCategoryOption>[];
    final selectedSourceName = _selectedAccountName(accountOptions, form.fromAccountId);
    final selectedDestinationName = _selectedAccountName(accountOptions, form.toAccountId);

    final validationMessages = <String>[
      if (form.amount.trim().isEmpty) '금액을 입력해 주세요.',
      if (form.needsTransferSource) '보내는 계좌를 선택해 주세요.',
      if (form.needsTransferDestination) '받는 계좌를 선택해 주세요.',
      if (form.hasTransferAccountConflict)
        '보내는 계좌와 받는 계좌는 서로 달라야 합니다.',
      if (form.needsCategory) '카테고리를 선택해 주세요.',
    ];

    return AppScaffold(
      title: isEditing ? '거래 수정' : '빠른 입력',
      hideGlobalQuickPanel: true,
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          if (!isEditing) ...[
            Text(
              '금액과 기본 정보만 빠르게 입력한 뒤 바로 저장할 수 있어요.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (isEditing) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.edit_outlined),
                  const SizedBox(width: AppSpacing.sm),
                  const Expanded(
                    child: Text('기존 거래를 수정 중입니다. 저장하면 현재 거래가 바로 업데이트됩니다.'),
                  ),
                  TextButton(
                    onPressed:
                        isSubmitting ? null : () => ref.read(quickEntryFormProvider.notifier).reset(),
                    child: const Text('취소'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          SegmentedButton<TransactionEntryType>(
            segments: const [
              ButtonSegment(
                value: TransactionEntryType.expense,
                label: Text('지출'),
              ),
              ButtonSegment(
                value: TransactionEntryType.income,
                label: Text('수입'),
              ),
              ButtonSegment(
                value: TransactionEntryType.transfer,
                label: Text('이체'),
              ),
            ],
            selected: {form.type},
            onSelectionChanged: (selection) {
              ref.read(quickEntryFormProvider.notifier).setType(selection.first);
            },
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '금액',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: _amountController,
                  onChanged: ref.read(quickEntryFormProvider.notifier).setAmount,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontSize: 44,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface,
                        letterSpacing: -1,
                      ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    fillColor: Colors.transparent,
                    hintText: '0',
                    hintStyle: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontSize: 44,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15),
                      letterSpacing: -1,
                    ),
                    prefixText: '₩ ',
                    prefixStyle: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                ),
                Container(
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        AppColors.primary,
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _memoController,
            onChanged: ref.read(quickEntryFormProvider.notifier).setMemo,
            decoration: const InputDecoration(labelText: '메모'),
          ),
          const SizedBox(height: AppSpacing.md),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: isSubmitting ? null : () => _pickOccurredAt(context, ref, occurredAt),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: '날짜와 시간',
                suffixIcon: Icon(Icons.schedule_outlined),
              ),
              child: Text(_formatOccurredAt(occurredAt)),
            ),
          ),
          if (form.type == TransactionEntryType.transfer) ...[
            const SizedBox(height: AppSpacing.md),
            if (accountsAsync.asData != null && accountOptions.length < 2)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _InlineWarningCard(
                  icon: Icons.account_balance_outlined,
                  title: '이체하려면 계좌가 두 개 이상 필요합니다',
                  message:
                      '계좌 사이로 돈을 옮기려면 먼저 다른 계좌를 하나 더 만들어 주세요.',
                  actionLabel: '자산 관리 열기',
                  onPressed: () => context.push('/accounts'),
                ),
              ),
            accountsAsync.when(
              data: (accounts) => Column(
                children: [
                  _AccountPickerField(
                    label: '보내는 계좌',
                    value: selectedSourceName ?? '계좌를 선택해 주세요',
                    onTap: () => _openAccountPicker(
                      context,
                      ref,
                      accounts,
                      form.fromAccountId,
                      isSource: true,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _AccountPickerField(
                    label: '받는 계좌',
                    value: selectedDestinationName ?? '계좌를 선택해 주세요',
                    onTap: () => _openAccountPicker(
                      context,
                      ref,
                      accounts,
                      form.toAccountId,
                      isSource: false,
                    ),
                  ),
                ],
              ),
              loading: () => const LinearProgressIndicator(),
              error: (error, stackTrace) => Text('계좌를 불러오지 못했습니다: $error'),
            ),
          ] else ...[
            const SizedBox(height: AppSpacing.md),
            if (categoriesAsync.asData != null && categoryOptions.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _InlineWarningCard(
                  icon: Icons.category_outlined,
                  title: '카테고리가 아직 없습니다',
                  message:
                      '${form.type == TransactionEntryType.income ? '수입' : '지출'} 카테고리를 먼저 하나 만들어 주세요.',
                  actionLabel: '카테고리 만들기',
                  onPressed: () => _createCategoryFromEmptyState(context, ref, form),
                ),
              ),
            categoriesAsync.when(
              data: (categories) {
                if (categories.isEmpty) {
                  return const SizedBox.shrink();
                }

                QuickEntryCategoryOption? selectedCategory;
                for (final item in categories) {
                  if (item.id == form.categoryId) {
                    selectedCategory = item;
                    break;
                  }
                }

                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _openCategoryPicker(context, ref, categories, form),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: '카테고리',
                      suffixIcon: Icon(Icons.expand_more),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(selectedCategory?.name ?? '카테고리를 선택해 주세요'),
                        const SizedBox(height: 4),
                        Text(
                          '길게 누르면 이름 변경이나 삭제를 할 수 있습니다.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (error, stackTrace) => Text('카테고리를 불러오지 못했습니다: $error'),
            ),
          ],
          if (validationMessages.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.expense.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.expense.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.expense),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        validationMessages.join(' '),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.expense,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 56,
            child: FilledButton(
              onPressed: form.canSubmit && !isSubmitting
                  ? () {
                      developer.log(
                        'quick_entry_submit_pressed type=${form.type} amount=${form.amount} accountId=${form.accountId} fromAccountId=${form.fromAccountId} toAccountId=${form.toAccountId} categoryId=${form.categoryId} memo=${form.memo}',
                        name: 'quick_entry',
                      );
                      _submit(context, ref, form);
                    }
                  : null,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(isEditing ? Icons.check_rounded : Icons.save_rounded, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          isEditing ? '거래 수정하기' : '거래 저장하기',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _syncController(TextEditingController controller, String value) {
    if (controller.text == value) {
      return;
    }

    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  Future<void> _openCategoryPicker(
    BuildContext context,
    WidgetRef ref,
    List<QuickEntryCategoryOption> categories,
    QuickEntryFormState form,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final state = this;
    final parentContext = context;
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final navigator = Navigator.of(context);
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final category in categories)
                ListTile(
                  title: Text(category.name),
                  selected: category.id == form.categoryId,
                  onTap: () => navigator.pop(category.id),
                  onLongPress: () => navigator.pop('__manage__${category.id}'),
                ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('카테고리 추가'),
                onTap: () => navigator.pop('__create__'),
              ),
            ],
          ),
        );
      },
    );

    if (!context.mounted || selected == null) {
      return;
    }

    if (selected == '__create__') {
      await state._showCreateCategoryDialog(
        ref,
        form,
        (ref, form) async {
          final controller = TextEditingController();
          try {
            return await showDialog<String>(
              context: parentContext,
              builder: (dialogContext) {
                return AlertDialog(
                  title: const Text('카테고리 추가'),
                  content: TextField(
                    controller: controller,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: '새 카테고리 이름',
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text('취소'),
                    ),
                    FilledButton(
                      onPressed: () async {
                        final navigator = Navigator.of(dialogContext);
                        final createdId = await ref
                            .read(quickEntryCategoryActionsProvider)
                            .createCategory(
                              name: controller.text,
                              type: _categoryTypeFor(form.type),
                            );
                        navigator.pop(createdId);
                      },
                      child: const Text('추가'),
                    ),
                  ],
                );
              },
            );
          } finally {
            controller.dispose();
          }
        },
      );
      return;
    }

    if (selected.startsWith('__manage__')) {
      final categoryId = selected.replaceFirst('__manage__', '');
      final category = categories.firstWhere((item) => item.id == categoryId);
      await state._showManageCategoryActions(context, ref, category, form, messenger);
      return;
    }

    ref.read(quickEntryFormProvider.notifier).setCategory(selected);
  }

  String? _selectedAccountName(
    List<QuickEntryAccountOption> accounts,
    String? selectedId,
  ) {
    for (final account in accounts) {
      if (account.id == selectedId) {
        return account.name;
      }
    }

    return null;
  }

  Future<void> _openAccountPicker(
    BuildContext context,
    WidgetRef ref,
    List<QuickEntryAccountOption> accounts,
    String? selectedId, {
    required bool isSource,
  }) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        final navigator = Navigator.of(context);
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final account in accounts)
                ListTile(
                  title: Text(account.name),
                  selected: account.id == selectedId,
                  onTap: () => navigator.pop(account.id),
                ),
            ],
          ),
        );
      },
    );

    if (!context.mounted || selected == null) {
      return;
    }

    final notifier = ref.read(quickEntryFormProvider.notifier);
    if (isSource) {
      notifier.setFromAccount(selected);
    } else {
      notifier.setToAccount(selected);
    }
  }

  Future<String?> _showCreateCategoryDialog(
    WidgetRef ref,
    QuickEntryFormState form,
    Future<String?> Function(WidgetRef ref, QuickEntryFormState form) openDialog,
  ) async {
    final createdId = await openDialog(ref, form);
    if (createdId != null) {
      ref.read(quickEntryFormProvider.notifier).setCategory(createdId);
    }
    return createdId;
  }

  Future<void> _showManageCategoryActions(
    BuildContext context,
    WidgetRef ref,
    QuickEntryCategoryOption category,
    QuickEntryFormState form,
    ScaffoldMessengerState messenger,
  ) async {
    final manageContext = context;
    final action = await showModalBottomSheet<String>(
      context: manageContext,
      builder: (context) {
        final navigator = Navigator.of(context);
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('이름 변경'),
                onTap: () => navigator.pop('edit'),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('삭제'),
                onTap: () => navigator.pop('delete'),
              ),
            ],
          ),
        );
      },
    );

    if (!context.mounted || action == null) {
      return;
    }

    if (action == 'edit') {
      final state = this;
      await state._showRenameCategoryDialog(context, ref, category, messenger);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: manageContext,
      builder: (context) {
        return AlertDialog(
          title: const Text('카테고리 삭제'),
          content: Text('`${category.name}` 카테고리를 삭제할까요?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );

    if (!context.mounted) {
      return;
    }

    if (confirmed == true) {
      await ref.read(quickEntryCategoryActionsProvider).deleteCategory(
            localId: category.id,
          );
      if (form.categoryId == category.id) {
        ref.read(quickEntryFormProvider.notifier).setCategory(null);
      }
    }
  }

  Future<void> _createCategoryFromEmptyState(
    BuildContext context,
    WidgetRef ref,
    QuickEntryFormState form,
  ) async {
    await _showCreateCategoryDialog(
      ref,
      form,
      (ref, form) async {
        final controller = TextEditingController();
        try {
          return await showDialog<String>(
            context: context,
            builder: (dialogContext) {
              return AlertDialog(
                title: const Text('카테고리 만들기'),
                content: TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: '새 카테고리 이름',
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('취소'),
                  ),
                  FilledButton(
                    onPressed: () async {
                      final navigator = Navigator.of(dialogContext);
                      final createdId = await ref
                          .read(quickEntryCategoryActionsProvider)
                          .createCategory(
                            name: controller.text,
                            type: _categoryTypeFor(form.type),
                          );
                      navigator.pop(createdId);
                    },
                    child: const Text('만들기'),
                  ),
                ],
              );
            },
          );
        } finally {
          controller.dispose();
        }
      },
    );
  }

  Future<void> _showRenameCategoryDialog(
    BuildContext context,
    WidgetRef ref,
    QuickEntryCategoryOption category,
    ScaffoldMessengerState messenger,
  ) async {
    final renameContext = context;
    final controller = TextEditingController(text: category.name);

    try {
      await showDialog<void>(
        context: renameContext,
        builder: (context) {
          return AlertDialog(
            title: const Text('카테고리 이름 변경'),
            content: TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: '바꿀 카테고리 이름',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('취소'),
              ),
              FilledButton(
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  try {
                    await ref.read(quickEntryCategoryActionsProvider).renameCategory(
                          localId: category.id,
                          name: controller.text,
                        );
                    navigator.pop();
                  } catch (error) {
                    messenger.showSnackBar(SnackBar(content: Text('$error')));
                  }
                },
                child: const Text('저장'),
              ),
            ],
          );
        },
      );
    } finally {
      controller.dispose();
    }
  }

  String _labelForType(TransactionEntryType type) {
    switch (type) {
      case TransactionEntryType.expense:
        return '지출';
      case TransactionEntryType.income:
        return '수입';
      case TransactionEntryType.transfer:
        return '이체';
    }
  }

  String _categoryTypeFor(TransactionEntryType type) {
    switch (type) {
      case TransactionEntryType.expense:
        return 'expense';
      case TransactionEntryType.income:
        return 'income';
      case TransactionEntryType.transfer:
        return 'transfer_reserved';
    }
  }

  Future<void> _submit(
    BuildContext context,
    WidgetRef ref,
    QuickEntryFormState form,
  ) async {
    ref.read(quickEntrySubmitStateProvider.notifier).state = true;
    developer.log(
      'quick_entry_submit_start editingId=${form.editingId} type=${form.type} amount=${form.amount} accountId=${form.accountId} fromAccountId=${form.fromAccountId} toAccountId=${form.toAccountId} categoryId=${form.categoryId} memo=${form.memo}',
      name: 'quick_entry',
    );

    try {
      if (form.editingId != null) {
        await ref.read(transactionRepositoryProvider).updateFromQuickEntry(form);
      } else {
        await ref.read(transactionRepositoryProvider).createFromQuickEntry(form);
      }
      developer.log('quick_entry_submit_success', name: 'quick_entry');
      ref.read(quickEntryFormProvider.notifier).reset();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              form.editingId != null
                  ? '${_labelForType(form.type)} 거래를 수정했습니다.'
                  : '${_labelForType(form.type)} 거래를 저장했습니다.',
            ),
          ),
        );

        if (form.editingId != null) {
          await Navigator.of(context).maybePop();
        }
      }
    } catch (error, stackTrace) {
      developer.log('quick_entry_submit_failed error=$error', name: 'quick_entry', error: error, stackTrace: stackTrace);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              form.editingId != null
                  ? '거래를 수정하지 못했습니다.'
                  : '거래를 저장하지 못했습니다.',
            ),
          ),
        );
      }
    } finally {
      ref.read(quickEntrySubmitStateProvider.notifier).state = false;
    }
  }

  Future<void> _pickOccurredAt(
    BuildContext context,
    WidgetRef ref,
    DateTime initialValue,
  ) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialValue,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null || !context.mounted) {
      return;
    }

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialValue),
    );

    if (pickedTime == null) {
      return;
    }

    ref.read(quickEntryFormProvider.notifier).setOccurredAt(
          DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          ),
        );
  }

  String _formatOccurredAt(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
  }
}

class _AccountPickerField extends StatelessWidget {
  const _AccountPickerField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.expand_more),
        ),
        child: Text(value),
      ),
    );
  }
}

class _InlineWarningCard extends StatelessWidget {
  const _InlineWarningCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(message),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton(
              onPressed: onPressed,
              child: Text(actionLabel),
            ),
          ),
        ],
      ),
    );
  }
}
