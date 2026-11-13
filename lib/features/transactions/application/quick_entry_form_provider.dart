import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';

const _quickEntryUnset = Object();

enum TransactionEntryType {
  expense,
  income,
  transfer,
}

class QuickEntryFormState {
  const QuickEntryFormState({
    this.type = TransactionEntryType.expense,
    this.amount = '',
    this.memo = '',
    this.occurredAt,
    this.accountId,
    this.fromAccountId,
    this.toAccountId,
    this.categoryId,
    this.editingId,
  });

  final TransactionEntryType type;
  final String amount;
  final String memo;
  final DateTime? occurredAt;
  final String? accountId;
  final String? fromAccountId;
  final String? toAccountId;
  final String? categoryId;
  final String? editingId;

  bool get canSubmit {
    if (amount.trim().isEmpty) {
      return false;
    }

    if (type == TransactionEntryType.transfer) {
      return fromAccountId != null &&
          toAccountId != null &&
          fromAccountId != toAccountId;
    }

    return accountId != null;
  }

  bool get needsAccount => accountId == null;

  bool get needsTransferSource => type == TransactionEntryType.transfer && fromAccountId == null;

  bool get needsTransferDestination =>
      type == TransactionEntryType.transfer && toAccountId == null;

  bool get hasTransferAccountConflict =>
      type == TransactionEntryType.transfer &&
      fromAccountId != null &&
      toAccountId != null &&
      fromAccountId == toAccountId;

  bool get needsCategory => false;

  QuickEntryFormState copyWith({
    TransactionEntryType? type,
    String? amount,
    String? memo,
    Object? occurredAt = _quickEntryUnset,
    Object? accountId = _quickEntryUnset,
    Object? fromAccountId = _quickEntryUnset,
    Object? toAccountId = _quickEntryUnset,
    Object? categoryId = _quickEntryUnset,
    Object? editingId = _quickEntryUnset,
  }) {
    return QuickEntryFormState(
      type: type ?? this.type,
      amount: amount ?? this.amount,
      memo: memo ?? this.memo,
      occurredAt:
          identical(occurredAt, _quickEntryUnset) ? this.occurredAt : occurredAt as DateTime?,
      accountId: identical(accountId, _quickEntryUnset) ? this.accountId : accountId as String?,
      fromAccountId: identical(fromAccountId, _quickEntryUnset)
          ? this.fromAccountId
          : fromAccountId as String?,
      toAccountId:
          identical(toAccountId, _quickEntryUnset) ? this.toAccountId : toAccountId as String?,
      categoryId:
          identical(categoryId, _quickEntryUnset) ? this.categoryId : categoryId as String?,
      editingId:
          identical(editingId, _quickEntryUnset) ? this.editingId : editingId as String?,
    );
  }
}

class QuickEntryFormController extends AutoDisposeNotifier<QuickEntryFormState> {
  void Function()? _releaseEdit;
  bool _failedSaveNeedsRestore = false;

  @override
  QuickEntryFormState build() {
    return const QuickEntryFormState();
  }

  void setType(TransactionEntryType type) {
    if (_isSubmitting) return;
    state = QuickEntryFormState(
      type: type,
      amount: state.amount,
      memo: state.memo,
      occurredAt: state.occurredAt,
      accountId: type == TransactionEntryType.transfer ? null : state.accountId,
      fromAccountId:
          type == TransactionEntryType.transfer ? state.fromAccountId ?? state.accountId : null,
      toAccountId: type == TransactionEntryType.transfer ? state.toAccountId : null,
      categoryId: type == TransactionEntryType.transfer ? null : state.categoryId,
      editingId: state.editingId,
    );
  }

  void setAmount(String amount) {
    if (_isSubmitting) return;
    state = state.copyWith(amount: amount);
  }

  void setMemo(String memo) {
    if (_isSubmitting) return;
    state = state.copyWith(memo: memo);
  }

  void setOccurredAt(DateTime? occurredAt) {
    if (_isSubmitting) return;
    state = state.copyWith(occurredAt: occurredAt);
  }

  void setAccount(String? accountId) {
    if (_isSubmitting) return;
    state = state.copyWith(accountId: accountId);
  }

  void setFromAccount(String? accountId) {
    if (_isSubmitting) return;
    state = state.copyWith(fromAccountId: accountId);
  }

  void setToAccount(String? accountId) {
    if (_isSubmitting) return;
    state = state.copyWith(toAccountId: accountId);
  }

  void setCategory(String? categoryId) {
    if (_isSubmitting) return;
    state = state.copyWith(categoryId: categoryId);
  }

  void setEditingId(String? editingId) {
    if (_isSubmitting) return;
    _failedSaveNeedsRestore = false;
    if (editingId == null) {
      _stopRetainingEdit();
    } else {
      _retainEdit();
    }
    state = state.copyWith(editingId: editingId);
  }

  void loadTransaction(Transaction transaction) {
    if (_isSubmitting) return;
    _failedSaveNeedsRestore = false;
    _retainEdit();
    state = QuickEntryFormState(
      type: _mapTransactionType(transaction.type),
      amount: transaction.amount.toString(),
      memo: transaction.memo ?? '',
      occurredAt: transaction.occurredAt,
      accountId: transaction.accountId,
      fromAccountId: transaction.fromAccountId,
      toAccountId: transaction.toAccountId,
      categoryId: transaction.categoryId,
      editingId: transaction.localId,
    );
  }

  void loadTemplate(Transaction transaction) {
    if (_isSubmitting) return;
    _failedSaveNeedsRestore = false;
    _stopRetainingEdit();
    final type = _mapTransactionType(transaction.type);
    state = QuickEntryFormState(
      type: type,
      amount: transaction.amount.toString(),
      memo: (transaction.memo?.trim().isNotEmpty == true
          ? transaction.memo!.trim()
          : transaction.merchantName?.trim()) ??
          '',
      occurredAt: DateTime.now(),
      accountId: type == TransactionEntryType.transfer ? null : transaction.accountId,
      fromAccountId: type == TransactionEntryType.transfer ? transaction.fromAccountId : null,
      toAccountId: type == TransactionEntryType.transfer ? transaction.toAccountId : null,
      categoryId: type == TransactionEntryType.transfer ? null : transaction.categoryId,
      editingId: null,
    );
  }

  void reset() {
    if (_isSubmitting) return;
    state = const QuickEntryFormState();
    _failedSaveNeedsRestore = false;
    _stopRetainingEdit();
  }

  /// Clear only the exact snapshot that was successfully saved.
  bool clearIfCurrent(QuickEntryFormState submitted) {
    if (!identical(state, submitted)) return false;
    state = const QuickEntryFormState();
    _failedSaveNeedsRestore = false;
    _stopRetainingEdit();
    return true;
  }

  bool get _isSubmitting => ref.read(quickEntrySubmitStateProvider);

  /// Keep a failed new entry available if the editor was covered by the lock.
  void retainAfterFailedSave() {
    _failedSaveNeedsRestore = true;
    _retainEdit();
  }

  bool get needsRestoreAfterLock =>
      state.editingId != null || _failedSaveNeedsRestore || _isSubmitting;

  /// Holds the form until an asynchronous write finishes, even if the app
  /// becomes locked and the editor widget is temporarily removed.
  void Function() retainDuringSave() => ref.keepAlive().close;

  void _retainEdit() {
    _releaseEdit ??= ref.keepAlive().close;
  }

  void _stopRetainingEdit() {
    final release = _releaseEdit;
    _releaseEdit = null;
    release?.call();
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

/// Keep the submission flag across a temporary lock screen to prevent a
/// second write while the original save is still running.
final quickEntrySubmitStateProvider =
    StateProvider<bool>((ref) => false);

final quickEntryFormProvider =
    NotifierProvider.autoDispose<QuickEntryFormController, QuickEntryFormState>(
  QuickEntryFormController.new,
);
