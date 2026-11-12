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

const _accountBalanceSql = '''
SELECT a.*,
       COALESCE(SUM(
         CASE
           WHEN t.type = 'income' AND t.account_id = a.local_id THEN t.amount
           WHEN t.type = 'expense' AND t.account_id = a.local_id THEN -t.amount
           ELSE 0
         END
         + CASE WHEN t.type = 'transfer' AND t.to_account_id = a.local_id
                THEN t.amount ELSE 0 END
         - CASE WHEN t.type = 'transfer' AND t.from_account_id = a.local_id
                THEN t.amount ELSE 0 END
       ), 0) AS calculated_balance
FROM accounts AS a
LEFT JOIN transactions AS t
  ON t.deleted_at IS NULL
 AND ((t.type IN ('income', 'expense') AND t.account_id = a.local_id)
      OR (t.type = 'transfer' AND (t.from_account_id = a.local_id
                                   OR t.to_account_id = a.local_id)))
WHERE a.is_active = 1
GROUP BY a.local_id
ORDER BY a.created_at ASC, a.local_id ASC
''';

final accountBalancesProvider = StreamProvider<List<AccountBalance>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  // Drift must observe both tables: transactions can change without any
  // change to the account row itself.
  return db.customSelect(
    _accountBalanceSql,
    readsFrom: {db.accounts, db.transactions},
  ).watch().map(
        (rows) => rows
            .map((row) => AccountBalance(
                  account: db.accounts.map(row.data),
                  balance: row.read<int>('calculated_balance'),
                ))
            .toList(),
      );
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
