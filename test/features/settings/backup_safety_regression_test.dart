import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet_app/core/database/app_database.dart';
import 'package:smart_wallet_app/features/settings/application/backup_service.dart';

import '../../test_support/sqlite_test_setup.dart';

void main() {
  setUpAll(configureSqliteForTests);

  test('a backup missing the transactions section is rejected without deletion',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final now = DateTime.now();
    await db.into(db.transactions).insert(TransactionsCompanion.insert(
          localId: 'keep-me',
          type: 'expense',
          amount: 1000,
          occurredAt: now,
          createdAt: now,
          lastModifiedAt: now,
        ));
    final service = BackupService(db);
    final json = jsonEncode({
      'backupVersion': 1,
      'schemaVersion': 3,
      'createdAt': now.toUtc().toIso8601String(),
      'data': {
        'accounts': [],
        'categories': [],
        'budgets': [],
        'settings': null,
      },
    });

    await expectLater(service.restoreJsonBackup(json),
        throwsA(isA<BackupFormatException>()));
    expect((await db.select(db.transactions).get()).single.localId, 'keep-me');
  });

  test('restoring a backup keeps the current device PIN and lock setting',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final now = DateTime.now();
    await db.into(db.appSettings).insert(AppSettingsCompanion.insert(
          appLockEnabled: const drift.Value(true),
          biometricEnabled: const drift.Value(true),
          pinCode: const drift.Value('v2-pbkdf2-hash-on-this-device'),
          createdAt: now,
          lastModifiedAt: now,
        ));
    final service = BackupService(db);
    final backup = await service.exportJsonBackup();

    await service.restoreJsonBackup(backup.json);

    final settings = await db.select(db.appSettings).getSingle();
    expect(settings.pinCode, 'v2-pbkdf2-hash-on-this-device');
    expect(settings.appLockEnabled, isTrue);
    expect(settings.biometricEnabled, isTrue);
  });

  test('a section count mismatch stops restoration before current data changes',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final now = DateTime.now();
    await db.into(db.transactions).insert(TransactionsCompanion.insert(
          localId: 'keep-me',
          type: 'expense',
          amount: 1000,
          occurredAt: now,
          createdAt: now,
          lastModifiedAt: now,
        ));
    final service = BackupService(db);
    final decoded = jsonDecode((await service.exportJsonBackup()).json)
        as Map<String, dynamic>;
    decoded['backupVersion'] = 1;
    decoded.remove('dataChecksum');
    (decoded['data'] as Map<String, dynamic>)['transactions'] = <Object>[];

    await expectLater(service.restoreJsonBackup(jsonEncode(decoded)),
        throwsA(isA<BackupFormatException>()));
    expect((await db.select(db.transactions).get()).single.localId, 'keep-me');
  });

  test('editing one transaction in a new backup invalidates its checksum',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final now = DateTime.now();
    await db.into(db.transactions).insert(TransactionsCompanion.insert(
          localId: 'keep-me', type: 'expense', amount: 1000,
          occurredAt: now, createdAt: now, lastModifiedAt: now,
        ));
    final service = BackupService(db);
    final decoded = jsonDecode((await service.exportJsonBackup()).json)
        as Map<String, dynamic>;
    final data = decoded['data'] as Map<String, dynamic>;
    final transaction = (data['transactions'] as List).single as Map<String, dynamic>;
    transaction['amount'] = 9000;

    await expectLater(service.restoreJsonBackup(jsonEncode(decoded)),
        throwsA(isA<BackupFormatException>()));
    expect((await db.select(db.transactions).get()).single.amount, 1000);
  });

  test('a legacy transaction missing deletedAt is rejected before restore',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final now = DateTime.now();
    await db.into(db.transactions).insert(TransactionsCompanion.insert(
          localId: 'deleted', type: 'expense', amount: 1000,
          occurredAt: now, deletedAt: drift.Value(now),
          createdAt: now, lastModifiedAt: now,
        ));
    final service = BackupService(db);
    final decoded = jsonDecode((await service.exportJsonBackup()).json)
        as Map<String, dynamic>;
    decoded['backupVersion'] = 1;
    decoded.remove('dataChecksum');
    final data = decoded['data'] as Map<String, dynamic>;
    final transaction = (data['transactions'] as List).single as Map<String, dynamic>;
    transaction.remove('deletedAt');

    await expectLater(service.restoreJsonBackup(jsonEncode(decoded)),
        throwsA(isA<BackupFormatException>()));
    expect((await db.select(db.transactions).get()).single.deletedAt, isNotNull);
  });

  test('restore stops if new data arrives after the safety backup', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final now = DateTime.now();
    Future<void> insert(String id) => db.into(db.transactions).insert(
          TransactionsCompanion.insert(
            localId: id, type: 'expense', amount: 1000,
            occurredAt: now, createdAt: now, lastModifiedAt: now,
          ),
        ).then((_) {});
    await insert('before-snapshot');
    final service = BackupService(db);
    final snapshot = await service.exportJsonBackup();
    await insert('arrived-after-snapshot');

    await expectLater(
      service.restoreJsonBackup(snapshot.json, expectedCurrentJson: snapshot.json),
      throwsA(isA<BackupFormatException>()),
    );
    expect((await db.select(db.transactions).get()).map((tx) => tx.localId),
        containsAll(['before-snapshot', 'arrived-after-snapshot']));
  });

  test('preview counts actual records even when the summary is absent', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final now = DateTime.now();
    await db.into(db.transactions).insert(TransactionsCompanion.insert(
          localId: 'one', type: 'expense', amount: 1000,
          occurredAt: now, createdAt: now, lastModifiedAt: now,
        ));
    final service = BackupService(db);
    final decoded = jsonDecode((await service.exportJsonBackup()).json)
        as Map<String, dynamic>;
    decoded.remove('summary');

    final preview = await service.inspectJsonBackup(jsonEncode(decoded));
    expect(preview.summary.transactionCount, 1);
  });
}
