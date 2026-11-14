import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:smart_wallet_app/core/database/app_database.dart';

import '../../test_support/sqlite_test_setup.dart';

void main() {
  setUpAll(configureSqliteForTests);

  test('version 9 histories remain unverified after upgrade', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory(setup: (raw) {
      raw.execute('''
        CREATE TABLE notification_histories (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          package_name TEXT NOT NULL, amount INTEGER NOT NULL,
          type TEXT NOT NULL, merchant TEXT, suggested_category TEXT,
          detected_at INTEGER NOT NULL
        )
      ''');
      raw.execute("INSERT INTO notification_histories VALUES (1, 'bank', 1000, 'expense', 'shop', NULL, 100)");
      raw.execute('PRAGMA user_version = 9');
    }));
    addTearDown(db.close);

    final history = await db.customSelect(
      'SELECT merchant, event_id, status, transaction_id FROM notification_histories',
    ).getSingle();
    expect(history.data['merchant'], 'shop');
    expect(history.data['status'], 'legacy');
    expect(history.data['event_id'], isNull);
    expect(history.data['transaction_id'], isNull);
    expect((await db.customSelect('PRAGMA user_version').getSingle())
        .data.values.single, 10);
    expect((await db.customSelect(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='merchant_category_rules'",
    ).get()), hasLength(1));
    await _assertEventIdsAreUnique(db);
  });

  test('fresh databases enforce event ids while accepting multiple nulls',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await _assertEventIdsAreUnique(db);
  });

  test('failed v10 index creation rolls back all migration changes', () async {
    final directory = await Directory.systemTemp.createTemp('wallet-v10-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}${Platform.pathSeparator}wallet.sqlite');
    final raw = sqlite.sqlite3.open(file.path);
    raw.execute('''
      CREATE TABLE notification_histories (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        package_name TEXT NOT NULL, amount INTEGER NOT NULL,
        type TEXT NOT NULL, merchant TEXT, suggested_category TEXT,
        detected_at INTEGER NOT NULL, event_id TEXT
      )
    ''');
    raw.execute('''
      INSERT INTO notification_histories (package_name, amount, type, detected_at, event_id)
      VALUES ('bank', 100, 'expense', 100, 'duplicate'),
             ('bank', 101, 'expense', 101, 'duplicate')
    ''');
    raw.execute('PRAGMA user_version = 9');
    raw.dispose();

    final db = AppDatabase.forTesting(NativeDatabase(file));
    await expectLater(db.customSelect('SELECT 1').get(), throwsA(anything));
    try {
      await db.close();
    } catch (_) {
      // Opening may already have closed the connection.
    }
    final reopened = sqlite.sqlite3.open(file.path);
    addTearDown(reopened.dispose);
    final columns = reopened.select('PRAGMA table_info(notification_histories)')
        .map((row) => row['name']);
    expect(columns, isNot(contains('status')));
    expect(columns, isNot(contains('transaction_id')));
    expect(reopened.select('PRAGMA user_version').single.values.single, 9);
    expect(reopened.select('SELECT event_id FROM notification_histories'), hasLength(2));
    expect(reopened.select("SELECT name FROM sqlite_master WHERE name = 'merchant_category_rules'"), isEmpty);
  });

  test('automatic cleanup retains unreviewed histories and all event ids',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db.customStatement('''
      INSERT INTO notification_histories
        (package_name, amount, type, detected_at, status, event_id)
      VALUES ('bank', 100, 'expense', 100, 'pending', 'pending-event'),
             ('bank', 101, 'expense', 101, 'recorded', 'saved-event'),
             ('bank', 102, 'expense', 102, 'legacy', NULL)
    ''');
    await db.deleteOldNotificationHistories(keepCount: 1);
    final rows = await db.customSelect(
      'SELECT status, event_id FROM notification_histories',
    ).get();
    expect(rows, hasLength(3));
  });

  test('the history stream includes entries beyond the first hundred', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db.customStatement('''
      WITH RECURSIVE numbers(value) AS (
        SELECT 1 UNION ALL SELECT value + 1 FROM numbers WHERE value < 101
      )
      INSERT INTO notification_histories (package_name, amount, type, detected_at)
      SELECT 'bank', value, 'expense', value FROM numbers
    ''');
    expect(await db.watchNotificationHistories().first, hasLength(101));
    expect(await db.watchNotificationHistories(limit: 10).first, hasLength(10));
  });
}

Future<void> _assertEventIdsAreUnique(AppDatabase db) async {
  await db.customStatement('''
    INSERT INTO notification_histories (package_name, amount, type, detected_at)
    VALUES ('bank', 100, 'expense', 100), ('bank', 101, 'expense', 101)
  ''');
  await db.customStatement('''
    INSERT INTO notification_histories
      (package_name, amount, type, detected_at, event_id)
    VALUES ('bank', 102, 'expense', 102, 'one-event')
  ''');
  await expectLater(
    db.customStatement('''
      INSERT INTO notification_histories
        (package_name, amount, type, detected_at, event_id)
      VALUES ('bank', 103, 'expense', 103, 'one-event')
    '''),
    throwsA(anything),
  );
}
