import 'package:drift/drift.dart';
import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/providers/database_providers.dart';
import '../application/quick_entry_form_provider.dart';
import 'transaction_repository_interface.dart';

class TransactionRepository implements ITransactionRepository {
  TransactionRepository(this._database);

  final AppDatabase _database;

  Future<void> createFromQuickEntry(QuickEntryFormState form) async {
    final now = DateTime.now();
    final occurredAt = form.occurredAt ?? now;
    final amount = int.tryParse(form.amount.trim()) ?? 0;

    developer.log(
      'repository_create_from_quick_entry type=${form.type} amount=${form.amount} parsedAmount=$amount accountId=${form.accountId} fromAccountId=${form.fromAccountId} toAccountId=${form.toAccountId} categoryId=${form.categoryId} memo=${form.memo}',
      name: 'quick_entry_repository',
    );

    if (amount <= 0) {
      developer.log('repository_amount_invalid', name: 'quick_entry_repository');
      throw ArgumentError('amount must be greater than zero');
    }

    if (form.type == TransactionEntryType.transfer) {
      final fromAccountId = form.fromAccountId;
      final toAccountId = form.toAccountId;

      if (fromAccountId == null || toAccountId == null) {
        throw ArgumentError('transfer requires both source and destination accounts');
      }

      if (fromAccountId == toAccountId) {
        throw ArgumentError('transfer accounts must be different');
      }

      await _database.into(_database.transactions).insert(
            TransactionsCompanion.insert(
              localId: 'tx_${now.microsecondsSinceEpoch}',
              type: _mapType(form.type),
              amount: amount,
              occurredAt: occurredAt,
              accountId: const Value(null),
              fromAccountId: Value(fromAccountId),
              toAccountId: Value(toAccountId),
              categoryId: const Value(null),
              memo: Value(form.memo.trim().isEmpty ? null : form.memo.trim()),
              createdAt: now,
              lastModifiedAt: now,
            ),
          );

      developer.log(
        'repository_insert_success localId=tx_${now.microsecondsSinceEpoch}',
        name: 'quick_entry_repository',
      );
      return;
    }

    if (form.accountId == null) {
      throw ArgumentError('account is required');
    }

    await _database.into(_database.transactions).insert(
          TransactionsCompanion.insert(
            localId: 'tx_${now.microsecondsSinceEpoch}',
            type: _mapType(form.type),
            amount: amount,
            occurredAt: occurredAt,
            accountId: Value(form.accountId),
            categoryId: Value(form.categoryId),
            memo: Value(form.memo.trim().isEmpty ? null : form.memo.trim()),
            createdAt: now,
            lastModifiedAt: now,
          ),
        );

    developer.log(
      'repository_insert_success localId=tx_${now.microsecondsSinceEpoch}',
      name: 'quick_entry_repository',
    );
  }

  Future<void> updateFromQuickEntry(QuickEntryFormState form) async {
    final now = DateTime.now();
    final occurredAt = form.occurredAt ?? now;
    final amount = int.tryParse(form.amount.trim()) ?? 0;

    developer.log(
      'repository_update_from_quick_entry localId=${form.editingId} type=${form.type} amount=${form.amount} parsedAmount=$amount accountId=${form.accountId} fromAccountId=${form.fromAccountId} toAccountId=${form.toAccountId} categoryId=${form.categoryId} memo=${form.memo}',
      name: 'quick_entry_repository',
    );

    if (amount <= 0) {
      throw ArgumentError('amount must be greater than zero');
    }

    final localId = form.editingId;
    if (localId == null) {
      throw ArgumentError('editingId cannot be null for update');
    }

    if (form.type == TransactionEntryType.transfer) {
      final fromAccountId = form.fromAccountId;
      final toAccountId = form.toAccountId;

      if (fromAccountId == null || toAccountId == null) {
        throw ArgumentError('transfer requires both source and destination accounts');
      }
      if (fromAccountId == toAccountId) {
        throw ArgumentError('transfer accounts must be different');
      }

      await (_database.update(_database.transactions)
            ..where((t) => t.localId.equals(localId)))
          .write(
        TransactionsCompanion(
          type: Value(_mapType(form.type)),
          amount: Value(amount),
          occurredAt: Value(occurredAt),
          accountId: const Value(null),
          fromAccountId: Value(fromAccountId),
          toAccountId: Value(toAccountId),
          categoryId: const Value(null),
          memo: Value(form.memo.trim().isEmpty ? null : form.memo.trim()),
          lastModifiedAt: Value(now),
        ),
      );
      return;
    }

    if (form.accountId == null) {
      throw ArgumentError('account is required');
    }

    await (_database.update(_database.transactions)
          ..where((t) => t.localId.equals(localId)))
        .write(
      TransactionsCompanion(
        type: Value(_mapType(form.type)),
        amount: Value(amount),
        occurredAt: Value(occurredAt),
        accountId: Value(form.accountId),
        fromAccountId: const Value(null),
        toAccountId: const Value(null),
        categoryId: Value(form.categoryId),
        memo: Value(form.memo.trim().isEmpty ? null : form.memo.trim()),
        lastModifiedAt: Value(now),
      ),
    );
  }

  Future<void> undoDeleteTransaction(String localId) async {
    final now = DateTime.now();
    await (_database.update(_database.transactions)
          ..where((tbl) => tbl.localId.equals(localId)))
        .write(
          TransactionsCompanion(
            deletedAt: const Value(null),
            lastModifiedAt: Value(now),
          ),
        );
  }

  Future<void> softDeleteTransaction(String localId) async {
    final existing = await (_database.select(_database.transactions)
          ..where((tbl) => tbl.localId.equals(localId)))
        .getSingleOrNull();
    final rawNow = DateTime.now();
    final minimumNextModifiedAt =
        existing?.lastModifiedAt.add(const Duration(seconds: 1));
    final now = minimumNextModifiedAt != null &&
            !rawNow.isAfter(minimumNextModifiedAt)
        ? minimumNextModifiedAt
        : rawNow;

    await (_database.update(_database.transactions)
          ..where((tbl) => tbl.localId.equals(localId)))
        .write(
          TransactionsCompanion(
            deletedAt: Value(now),
            lastModifiedAt: Value(now),
          ),
        );
  }

  String _mapType(TransactionEntryType type) {
    switch (type) {
      case TransactionEntryType.expense:
        return 'expense';
      case TransactionEntryType.income:
        return 'income';
      case TransactionEntryType.transfer:
        return 'transfer';
    }
  }
}

/// Provider는 인터페이스 타입으로 노출 — 테스트에서 override 가능.
final transactionRepositoryProvider =
    Provider<ITransactionRepository>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return TransactionRepository(database);
});

