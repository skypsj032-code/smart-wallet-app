// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/providers/database_providers.dart';

class BudgetSetupDialog extends ConsumerStatefulWidget {
  const BudgetSetupDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => const BudgetSetupDialog(),
    );
  }

  @override
  ConsumerState<BudgetSetupDialog> createState() => _BudgetSetupDialogState();
}

class _BudgetSetupDialogState extends ConsumerState<BudgetSetupDialog> {
  final _amountController = TextEditingController();
  String? _selectedCategoryId;
  bool _isLoading = true;
  List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final db = ref.read(appDatabaseProvider);
    final cats = await (db.select(db.categories)..where((c) => c.isActive.equals(true) & c.type.equals('expense'))).get();
    setState(() {
      _categories = cats;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _saveBudget() async {
    final amountText = _amountController.text.replaceAll(',', '');
    final amount = int.tryParse(amountText);
    
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('올바른 금액을 입력하세요.')),
      );
      return;
    }

    final db = ref.read(appDatabaseProvider);
    final now = DateTime.now();
    final monthKey = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';

    // Check if budget already exists for this category/month
    final existingQuery = db.select(db.budgets)
      ..where((b) => b.monthKey.equals(monthKey));
    
    if (_selectedCategoryId == null) {
      existingQuery.where((b) => b.categoryId.isNull());
    } else {
      existingQuery.where((b) => b.categoryId.equals(_selectedCategoryId!));
    }
    
    final existing = await existingQuery.getSingleOrNull();

    if (existing != null) {
      // Update
      await db.update(db.budgets).replace(
        existing.copyWith(
          amountLimit: amount,
          lastModifiedAt: DateTime.now(),
        ),
      );
    } else {
      // Insert
      const uuid = Uuid();
      await db.into(db.budgets).insert(
        BudgetsCompanion.insert(
          localId: uuid.v4(),
          monthKey: monthKey,
          categoryId: drift.Value(_selectedCategoryId),
          amountLimit: amount,
          createdAt: DateTime.now(),
          lastModifiedAt: DateTime.now(),
        ),
      );
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
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
              DropdownButtonFormField<String?>(
                initialValue: _selectedCategoryId,
                decoration: const InputDecoration(labelText: '대상 카테고리'),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('전체 예산'),
                  ),
                  ..._categories.map(
                    (c) => DropdownMenuItem(
                      value: c.localId,
                      child: Text(c.name),
                    ),
                  ),
                ],
                onChanged: (val) {
                  setState(() {
                    _selectedCategoryId = val;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: '예산 금액',
                  suffixText: '원',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: _saveBudget,
              child: const Text('저장'),
            ),
          ],
        ),
      ),
    );
  }
}
