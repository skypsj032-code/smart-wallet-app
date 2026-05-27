import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/providers/database_providers.dart';

class BackupSummary {
  const BackupSummary({
    required this.transactionCount,
    required this.categoryCount,
    required this.budgetCount,
    required this.accountCount,
    required this.recurringExpenseCount,
  });

  final int transactionCount;
  final int categoryCount;
  final int budgetCount;
  final int accountCount;
  final int recurringExpenseCount;
}

class BackupPayload {
  const BackupPayload({
    required this.json,
    required this.summary,
    required this.fileName,
  });

  final String json;
  final BackupSummary summary;
  final String fileName;
}

class RestoreSafetyBackup {
  const RestoreSafetyBackup({
    required this.payload,
    required this.file,
  });

  final BackupPayload payload;
  final File file;
}

class BackupPreview {
  const BackupPreview({
    required this.backupVersion,
    required this.schemaVersion,
    required this.createdAt,
    required this.appVersion,
    required this.summary,
  });

  final int backupVersion;
  final int schemaVersion;
  final DateTime createdAt;
  final String appVersion;
  final BackupSummary summary;
}

class BackupFormatException implements Exception {
  const BackupFormatException(this.message);

  final String message;

  @override
  String toString() => message;
}

class BackupService {
  BackupService(this._database);

  final AppDatabase _database;
  static const int backupVersion = 1;

  Future<BackupPayload> exportJsonBackup() async {
    final transactionsData = await _database.select(_database.transactions).get();
    final categoriesData = await _database.select(_database.categories).get();
    final budgetsData = await _database.select(_database.budgets).get();
    final accountsData = await _database.select(_database.accounts).get();
    final recurringExpensesData =
        await _database.select(_database.recurringExpenses).get();
    final settingsData = await _database.select(_database.appSettings).get();

    final createdAt = DateTime.now().toUtc();
    final payload = {
      'backupVersion': backupVersion,
      'schemaVersion': _database.schemaVersion,
      'createdAt': createdAt.toIso8601String(),
      'appVersion': '0.1.0',
      'deviceId': 'local-device',
      'summary': {
        'transactionCount': transactionsData.length,
        'categoryCount': categoriesData.length,
        'budgetCount': budgetsData.length,
        'accountCount': accountsData.length,
        'recurringExpenseCount': recurringExpensesData.length,
      },
      'data': {
        'transactions': transactionsData.map(_transactionToJson).toList(),
        'categories': categoriesData.map(_categoryToJson).toList(),
        'budgets': budgetsData.map(_budgetToJson).toList(),
        'accounts': accountsData.map(_accountToJson).toList(),
        'recurringExpenses':
            recurringExpensesData.map(_recurringExpenseToJson).toList(),
        'settings': settingsData.isEmpty ? null : _settingsToJson(settingsData.first),
      },
    };

    final fileName = 'smart_wallet_backup_${createdAt.millisecondsSinceEpoch}.json';

    // JSON 직렬화는 CPU 집약적이므로 별도 Isolate에서 실행해 UI 프레임 드롭 방지.
    final jsonString = await Isolate.run(
      () => const JsonEncoder.withIndent('  ').convert(payload),
    );

    return BackupPayload(
      json: jsonString,
      summary: BackupSummary(
        transactionCount: transactionsData.length,
        categoryCount: categoriesData.length,
        budgetCount: budgetsData.length,
        accountCount: accountsData.length,
        recurringExpenseCount: recurringExpensesData.length,
      ),
      fileName: fileName,
    );
  }

  Future<File> saveBackupFile(BackupPayload payload) async {
    final directory = await getApplicationDocumentsDirectory();
    final targetPath = p.join(directory.path, payload.fileName);
    final tmpPath = '$targetPath.tmp';
    final tmpFile = File(tmpPath);
    final targetFile = File(targetPath);
    final backupPath = '$targetPath.bak';
    final backupFile = File(backupPath);

    // 원자적 저장: .tmp 파일에 먼저 쓰고 완료 후 rename
    // → 기존 파일이 있으면 .bak으로 잠시 대피시켜 교체 실패 시 복구
    await tmpFile.writeAsString(payload.json, flush: true);

    if (!await targetFile.exists()) {
      return tmpFile.rename(targetPath);
    }

    if (await backupFile.exists()) {
      await backupFile.delete();
    }

    await targetFile.rename(backupPath);
    try {
      final finalFile = await tmpFile.rename(targetPath);
      if (await backupFile.exists()) {
        await backupFile.delete();
      }
      return finalFile;
    } catch (_) {
      if (await backupFile.exists()) {
        await backupFile.rename(targetPath);
      }
      rethrow;
    } finally {
      if (await tmpFile.exists()) {
        await tmpFile.delete();
      }
    }
  }

  Future<void> shareBackupFile(
    File file, {
    String text = 'Smart Wallet JSON backup file',
  }) async {
    await Share.shareXFiles([XFile(file.path)], text: text);
  }

  Future<RestoreSafetyBackup> createRestoreSafetyBackup() async {
    final payload = await exportJsonBackup();
    final file = await saveBackupFile(payload);
    return RestoreSafetyBackup(payload: payload, file: file);
  }

  Future<BackupPreview> inspectJsonBackup(String jsonText) async {
    final decoded = await _decodeAndValidateBackup(jsonText);
    final summaryData = decoded['summary'] as Map<String, dynamic>? ?? const {};

    return BackupPreview(
      backupVersion: decoded['backupVersion'] as int,
      schemaVersion: decoded['schemaVersion'] as int,
      createdAt: DateTime.parse(decoded['createdAt'] as String),
      appVersion: decoded['appVersion'] as String? ?? 'unknown',
      summary: BackupSummary(
        transactionCount: (summaryData['transactionCount'] as num?)?.toInt() ?? 0,
        categoryCount: (summaryData['categoryCount'] as num?)?.toInt() ?? 0,
        budgetCount: (summaryData['budgetCount'] as num?)?.toInt() ?? 0,
        accountCount: (summaryData['accountCount'] as num?)?.toInt() ?? 0,
        recurringExpenseCount:
            (summaryData['recurringExpenseCount'] as num?)?.toInt() ?? 0,
      ),
    );
  }

  Future<BackupSummary> restoreJsonBackup(String jsonText) async {
    final decoded = await _decodeAndValidateBackup(jsonText);
    final data = decoded['data'] as Map<String, dynamic>;

    final transactionsData = (data['transactions'] as List<dynamic>? ?? const []);
    final categoriesData = (data['categories'] as List<dynamic>? ?? const []);
    final budgetsData = (data['budgets'] as List<dynamic>? ?? const []);
    final accountsData = (data['accounts'] as List<dynamic>? ?? const []);
    final recurringExpensesData =
        (data['recurringExpenses'] as List<dynamic>? ?? const []);
    final settingsData = data['settings'] as Map<String, dynamic>?;

    await _database.transaction(() async {
      await _database.delete(_database.transactions).go();
      await _database.delete(_database.categories).go();
      await _database.delete(_database.budgets).go();
      await _database.delete(_database.recurringExpenses).go();
      await _database.delete(_database.accounts).go();
      await _database.delete(_database.appSettings).go();

      // ─── batch.insertAll: N번 디스크 I/O → 1번 Transaction으로 최적화 ───
      await _database.batch((batch) {
        batch.insertAll(
          _database.categories,
          categoriesData.cast<Map<String, dynamic>>().map((raw) =>
              CategoriesCompanion.insert(
                localId: raw['localId'] as String,
                name: raw['name'] as String,
                type: raw['type'] as String,
                iconName: Value(raw['iconName'] as String?),
                colorHex: Value(raw['colorHex'] as String?),
                isDefault: Value((raw['isDefault'] as bool?) ?? false),
                isActive: Value((raw['isActive'] as bool?) ?? true),
                sortOrder: Value((raw['sortOrder'] as int?) ?? 0),
                createdAt: DateTime.parse(raw['createdAt'] as String),
                lastModifiedAt: DateTime.parse(raw['lastModifiedAt'] as String),
              )).toList(),
        );

        batch.insertAll(
          _database.accounts,
          accountsData.cast<Map<String, dynamic>>().map((raw) =>
              AccountsCompanion.insert(
                localId: raw['localId'] as String,
                name: raw['name'] as String,
                type: raw['type'] as String,
                colorHex: Value(raw['colorHex'] as String?),
                includeInNetWorth: Value((raw['includeInNetWorth'] as bool?) ?? true),
                isActive: Value((raw['isActive'] as bool?) ?? true),
                createdAt: DateTime.parse(raw['createdAt'] as String),
                lastModifiedAt: DateTime.parse(raw['lastModifiedAt'] as String),
              )).toList(),
        );

        batch.insertAll(
          _database.budgets,
          budgetsData.cast<Map<String, dynamic>>().map((raw) =>
              BudgetsCompanion.insert(
                localId: raw['localId'] as String,
                monthKey: raw['monthKey'] as String,
                categoryId: Value(raw['categoryId'] as String?),
                amountLimit: raw['amountLimit'] as int,
                alert50Enabled: Value((raw['alert50Enabled'] as bool?) ?? true),
                alert80Enabled: Value((raw['alert80Enabled'] as bool?) ?? true),
                alert100Enabled: Value((raw['alert100Enabled'] as bool?) ?? true),
                createdAt: DateTime.parse(raw['createdAt'] as String),
                lastModifiedAt: DateTime.parse(raw['lastModifiedAt'] as String),
              )).toList(),
        );

        batch.insertAll(
          _database.transactions,
          transactionsData.cast<Map<String, dynamic>>().map((raw) =>
              TransactionsCompanion.insert(
                localId: raw['localId'] as String,
                type: raw['type'] as String,
                amount: raw['amount'] as int,
                occurredAt: DateTime.parse(raw['occurredAt'] as String),
                accountId: Value(raw['accountId'] as String?),
                fromAccountId: Value(raw['fromAccountId'] as String?),
                toAccountId: Value(raw['toAccountId'] as String?),
                categoryId: Value(raw['categoryId'] as String?),
                merchantName: Value(raw['merchantName'] as String?),
                paymentMethod: Value(raw['paymentMethod'] as String?),
                memo: Value(raw['memo'] as String?),
                tagJson: Value(raw['tagJson'] as String?),
                createdAt: DateTime.parse(raw['createdAt'] as String),
                lastModifiedAt: DateTime.parse(raw['lastModifiedAt'] as String),
                deletedAt: Value(
                  raw['deletedAt'] == null
                      ? null
                      : DateTime.parse(raw['deletedAt'] as String),
                ),
              )).toList(),
        );

        batch.insertAll(
          _database.recurringExpenses,
          recurringExpensesData.cast<Map<String, dynamic>>().map((raw) =>
              RecurringExpensesCompanion.insert(
                localId: raw['localId'] as String,
                name: raw['name'] as String,
                type: raw['type'] as String? ?? 'expense',
                amount: raw['amount'] as int,
                cadence: raw['cadence'] as String? ?? 'monthly',
                dayOfMonth: Value(raw['dayOfMonth'] as int?),
                weekday: Value(raw['weekday'] as int?),
                accountId: raw['accountId'] as String,
                categoryId: Value(raw['categoryId'] as String?),
                isActive: Value((raw['isActive'] as bool?) ?? true),
                lastSuggestedCycleKey: Value(raw['lastSuggestedCycleKey'] as String?),
                lastCompletedCycleKey: Value(raw['lastCompletedCycleKey'] as String?),
                lastDismissedCycleKey: Value(raw['lastDismissedCycleKey'] as String?),
                createdAt: DateTime.parse(raw['createdAt'] as String),
                lastModifiedAt: DateTime.parse(raw['lastModifiedAt'] as String),
              )).toList(),
        );
      });

      if (settingsData != null) {
        await _database.into(_database.appSettings).insert(
              AppSettingsCompanion.insert(
                id: Value((settingsData['id'] as int?) ?? 1),
                currencyCode: Value((settingsData['currencyCode'] as String?) ?? 'KRW'),
                weekStart: Value((settingsData['weekStart'] as String?) ?? 'monday'),
                themeMode: Value((settingsData['themeMode'] as String?) ?? 'system'),
                defaultCategorySeedVersion: Value(
                  (settingsData['defaultCategorySeedVersion'] as int?) ?? 0,
                ),
                appLockEnabled: const Value(false),
                biometricEnabled: Value((settingsData['biometricEnabled'] as bool?) ?? false),
                exportIncludeDeleted: Value(
                  (settingsData['exportIncludeDeleted'] as bool?) ?? false,
                ),
                createdAt: DateTime.parse(settingsData['createdAt'] as String),
                lastModifiedAt: DateTime.parse(settingsData['lastModifiedAt'] as String),
              ),
            );
      }
    });


    return BackupSummary(
      transactionCount: transactionsData.length,
      categoryCount: categoriesData.length,
      budgetCount: budgetsData.length,
      accountCount: accountsData.length,
      recurringExpenseCount: recurringExpensesData.length,
    );
  }

  Future<Map<String, dynamic>> _decodeAndValidateBackup(String jsonText) async {
    // JSON 디코딩은 대형 파일에서 CPU 집약적이므로 별도 Isolate에서 실행.
    final decodedDynamic = await Isolate.run(() => jsonDecode(jsonText));
    if (decodedDynamic is! Map<String, dynamic>) {
      throw const BackupFormatException('Backup file top-level structure is invalid.');
    }

    final decoded = decodedDynamic;
    final backupVersionValue = decoded['backupVersion'];
    final schemaVersionValue = decoded['schemaVersion'];
    final createdAtValue = decoded['createdAt'];
    final dataValue = decoded['data'];

    if (backupVersionValue is! int) {
      throw const BackupFormatException('backupVersion is missing or invalid.');
    }

    if (backupVersionValue != backupVersion) {
      throw BackupFormatException(
        'Unsupported backup version: $backupVersionValue. Current app supports version $backupVersion only.',
      );
    }

    if (schemaVersionValue is! int) {
      throw const BackupFormatException('schemaVersion is missing or invalid.');
    }

    if (schemaVersionValue > _database.schemaVersion) {
      throw BackupFormatException(
        'Backup was created with newer schema version $schemaVersionValue.',
      );
    }

    if (createdAtValue is! String) {
      throw const BackupFormatException('createdAt is missing or invalid.');
    }

    try {
      DateTime.parse(createdAtValue);
    } catch (_) {
      throw const BackupFormatException('createdAt format is invalid.');
    }

    if (dataValue is! Map<String, dynamic>) {
      throw const BackupFormatException('data payload is invalid.');
    }

    for (final key in const [
      'transactions',
      'categories',
      'budgets',
      'accounts',
      'recurringExpenses',
    ]) {
      final value = dataValue[key];
      if (value != null && value is! List<dynamic>) {
        throw BackupFormatException('$key payload is invalid.');
      }
    }

    final settingsValue = dataValue['settings'];
    if (settingsValue != null && settingsValue is! Map<String, dynamic>) {
      throw const BackupFormatException('settings payload is invalid.');
    }

    return decoded;
  }

  Map<String, dynamic> _transactionToJson(Transaction transaction) => {
        'localId': transaction.localId,
        'type': transaction.type,
        'amount': transaction.amount,
        'occurredAt': transaction.occurredAt.toIso8601String(),
        'accountId': transaction.accountId,
        'fromAccountId': transaction.fromAccountId,
        'toAccountId': transaction.toAccountId,
        'categoryId': transaction.categoryId,
        'merchantName': transaction.merchantName,
        'paymentMethod': transaction.paymentMethod,
        'memo': transaction.memo,
        'tagJson': transaction.tagJson,
        'createdAt': transaction.createdAt.toIso8601String(),
        'lastModifiedAt': transaction.lastModifiedAt.toIso8601String(),
        'deletedAt': transaction.deletedAt?.toIso8601String(),
      };

  Map<String, dynamic> _categoryToJson(Category category) => {
        'localId': category.localId,
        'name': category.name,
        'type': category.type,
        'iconName': category.iconName,
        'colorHex': category.colorHex,
        'isDefault': category.isDefault,
        'isActive': category.isActive,
        'sortOrder': category.sortOrder,
        'createdAt': category.createdAt.toIso8601String(),
        'lastModifiedAt': category.lastModifiedAt.toIso8601String(),
      };

  Map<String, dynamic> _budgetToJson(Budget budget) => {
        'localId': budget.localId,
        'monthKey': budget.monthKey,
        'categoryId': budget.categoryId,
        'amountLimit': budget.amountLimit,
        'alert50Enabled': budget.alert50Enabled,
        'alert80Enabled': budget.alert80Enabled,
        'alert100Enabled': budget.alert100Enabled,
        'createdAt': budget.createdAt.toIso8601String(),
        'lastModifiedAt': budget.lastModifiedAt.toIso8601String(),
      };

  Map<String, dynamic> _accountToJson(Account account) => {
        'localId': account.localId,
        'name': account.name,
        'type': account.type,
        'colorHex': account.colorHex,
        'includeInNetWorth': account.includeInNetWorth,
        'isActive': account.isActive,
        'createdAt': account.createdAt.toIso8601String(),
        'lastModifiedAt': account.lastModifiedAt.toIso8601String(),
      };

  Map<String, dynamic> _recurringExpenseToJson(RecurringExpense item) => {
        'localId': item.localId,
        'name': item.name,
        'type': item.type,
        'amount': item.amount,
        'cadence': item.cadence,
        'dayOfMonth': item.dayOfMonth,
        'weekday': item.weekday,
        'accountId': item.accountId,
        'categoryId': item.categoryId,
        'isActive': item.isActive,
        'lastSuggestedCycleKey': item.lastSuggestedCycleKey,
        'lastCompletedCycleKey': item.lastCompletedCycleKey,
        'lastDismissedCycleKey': item.lastDismissedCycleKey,
        'createdAt': item.createdAt.toIso8601String(),
        'lastModifiedAt': item.lastModifiedAt.toIso8601String(),
      };

  Map<String, dynamic> _settingsToJson(AppSetting settings) => {
        'id': settings.id,
        'currencyCode': settings.currencyCode,
        'weekStart': settings.weekStart,
        'themeMode': settings.themeMode,
        'defaultCategorySeedVersion': settings.defaultCategorySeedVersion,
        'appLockEnabled': settings.appLockEnabled,
        'biometricEnabled': settings.biometricEnabled,
        'exportIncludeDeleted': settings.exportIncludeDeleted,
        'createdAt': settings.createdAt.toIso8601String(),
        'lastModifiedAt': settings.lastModifiedAt.toIso8601String(),
      };
}

final backupServiceProvider = Provider<BackupService>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return BackupService(database);
});
