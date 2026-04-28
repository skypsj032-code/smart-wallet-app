import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_wallet_app/core/database/app_database.dart';
import 'package:smart_wallet_app/features/transactions/application/quick_entry_form_provider.dart';

void main() {
  test('loadTransaction hydrates an expense entry for editing', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final now = DateTime(2026, 4, 27, 12, 0);
    final transaction = Transaction(
      localId: 'tx-1',
      type: 'expense',
      amount: 12800,
      occurredAt: now,
      accountId: 'cash-1',
      fromAccountId: null,
      toAccountId: null,
      categoryId: 'expense-food',
      merchantName: 'Lunch Place',
      paymentMethod: null,
      memo: 'Team lunch',
      tagJson: null,
      createdAt: now,
      lastModifiedAt: now,
      deletedAt: null,
    );

    container.read(quickEntryFormProvider.notifier).loadTransaction(transaction);
    final state = container.read(quickEntryFormProvider);

    expect(state.type, TransactionEntryType.expense);
    expect(state.amount, '12800');
    expect(state.accountId, 'cash-1');
    expect(state.categoryId, 'expense-food');
    expect(state.memo, 'Team lunch');
    expect(state.editingId, 'tx-1');
  });

  test('loadTransaction hydrates a transfer entry for editing', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final now = DateTime(2026, 4, 27, 12, 30);
    final transaction = Transaction(
      localId: 'tx-transfer',
      type: 'transfer',
      amount: 50000,
      occurredAt: now,
      accountId: null,
      fromAccountId: 'bank-1',
      toAccountId: 'cash-1',
      categoryId: null,
      merchantName: null,
      paymentMethod: null,
      memo: 'ATM withdrawal',
      tagJson: null,
      createdAt: now,
      lastModifiedAt: now,
      deletedAt: null,
    );

    container.read(quickEntryFormProvider.notifier).loadTransaction(transaction);
    final state = container.read(quickEntryFormProvider);

    expect(state.type, TransactionEntryType.transfer);
    expect(state.amount, '50000');
    expect(state.fromAccountId, 'bank-1');
    expect(state.toAccountId, 'cash-1');
    expect(state.accountId, isNull);
    expect(state.categoryId, isNull);
    expect(state.memo, 'ATM withdrawal');
    expect(state.editingId, 'tx-transfer');
  });

  test('setType to transfer reuses account as initial source and clears category', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(quickEntryFormProvider.notifier);
    notifier.setAccount('cash-1');
    notifier.setCategory('expense-food');
    notifier.setAmount('9000');
    notifier.setMemo('Taxi');

    notifier.setType(TransactionEntryType.transfer);
    final state = container.read(quickEntryFormProvider);

    expect(state.type, TransactionEntryType.transfer);
    expect(state.fromAccountId, 'cash-1');
    expect(state.toAccountId, isNull);
    expect(state.accountId, isNull);
    expect(state.categoryId, isNull);
    expect(state.amount, '9000');
    expect(state.memo, 'Taxi');
  });
}
