import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/providers/database_providers.dart';

final accountsStreamProvider = StreamProvider<List<Account>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return (db.select(db.accounts)
        ..where((a) => a.isActive.equals(true))
        ..orderBy([(a) => OrderingTerm.asc(a.createdAt)]))
      .watch();
});

class AccountBalance {
  const AccountBalance({
    required this.account,
    required this.balance,
  });

  final Account account;
  final int balance;
}

final accountBalancesProvider = StreamProvider<List<AccountBalance>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final accountsStream = db.select(db.accounts).watch();
  final transactionsStream = (db.select(db.transactions)
        ..where((t) => t.deletedAt.isNull()))
      .watch();

  return _combine2(
    accountsStream,
    transactionsStream,
    (accounts, transactions) {
      final activeAccounts = accounts.where((account) => account.isActive).toList();

      return activeAccounts.map((account) {
        var income = 0;
        var expense = 0;

        for (final tx in transactions) {
          if (tx.type == 'income' && tx.accountId == account.localId) {
            income += tx.amount;
          } else if (tx.type == 'expense' && tx.accountId == account.localId) {
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
          account: account,
          balance: income - expense,
        );
      }).toList();
    },
  );
});

Stream<R> _combine2<A, B, R>(
  Stream<A> a,
  Stream<B> b,
  R Function(A a, B b) combiner,
) {
  late A latestA;
  late B latestB;
  var hasA = false;
  var hasB = false;

  final controller = StreamController<R>.broadcast();
  late StreamSubscription<A> subA;
  late StreamSubscription<B> subB;

  void emitIfReady() {
    if (hasA && hasB) {
      controller.add(combiner(latestA, latestB));
    }
  }

  subA = a.listen(
    (value) {
      latestA = value;
      hasA = true;
      emitIfReady();
    },
    onError: controller.addError,
  );

  subB = b.listen(
    (value) {
      latestB = value;
      hasB = true;
      emitIfReady();
    },
    onError: controller.addError,
  );

  controller.onCancel = () async {
    await subA.cancel();
    await subB.cancel();
  };

  return controller.stream;
}

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
    await (_db.update(_db.accounts)..where((a) => a.localId.equals(localId))).write(
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
    await (_db.update(_db.accounts)..where((a) => a.localId.equals(localId))).write(
      AccountsCompanion(
        isActive: const Value(false),
        lastModifiedAt: Value(now),
      ),
    );
  }
}

final accountsNotifierProvider =
    NotifierProvider<AccountsNotifier, void>(AccountsNotifier.new);
