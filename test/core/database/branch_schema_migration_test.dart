import 'dart:io';

import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:smart_wallet_app/core/database/app_database.dart';

import '../../test_support/sqlite_test_setup.dart';

void main() {
  setUpAll(configureSqliteForTests);

  test('version 1 upgrade retains the legacy profile and ledger', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory(setup: (db) {
      _createSharedVersion4Tables(db);
      db.execute('''
        CREATE TABLE local_user_profile (
          local_user_id TEXT NOT NULL PRIMARY KEY,
          mode TEXT NOT NULL,
          device_id TEXT NOT NULL
        )
      ''');
      db.execute("INSERT INTO local_user_profile VALUES ('guest', 'guest', 'device-before-upgrade')");
      db.execute('PRAGMA user_version = 1');
    }));
    addTearDown(database.close);

    expect(await _tableExists(database, 'local_user_profile'), isTrue);
    final profile = await database.customSelect(
      'SELECT device_id FROM local_user_profile WHERE local_user_id = ?',
      variables: [Variable.withString('guest')],
    ).getSingle();
    expect(profile.data['device_id'], 'device-before-upgrade');
    expect((await database.customSelect('SELECT local_id FROM transactions').get())
        .single.data['local_id'], 'transaction-before-upgrade');
    expect(await _tableExists(database, 'recurring_spend_overrides'), isTrue);
  });

  test('Korean version 4 keeps exclusions while creating scheduled expenses',
      () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory(setup: (db) {
      _createSharedVersion4Tables(db);
      db.execute('''
        CREATE TABLE recurring_spend_overrides (
          group_key TEXT NOT NULL PRIMARY KEY,
          action_type TEXT NOT NULL,
          created_at INTEGER NOT NULL,
          last_modified_at INTEGER NOT NULL
        );
      ''');
      db.execute("INSERT INTO recurring_spend_overrides VALUES ('excluded', 'not_recurring', 100, 101)");
      db.execute('PRAGMA user_version = 4');
    }));
    addTearDown(database.close);

    final rows = await database.customSelect(
      'SELECT group_key, action_type FROM recurring_spend_overrides',
    ).get();
    expect(rows.single.data['group_key'], 'excluded');
    expect(rows.single.data['action_type'], 'not_recurring');
    expect(await _tableExists(database, 'recurring_expenses'), isTrue);
    expect(await _tableExists(database, 'notification_histories'), isTrue);
    expect((await database.customSelect('SELECT local_id FROM transactions').get())
        .single.data['local_id'], 'transaction-before-upgrade');
  });

  test('design version 4 preserves scheduled expense completion state', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory(setup: (db) {
      _createSharedVersion4Tables(db);
      db.execute('''
        CREATE TABLE recurring_expenses (
          local_id TEXT NOT NULL PRIMARY KEY, name TEXT NOT NULL,
          amount INTEGER NOT NULL, day_of_month INTEGER NOT NULL,
          account_id TEXT NOT NULL, category_id TEXT,
          is_active INTEGER NOT NULL DEFAULT 1, last_created_month_key TEXT,
          created_at INTEGER NOT NULL, last_modified_at INTEGER NOT NULL
        );
      ''');
      db.execute("INSERT INTO recurring_expenses VALUES ('rent', 'Rent', 700000, 25, 'bank', NULL, 1, '2026-04', 100, 101)");
      db.execute('PRAGMA user_version = 4');
    }));
    addTearDown(database.close);

    final rows = await database.customSelect('''
      SELECT local_id, type, cadence, last_completed_cycle_key
      FROM recurring_expenses
    ''').get();
    expect(rows.single.data['local_id'], 'rent');
    expect(rows.single.data['type'], 'expense');
    expect(rows.single.data['cadence'], 'monthly');
    expect(rows.single.data['last_completed_cycle_key'], '2026-04');
    expect(await _tableExists(database, 'recurring_spend_overrides'), isTrue);
  });

  test('fresh databases include both types of recurring data', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    expect(await _tableExists(database, 'recurring_expenses'), isTrue);
    expect(await _tableExists(database, 'recurring_spend_overrides'), isTrue);
  });

  test('design version 8 retains scheduled transactions when adding exclusions',
      () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory(setup: (db) {
      _createSharedVersion4Tables(db);
      db.execute('CREATE TABLE recurring_expenses (local_id TEXT NOT NULL PRIMARY KEY)');
      db.execute("INSERT INTO recurring_expenses VALUES ('keep-schedule')");
      db.execute('PRAGMA user_version = 8');
    }));
    addTearDown(database.close);

    expect(await _tableExists(database, 'recurring_spend_overrides'), isTrue);
    expect((await database.customSelect('SELECT local_id FROM recurring_expenses').get())
        .single.data['local_id'], 'keep-schedule');
  });

  test('a failed upgrade rolls back earlier changes to the original database',
      () async {
    final directory = await Directory.systemTemp.createTemp('wallet-migration-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}${Platform.pathSeparator}wallet.sqlite');
    final raw = sqlite.sqlite3.open(file.path);
    _createSharedVersion4Tables(raw);
    raw.execute('CREATE TABLE recurring_expenses (local_id TEXT NOT NULL PRIMARY KEY)');
    raw.execute("INSERT INTO recurring_expenses VALUES ('keep-schedule')");
    raw.execute('PRAGMA user_version = 4');
    raw.dispose();

    final database = AppDatabase.forTesting(NativeDatabase(file));
    await expectLater(database.customSelect('SELECT 1').get(),
        throwsA(isA<StateError>()));
    try {
      await database.close();
    } catch (_) {
      // The connection may already be closed after a failed open.
    }

    final reopened = sqlite.sqlite3.open(file.path);
    addTearDown(reopened.dispose);
    final names = reopened.select('PRAGMA table_info(app_settings)')
        .map((row) => row['name']).toList();
    expect(names, isNot(contains('default_category_seed_version')));
    expect(reopened.select('PRAGMA user_version').single.values.single, 4);
    expect(reopened.select('SELECT local_id FROM transactions').single['local_id'],
        'transaction-before-upgrade');
  });

  test('a previously added seed column survives a retried version 4 upgrade',
      () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory(setup: (db) {
      _createSharedVersion4Tables(db);
      db.execute('ALTER TABLE app_settings ADD COLUMN default_category_seed_version INTEGER NOT NULL DEFAULT 0');
      db.execute('INSERT INTO app_settings VALUES (1, 7)');
      db.execute('PRAGMA user_version = 4');
    }));
    addTearDown(database.close);

    final rows = await database.customSelect(
      'SELECT default_category_seed_version FROM app_settings WHERE id = 1',
    ).get();
    expect(rows.single.data['default_category_seed_version'], 7);
    expect(await _tableExists(database, 'recurring_spend_overrides'), isTrue);
  });

  test('excluded recurring groups survive reopening and can be restored',
      () async {
    final directory = await Directory.systemTemp.createTemp('wallet-exclusion-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}${Platform.pathSeparator}wallet.sqlite');
    final first = AppDatabase.forTesting(NativeDatabase(file));
    await first.markRecurringSpendGroupNotRecurring('bank|월세');
    await first.close();

    final reopened = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(reopened.close);
    expect(await reopened.watchNotRecurringGroupKeys().first, contains('bank|월세'));
    await reopened.unmarkRecurringSpendGroupNotRecurring('bank|월세');
    expect(await reopened.watchNotRecurringGroupKeys().first, isEmpty);
  });
}

void _createSharedVersion4Tables(dynamic db) {
  db.execute('CREATE TABLE app_settings (id INTEGER NOT NULL PRIMARY KEY)');
  db.execute('''
    CREATE TABLE transactions (
      local_id TEXT NOT NULL PRIMARY KEY,
      deleted_at INTEGER,
      occurred_at INTEGER NOT NULL,
      created_at INTEGER NOT NULL,
      category_id TEXT
    );
  ''');
  db.execute("INSERT INTO transactions VALUES ('transaction-before-upgrade', NULL, 100, 100, NULL)");
}

Future<bool> _tableExists(AppDatabase database, String tableName) async {
  final rows = await database.customSelect(
    "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
    variables: [Variable.withString(tableName)],
  ).get();
  return rows.isNotEmpty;
}
