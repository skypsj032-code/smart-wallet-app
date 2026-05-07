import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet_app/core/database/app_database.dart';
import 'package:smart_wallet_app/features/settings/application/backup_service.dart';

import '../../test_support/sqlite_test_setup.dart';

void main() {
  late AppDatabase database;
  late BackupService backupService;

  setUpAll(() {
    configureSqliteForTests();
  });

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    backupService = BackupService(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('restore disables app lock when backup has no PIN code', () async {
    final backupJson = jsonEncode({
      'backupVersion': BackupService.backupVersion,
      'schemaVersion': database.schemaVersion,
      'createdAt': DateTime(2026, 5, 4).toUtc().toIso8601String(),
      'appVersion': '0.1.0',
      'summary': {
        'transactionCount': 0,
        'categoryCount': 0,
        'budgetCount': 0,
        'accountCount': 0,
      },
      'data': {
        'transactions': [],
        'categories': [],
        'budgets': [],
        'accounts': [],
        'settings': {
          'id': 1,
          'currencyCode': 'KRW',
          'weekStart': 'monday',
          'themeMode': 'system',
          'appLockEnabled': true,
          'biometricEnabled': false,
          'exportIncludeDeleted': false,
          'createdAt': DateTime(2026, 5, 4).toIso8601String(),
          'lastModifiedAt': DateTime(2026, 5, 4).toIso8601String(),
        },
      },
    });

    await backupService.restoreJsonBackup(backupJson);

    final settings = await database.select(database.appSettings).getSingle();
    expect(settings.appLockEnabled, isFalse);
    expect(settings.pinCode, isNull);
  });

  test('exportJsonBackup does not include the local PIN hash', () async {
    final now = DateTime(2026, 5, 4);
    await database.into(database.appSettings).insert(
          AppSettingsCompanion.insert(
            appLockEnabled: const drift.Value(true),
            pinCode: const drift.Value('local-pin-hash'),
            createdAt: now,
            lastModifiedAt: now,
          ),
        );

    final payload = await backupService.exportJsonBackup();
    final decoded = jsonDecode(payload.json) as Map<String, dynamic>;
    final data = decoded['data'] as Map<String, dynamic>;
    final settings = data['settings'] as Map<String, dynamic>;

    expect(settings.containsKey('pinCode'), isFalse);
  });

  test('backup round-trips recurring expenses', () async {
    final now = DateTime(2026, 5, 4);
    await database.into(database.recurringExpenses).insert(
          RecurringExpensesCompanion.insert(
            localId: 'rec_rent',
            name: 'Rent',
            type: 'expense',
            amount: 700000,
            cadence: 'monthly',
            dayOfMonth: const drift.Value(25),
            weekday: const drift.Value(null),
            accountId: 'bank',
            categoryId: const drift.Value('expense-home'),
            lastSuggestedCycleKey: const drift.Value('2026-05'),
            lastCompletedCycleKey: const drift.Value('2026-04'),
            lastDismissedCycleKey: const drift.Value('2026-03'),
            createdAt: now,
            lastModifiedAt: now,
          ),
        );

    final payload = await backupService.exportJsonBackup();

    expect(payload.summary.recurringExpenseCount, 1);
    expect(
      backupService.inspectJsonBackup(payload.json).summary.recurringExpenseCount,
      1,
    );

    final decoded = jsonDecode(payload.json) as Map<String, dynamic>;
    final data = decoded['data'] as Map<String, dynamic>;
    final recurringExpenses = data['recurringExpenses'] as List<dynamic>;
    expect(recurringExpenses, hasLength(1));
    expect(
      recurringExpenses.single,
      allOf(
        containsPair('type', 'expense'),
        containsPair('cadence', 'monthly'),
        containsPair('dayOfMonth', 25),
        containsPair('weekday', null),
        containsPair('lastSuggestedCycleKey', '2026-05'),
        containsPair('lastCompletedCycleKey', '2026-04'),
        containsPair('lastDismissedCycleKey', '2026-03'),
      ),
    );

    final summary = await backupService.restoreJsonBackup(payload.json);

    expect(summary.recurringExpenseCount, 1);

    final restored =
        await database.select(database.recurringExpenses).getSingle();
    expect(restored.localId, 'rec_rent');
    expect(restored.name, 'Rent');
    expect(restored.type, 'expense');
    expect(restored.amount, 700000);
    expect(restored.cadence, 'monthly');
    expect(restored.dayOfMonth, 25);
    expect(restored.weekday, isNull);
    expect(restored.accountId, 'bank');
    expect(restored.categoryId, 'expense-home');
    expect(restored.lastSuggestedCycleKey, '2026-05');
    expect(restored.lastCompletedCycleKey, '2026-04');
    expect(restored.lastDismissedCycleKey, '2026-03');
  });

  test('inspectJsonBackup rejects backups from a newer schema', () {
    final backupJson = jsonEncode({
      'backupVersion': BackupService.backupVersion,
      'schemaVersion': database.schemaVersion + 1,
      'createdAt': DateTime(2026, 5, 4).toUtc().toIso8601String(),
      'appVersion': '0.1.0',
      'data': {
        'transactions': [],
        'categories': [],
        'budgets': [],
        'accounts': [],
      },
    });

    expect(
      () => backupService.inspectJsonBackup(backupJson),
      throwsA(isA<BackupFormatException>()),
    );
  });
}
