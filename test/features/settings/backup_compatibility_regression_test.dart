import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet_app/core/database/app_database.dart';
import 'package:smart_wallet_app/features/settings/application/backup_service.dart';

import '../../test_support/sqlite_test_setup.dart';

void main() {
  setUpAll(configureSqliteForTests);

  test('old backup without schedules keeps compatible local schedules', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await _seedScheduledExpense(db);
    final service = BackupService(db);
    final decoded = jsonDecode((await service.exportJsonBackup()).json)
        as Map<String, dynamic>;
    decoded['backupVersion'] = 1;
    decoded.remove('dataChecksum');
    decoded['schemaVersion'] = 3;
    (decoded['data'] as Map<String, dynamic>).remove('recurringExpenses');
    (decoded['summary'] as Map<String, dynamic>).remove('recurringExpenseCount');

    await service.restoreJsonBackup(jsonEncode(decoded));

    expect((await db.select(db.recurringExpenses).get()).single.localId, 'rent');
  });

  test('old backup is rejected if retained schedules would lose their account',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await _seedScheduledExpense(db);
    final service = BackupService(db);
    final decoded = jsonDecode((await service.exportJsonBackup()).json)
        as Map<String, dynamic>;
    decoded['backupVersion'] = 1;
    decoded.remove('dataChecksum');
    decoded['schemaVersion'] = 3;
    final data = decoded['data'] as Map<String, dynamic>;
    data.remove('recurringExpenses');
    data['accounts'] = <Object>[];
    final summary = decoded['summary'] as Map<String, dynamic>;
    summary.remove('recurringExpenseCount');
    summary['accountCount'] = 0;

    await expectLater(service.restoreJsonBackup(jsonEncode(decoded)),
        throwsA(isA<BackupFormatException>()));
    expect((await db.select(db.accounts).get()).single.localId, 'bank');
    expect((await db.select(db.recurringExpenses).get()).single.localId, 'rent');
  });

  test('legacy recurring backup retains its last completed month', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await _seedScheduledExpense(db);
    final service = BackupService(db);
    final decoded = jsonDecode((await service.exportJsonBackup()).json)
        as Map<String, dynamic>;
    decoded['backupVersion'] = 1;
    decoded.remove('dataChecksum');
    decoded['schemaVersion'] = 5;
    final data = decoded['data'] as Map<String, dynamic>;
    final recurring = (data['recurringExpenses'] as List).single
        as Map<String, dynamic>;
    recurring['lastCreatedMonthKey'] = recurring.remove('lastCompletedCycleKey');
    recurring.remove('type');
    recurring.remove('cadence');

    await service.restoreJsonBackup(jsonEncode(decoded));

    final restored = (await db.select(db.recurringExpenses).get()).single;
    expect(restored.lastCompletedCycleKey, '2026-04');
    expect(restored.type, 'expense');
    expect(restored.cadence, 'monthly');
  });

  test('full backup restores notification history, OCR drafts and exclusions',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final now = DateTime(2026, 5, 4);
    await db.into(db.notificationHistories).insert(
          NotificationHistoriesCompanion.insert(
            packageName: 'bank', amount: 1000, type: 'expense', detectedAt: now,
          ),
        );
    await db.into(db.ocrDrafts).insert(OcrDraftsCompanion.insert(
          localId: 'receipt',
          ocrStatus: 'pending',
          createdAt: now,
          lastModifiedAt: now,
        ));
    await db.customStatement('''
      CREATE TABLE IF NOT EXISTS recurring_spend_overrides (
        group_key TEXT NOT NULL PRIMARY KEY, action_type TEXT NOT NULL,
        created_at INTEGER NOT NULL, last_modified_at INTEGER NOT NULL
      )
    ''');
    await db.customStatement(
      "INSERT INTO recurring_spend_overrides VALUES ('hidden', 'not_recurring', 100, 101)",
    );

    final service = BackupService(db);
    final backup = await service.exportJsonBackup();
    await db.delete(db.notificationHistories).go();
    await db.delete(db.ocrDrafts).go();
    await db.customStatement('DELETE FROM recurring_spend_overrides');
    await service.restoreJsonBackup(backup.json);

    expect((await db.select(db.notificationHistories).get()), hasLength(1));
    expect((await db.select(db.ocrDrafts).get()).single.localId, 'receipt');
    expect((await db.customSelect('SELECT group_key FROM recurring_spend_overrides').get())
        .single.data['group_key'], 'hidden');
  });

  test('old settings keep the current default category seed version', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final now = DateTime.now();
    await db.into(db.appSettings).insert(AppSettingsCompanion.insert(
          defaultCategorySeedVersion: const drift.Value(2),
          createdAt: now,
          lastModifiedAt: now,
        ));
    final service = BackupService(db);
    final decoded = jsonDecode((await service.exportJsonBackup()).json)
        as Map<String, dynamic>;
    decoded['backupVersion'] = 1;
    decoded['schemaVersion'] = 3;
    decoded.remove('dataChecksum');
    final data = decoded['data'] as Map<String, dynamic>;
    (data['settings'] as Map<String, dynamic>).remove('defaultCategorySeedVersion');
    data.remove('recurringExpenses');
    (decoded['summary'] as Map<String, dynamic>).remove('recurringExpenseCount');

    await service.restoreJsonBackup(jsonEncode(decoded));

    expect((await db.select(db.appSettings).getSingle()).defaultCategorySeedVersion, 2);
  });
}

Future<void> _seedScheduledExpense(AppDatabase db) async {
  final now = DateTime(2026, 5, 4);
  await db.into(db.accounts).insert(AccountsCompanion.insert(
        localId: 'bank',
        name: 'Bank',
        type: 'bank',
        createdAt: now,
        lastModifiedAt: now,
      ));
  await db.into(db.recurringExpenses).insert(RecurringExpensesCompanion.insert(
        localId: 'rent',
        name: 'Rent',
        type: 'expense',
        amount: 700000,
        cadence: 'monthly',
        dayOfMonth: const drift.Value(25),
        accountId: 'bank',
        lastCompletedCycleKey: const drift.Value('2026-04'),
        createdAt: now,
        lastModifiedAt: now,
      ));
}
