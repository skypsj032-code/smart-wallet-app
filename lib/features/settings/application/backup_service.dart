import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
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
    this.warnings = const [],
  });

  final int backupVersion;
  final int schemaVersion;
  final DateTime createdAt;
  final String appVersion;
  final BackupSummary summary;
  final List<String> warnings;
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
  static const int backupVersion = 2;

  Future<BackupPayload> exportJsonBackup() async {
    // Read every section from the same SQLite snapshot.
    final data = await _database.transaction(_readBackupData);
    final transactionsData = data['transactions'] as List<dynamic>;
    final categoriesData = data['categories'] as List<dynamic>;
    final budgetsData = data['budgets'] as List<dynamic>;
    final accountsData = data['accounts'] as List<dynamic>;
    final recurringExpensesData = data['recurringExpenses'] as List<dynamic>;

    final createdAt = DateTime.now().toUtc();
    final payload = {
      'backupVersion': backupVersion,
      'schemaVersion': _database.schemaVersion,
      'createdAt': createdAt.toIso8601String(),
      'appVersion': '0.1.0',
      'deviceId': 'local-device',
      'dataChecksum': sha256.convert(utf8.encode(jsonEncode(data))).toString(),
      'summary': {
        'transactionCount': transactionsData.length,
        'categoryCount': categoriesData.length,
        'budgetCount': budgetsData.length,
        'accountCount': accountsData.length,
        'recurringExpenseCount': recurringExpensesData.length,
        'recurringSpendOverrideCount':
            (data['recurringSpendOverrides'] as List<dynamic>).length,
        'notificationHistoryCount':
            (data['notificationHistories'] as List<dynamic>).length,
        'ocrDraftCount': (data['ocrDrafts'] as List<dynamic>).length,
      },
      'data': data,
    };

    final fileName = 'smart_wallet_backup_${createdAt.millisecondsSinceEpoch}.json';

    // JSON 직렬화는 CPU 집약적이므로 별도 Isolate에서 실행해 UI 프레임 드롭 방지.
    final jsonString = await _encodeBackupJson(payload);

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

  Future<Map<String, dynamic>> _readBackupData() async {
    final transactions = await _database.select(_database.transactions).get();
    final categories = await _database.select(_database.categories).get();
    final budgets = await _database.select(_database.budgets).get();
    final accounts = await _database.select(_database.accounts).get();
    final recurring = await _database.select(_database.recurringExpenses).get();
    final overrides =
        await _database.select(_database.recurringSpendOverrides).get();
    final notifications =
        await _database.select(_database.notificationHistories).get();
    final ocrDrafts = await _database.select(_database.ocrDrafts).get();
    final settings = await _database.select(_database.appSettings).get();
    return {
      'transactions': transactions.map(_transactionToJson).toList(),
      'categories': categories.map(_categoryToJson).toList(),
      'budgets': budgets.map(_budgetToJson).toList(),
      'accounts': accounts.map(_accountToJson).toList(),
      'recurringExpenses': recurring.map(_recurringExpenseToJson).toList(),
      'recurringSpendOverrides': overrides.map(_recurringSpendOverrideToJson).toList(),
      'notificationHistories': notifications.map(_notificationHistoryToJson).toList(),
      'ocrDrafts': ocrDrafts.map(_ocrDraftToJson).toList(),
      'settings': settings.isEmpty ? null : _settingsToJson(settings.first),
    };
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
    final data = decoded['data'] as Map<String, dynamic>;
    final warnings = <String>[];
    if (const [
      'recurringExpenses', 'recurringSpendOverrides', 'notificationHistories', 'ocrDrafts',
    ].any((key) => !data.containsKey(key))) {
      warnings.add('이전 백업에 없는 항목은 현재 기기의 데이터를 유지합니다.');
    }
    if ((data['ocrDrafts'] as List<dynamic>?)?.isNotEmpty == true) {
      warnings.add('영수증 사진 원본은 백업에 포함되지 않습니다.');
    }

    return BackupPreview(
      backupVersion: decoded['backupVersion'] as int,
      schemaVersion: decoded['schemaVersion'] as int,
      createdAt: DateTime.parse(decoded['createdAt'] as String),
      appVersion: decoded['appVersion'] as String? ?? 'unknown',
      warnings: warnings,
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

  Future<BackupSummary> restoreJsonBackup(
    String jsonText, {
    String? expectedCurrentJson,
  }) async {
    final decoded = await _decodeAndValidateBackup(jsonText);
    final expectedCurrent = expectedCurrentJson == null
        ? null
        : await _decodeAndValidateBackup(expectedCurrentJson);
    final data = decoded['data'] as Map<String, dynamic>;

    final transactionsData = (data['transactions'] as List<dynamic>? ?? const []);
    final categoriesData = (data['categories'] as List<dynamic>? ?? const []);
    final budgetsData = (data['budgets'] as List<dynamic>? ?? const []);
    final accountsData = (data['accounts'] as List<dynamic>? ?? const []);
    final recurringExpensesData = data['recurringExpenses'] as List<dynamic>?;
    final recurringSpendOverridesData =
        data['recurringSpendOverrides'] as List<dynamic>?;
    final notificationHistoriesData =
        data['notificationHistories'] as List<dynamic>?;
    final ocrDraftsData = data['ocrDrafts'] as List<dynamic>?;
    final settingsData = data['settings'] as Map<String, dynamic>?;
    var retainedRecurringExpenseCount = 0;

    await _database.transaction(() async {
      // The safety file is written before the restore transaction starts.
      // Stop if anything changed in that interval so newer records are not
      // replaced without being present in the safety backup.
      if (expectedCurrent != null) {
        final currentData = await _readBackupData();
        if (jsonEncode(currentData) != jsonEncode(expectedCurrent['data'])) {
          throw const BackupFormatException(
            '안전 백업을 만든 뒤 새 기록이 생겨 복원을 멈췄어요. 다시 시도해 주세요.',
          );
        }
      }
      // The PIN never leaves the device as part of a shareable backup.
      final localSettings =
          await _database.select(_database.appSettings).getSingleOrNull();
      if (recurringExpensesData == null) {
        final retained = await _database.select(_database.recurringExpenses).get();
        final accountIds = accountsData.cast<Map<String, dynamic>>()
            .map((raw) => raw['localId']).toSet();
        final categoryIds = categoriesData.cast<Map<String, dynamic>>()
            .map((raw) => raw['localId']).toSet();
        for (final item in retained) {
          if (!accountIds.contains(item.accountId) ||
              (item.categoryId != null && !categoryIds.contains(item.categoryId))) {
            throw const BackupFormatException(
              '기존 정기거래와 연결된 계좌 또는 카테고리가 백업에 없어 복원을 멈췄어요.',
            );
          }
        }
        retainedRecurringExpenseCount = retained.length;
      }
      await _database.delete(_database.transactions).go();
      await _database.delete(_database.categories).go();
      await _database.delete(_database.budgets).go();
      if (recurringExpensesData != null) {
        await _database.delete(_database.recurringExpenses).go();
      }
      if (recurringSpendOverridesData != null) {
        await _database.delete(_database.recurringSpendOverrides).go();
      }
      if (notificationHistoriesData != null) {
        await _database.delete(_database.notificationHistories).go();
      }
      if (ocrDraftsData != null) {
        await _database.delete(_database.ocrDrafts).go();
      }
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
          (recurringExpensesData ?? const <dynamic>[]).cast<Map<String, dynamic>>().map((raw) =>
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
                lastCompletedCycleKey: Value(
                  (raw['lastCompletedCycleKey'] ?? raw['lastCreatedMonthKey']) as String?,
                ),
                lastDismissedCycleKey: Value(raw['lastDismissedCycleKey'] as String?),
                createdAt: DateTime.parse(raw['createdAt'] as String),
                lastModifiedAt: DateTime.parse(raw['lastModifiedAt'] as String),
              )).toList(),
        );

        if (recurringSpendOverridesData != null) {
          batch.insertAll(
            _database.recurringSpendOverrides,
            recurringSpendOverridesData.cast<Map<String, dynamic>>().map((raw) =>
                RecurringSpendOverridesCompanion.insert(
                  groupKey: raw['groupKey'] as String,
                  actionType: raw['actionType'] as String,
                  createdAt: DateTime.parse(raw['createdAt'] as String),
                  lastModifiedAt: DateTime.parse(raw['lastModifiedAt'] as String),
                )).toList(),
          );
        }
        if (notificationHistoriesData != null) {
          batch.insertAll(
            _database.notificationHistories,
            notificationHistoriesData.cast<Map<String, dynamic>>().map((raw) =>
                NotificationHistoriesCompanion.insert(
                  id: Value(raw['id'] as int),
                  packageName: raw['packageName'] as String,
                  amount: raw['amount'] as int,
                  type: raw['type'] as String,
                  merchant: Value(raw['merchant'] as String?),
                  suggestedCategory: Value(raw['suggestedCategory'] as String?),
                  detectedAt: DateTime.parse(raw['detectedAt'] as String),
                )).toList(),
          );
        }
        if (ocrDraftsData != null) {
          batch.insertAll(
            _database.ocrDrafts,
            ocrDraftsData.cast<Map<String, dynamic>>().map((raw) =>
                OcrDraftsCompanion.insert(
                  localId: raw['localId'] as String,
                  sourceImagePath: Value(raw['sourceImagePath'] as String?),
                  ocrRawText: Value(raw['ocrRawText'] as String?),
                  ocrConfidence: Value((raw['ocrConfidence'] as num?)?.toDouble()),
                  ocrStatus: raw['ocrStatus'] as String,
                  parsedStoreName: Value(raw['parsedStoreName'] as String?),
                  parsedTotalAmount: Value(raw['parsedTotalAmount'] as int?),
                  parsedTransactionDate: Value(raw['parsedTransactionDate'] == null
                      ? null
                      : DateTime.parse(raw['parsedTransactionDate'] as String)),
                  parsedCategoryGuess: Value(raw['parsedCategoryGuess'] as String?),
                  errorMessage: Value(raw['errorMessage'] as String?),
                  createdAt: DateTime.parse(raw['createdAt'] as String),
                  lastModifiedAt: DateTime.parse(raw['lastModifiedAt'] as String),
                )).toList(),
          );
        }
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
                appLockEnabled: Value(localSettings?.appLockEnabled ?? false),
                biometricEnabled: Value(localSettings?.biometricEnabled ?? false),
                pinCode: Value(localSettings?.pinCode),
                exportIncludeDeleted: Value(
                  (settingsData['exportIncludeDeleted'] as bool?) ?? false,
                ),
                createdAt: DateTime.parse(settingsData['createdAt'] as String),
                lastModifiedAt: DateTime.parse(settingsData['lastModifiedAt'] as String),
              ),
            );
      } else if (localSettings != null) {
        await _database.into(_database.appSettings).insert(localSettings);
      }
    });


    return BackupSummary(
      transactionCount: transactionsData.length,
      categoryCount: categoriesData.length,
      budgetCount: budgetsData.length,
      accountCount: accountsData.length,
      recurringExpenseCount:
          recurringExpensesData?.length ?? retainedRecurringExpenseCount,
    );
  }

  Future<Map<String, dynamic>> _decodeAndValidateBackup(String jsonText) async {
    // JSON 디코딩은 대형 파일에서 CPU 집약적이므로 별도 Isolate에서 실행.
    final dynamic decodedDynamic;
    try {
      decodedDynamic = await _decodeBackupJson(jsonText);
    } on FormatException {
      throw const BackupFormatException('Backup JSON is invalid.');
    }
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

    if (backupVersionValue != 1 && backupVersionValue != backupVersion) {
      throw BackupFormatException(
        'Unsupported backup version: $backupVersionValue.',
      );
    }

    if (schemaVersionValue is! int) {
      throw const BackupFormatException('schemaVersion is missing or invalid.');
    }

    if (schemaVersionValue < 1 || schemaVersionValue > _database.schemaVersion) {
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

    if (backupVersionValue == 2) {
      final checksum = decoded['dataChecksum'];
      final actual = sha256.convert(utf8.encode(jsonEncode(dataValue))).toString();
      if (checksum is! String || checksum != actual) {
        throw const BackupFormatException('백업 파일의 내용이 손상되었거나 변경됐어요.');
      }
    }

    for (final key in const [
      'transactions',
      'categories',
      'budgets',
      'accounts',
    ]) {
      final value = dataValue[key];
      if (value is! List<dynamic>) {
        throw BackupFormatException('$key payload is invalid.');
      }
    }

    for (final key in const [
      'recurringExpenses',
      'recurringSpendOverrides',
      'notificationHistories',
      'ocrDrafts',
    ]) {
      final value = dataValue[key];
      if (value != null && value is! List<dynamic>) {
        throw BackupFormatException('$key payload is invalid.');
      }
    }

    final summary = decoded['summary'];
    if (summary != null && summary is! Map<String, dynamic>) {
      throw const BackupFormatException('summary payload is invalid.');
    }
    if (summary is Map<String, dynamic>) {
      const sectionCounts = {
        'transactions': 'transactionCount',
        'categories': 'categoryCount',
        'budgets': 'budgetCount',
        'accounts': 'accountCount',
        'recurringExpenses': 'recurringExpenseCount',
        'recurringSpendOverrides': 'recurringSpendOverrideCount',
        'notificationHistories': 'notificationHistoryCount',
        'ocrDrafts': 'ocrDraftCount',
      };
      for (final entry in sectionCounts.entries) {
        if (!summary.containsKey(entry.value)) continue;
        final count = summary[entry.value];
        final section = dataValue[entry.key];
        if (count is! int || count < 0 ||
            (section is List && section.length != count) ||
            (section == null && count != 0)) {
          throw BackupFormatException('${entry.key} count does not match the backup data.');
        }
      }
    }

    final settingsValue = dataValue['settings'];
    if (settingsValue != null && settingsValue is! Map<String, dynamic>) {
      throw const BackupFormatException('settings payload is invalid.');
    }

    for (final section in _recordFields.keys) {
      final value = dataValue[section];
      if (value == null) continue;
      final records = section == 'settings' ? [value] : value as List<dynamic>;
      final ids = <Object>{};
      for (final record in records) {
        if (record is! Map<String, dynamic>) {
          throw BackupFormatException('$section contains an invalid record.');
        }
        _validateBackupRecord(section, record);
        if (section == 'recurringExpenses') {
          if (schemaVersionValue >= 6) {
            _validateBackupRecord(section, record, fields: _modernRecurringFields);
          } else if (schemaVersionValue >= 4) {
            _validateBackupRecord(section, record, fields: const {
              'lastCreatedMonthKey': 'string?',
            });
          }
        }
        final idKey = section == 'notificationHistories' ? 'id' :
            section == 'recurringSpendOverrides' ? 'groupKey' :
            section == 'settings' ? 'id' : 'localId';
        if (!ids.add(record[idKey] as Object)) {
          throw BackupFormatException('$section contains duplicate identifiers.');
        }
      }
    }

    return decoded;
  }

  static const _recordFields = <String, Map<String, String>>{
    'transactions': {
      'localId': 'string', 'type': 'string', 'amount': 'int', 'occurredAt': 'date',
      'accountId': 'string?', 'fromAccountId': 'string?', 'toAccountId': 'string?',
      'categoryId': 'string?', 'merchantName': 'string?', 'paymentMethod': 'string?',
      'memo': 'string?', 'tagJson': 'string?', 'createdAt': 'date',
      'lastModifiedAt': 'date', 'deletedAt': 'date?',
    },
    'categories': {
      'localId': 'string', 'name': 'string', 'type': 'string', 'iconName': 'string?',
      'colorHex': 'string?', 'isDefault': 'bool', 'isActive': 'bool', 'sortOrder': 'int',
      'createdAt': 'date', 'lastModifiedAt': 'date',
    },
    'budgets': {
      'localId': 'string', 'monthKey': 'string', 'categoryId': 'string?',
      'amountLimit': 'int', 'alert50Enabled': 'bool', 'alert80Enabled': 'bool',
      'alert100Enabled': 'bool', 'createdAt': 'date', 'lastModifiedAt': 'date',
    },
    'accounts': {
      'localId': 'string', 'name': 'string', 'type': 'string', 'colorHex': 'string?',
      'includeInNetWorth': 'bool', 'isActive': 'bool', 'createdAt': 'date',
      'lastModifiedAt': 'date',
    },
    'recurringExpenses': {
      'localId': 'string', 'name': 'string', 'amount': 'int',
      'dayOfMonth': 'int?', 'accountId': 'string', 'categoryId': 'string?',
      'isActive': 'bool', 'createdAt': 'date', 'lastModifiedAt': 'date',
    },
    'settings': {
      'id': 'int', 'currencyCode': 'string', 'weekStart': 'string', 'themeMode': 'string',
      'appLockEnabled': 'bool', 'biometricEnabled': 'bool', 'exportIncludeDeleted': 'bool',
      'createdAt': 'date', 'lastModifiedAt': 'date',
    },
    'recurringSpendOverrides': {
      'groupKey': 'string', 'actionType': 'string', 'createdAt': 'date',
      'lastModifiedAt': 'date',
    },
    'notificationHistories': {
      'id': 'int', 'packageName': 'string', 'amount': 'int', 'type': 'string',
      'merchant': 'string?', 'suggestedCategory': 'string?', 'detectedAt': 'date',
    },
    'ocrDrafts': {
      'localId': 'string', 'sourceImagePath': 'string?', 'ocrRawText': 'string?',
      'ocrConfidence': 'number?', 'ocrStatus': 'string', 'parsedStoreName': 'string?',
      'parsedTotalAmount': 'int?', 'parsedTransactionDate': 'date?',
      'parsedCategoryGuess': 'string?', 'errorMessage': 'string?',
      'createdAt': 'date', 'lastModifiedAt': 'date',
    },
  };

  static const _modernRecurringFields = <String, String>{
    'type': 'string', 'cadence': 'string', 'weekday': 'int?',
    'lastSuggestedCycleKey': 'string?', 'lastCompletedCycleKey': 'string?',
    'lastDismissedCycleKey': 'string?',
  };

  void _validateBackupRecord(String section, Map<String, dynamic> record,
      {Map<String, String>? fields}) {
    for (final field in (fields ?? _recordFields[section]!).entries) {
      if (!record.containsKey(field.key)) {
        throw BackupFormatException('$section record is missing ${field.key}.');
      }
      final value = record[field.key];
      final valid = switch (field.value) {
        'string' => value is String,
        'string?' => value == null || value is String,
        'int' => value is int,
        'int?' => value == null || value is int,
        'number?' => value == null || value is num,
        'bool' => value is bool,
        'date' => value is String && DateTime.tryParse(value) != null,
        'date?' => value == null || (value is String && DateTime.tryParse(value) != null),
        _ => false,
      };
      if (!valid) {
        throw BackupFormatException('$section record has an invalid ${field.key}.');
      }
    }
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

  Map<String, dynamic> _recurringSpendOverrideToJson(
          RecurringSpendOverride item) =>
      {
        'groupKey': item.groupKey,
        'actionType': item.actionType,
        'createdAt': item.createdAt.toIso8601String(),
        'lastModifiedAt': item.lastModifiedAt.toIso8601String(),
      };

  Map<String, dynamic> _notificationHistoryToJson(NotificationHistory item) => {
        'id': item.id,
        'packageName': item.packageName,
        'amount': item.amount,
        'type': item.type,
        'merchant': item.merchant,
        'suggestedCategory': item.suggestedCategory,
        'detectedAt': item.detectedAt.toIso8601String(),
      };

  Map<String, dynamic> _ocrDraftToJson(OcrDraft item) => {
        'localId': item.localId,
        'sourceImagePath': item.sourceImagePath,
        'ocrRawText': item.ocrRawText,
        'ocrConfidence': item.ocrConfidence,
        'ocrStatus': item.ocrStatus,
        'parsedStoreName': item.parsedStoreName,
        'parsedTotalAmount': item.parsedTotalAmount,
        'parsedTransactionDate': item.parsedTransactionDate?.toIso8601String(),
        'parsedCategoryGuess': item.parsedCategoryGuess,
        'errorMessage': item.errorMessage,
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

// Keep isolate closures outside BackupService so they only capture transferable
// JSON data and never capture the database connection or its async locks.
Future<String> _encodeBackupJson(Map<String, dynamic> payload) => Isolate.run(
      () => const JsonEncoder.withIndent('  ').convert(payload),
    );

Future<dynamic> _decodeBackupJson(String jsonText) =>
    Isolate.run(() => jsonDecode(jsonText));

final backupServiceProvider = Provider<BackupService>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return BackupService(database);
});
