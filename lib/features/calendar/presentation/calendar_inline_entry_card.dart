import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../transactions/application/quick_entry_form_provider.dart';
import '../../transactions/application/quick_entry_options_provider.dart';
import '../application/calendar_inline_entry_controller.dart';

class CalendarInlineEntryCard extends ConsumerStatefulWidget {
  const CalendarInlineEntryCard({
    super.key,
    required this.selectedDate,
  });

  final DateTime selectedDate;

  @override
  ConsumerState<CalendarInlineEntryCard> createState() =>
      _CalendarInlineEntryCardState();
}

class _CalendarInlineEntryCardState extends ConsumerState<CalendarInlineEntryCard> {
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
    final state = ref.watch(calendarInlineEntryControllerProvider);
    final notifier = ref.read(calendarInlineEntryControllerProvider.notifier);
    final form = state.form;
    final accountsAsync = ref.watch(quickEntryAccountsProvider);
    final categoriesAsync = ref.watch(
      quickEntryCategoriesProvider(
        form.type == TransactionEntryType.income ? 'income' : 'expense',
      ),
    );

    _syncController(_amountController, form.amount);
    _syncController(_memoController, form.memo);

    accountsAsync.whenData((accounts) {
      if (accounts.isEmpty || form.accountId != null) {
        return;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        notifier.setAccount(accounts.first.id);
      });
    });

    categoriesAsync.whenData((categories) {
      if (categories.isEmpty || form.categoryId != null) {
        return;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        notifier.setCategory(categories.first.id);
      });
    });

    final accounts = accountsAsync.asData?.value ?? const <QuickEntryAccountOption>[];
    final categories =
        categoriesAsync.asData?.value ?? const <QuickEntryCategoryOption>[];

    return Container(
      key: const Key('calendar-inline-entry-card'),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${widget.selectedDate.month}월 ${widget.selectedDate.day}일 바로 기록',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              if (state.isSaving)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SegmentedButton<TransactionEntryType>(
            segments: const [
              ButtonSegment<TransactionEntryType>(
                value: TransactionEntryType.expense,
                label: Text('지출'),
              ),
              ButtonSegment<TransactionEntryType>(
                value: TransactionEntryType.income,
                label: Text('수입'),
              ),
            ],
            selected: {form.type == TransactionEntryType.income ? TransactionEntryType.income : TransactionEntryType.expense},
            onSelectionChanged: state.isSaving
                ? null
                : (selection) => notifier.setType(selection.first),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            key: const Key('calendar-inline-amount-field'),
            controller: _amountController,
            enabled: !state.isSaving,
            keyboardType: const TextInputType.numberWithOptions(decimal: false),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: '금액',
              hintText: '예: 12000',
            ),
            onChanged: notifier.setAmount,
          ),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<String>(
            initialValue:
                _normalizeSelectedValue(form.accountId, accounts.map((e) => e.id)),
            decoration: const InputDecoration(labelText: '계좌'),
            items: [
              for (final account in accounts)
                DropdownMenuItem<String>(
                  value: account.id,
                  child: Text(account.name),
                ),
            ],
            onChanged: state.isSaving ? null : notifier.setAccount,
          ),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<String>(
            initialValue: _normalizeSelectedValue(
              form.categoryId,
              categories.map((e) => e.id),
            ),
            decoration: const InputDecoration(labelText: '카테고리'),
            items: [
              for (final category in categories)
                DropdownMenuItem<String>(
                  value: category.id,
                  child: Text(category.name),
                ),
            ],
            onChanged: state.isSaving ? null : notifier.setCategory,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _memoController,
            enabled: !state.isSaving,
            decoration: const InputDecoration(
              labelText: '메모',
              hintText: '가게 이름이나 짧은 메모',
            ),
            onChanged: notifier.setMemo,
          ),
          if (state.errorMessage?.isNotEmpty == true) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              state.errorMessage!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.expense,
                  ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              OutlinedButton(
                onPressed: state.isSaving ? null : notifier.reset,
                child: const Text('초기화'),
              ),
              const Spacer(),
              FilledButton(
                key: const Key('calendar-inline-save-button'),
                onPressed: state.isSaving ? null : () => notifier.save(),
                child: const Text('기록 저장'),
              ),
            ],
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

  String? _normalizeSelectedValue(String? value, Iterable<String> candidates) {
    if (value == null) {
      return null;
    }

    return candidates.contains(value) ? value : null;
  }
}
