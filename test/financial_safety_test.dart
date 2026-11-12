import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet_app/app/bootstrap/app_bootstrap_provider.dart';
import 'package:smart_wallet_app/core/database/app_database.dart';
import 'package:smart_wallet_app/core/database/providers/database_providers.dart';
import 'package:smart_wallet_app/features/accounts/application/accounts_provider.dart';
import 'package:smart_wallet_app/features/dashboard/application/dashboard_summary_provider.dart';
import 'package:smart_wallet_app/features/settings/application/backup_service.dart';

void main() {
  late AppDatabase database;
  late DateTime now;

  setUp(() {
    database = AppDatabase.testing(NativeDatabase.memory());
    now = DateTime.now();
  });

  tearDown(() => database.close());

  Future<void> addAccount(String id) async {
    await database.into(database.accounts).insert(AccountsCompanion.insert(
          localId: id,
          name: id,
          type: 'bank',
          createdAt: now,
          lastModifiedAt: now,
        ));
  }

  Future<void> addTransaction({
    required String id,
    required String type,
    required int amount,
    String? accountId,
    String? fromAccountId,
    String? toAccountId,
    String? categoryId,
  }) async {
    await database.into(database.transactions).insert(TransactionsCompanion.insert(
          localId: id,
          type: type,
          amount: amount,
          occurredAt: now,
          accountId: drift.Value(accountId),
          fromAccountId: drift.Value(fromAccountId),
          toAccountId: drift.Value(toAccountId),
          categoryId: drift.Value(categoryId),
          createdAt: now,
          lastModifiedAt: now,
        ));
  }

  Future<void> addBudget(String id, String? categoryId, int amount) async {
    final month = '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}';
    await database.into(database.budgets).insert(BudgetsCompanion.insert(
          localId: id,
          monthKey: month,
          categoryId: drift.Value(categoryId),
          amountLimit: amount,
          createdAt: now,
          lastModifiedAt: now,
        ));
  }

  group('backup restore safety', () {
    test('missing data sections are rejected before existing records change', () async {
      await addTransaction(id: 'saved', type: 'expense', amount: 12000);
      final backup = jsonEncode({
        'backupVersion': 1,
        'schemaVersion': 3,
        'createdAt': now.toIso8601String(),
        'data': {'transactions': <Object>[]},
      });
      final service = BackupService(database);

      expect(() => service.inspectJsonBackup(backup), throwsA(isA<BackupFormatException>()));
      await expectLater(
        service.restoreJsonBackup(backup),
        throwsA(isA<BackupFormatException>()),
      );
      expect((await database.select(database.transactions).get()).single.localId, 'saved');
    });

    test('restoring preserves the current device PIN and lock setting', () async {
      await database.into(database.appSettings).insert(AppSettingsCompanion.insert(
            appLockEnabled: const drift.Value(true),
            pinCode: const drift.Value('existing-pin-hash'),
            createdAt: now,
            lastModifiedAt: now,
          ));
      final service = BackupService(database);
      final backup = await service.exportJsonBackup();
      final data = jsonDecode(backup.json) as Map<String, dynamic>;
      final settings = (data['data'] as Map<String, dynamic>)['settings'] as Map<String, dynamic>;
      expect(settings.containsKey('pinCode'), isFalse);

      await service.restoreJsonBackup(backup.json);

      final restored = await database.select(database.appSettings).getSingle();
      expect(restored.appLockEnabled, isTrue);
      expect(restored.pinCode, 'existing-pin-hash');
    });

    test('a legacy backup without settings keeps the current settings row', () async {
      await database.into(database.appSettings).insert(AppSettingsCompanion.insert(
            appLockEnabled: const drift.Value(true),
            pinCode: const drift.Value('local-pin'),
            createdAt: now,
            lastModifiedAt: now,
          ));
      final backup = jsonEncode({
        'backupVersion': 1,
        'schemaVersion': 1,
        'createdAt': now.toIso8601String(),
        'summary': {
          'transactionCount': 0, 'categoryCount': 0, 'budgetCount': 0, 'accountCount': 0,
        },
        'data': {
          'transactions': <Object>[],
          'categories': <Object>[],
          'budgets': <Object>[],
          'accounts': <Object>[],
          'settings': null,
        },
      });

      await BackupService(database).restoreJsonBackup(backup);

      final restored = await database.select(database.appSettings).getSingle();
      expect(restored.appLockEnabled, isTrue);
      expect(restored.pinCode, 'local-pin');
    });

    test('a backup with misleading summary counts is rejected', () async {
      await addTransaction(id: 'one', type: 'expense', amount: 12000);
      final service = BackupService(database);
      final payload = await service.exportJsonBackup();
      final backup = jsonDecode(payload.json) as Map<String, dynamic>;
      (backup['summary'] as Map<String, dynamic>)['transactionCount'] = 999;

      expect(
        () => service.inspectJsonBackup(jsonEncode(backup)),
        throwsA(isA<BackupFormatException>()),
      );
    });

    test('modified backup data with unchanged counts fails integrity validation', () async {
      await addTransaction(id: 'one', type: 'expense', amount: 12000);
      final service = BackupService(database);
      final payload = await service.exportJsonBackup();
      final backup = jsonDecode(payload.json) as Map<String, dynamic>;
      final data = backup['data'] as Map<String, dynamic>;
      ((data['transactions'] as List<dynamic>).single as Map<String, dynamic>)['amount'] = 1;

      await expectLater(service.restoreJsonBackup(jsonEncode(backup)), throwsA(isA<BackupFormatException>()));
      expect((await database.select(database.transactions).get()).single.amount, 12000);
    });

    test('a new backup without its checksum is rejected', () async {
      await addTransaction(id: 'one', type: 'expense', amount: 12000);
      final service = BackupService(database);
      final payload = await service.exportJsonBackup();
      final backup = jsonDecode(payload.json) as Map<String, dynamic>;
      backup.remove('dataChecksum');

      await expectLater(service.restoreJsonBackup(jsonEncode(backup)), throwsA(isA<BackupFormatException>()));
      expect((await database.select(database.transactions).get()).single.localId, 'one');
    });

    test('missing count metadata is rejected before data is replaced', () async {
      await addTransaction(id: 'one', type: 'expense', amount: 12000);
      final service = BackupService(database);
      final payload = await service.exportJsonBackup();
      final backup = jsonDecode(payload.json) as Map<String, dynamic>;
      (backup['summary'] as Map<String, dynamic>).remove('transactionCount');

      await expectLater(service.restoreJsonBackup(jsonEncode(backup)), throwsA(isA<BackupFormatException>()));
      expect((await database.select(database.transactions).get()).single.localId, 'one');
    });

    test('an invalid record does not erase existing data on restore', () async {
      await addTransaction(id: 'keep-me', type: 'expense', amount: 15000);
      final service = BackupService(database);
      final payload = await service.exportJsonBackup();
      final backup = jsonDecode(payload.json) as Map<String, dynamic>;
      final data = backup['data'] as Map<String, dynamic>;
      data['transactions'] = [<String, dynamic>{'type': 'expense'}];

      await expectLater(service.restoreJsonBackup(jsonEncode(backup)), throwsA(anything));
      expect((await database.select(database.transactions).get()).single.localId, 'keep-me');
    });

    test('missing nullable transaction fields are rejected before restore', () async {
      await addAccount('bank');
      await addTransaction(id: 'deleted', type: 'expense', amount: 12000, accountId: 'bank');
      await (database.update(database.transactions)..where((t) => t.localId.equals('deleted')))
          .write(TransactionsCompanion(deletedAt: drift.Value(now)));
      final service = BackupService(database);
      final payload = await service.exportJsonBackup();
      expect(service.inspectJsonBackup(payload.json).summary.transactionCount, 1);

      for (final field in ['accountId', 'deletedAt']) {
        final backup = jsonDecode(payload.json) as Map<String, dynamic>;
        final data = backup['data'] as Map<String, dynamic>;
        final transaction = (data['transactions'] as List<dynamic>).single as Map<String, dynamic>;
        transaction.remove(field);
        expect(
          () => service.inspectJsonBackup(jsonEncode(backup)),
          throwsA(isA<BackupFormatException>()),
        );
        await expectLater(service.restoreJsonBackup(jsonEncode(backup)), throwsA(isA<BackupFormatException>()));
        expect((await database.select(database.transactions).get()).single.deletedAt, isNotNull);
      }
    });

    test('schema-1 formatted backups with transactions remain readable', () async {
      await addAccount('bank');
      await addTransaction(id: 'legacy', type: 'expense', amount: 12000, accountId: 'bank');
      final service = BackupService(database);
      final payload = await service.exportJsonBackup();
      final backup = jsonDecode(payload.json) as Map<String, dynamic>;
      backup['backupVersion'] = 1;
      backup['schemaVersion'] = 1;
      backup.remove('dataChecksum');
      (backup['data'] as Map<String, dynamic>)['settings'] = null;

      await service.restoreJsonBackup(jsonEncode(backup));
      final restored = (await database.select(database.transactions).get()).single;
      expect(restored.localId, 'legacy');
      expect(restored.accountId, 'bank');
      expect(restored.amount, 12000);
    });

    test('preview warns if an existing record refers to a missing account', () async {
      await addTransaction(id: 'orphan', type: 'expense', amount: 12000, accountId: 'missing');
      final service = BackupService(database);
      final payload = await service.exportJsonBackup();
      final preview = service.inspectJsonBackup(payload.json);
      expect(preview.warnings, isNotEmpty);
    });

    test('preview warns if a budget has an invalid amount or month', () async {
      await database.into(database.budgets).insert(BudgetsCompanion.insert(
            localId: 'bad-budget',
            monthKey: '2026-99',
            amountLimit: -10,
            createdAt: now,
            lastModifiedAt: now,
          ));
      final service = BackupService(database);
      final payload = await service.exportJsonBackup();
      expect(service.inspectJsonBackup(payload.json).warnings, isNotEmpty);
    });

    test('legacy backup with no settings creates a usable settings row', () async {
      final backup = jsonEncode({
        'backupVersion': 1,
        'schemaVersion': 1,
        'createdAt': now.toIso8601String(),
        'summary': {
          'transactionCount': 0, 'categoryCount': 0, 'budgetCount': 0, 'accountCount': 0,
        },
        'data': {
          'transactions': <Object>[],
          'categories': <Object>[],
          'budgets': <Object>[],
          'accounts': <Object>[],
          'settings': null,
        },
      });
      await BackupService(database).restoreJsonBackup(backup);
      final settings = await database.select(database.appSettings).getSingle();
      expect(settings.appLockEnabled, isFalse);
      expect(settings.pinCode, isNull);
    });

    test('an old enabled lock without a PIN is not reported as active at startup', () async {
      await database.into(database.appSettings).insert(AppSettingsCompanion.insert(
            appLockEnabled: const drift.Value(true),
            biometricEnabled: const drift.Value(true),
            createdAt: now,
            lastModifiedAt: now,
          ));
      final container = ProviderContainer(overrides: [
        appDatabaseProvider.overrideWith((ref) => database),
      ]);
      addTearDown(container.dispose);
      await container.read(appBootstrapProvider.future);
      final settings = await database.select(database.appSettings).getSingle();
      expect(settings.appLockEnabled, isFalse);
      expect(settings.biometricEnabled, isFalse);
    });
  });

  group('budget totals', () {
    test('overall budget is not added to its category budgets', () async {
      await addBudget('overall', null, 1000000);
      await addBudget('food', 'food', 300000);
      await addTransaction(id: 'lunch', type: 'expense', amount: 200000, categoryId: 'food');

      final summary = await database.watchBudgetSummary().first;
      expect(summary.totalBudget, 1000000);
      expect(summary.totalSpent, 200000);
      expect(summary.remaining, 800000);
      expect(summary.items.singleWhere((item) => item.categoryId == null).spentAmount, 200000);

      final container = ProviderContainer(overrides: [
        appDatabaseProvider.overrideWith((ref) => database),
      ]);
      addTearDown(container.dispose);
      final dashboard = await container.read(dashboardSummaryProvider.future);
      expect(dashboard.totalBudget, 1000000);
      expect(dashboard.remainingBudget, 800000);
    });

    test('category budgets are summed when no overall budget exists', () async {
      await addBudget('food', 'food', 300000);
      await addBudget('transport', 'transport', 100000);
      final summary = await database.watchBudgetSummary().first;
      expect(summary.totalBudget, 400000);
    });
  });

  test('account balances update for income, transfers, edits and deletion', () async {
    await addAccount('bank');
    await addAccount('cash');
    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWith((ref) => database),
    ]);
    addTearDown(container.dispose);
    final iterator = StreamIterator(container.read(accountBalancesProvider.stream));
    addTearDown(iterator.cancel);

    Future<Map<String, int>> nextBalances() async {
      expect(await iterator.moveNext().timeout(const Duration(seconds: 3)), isTrue);
      return {for (final item in iterator.current) item.account.localId: item.balance};
    }

    expect(await nextBalances(), {'bank': 0, 'cash': 0});
    await addTransaction(id: 'income', type: 'income', amount: 100000, accountId: 'bank');
    expect(await nextBalances(), {'bank': 100000, 'cash': 0});
    await addTransaction(
      id: 'transfer', type: 'transfer', amount: 30000,
      fromAccountId: 'bank', toAccountId: 'cash',
    );
    expect(await nextBalances(), {'bank': 70000, 'cash': 30000});
    await (database.update(database.transactions)..where((t) => t.localId.equals('transfer')))
        .write(const TransactionsCompanion(amount: drift.Value(20000)));
    expect(await nextBalances(), {'bank': 80000, 'cash': 20000});
    await (database.update(database.transactions)..where((t) => t.localId.equals('transfer')))
        .write(TransactionsCompanion(deletedAt: drift.Value(now)));
    expect(await nextBalances(), {'bank': 100000, 'cash': 0});
  });
}
