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
}
