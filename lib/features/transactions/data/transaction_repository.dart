import 'package:drift/drift.dart';
import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/providers/database_providers.dart';
import '../../notifications/application/notification_merchant.dart';
import '../application/quick_entry_form_provider.dart';
import 'transaction_repository_interface.dart';

const _uuid = Uuid();

class TransactionRepository implements ITransactionRepository {
  TransactionRepository(this._database);

  final AppDatabase _database;

  Future<void> createFromQuickEntry(QuickEntryFormState form) async {
    final now = DateTime.now();
    final occurredAt = form.occurredAt ?? now;
    final amount = int.tryParse(form.amount.trim()) ?? 0;

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

    } else if (form.accountId == null) {
      throw ArgumentError('account is required');
    }

    final txId = 'tx_${_uuid.v4()}';
    await _database.transaction(() async {
      final historyId = form.notificationHistoryId;
      NotificationHistory? history;
      if (historyId != null) {
        history = await (_database.select(_database.notificationHistories)
              ..where((h) => h.id.equals(historyId)))
            .getSingleOrNull();
        // Claim first, in the same transaction as the insert. A concurrent or
        // repeated save cannot turn a single candidate into two transactions.
        final claimed = await (_database.update(_database.notificationHistories)
              ..where((h) => h.id.equals(historyId) &
                  h.status.isIn(['pending', 'legacy'])))
            .write(NotificationHistoriesCompanion(
          status: const Value('recorded'),
          transactionId: Value(txId),
        ));
        if (claimed != 1) {
          throw StateError('This notification has already been handled');
        }
      }

      final isTransfer = form.type == TransactionEntryType.transfer;
      await _database.into(_database.transactions).insert(
        TransactionsCompanion.insert(
          localId: txId,
          type: _mapType(form.type),
          amount: amount,
          occurredAt: occurredAt,
          accountId: Value(isTransfer ? null : form.accountId),
          fromAccountId: Value(isTransfer ? form.fromAccountId : null),
          toAccountId: Value(isTransfer ? form.toAccountId : null),
          categoryId: Value(isTransfer ? null : form.categoryId),
          merchantName: Value(history?.type == 'unknown' ? null : form.notificationMerchant),
          memo: Value(form.memo.trim().isEmpty ? null : form.memo.trim()),
          createdAt: now,
          lastModifiedAt: now,
        ),
      );

      final merchantKey = normalizeNotificationMerchant(form.notificationMerchant ?? '');
      final categoryId = form.categoryId;
      final hasRecognizedMerchant = history != null &&
          history.type != 'unknown' &&
          merchantKey == normalizeNotificationMerchant(history.merchant ?? '');
      if (hasRecognizedMerchant && !isTransfer && merchantKey.isNotEmpty && categoryId != null) {
        final type = _mapType(form.type);
        final category = await (_database.select(_database.categories)
              ..where((c) => c.localId.equals(categoryId) &
                  c.type.equals(type) & c.isActive.equals(true)))
            .getSingleOrNull();
        if (category != null) {
          await _database.into(_database.merchantCategoryRules).insertOnConflictUpdate(
            MerchantCategoryRulesCompanion.insert(
              merchantKey: merchantKey,
              type: type,
              categoryId: categoryId,
              updatedAt: now,
            ),
          );
        }
      }
    });
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

      final updated = await (_database.update(_database.transactions)
            ..where((t) => t.localId.equals(localId) & t.deletedAt.isNull()))
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
      if (updated != 1) {
        throw StateError('The transaction no longer exists or has been deleted');
      }
      return;
    }

    if (form.accountId == null) {
      throw ArgumentError('account is required');
    }

    final updated = await (_database.update(_database.transactions)
          ..where((t) => t.localId.equals(localId) & t.deletedAt.isNull()))
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
    if (updated != 1) {
      throw StateError('The transaction no longer exists or has been deleted');
    }
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

