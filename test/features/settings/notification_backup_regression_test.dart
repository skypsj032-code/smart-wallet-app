import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet_app/core/database/app_database.dart';
import 'package:smart_wallet_app/features/settings/application/backup_service.dart';

import '../../test_support/sqlite_test_setup.dart';

void main() {
  setUpAll(configureSqliteForTests);

  test('backup round-trips notification links to soft-deleted transactions and rules',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final now = DateTime(2026, 5, 4);
    await db.into(db.transactions).insert(TransactionsCompanion.insert(
      localId: 'tx-1', type: 'expense', amount: 1000,
      occurredAt: now, deletedAt: drift.Value(now),
      createdAt: now, lastModifiedAt: now,
    ));
    await db.customStatement('''
      INSERT INTO notification_histories
        (package_name, amount, type, merchant, detected_at, event_id, status, transaction_id)
      VALUES ('bank', 1000, 'expense', 'shop', 100, 'event-1', 'recorded', 'tx-1'),
             ('bank', 2000, 'expense', 'shop', 101, 'event-2', 'pending', NULL)
    ''');
    await db.customStatement('''
      INSERT INTO merchant_category_rules (merchant_key, type, category_id, updated_at)
      VALUES ('shop', 'expense', 'food', 100)
    ''');

    final service = BackupService(db);
    final backup = await service.exportJsonBackup();
    await db.customStatement('DELETE FROM notification_histories');
    await db.customStatement('DELETE FROM merchant_category_rules');
    await service.restoreJsonBackup(backup.json);

    final histories = await db.customSelect('''
      SELECT event_id, status, transaction_id FROM notification_histories ORDER BY id
    ''').get();
    expect(histories.map((row) => row.data['event_id']), ['event-1', 'event-2']);
    expect(histories.first.data['status'], 'recorded');
    expect(histories.first.data['transaction_id'], 'tx-1');
    expect(histories.last.data['status'], 'pending');
    expect((await db.select(db.transactions).getSingle()).deletedAt, isNotNull);
    final rule = await db.customSelect('''
      SELECT merchant_key, type, category_id FROM merchant_category_rules
    ''').getSingle();
    expect(rule.data, containsPair('merchant_key', 'shop'));
    expect(rule.data, containsPair('type', 'expense'));
    expect(rule.data, containsPair('category_id', 'food'));
  });

  test('version 9 backup histories without new fields restore as legacy',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db.customStatement('''
      INSERT INTO notification_histories (package_name, amount, type, detected_at)
      VALUES ('bank', 1000, 'expense', 100)
    ''');
    final service = BackupService(db);
    final decoded = jsonDecode((await service.exportJsonBackup()).json)
        as Map<String, dynamic>;
    decoded['schemaVersion'] = 9;
    final data = decoded['data'] as Map<String, dynamic>;
    data.remove('merchantCategoryRules');
    final history = (data['notificationHistories'] as List).single
        as Map<String, dynamic>;
    history.remove('eventId');
    history.remove('status');
    history.remove('transactionId');
    _updateChecksum(decoded);

    await service.restoreJsonBackup(jsonEncode(decoded));

    final restored = await db.customSelect('''
      SELECT event_id, status, transaction_id FROM notification_histories
    ''').getSingle();
    expect(restored.data['status'], 'legacy');
    expect(restored.data['event_id'], isNull);
    expect(restored.data['transaction_id'], isNull);
  });

  test('old backup retaining histories clears links to missing transactions',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final now = DateTime(2026, 5, 4);
    await db.into(db.transactions).insert(TransactionsCompanion.insert(
      localId: 'tx-current', type: 'expense', amount: 1000,
      occurredAt: now, createdAt: now, lastModifiedAt: now,
    ));
    await db.customStatement('''
      INSERT INTO notification_histories
        (package_name, amount, type, detected_at, event_id, status, transaction_id)
      VALUES ('bank', 1000, 'expense', 100, 'event-current', 'recorded', 'tx-current')
    ''');
    await db.customStatement('''
      INSERT INTO merchant_category_rules (merchant_key, type, category_id, updated_at)
      VALUES ('shop', 'expense', 'food', 100)
    ''');
    final service = BackupService(db);
    final decoded = jsonDecode((await service.exportJsonBackup()).json)
        as Map<String, dynamic>;
    decoded['schemaVersion'] = 9;
    final data = decoded['data'] as Map<String, dynamic>;
    data['transactions'] = <Object>[];
    data.remove('notificationHistories');
    data.remove('merchantCategoryRules');
    final summary = decoded['summary'] as Map<String, dynamic>;
    summary['transactionCount'] = 0;
    summary.remove('notificationHistoryCount');
    summary.remove('merchantCategoryRuleCount');
    _updateChecksum(decoded);

    await service.restoreJsonBackup(jsonEncode(decoded));

    final history = await db.customSelect('''
      SELECT event_id, status, transaction_id FROM notification_histories
    ''').getSingle();
    expect(history.data['event_id'], 'event-current');
    expect(history.data['status'], 'legacy');
    expect(history.data['transaction_id'], isNull);
    expect((await db.customSelect('SELECT category_id FROM merchant_category_rules')
        .getSingle()).data['category_id'], 'food');
  });

  test('duplicate event ids reject a backup without replacing current data',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db.customStatement('''
      INSERT INTO notification_histories
        (package_name, amount, type, detected_at, event_id, status)
      VALUES ('bank', 1000, 'expense', 100, 'event-1', 'pending'),
             ('bank', 2000, 'expense', 101, 'event-2', 'pending')
    ''');
    final service = BackupService(db);
    final decoded = jsonDecode((await service.exportJsonBackup()).json)
        as Map<String, dynamic>;
    final histories = (decoded['data'] as Map<String, dynamic>)['notificationHistories'] as List;
    (histories.last as Map<String, dynamic>)['eventId'] = 'event-1';
    _updateChecksum(decoded);

    await expectLater(service.restoreJsonBackup(jsonEncode(decoded)),
        throwsA(isA<BackupFormatException>()));
    final rows = await db.customSelect(
      'SELECT event_id FROM notification_histories ORDER BY id',
    ).get();
    expect(rows.map((row) => row.data['event_id']), ['event-1', 'event-2']);
  });
}

void _updateChecksum(Map<String, dynamic> backup) {
  backup['dataChecksum'] = sha256
      .convert(utf8.encode(jsonEncode(backup['data'])))
      .toString();
}
