import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../shared/widgets/app_hero_panel.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/app_status_chip.dart';
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
    final selectedAccountName = _selectedAccountName(accountOptions, form.accountId);
    final selectedSourceName = _selectedAccountName(accountOptions, form.fromAccountId);
    final selectedDestinationName = _selectedAccountName(accountOptions, form.toAccountId);
    final selectedCategoryName = _selectedCategoryName(categoryOptions, form.categoryId);
    final validationMessages = _validationMessages(form);

    return AppScaffold(
      title: isEditing ? '거래 수정' : '빠른 입력',
      hideGlobalQuickPanel: true,
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        children: [
          AppHeroPanel(
            eyebrow: AppStatusChip(
              label: isEditing ? 'EDIT ENTRY' : 'EXPANDED ENTRY',
              dotColor: isEditing ? AppColors.primary : _chipColorFor(form.type),
            ),
            title: _heroTitleFor(form.type, isEditing),
            body: _heroBodyFor(form.type, isEditing),
            footer: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                AppStatusChip(
                  label: _labelForType(form.type),
                  dotColor: _chipColorFor(form.type),
                ),
                AppStatusChip(
                  label: _heroDateLabel(occurredAt),
                  foregroundColor: Colors.white.withValues(alpha: 0.88),
                  backgroundColor: Colors.white.withValues(alpha: 0.06),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (isEditing) ...[
            _EditingBanner(
              isSubmitting: isSubmitting,
              onReset: () => ref.read(quickEntryFormProvider.notifier).reset(),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          const _CompactSectionHeader(
            title: '기록 방식',
            subtitle: '지금 흐름에 맞는 종류만 먼저 고르면 아래 입력이 자연스럽게 따라옵니다.',
          ),
          const SizedBox(height: AppSpacing.sm),
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
          const SizedBox(height: AppSpacing.lg),
          _AmountPanel(
            controller: _amountController,
            memoController: _memoController,
            form: form,
            occurredAt: occurredAt,
            selectedAccountName: selectedAccountName,
            selectedSourceName: selectedSourceName,
            selectedDestinationName: selectedDestinationName,
            selectedCategoryName: selectedCategoryName,
            onAmountChanged: ref.read(quickEntryFormProvider.notifier).setAmount,
            onMemoChanged: ref.read(quickEntryFormProvider.notifier).setMemo,
          ),
          const SizedBox(height: AppSpacing.lg),
          const _CompactSectionHeader(
            title: '기록을 마무리할 정보',
            subtitle: '핵심 입력은 이미 끝났고, 이제 어디에서 생긴 흐름인지 붙여주면 다시 찾기 쉬워집니다.',
          ),
          const SizedBox(height: AppSpacing.sm),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  _PickerField(
                    label: '날짜와 시간',
                    value: _formatOccurredAt(occurredAt),
                    icon: Icons.schedule_outlined,
                    onTap: isSubmitting
                        ? null
                        : () => _pickOccurredAt(context, ref, occurredAt),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (form.type == TransactionEntryType.transfer) ...[
                    if (accountsAsync.asData != null && accountOptions.length < 2)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: _InlineWarningCard(
                          icon: Icons.account_balance_outlined,
                          title: '이체를 기록하려면 계좌가 두 개 이상 있어야 해요.',
                          message:
                              '보내는 곳과 받는 곳이 나뉘어야 흐름이 또렷해져요. 자주 쓰는 계좌를 하나 더 만들어두면 바로 이어서 기록할 수 있어요.',
                          actionLabel: '계좌 관리 열기',
                          onPressed: () => context.push('/accounts'),
                        ),
                      ),
                    accountsAsync.when(
                      data: (accounts) => Column(
                        children: [
                          _PickerField(
                            label: '보내는 계좌',
                            value: selectedSourceName ?? '계좌를 선택해 주세요',
                            icon: Icons.call_made_rounded,
                            onTap: () => _openTransferAccountPicker(
                              context,
                              ref,
                              accounts,
                              form.fromAccountId,
                              isSource: true,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _PickerField(
                            label: '받는 계좌',
                            value: selectedDestinationName ?? '계좌를 선택해 주세요',
                            icon: Icons.call_received_rounded,
                            onTap: () => _openTransferAccountPicker(
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
                      error: (error, stackTrace) =>
                          _InlineErrorText(message: '계좌를 불러오지 못했어요. $error'),
                    ),
                  ] else ...[
                    if (accountsAsync.asData != null && accountOptions.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: _InlineWarningCard(
                          icon: Icons.account_balance_wallet_outlined,
                          title: '먼저 연결할 계좌가 필요해요.',
                          message:
                              '현금, 카드, 통장 중에서 자주 쓰는 흐름 하나만 먼저 만들어도 기록은 바로 이어갈 수 있어요.',
                          actionLabel: '계좌 관리 열기',
                          onPressed: () => context.push('/accounts'),
                        ),
                      ),
                    accountsAsync.when(
                      data: (accounts) {
                        if (accounts.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        return _PickerField(
                          label: '기록할 계좌',
                          value: selectedAccountName ?? '계좌를 선택해 주세요',
                          icon: Icons.account_balance_wallet_outlined,
                          onTap: () => _openSingleAccountPicker(
                            context,
                            ref,
                            accounts,
                            form.accountId,
                          ),
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (error, stackTrace) =>
                          _InlineErrorText(message: '계좌를 불러오지 못했어요. $error'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (categoriesAsync.asData != null && categoryOptions.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: _InlineWarningCard(
                          icon: Icons.category_outlined,
                          title: '이 흐름을 담을 카테고리가 아직 없어요.',
                          message:
                              '${form.type == TransactionEntryType.income ? '수입' : '지출'} 카테고리를 하나만 만들어두면 같은 기록이 다음부터 훨씬 빨라집니다.',
                          actionLabel: '카테고리 만들기',
                          onPressed: () => _createCategoryFromEmptyState(
                            context,
                            ref,
                            form,
                          ),
                        ),
                      ),
                    categoriesAsync.when(
                      data: (categories) {
                        if (categories.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        return _PickerField(
                          label: '카테고리',
                          value: selectedCategoryName ?? '카테고리를 선택해 주세요',
                          icon: Icons.category_outlined,
                          helper:
                              '길게 누르면 이름을 고치거나 지울 수 있고, 아래 목록에서 바로 새 카테고리도 만들 수 있어요.',
                          onTap: () => _openCategoryPicker(
                            context,
                            ref,
                            categories,
                            form,
                          ),
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (error, stackTrace) =>
                          _InlineErrorText(message: '카테고리를 불러오지 못했어요. $error'),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _EntryReadinessCard(
            form: form,
            occurredAt: occurredAt,
            selectedAccountName: selectedAccountName,
            selectedSourceName: selectedSourceName,
            selectedDestinationName: selectedDestinationName,
            selectedCategoryName: selectedCategoryName,
            validationMessages: validationMessages,
          ),
          if (validationMessages.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _ValidationCard(messages: validationMessages),
          ],
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
                        Icon(
                          isEditing ? Icons.check_rounded : Icons.save_rounded,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isEditing ? '거래 수정하기' : '거래 저장하기',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _validationMessages(QuickEntryFormState form) {
    return <String>[
      if (form.amount.trim().isEmpty) '금액을 먼저 적어 주세요.',
      if (form.type != TransactionEntryType.transfer && form.needsAccount)
        '어느 계좌의 흐름인지 선택해 주세요.',
      if (form.needsTransferSource) '보내는 계좌를 골라 주세요.',
      if (form.needsTransferDestination) '받는 계좌를 골라 주세요.',
      if (form.hasTransferAccountConflict) '보내는 계좌와 받는 계좌는 서로 달라야 해요.',
    ];
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

  Future<void> _openSingleAccountPicker(
    BuildContext context,
    WidgetRef ref,
    List<QuickEntryAccountOption> accounts,
    String? selectedId,
  ) async {
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

    ref.read(quickEntryFormProvider.notifier).setAccount(selected);
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

  String? _selectedCategoryName(
    List<QuickEntryCategoryOption> categories,
    String? selectedId,
  ) {
    for (final category in categories) {
      if (category.id == selectedId) {
        return category.name;
      }
    }

    return null;
  }

  Future<void> _openTransferAccountPicker(
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

  String _heroTitleFor(TransactionEntryType type, bool isEditing) {
    if (isEditing) {
      return '${_labelForType(type)} 기록을 차분하게 다듬고 있어요';
    }

    switch (type) {
      case TransactionEntryType.expense:
        return '지출 흐름을 조금 더 또렷하게 남겨둘게요';
      case TransactionEntryType.income:
        return '들어온 흐름을 놓치지 않게 바로 적어둘게요';
      case TransactionEntryType.transfer:
        return '계좌 사이의 움직임을 한 번에 정리할 수 있어요';
    }
  }

  String _heroBodyFor(TransactionEntryType type, bool isEditing) {
    if (isEditing) {
      return '금액은 그대로 중심에 두고, 메모와 계좌만 다시 맞춰도 기록은 곧바로 반영됩니다.';
    }

    switch (type) {
      case TransactionEntryType.expense:
        return '급하게 적은 전역 입력을 여기서 한 번만 다듬으면, 나중에 다시 찾을 때 훨씬 덜 헷갈립니다.';
      case TransactionEntryType.income:
        return '수입 기록은 타이밍이 중요해요. 금액부터 붙잡고, 필요한 정보만 짧게 이어서 채우면 충분합니다.';
      case TransactionEntryType.transfer:
        return '보내는 곳과 받는 곳만 명확하면 이체 기록은 빠르게 끝낼 수 있어요. 흐름이 끊기지 않게 핵심만 남겨둘게요.';
    }
  }

  Color _chipColorFor(TransactionEntryType type) {
    switch (type) {
      case TransactionEntryType.expense:
        return AppColors.expense;
      case TransactionEntryType.income:
        return AppColors.income;
      case TransactionEntryType.transfer:
        return AppColors.primary;
    }
  }

  String _heroDateLabel(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$month.$day $hour:$minute';
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
                  ? '${_labelForType(form.type)} 거래를 수정했어요.'
                  : '${_labelForType(form.type)} 거래를 저장했어요.',
            ),
          ),
        );

        if (form.editingId != null) {
          await Navigator.of(context).maybePop();
        }
      }
    } catch (error, stackTrace) {
      developer.log(
        'quick_entry_submit_failed error=$error',
        name: 'quick_entry',
        error: error,
        stackTrace: stackTrace,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              form.editingId != null
                  ? '거래를 수정하지 못했어요.'
                  : '거래를 저장하지 못했어요.',
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

class _EditingBanner extends StatelessWidget {
  const _EditingBanner({
    required this.isSubmitting,
    required this.onReset,
  });

  final bool isSubmitting;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          const Icon(Icons.edit_outlined),
          const SizedBox(width: AppSpacing.sm),
          const Expanded(
            child: Text(
              '기존 거래를 다듬는 중이에요. 저장하면 바로 현재 기록으로 반영됩니다.',
            ),
          ),
          TextButton(
            onPressed: isSubmitting ? null : onReset,
            child: const Text('취소'),
          ),
        ],
      ),
    );
  }
}

class _CompactSectionHeader extends StatelessWidget {
  const _CompactSectionHeader({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
          ),
        ),
      ],
    );
  }
}

class _AmountPanel extends StatelessWidget {
  const _AmountPanel({
    required this.controller,
    required this.memoController,
    required this.form,
    required this.occurredAt,
    required this.selectedAccountName,
    required this.selectedSourceName,
    required this.selectedDestinationName,
    required this.selectedCategoryName,
    required this.onAmountChanged,
    required this.onMemoChanged,
  });

  final TextEditingController controller;
  final TextEditingController memoController;
  final QuickEntryFormState form;
  final DateTime occurredAt;
  final String? selectedAccountName;
  final String? selectedSourceName;
  final String? selectedDestinationName;
  final String? selectedCategoryName;
  final ValueChanged<String> onAmountChanged;
  final ValueChanged<String> onMemoChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '금액',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.48),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: controller,
              onChanged: onAmountChanged,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineLarge?.copyWith(
                    fontSize: 46,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: -1.2,
                  ),
              decoration: InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                fillColor: Colors.transparent,
                hintText: '0',
                hintStyle: theme.textTheme.headlineLarge?.copyWith(
                  fontSize: 46,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.14),
                  letterSpacing: -1.2,
                ),
                prefixText: '₩ ',
                prefixStyle: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.44),
                ),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: memoController,
              onChanged: onMemoChanged,
              maxLines: 2,
              minLines: 1,
              decoration: const InputDecoration(
                labelText: '메모',
                hintText: '예: 점심, 병원, 급여, 카드값 정리',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: _summaryChips(
                  occurredAt: occurredAt,
                  selectedAccountName: selectedAccountName,
                  selectedSourceName: selectedSourceName,
                  selectedDestinationName: selectedDestinationName,
                  selectedCategoryName: selectedCategoryName,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _summaryChips({
    required DateTime occurredAt,
    required String? selectedAccountName,
    required String? selectedSourceName,
    required String? selectedDestinationName,
    required String? selectedCategoryName,
  }) {
    final chips = <Widget>[
      _SoftChip(
        icon: Icons.schedule_outlined,
        label:
            '${occurredAt.month.toString().padLeft(2, '0')}.${occurredAt.day.toString().padLeft(2, '0')} ${occurredAt.hour.toString().padLeft(2, '0')}:${occurredAt.minute.toString().padLeft(2, '0')}',
      ),
    ];

    if (form.type == TransactionEntryType.transfer) {
      if (selectedSourceName != null) {
        chips.add(
          _SoftChip(
            icon: Icons.call_made_rounded,
            label: selectedSourceName,
          ),
        );
      }
      if (selectedDestinationName != null) {
        chips.add(
          _SoftChip(
            icon: Icons.call_received_rounded,
            label: selectedDestinationName,
          ),
        );
      }
      return chips;
    }

    if (selectedAccountName != null) {
      chips.add(
        _SoftChip(
          icon: Icons.account_balance_wallet_outlined,
          label: selectedAccountName,
        ),
      );
    }
    if (selectedCategoryName != null) {
      chips.add(
        _SoftChip(
          icon: Icons.category_outlined,
          label: selectedCategoryName,
        ),
      );
    }
    return chips;
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    this.helper,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: const Icon(Icons.expand_more),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value),
            if (helper != null) ...[
              const SizedBox(height: 4),
              Text(
                helper!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.54),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SoftChip extends StatelessWidget {
  const _SoftChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.softHighlight.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _EntryReadinessCard extends StatelessWidget {
  const _EntryReadinessCard({
    required this.form,
    required this.occurredAt,
    required this.selectedAccountName,
    required this.selectedSourceName,
    required this.selectedDestinationName,
    required this.selectedCategoryName,
    required this.validationMessages,
  });

  final QuickEntryFormState form;
  final DateTime occurredAt;
  final String? selectedAccountName;
  final String? selectedSourceName;
  final String? selectedDestinationName;
  final String? selectedCategoryName;
  final List<String> validationMessages;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isReady = validationMessages.isEmpty && form.amount.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isReady
            ? AppColors.income.withValues(alpha: 0.08)
            : AppColors.softHighlight.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isReady
              ? AppColors.income.withValues(alpha: 0.18)
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isReady ? '지금 저장해도 흐름이 충분히 남아요' : '저장 전에 이것만 가볍게 확인할게요',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            isReady
                ? '핵심 정보가 이미 붙어 있어서, 지금 저장하면 나중에 다시 찾을 때도 흐름이 바로 이어집니다.'
                : '지금 입력은 잘 이어지고 있어요. 아래 빠진 항목만 채우면 같은 자리에서 바로 저장할 수 있어요.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _SoftChip(
                icon: Icons.swap_horiz_rounded,
                label: _typeLabel(form.type),
              ),
              _SoftChip(
                icon: Icons.schedule_outlined,
                label:
                    '${occurredAt.month.toString().padLeft(2, '0')}.${occurredAt.day.toString().padLeft(2, '0')} ${occurredAt.hour.toString().padLeft(2, '0')}:${occurredAt.minute.toString().padLeft(2, '0')}',
              ),
              if (form.type == TransactionEntryType.transfer) ...[
                if (selectedSourceName != null)
                  _SoftChip(
                    icon: Icons.call_made_rounded,
                    label: selectedSourceName!,
                  ),
                if (selectedDestinationName != null)
                  _SoftChip(
                    icon: Icons.call_received_rounded,
                    label: selectedDestinationName!,
                  ),
              ] else ...[
                if (selectedAccountName != null)
                  _SoftChip(
                    icon: Icons.account_balance_wallet_outlined,
                    label: selectedAccountName!,
                  ),
                if (selectedCategoryName != null)
                  _SoftChip(
                    icon: Icons.category_outlined,
                    label: selectedCategoryName!,
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _typeLabel(TransactionEntryType type) {
    switch (type) {
      case TransactionEntryType.expense:
        return '지출';
      case TransactionEntryType.income:
        return '수입';
      case TransactionEntryType.transfer:
        return '이체';
    }
  }
}

class _ValidationCard extends StatelessWidget {
  const _ValidationCard({required this.messages});

  final List<String> messages;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.expense.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.expense.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.info_outline_rounded,
              size: 16,
              color: AppColors.expense,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              messages.join(' '),
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.expense,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineErrorText extends StatelessWidget {
  const _InlineErrorText({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.expense,
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
        borderRadius: BorderRadius.circular(AppRadius.lg),
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
