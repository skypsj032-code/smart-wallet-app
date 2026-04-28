import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_wallet_app/core/database/app_database.dart';
import 'package:smart_wallet_app/features/transactions/application/quick_entry_form_provider.dart';

void main() {
  group('QuickEntryFormState', () {
    test('transfer submission requires distinct source and destination accounts', () {
      const state = QuickEntryFormState(
        type: TransactionEntryType.transfer,
        amount: '12500',
        fromAccountId: 'cash',
        toAccountId: 'cash',
      );

      expect(state.canSubmit, isFalse);
      expect(state.needsTransferSource, isFalse);
      expect(state.needsTransferDestination, isFalse);
      expect(state.hasTransferAccountConflict, isTrue);
    });
  });

  group('QuickEntryFormController', () {
    test('switching to transfer carries the selected account and clears category', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(quickEntryFormProvider.notifier);

      controller.setAmount('33000');
      controller.setAccount('checking');
      controller.setCategory('groceries');
      controller.setType(TransactionEntryType.transfer);

      final state = container.read(quickEntryFormProvider);

      expect(state.type, TransactionEntryType.transfer);
      expect(state.amount, '33000');
      expect(state.accountId, isNull);
      expect(state.fromAccountId, 'checking');
      expect(state.toAccountId, isNull);
      expect(state.categoryId, isNull);
      expect(state.canSubmit, isFalse);
      expect(state.needsTransferDestination, isTrue);
    });

    test('loadTransaction maps an existing transfer into editable form state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(quickEntryFormProvider.notifier);
      final occurredAt = DateTime(2026, 4, 20, 8, 30);
      final transaction = Transaction(
        localId: 'tx-transfer-1',
        type: 'transfer',
        amount: 4200,
        occurredAt: occurredAt,
        accountId: null,
        fromAccountId: 'wallet',
        toAccountId: 'savings',
        categoryId: null,
        merchantName: null,
        paymentMethod: 'manual',
        memo: 'Move spare cash',
        tagJson: null,
        createdAt: occurredAt.subtract(const Duration(hours: 2)),
        lastModifiedAt: occurredAt.add(const Duration(minutes: 15)),
        deletedAt: null,
      );

      controller.loadTransaction(transaction);

      final state = container.read(quickEntryFormProvider);

      expect(state.type, TransactionEntryType.transfer);
      expect(state.amount, '4200');
      expect(state.memo, 'Move spare cash');
      expect(state.occurredAt, occurredAt);
      expect(state.fromAccountId, 'wallet');
      expect(state.toAccountId, 'savings');
      expect(state.editingId, 'tx-transfer-1');
      expect(state.canSubmit, isTrue);
      expect(state.hasTransferAccountConflict, isFalse);
    });
  });
}
