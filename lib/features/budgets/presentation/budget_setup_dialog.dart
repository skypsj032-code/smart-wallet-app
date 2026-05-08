// ignore_for_file: depend_on_referenced_packages

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/providers/database_providers.dart';

String budgetSetupCategorySemanticLabel({required String? categoryName}) {
  final target = categoryName ?? 'all categories';
  return 'Budget category selector. Current selection: $target.';
}

String budgetSetupAmountSemanticLabel() {
  return 'Budget amount input. Enter the monthly budget amount in won.';
}

String budgetSetupSaveSemanticLabel() {
  return 'Save budget. Create or update the monthly budget for the selected category.';
}

class BudgetSetupDialog extends ConsumerStatefulWidget {
  const BudgetSetupDialog({
    super.key,
    this.initialCategories,
  });

  final List<Category>? initialCategories;

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      routeSettings: const RouteSettings(name: '/budget-setup-dialog'),
      builder: (context) => const BudgetSetupDialog(),
    );
  }

  @override
  ConsumerState<BudgetSetupDialog> createState() => _BudgetSetupDialogState();
}

class _BudgetSetupDialogState extends ConsumerState<BudgetSetupDialog>
    with RestorationMixin {
  final _amountController = RestorableTextEditingController();
  String? _selectedCategoryId;
  bool _isLoading = true;
  List<Category> _categories = [];

  @override
  String? get restorationId => 'budget_setup_dialog';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_amountController, 'amount');
  }

  @override
  void initState() {
    super.initState();
    final initialCategories = widget.initialCategories;
    if (initialCategories != null) {
      _categories = initialCategories;
      _isLoading = false;
      return;
    }
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final db = ref.read(appDatabaseProvider);
    final categories = await (db.select(db.categories)
          ..where(
            (category) =>
                category.isActive.equals(true) &
                category.type.equals('expense'),
          ))
        .get();

    if (!mounted) {
      return;
    }

    setState(() {
      _categories = categories;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _saveBudget() async {
    final amountText = _amountController.value.text.replaceAll(',', '');
    final amount = int.tryParse(amountText);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('올바른 금액을 입력하세요.')),
      );
      return;
    }

    final db = ref.read(appDatabaseProvider);
    final now = DateTime.now();
    final monthKey =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';

    final existingQuery = db.select(db.budgets)
      ..where((budget) => budget.monthKey.equals(monthKey));

    if (_selectedCategoryId == null) {
      existingQuery.where((budget) => budget.categoryId.isNull());
    } else {
      existingQuery.where(
        (budget) => budget.categoryId.equals(_selectedCategoryId!),
      );
    }

    final existing = await existingQuery.getSingleOrNull();

    if (existing != null) {
      await db.update(db.budgets).replace(
            existing.copyWith(
              amountLimit: amount,
              lastModifiedAt: now,
            ),
          );
    } else {
      const uuid = Uuid();
      await db.into(db.budgets).insert(
            BudgetsCompanion.insert(
              localId: uuid.v4(),
              monthKey: monthKey,
              categoryId: drift.Value(_selectedCategoryId),
              amountLimit: amount,
              createdAt: now,
              lastModifiedAt: now,
            ),
          );
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  String? _selectedCategoryName() {
    if (_selectedCategoryId == null) {
      return null;
    }

    for (final category in _categories) {
      if (category.localId == _selectedCategoryId) {
        return category.name;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const AlertDialog(
        content: SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: AlertDialog(
          title: const Text('예산 설정'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                container: true,
                excludeSemantics: true,
                label: budgetSetupCategorySemanticLabel(
                  categoryName: _selectedCategoryName(),
                ),
                child: DropdownButtonFormField<String?>(
                  initialValue: _selectedCategoryId,
                  decoration: const InputDecoration(labelText: '대상 카테고리'),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('전체 예산'),
                    ),
                    ..._categories.map(
                      (category) => DropdownMenuItem(
                        value: category.localId,
                        child: Text(category.name),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedCategoryId = value;
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),
              Semantics(
                textField: true,
                container: true,
                excludeSemantics: true,
                label: budgetSetupAmountSemanticLabel(),
                child: TextField(
                  controller: _amountController.value,
                  decoration: const InputDecoration(
                    labelText: '예산 금액',
                    suffixText: '원',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            Semantics(
              button: true,
              container: true,
              excludeSemantics: true,
              label: budgetSetupSaveSemanticLabel(),
              child: FilledButton(
                onPressed: _saveBudget,
                child: const Text('저장'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
