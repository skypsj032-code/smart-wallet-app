import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/providers/database_providers.dart';

// ── 전체 계좌 목록 스트림 ────────────────────────────────────────────────────
final accountsStreamProvider = StreamProvider<List<Account>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return (db.select(db.accounts)
        ..where((a) => a.isActive.equals(true))
        ..orderBy([(a) => OrderingTerm.asc(a.createdAt)]))
      .watch();
});

// ── 계좌별 현재 잔액(순자산) 계산 ─────────────────────────────────────────────
class AccountBalance {
  const AccountBalance({
    required this.account,
    required this.balance,
  });
  final Account account;
  final int balance; // 수입 합계 - 지출 합계
}

final accountBalancesProvider = StreamProvider<List<AccountBalance>>((ref) {
  final db = ref.watch(appDatabaseProvider);

  // 두 쿼리를 결합하기 위해 accounts 스트림과 transactions 스트림을 개별 watch
  return db
      .select(db.accounts)
      .watch()
      .asyncMap((accounts) async {
        final txList = await (db.select(db.transactions)
              ..where((t) => t.deletedAt.isNull()))
            .get();

        final activeAccounts =
            accounts.where((a) => a.isActive).toList();

        return activeAccounts.map((account) {
          int income = 0;
          int expense = 0;

          for (final tx in txList) {
            if (tx.type == 'income' && tx.accountId == account.localId) {
              income += tx.amount;
            } else if (tx.type == 'expense' &&
                tx.accountId == account.localId) {
              expense += tx.amount;
            } else if (tx.type == 'transfer') {
              if (tx.fromAccountId == account.localId) {
                expense += tx.amount;
              }
              if (tx.toAccountId == account.localId) {
                income += tx.amount;
              }
            }
          }

          return AccountBalance(
              account: account, balance: income - expense);
        }).toList();
      });
});

// ── 계좌 CRUD 액션 ─────────────────────────────────────────────────────────────
class AccountsNotifier extends Notifier<void> {
  @override
  void build() {}

  AppDatabase get _db => ref.read(appDatabaseProvider);

  Future<void> createAccount({
    required String name,
    required String type,
    String? colorHex,
  }) async {
    final now = DateTime.now();
    final id = 'acc_${now.microsecondsSinceEpoch}';
    await _db.into(_db.accounts).insert(
          AccountsCompanion.insert(
            localId: id,
            name: name,
            type: type,
            colorHex: Value(colorHex),
            createdAt: now,
            lastModifiedAt: now,
          ),
        );
  }

  Future<void> updateAccount({
    required String localId,
    required String name,
    required String type,
    String? colorHex,
  }) async {
    final now = DateTime.now();
    await (_db.update(_db.accounts)
          ..where((a) => a.localId.equals(localId)))
        .write(
      AccountsCompanion(
        name: Value(name),
        type: Value(type),
        colorHex: Value(colorHex),
        lastModifiedAt: Value(now),
      ),
    );
  }

  Future<void> deleteAccount(String localId) async {
    final now = DateTime.now();
    await (_db.update(_db.accounts)
          ..where((a) => a.localId.equals(localId)))
        .write(
      AccountsCompanion(
        isActive: const Value(false),
        lastModifiedAt: Value(now),
      ),
    );
  }
}

final accountsNotifierProvider =
    NotifierProvider<AccountsNotifier, void>(AccountsNotifier.new);
