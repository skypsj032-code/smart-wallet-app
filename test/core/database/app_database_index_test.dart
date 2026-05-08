import 'package:drift/drift.dart' hide Column;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet_app/core/database/app_database.dart';

import '../../test_support/sqlite_test_setup.dart';

void main() {
  setUpAll(() {
    configureSqliteForTests();
  });

  test('fresh databases create timeline and category indexes for transactions',
      () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);

    final names = await _transactionIndexNames(database);

    expect(names, contains('transactions_timeline_idx'));
    expect(names, contains('transactions_category_timeline_idx'));
  });

  test('schema version 7 databases create transaction indexes during upgrade',
      () async {
    final executor = NativeDatabase.memory(
      setup: (rawDb) {
        rawDb.execute('''
          CREATE TABLE transactions (
            local_id TEXT NOT NULL PRIMARY KEY,
            type TEXT NOT NULL,
            amount INTEGER NOT NULL,
            occurred_at INTEGER NOT NULL,
            account_id TEXT NULL,
            from_account_id TEXT NULL,
            to_account_id TEXT NULL,
            category_id TEXT NULL,
            merchant_name TEXT NULL,
            payment_method TEXT NULL,
            memo TEXT NULL,
            tag_json TEXT NULL,
            created_at INTEGER NOT NULL,
            last_modified_at INTEGER NOT NULL,
            deleted_at INTEGER NULL
          );
        ''');
        rawDb.execute('PRAGMA user_version = 7;');
      },
    );

    final database = AppDatabase.forTesting(executor);
    addTearDown(database.close);

    await database.customSelect('SELECT 1').get();
    final names = await _transactionIndexNames(database);

    expect(names, contains('transactions_timeline_idx'));
    expect(names, contains('transactions_category_timeline_idx'));
  });
}

Future<List<String>> _transactionIndexNames(AppDatabase database) async {
  final rows =
      await database.customSelect('PRAGMA index_list(transactions);').get();

  return rows.map((row) => row.data['name']).whereType<String>().toList();
}
