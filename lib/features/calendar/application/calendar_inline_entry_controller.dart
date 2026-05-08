import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../transactions/application/quick_entry_form_provider.dart';
import '../../transactions/data/transaction_repository.dart';
import 'calendar_provider.dart';

class CalendarInlineEntryState {
  const CalendarInlineEntryState({
    required this.form,
    this.isSaving = false,
    this.errorMessage,
  });

  final QuickEntryFormState form;
  final bool isSaving;
  final String? errorMessage;

  CalendarInlineEntryState copyWith({
    QuickEntryFormState? form,
    bool? isSaving,
    Object? errorMessage = _calendarInlineUnset,
  }) {
    return CalendarInlineEntryState(
      form: form ?? this.form,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: identical(errorMessage, _calendarInlineUnset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

const _calendarInlineUnset = Object();

class CalendarInlineEntryController extends AutoDisposeNotifier<CalendarInlineEntryState> {
  @override
  CalendarInlineEntryState build() {
    final date = _selectedDate();
    return CalendarInlineEntryState(
      form: QuickEntryFormState(
        occurredAt: date,
      ),
    );
  }

  void setType(TransactionEntryType type) {
    final current = state.form;
    state = state.copyWith(
      form: QuickEntryFormState(
        type: type,
        amount: current.amount,
        memo: current.memo,
        occurredAt: current.occurredAt,
        accountId: type == TransactionEntryType.transfer ? null : current.accountId,
        fromAccountId:
            type == TransactionEntryType.transfer ? current.fromAccountId ?? current.accountId : null,
        toAccountId: type == TransactionEntryType.transfer ? current.toAccountId : null,
        categoryId: type == TransactionEntryType.transfer ? null : current.categoryId,
        editingId: current.editingId,
      ),
      errorMessage: null,
    );
  }

  void setAmount(String amount) {
    state = state.copyWith(
      form: state.form.copyWith(amount: amount),
      errorMessage: null,
    );
  }

  void setMemo(String memo) {
    state = state.copyWith(
      form: state.form.copyWith(memo: memo),
      errorMessage: null,
    );
  }

  void setAccount(String? accountId) {
    state = state.copyWith(
      form: state.form.copyWith(accountId: accountId),
      errorMessage: null,
    );
  }

  void setCategory(String? categoryId) {
    state = state.copyWith(
      form: state.form.copyWith(categoryId: categoryId),
      errorMessage: null,
    );
  }

  void loadTransaction(Transaction transaction) {
    state = state.copyWith(
      form: QuickEntryFormState(
        type: _mapTransactionType(transaction.type),
        amount: transaction.amount.toString(),
        memo: transaction.memo ?? '',
        occurredAt: transaction.occurredAt,
        accountId: transaction.accountId,
        fromAccountId: transaction.fromAccountId,
        toAccountId: transaction.toAccountId,
        categoryId: transaction.categoryId,
        editingId: transaction.localId,
      ),
      errorMessage: null,
    );
  }

  void reset() {
    final current = state.form;
    final date = _selectedDate();
    state = CalendarInlineEntryState(
      form: QuickEntryFormState(
        type: current.type,
        occurredAt: date,
        accountId: current.type == TransactionEntryType.transfer ? null : current.accountId,
        fromAccountId: current.type == TransactionEntryType.transfer ? current.fromAccountId : null,
        toAccountId: current.type == TransactionEntryType.transfer ? current.toAccountId : null,
        categoryId: current.type == TransactionEntryType.transfer ? null : current.categoryId,
      ),
    );
  }

  Future<bool> save() async {
    if (state.isSaving || !state.form.canSubmit) {
      return false;
    }

    final repository = ref.read(transactionRepositoryProvider);
    final form = state.form.copyWith(
      occurredAt: _selectedDate(),
    );

    state = state.copyWith(isSaving: true, errorMessage: null);

    try {
      if (form.editingId != null) {
        await repository.updateFromQuickEntry(form);
      } else {
        await repository.createFromQuickEntry(form);
      }

      ref.invalidate(calendarSnapshotProvider);
      ref.invalidate(selectedCalendarTransactionsProvider);
      ref.invalidate(calendarHomeSummaryProvider);
      ref.invalidate(calendarHomeMonthPreviewProvider);

      final nextForm = state.form;
      state = CalendarInlineEntryState(
        form: QuickEntryFormState(
          type: nextForm.type,
          occurredAt: _selectedDate(),
          accountId: nextForm.type == TransactionEntryType.transfer ? null : nextForm.accountId,
          fromAccountId:
              nextForm.type == TransactionEntryType.transfer ? nextForm.fromAccountId : null,
          toAccountId: nextForm.type == TransactionEntryType.transfer ? nextForm.toAccountId : null,
          categoryId: nextForm.type == TransactionEntryType.transfer ? null : nextForm.categoryId,
        ),
      );
      return true;
    } catch (error) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: error.toString(),
      );
      return false;
    }
  }

  DateTime _selectedDate() {
    final selected = ref.read(selectedCalendarDateProvider);
    final fallback = ref.read(calendarTodayProvider);
    return selected ?? fallback;
  }

  TransactionEntryType _mapTransactionType(String type) {
    switch (type) {
      case 'income':
        return TransactionEntryType.income;
      case 'transfer':
        return TransactionEntryType.transfer;
      case 'expense':
      default:
        return TransactionEntryType.expense;
    }
  }
}

final calendarInlineEntryControllerProvider =
    NotifierProvider.autoDispose<CalendarInlineEntryController, CalendarInlineEntryState>(
  CalendarInlineEntryController.new,
);
