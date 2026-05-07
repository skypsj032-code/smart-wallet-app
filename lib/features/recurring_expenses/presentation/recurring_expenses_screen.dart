import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/app_section_intro.dart';
import '../../accounts/application/accounts_provider.dart';
import '../../budgets/application/budget_provider.dart';
import '../application/recurring_expense_service.dart';

class RecurringExpensesScreen extends ConsumerWidget {
  const RecurringExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recurringAsync = ref.watch(activeRecurringExpensesProvider);

    return AppScaffold(
      title: '정기 거래',
      body: recurringAsync.when(
        data: (items) {
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              const AppSectionIntro(
                title: '반복되는 수입과 지출을 미리 준비해요',
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                onPressed: () => _showEditor(context, ref),
                icon: const Icon(Icons.add_rounded),
                label: const Text('정기 거래 추가'),
              ),
              const SizedBox(height: AppSpacing.md),
              if (items.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Text('아직 등록된 정기 거래가 없습니다.'),
                  ),
                )
              else
                for (final item in items) ...[
                  _RecurringExpenseTile(item: item),
                  const SizedBox(height: AppSpacing.sm),
                ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text('정기 거래를 불러오지 못했습니다.\n$error'),
          ),
        ),
      ),
    );
  }

  Future<void> _showEditor(
    BuildContext context,
    WidgetRef ref, {
    RecurringExpense? existing,
  }) async {
    final result = await showDialog<_RecurringExpenseEditorResult>(
      context: context,
      builder: (dialogContext) {
        return _RecurringExpenseEditorDialog(existing: existing);
      },
    );

    if (result == null || !context.mounted) {
      return;
    }

    final service = ref.read(recurringExpenseServiceProvider);
    if (existing == null) {
      await service.createRecurringTransaction(
        name: result.name,
        type: result.type,
        amount: result.amount,
        cadence: result.cadence,
        dayOfMonth: result.dayOfMonth,
        weekday: result.weekday,
        accountId: result.accountId,
        categoryId: result.categoryId,
      );
    } else {
      await service.updateRecurringTransaction(
        localId: existing.localId,
        name: result.name,
        type: result.type,
        amount: result.amount,
        cadence: result.cadence,
        dayOfMonth: result.dayOfMonth,
        weekday: result.weekday,
        accountId: result.accountId,
        categoryId: result.categoryId,
      );
    }

    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          existing == null ? '정기 거래를 추가했습니다.' : '정기 거래를 수정했습니다.',
        ),
      ),
    );
  }
}

class _RecurringExpenseTile extends ConsumerWidget {
  const _RecurringExpenseTile({required this.item});

  final RecurringExpense item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        title: Text(item.name),
        subtitle: Text(
          '${_typeLabel(item.type)} · ${_scheduleLabel(item)} · ${formatCurrency(item.amount)}',
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'edit') {
              await const RecurringExpensesScreen()
                  ._showEditor(context, ref, existing: item);
            } else if (value == 'delete') {
              await ref
                  .read(recurringExpenseServiceProvider)
                  .deactivate(item.localId);
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'edit', child: Text('수정')),
            PopupMenuItem(value: 'delete', child: Text('비활성화')),
          ],
        ),
      ),
    );
  }

  String _scheduleLabel(RecurringExpense item) {
    if (item.cadence == 'weekly') {
      return '매주 ${_weekdayLabel(item.weekday ?? DateTime.monday)}';
    }
    return '매달 ${item.dayOfMonth ?? 1}일';
  }

  String _typeLabel(String type) {
    return type == 'income' ? '수입' : '지출';
  }
}

class _RecurringExpenseEditorDialog extends ConsumerStatefulWidget {
  const _RecurringExpenseEditorDialog({this.existing});

  final RecurringExpense? existing;

  @override
  ConsumerState<_RecurringExpenseEditorDialog> createState() =>
      _RecurringExpenseEditorDialogState();
}

class _RecurringExpenseEditorDialogState
    extends ConsumerState<_RecurringExpenseEditorDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  late final TextEditingController _dayController;
  late String _type;
  late String _cadence;
  int _weekday = DateTime.monday;
  String? _accountId;
  String? _categoryId;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _amountController =
        TextEditingController(text: existing?.amount.toString() ?? '');
    _dayController = TextEditingController(
      text: (existing?.dayOfMonth ?? 1).toString(),
    );
    _type = existing?.type ?? 'expense';
    _cadence = existing?.cadence ?? 'monthly';
    _weekday = existing?.weekday ?? DateTime.monday;
    _accountId = existing?.accountId;
    _categoryId = existing?.categoryId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _dayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsStreamProvider).valueOrNull ?? const [];
    final categories =
        ref.watch(budgetCategoryOptionsProvider).valueOrNull ?? const [];
    _accountId ??= accounts.isEmpty ? null : accounts.first.localId;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: AlertDialog(
        title: Text(widget.existing == null ? '정기 거래 추가' : '정기 거래 수정'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'expense', label: Text('지출')),
                  ButtonSegment(value: 'income', label: Text('수입')),
                ],
                selected: {_type},
                onSelectionChanged: (selection) {
                  setState(() => _type = selection.first);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: '이름'),
                textInputAction: TextInputAction.next,
              ),
              TextField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: '금액'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.sm),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'monthly', label: Text('매달')),
                  ButtonSegment(value: 'weekly', label: Text('매주')),
                ],
                selected: {_cadence},
                onSelectionChanged: (selection) {
                  setState(() => _cadence = selection.first);
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              if (_cadence == 'monthly')
                TextField(
                  controller: _dayController,
                  decoration: const InputDecoration(labelText: '매달 날짜'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(2),
                  ],
                  textInputAction: TextInputAction.next,
                )
              else
                DropdownButtonFormField<int>(
                  initialValue: _weekday,
                  decoration: const InputDecoration(labelText: '요일'),
                  items: [
                    for (var value = DateTime.monday;
                        value <= DateTime.sunday;
                        value++)
                      DropdownMenuItem(
                        value: value,
                        child: Text(_weekdayLabel(value)),
                      ),
                  ],
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() => _weekday = value);
                  },
                ),
              DropdownButtonFormField<String>(
                initialValue: _accountId,
                decoration: const InputDecoration(labelText: '계좌'),
                items: [
                  for (final account in accounts)
                    DropdownMenuItem(
                      value: account.localId,
                      child: Text(account.name),
                    ),
                ],
                onChanged: (value) => setState(() => _accountId = value),
              ),
              DropdownButtonFormField<String?>(
                initialValue: _categoryId,
                decoration: const InputDecoration(labelText: '카테고리'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('선택 안 함'),
                  ),
                  for (final category in categories)
                    DropdownMenuItem<String?>(
                      value: category.id,
                      child: Text(category.name),
                    ),
                ],
                onChanged: (value) => setState(() => _categoryId = value),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: _submit,
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  void _submit() {
    final amount = int.tryParse(_amountController.text.trim()) ?? 0;
    final day = int.tryParse(_dayController.text.trim()) ?? 0;
    final accountId = _accountId;
    final isMonthly = _cadence == 'monthly';

    if (_nameController.text.trim().isEmpty ||
        amount <= 0 ||
        accountId == null ||
        (isMonthly && (day < 1 || day > 31))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이름, 금액, 주기, 계좌를 확인해 주세요.')),
      );
      return;
    }

    Navigator.of(context).pop(
      _RecurringExpenseEditorResult(
        name: _nameController.text.trim(),
        type: _type,
        amount: amount,
        cadence: _cadence,
        dayOfMonth: isMonthly ? day : null,
        weekday: isMonthly ? null : _weekday,
        accountId: accountId,
        categoryId: _categoryId,
      ),
    );
  }
}

class _RecurringExpenseEditorResult {
  const _RecurringExpenseEditorResult({
    required this.name,
    required this.type,
    required this.amount,
    required this.cadence,
    required this.dayOfMonth,
    required this.weekday,
    required this.accountId,
    required this.categoryId,
  });

  final String name;
  final String type;
  final int amount;
  final String cadence;
  final int? dayOfMonth;
  final int? weekday;
  final String accountId;
  final String? categoryId;
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
