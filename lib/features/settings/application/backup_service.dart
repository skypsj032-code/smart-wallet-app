import 'dart:convert';
import 'dart:io';

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
  });

  final int transactionCount;
  final int categoryCount;
  final int budgetCount;
  final int accountCount;
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
    // Read all tables from one database snapshot so a transaction added
    // during backup cannot refer to data from a different point in time.
    final snapshot = await _database.transaction(() async => (
          transactions: await _database.select(_database.transactions).get(),
          categories: await _database.select(_database.categories).get(),
          budgets: await _database.select(_database.budgets).get(),
          accounts: await _database.select(_database.accounts).get(),
          settings: await _database.select(_database.appSettings).get(),
        ));
    final transactionsData = snapshot.transactions;
    final categoriesData = snapshot.categories;
    final budgetsData = snapshot.budgets;
    final accountsData = snapshot.accounts;
    final settingsData = snapshot.settings;

    final createdAt = DateTime.now().toUtc();
    final data = <String, dynamic>{
      'transactions': transactionsData.map(_transactionToJson).toList(),
      'categories': categoriesData.map(_categoryToJson).toList(),
      'budgets': budgetsData.map(_budgetToJson).toList(),
      'accounts': accountsData.map(_accountToJson).toList(),
      'settings': settingsData.isEmpty ? null : _settingsToJson(settingsData.first),
    };
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
      },
      'data': data,
    };

    final fileName = 'smart_wallet_backup_${createdAt.millisecondsSinceEpoch}.json';

    return BackupPayload(
      json: const JsonEncoder.withIndent('  ').convert(payload),
      summary: BackupSummary(
        transactionCount: transactionsData.length,
        categoryCount: categoriesData.length,
        budgetCount: budgetsData.length,
        accountCount: accountsData.length,
      ),
      fileName: fileName,
    );
  }

  Future<File> saveBackupFile(BackupPayload payload) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(p.join(directory.path, payload.fileName));
    await file.writeAsString(payload.json);
    return file;
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

  BackupPreview inspectJsonBackup(String jsonText) {
    final decoded = _decodeAndValidateBackup(jsonText);
    final data = decoded['data'] as Map<String, dynamic>;

    return BackupPreview(
      backupVersion: decoded['backupVersion'] as int,
      schemaVersion: decoded['schemaVersion'] as int,
      createdAt: DateTime.parse(decoded['createdAt'] as String),
      appVersion: decoded['appVersion'] as String? ?? 'unknown',
      summary: BackupSummary(
        transactionCount: (data['transactions'] as List<dynamic>).length,
        categoryCount: (data['categories'] as List<dynamic>).length,
        budgetCount: (data['budgets'] as List<dynamic>).length,
        accountCount: (data['accounts'] as List<dynamic>).length,
      ),
      warnings: [
        if (!decoded.containsKey('dataChecksum')) '무결성 확인 정보가 없는 이전 백업입니다.',
        ..._collectBackupWarnings(data),
      ],
    );
  }

  Future<BackupSummary> restoreJsonBackup(String jsonText) async {
    final decoded = _decodeAndValidateBackup(jsonText);
    final data = decoded['data'] as Map<String, dynamic>;

    final transactionsData = (data['transactions'] as List<dynamic>? ?? const []);
    final categoriesData = (data['categories'] as List<dynamic>? ?? const []);
    final budgetsData = (data['budgets'] as List<dynamic>? ?? const []);
    final accountsData = (data['accounts'] as List<dynamic>? ?? const []);
    final settingsData = data['settings'] as Map<String, dynamic>?;

    await _database.transaction(() async {
      // A shared JSON backup intentionally does not contain a PIN hash.
      // Preserve this device's security settings instead of enabling a lock
      // that cannot actually be verified after the restore.
      final currentSettings = await _database.select(_database.appSettings).getSingleOrNull();
      final currentPin = currentSettings?.pinCode;
      final keepLock = (currentSettings?.appLockEnabled ?? false) && currentPin != null;

      await _database.delete(_database.transactions).go();
      await _database.delete(_database.categories).go();
      await _database.delete(_database.budgets).go();
      await _database.delete(_database.accounts).go();
      await _database.delete(_database.appSettings).go();

      for (final raw in categoriesData.cast<Map<String, dynamic>>()) {
        await _database.into(_database.categories).insert(
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
              ),
            );
      }

      for (final raw in accountsData.cast<Map<String, dynamic>>()) {
        await _database.into(_database.accounts).insert(
              AccountsCompanion.insert(
                localId: raw['localId'] as String,
                name: raw['name'] as String,
                type: raw['type'] as String,
                colorHex: Value(raw['colorHex'] as String?),
                includeInNetWorth: Value((raw['includeInNetWorth'] as bool?) ?? true),
                isActive: Value((raw['isActive'] as bool?) ?? true),
                createdAt: DateTime.parse(raw['createdAt'] as String),
                lastModifiedAt: DateTime.parse(raw['lastModifiedAt'] as String),
              ),
            );
      }

      for (final raw in budgetsData.cast<Map<String, dynamic>>()) {
        await _database.into(_database.budgets).insert(
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
              ),
            );
      }

      for (final raw in transactionsData.cast<Map<String, dynamic>>()) {
        await _database.into(_database.transactions).insert(
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
              ),
            );
      }

      if (settingsData != null) {
        await _database.into(_database.appSettings).insert(
              AppSettingsCompanion.insert(
                id: Value((settingsData['id'] as int?) ?? 1),
                currencyCode: Value((settingsData['currencyCode'] as String?) ?? 'KRW'),
                weekStart: Value((settingsData['weekStart'] as String?) ?? 'monday'),
                themeMode: Value((settingsData['themeMode'] as String?) ?? 'system'),
                appLockEnabled: Value(keepLock),
                biometricEnabled: Value(keepLock && (currentSettings?.biometricEnabled ?? false)),
                pinCode: Value(currentPin),
                exportIncludeDeleted: Value(
                  (settingsData['exportIncludeDeleted'] as bool?) ?? false,
                ),
                createdAt: DateTime.parse(settingsData['createdAt'] as String),
                lastModifiedAt: DateTime.parse(settingsData['lastModifiedAt'] as String),
              ),
            );
      } else if (currentSettings != null) {
        await _database.into(_database.appSettings).insert(
              currentSettings.copyWith(
                appLockEnabled: keepLock,
                biometricEnabled: keepLock && currentSettings.biometricEnabled,
              ),
            );
      } else {
        final now = DateTime.now();
        await _database.into(_database.appSettings).insert(
              AppSettingsCompanion.insert(createdAt: now, lastModifiedAt: now),
            );
      }
    });

    return BackupSummary(
      transactionCount: transactionsData.length,
      categoryCount: categoriesData.length,
      budgetCount: budgetsData.length,
      accountCount: accountsData.length,
    );
  }

  Map<String, dynamic> _decodeAndValidateBackup(String jsonText) {
    final decodedDynamic = jsonDecode(jsonText);
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
        'Unsupported backup version: $backupVersionValue. Supported versions are 1 and $backupVersion.',
      );
    }

    if (schemaVersionValue is! int) {
      throw const BackupFormatException('schemaVersion is missing or invalid.');
    }

    if (schemaVersionValue < 1) {
      throw const BackupFormatException('schemaVersion must be positive.');
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

    for (final key in const ['transactions', 'categories', 'budgets', 'accounts']) {
      final value = dataValue[key];
      if (value is! List<dynamic>) {
        throw BackupFormatException('$key payload is invalid.');
      }
      if (value.any((row) => row is! Map<String, dynamic>)) {
        throw BackupFormatException('$key contains an invalid record.');
      }
      final ids = <String>{};
      for (final row in value.cast<Map<String, dynamic>>()) {
        _validateBackupRecord(key, row);
        if (!ids.add(row['localId'] as String)) {
          throw BackupFormatException('$key contains duplicate record IDs.');
        }
      }
    }

    if (!dataValue.containsKey('settings')) {
      throw const BackupFormatException('settings payload is missing.');
    }
    final settingsValue = dataValue['settings'];
    if (settingsValue != null && settingsValue is! Map<String, dynamic>) {
      throw const BackupFormatException('settings payload is invalid.');
    }
    if (settingsValue is Map<String, dynamic>) {
      _validateBackupRecord('settings', settingsValue);
    }

    // Reject a damaged or inconsistent file rather than presenting a
    // misleading preview before replacing the current data.
    final summaryValue = decoded['summary'];
    if (summaryValue is! Map<String, dynamic>) {
      throw const BackupFormatException('summary payload is invalid.');
    }
    const counts = {
      'transactionCount': 'transactions',
      'categoryCount': 'categories',
      'budgetCount': 'budgets',
      'accountCount': 'accounts',
    };
    for (final entry in counts.entries) {
      final declaredCount = summaryValue[entry.key];
      final actualCount = (dataValue[entry.value] as List<dynamic>).length;
      if (declaredCount is! int || declaredCount != actualCount) {
        throw BackupFormatException('${entry.key} does not match the backup contents.');
      }
    }

    // Version 1 predates checksums. New version-2 backups must have one.
    // This detects accidental data changes; it is not authentication.
    final checksum = decoded['dataChecksum'];
    if (backupVersionValue >= 2 && checksum == null) {
      throw const BackupFormatException('Backup checksum is missing.');
    }
    if (checksum != null) {
      if (checksum is! String || !RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(checksum)) {
        throw const BackupFormatException('Backup checksum is invalid.');
      }
      final actual = sha256.convert(utf8.encode(jsonEncode(dataValue))).toString();
      if (checksum.toLowerCase() != actual) {
        throw const BackupFormatException('Backup data integrity check failed.');
      }
    } else if (decoded.containsKey('dataChecksum')) {
      throw const BackupFormatException('Backup checksum is missing or invalid.');
    }

    return decoded;
  }

  // Both the original schema-1 APK and the current exporter emit these fields,
  // including explicitly null values. Missing nullable fields must not be
  // silently converted into different data during restore.
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
    'settings': {
      'id': 'int', 'currencyCode': 'string', 'weekStart': 'string', 'themeMode': 'string',
      'appLockEnabled': 'bool', 'biometricEnabled': 'bool', 'exportIncludeDeleted': 'bool',
      'createdAt': 'date', 'lastModifiedAt': 'date',
    },
  };

  void _validateBackupRecord(String section, Map<String, dynamic> record) {
    for (final field in _recordFields[section]!.entries) {
      if (!record.containsKey(field.key)) {
        throw BackupFormatException('$section record is missing ${field.key}.');
      }
      final value = record[field.key];
      final valid = switch (field.value) {
        'string' => value is String,
        'string?' => value == null || value is String,
        'int' => value is int,
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

  List<String> _collectBackupWarnings(Map<String, dynamic> data) {
    final accounts = (data['accounts'] as List<dynamic>).cast<Map<String, dynamic>>();
    final categories = (data['categories'] as List<dynamic>).cast<Map<String, dynamic>>();
    final transactions = (data['transactions'] as List<dynamic>).cast<Map<String, dynamic>>();
    final budgets = (data['budgets'] as List<dynamic>).cast<Map<String, dynamic>>();
    final accountIds = accounts.map((row) => row['localId'] as String).toSet();
    final categoryIds = categories.map((row) => row['localId'] as String).toSet();
    var missingAccounts = 0;
    var missingCategories = 0;
    var unsupportedTypes = 0;
    var unusualAmounts = 0;
    var unusualBudgets = 0;
    var duplicateBudgets = 0;

    for (final row in transactions) {
      if (row['deletedAt'] != null) continue;
      final type = row['type'] as String;
      if (type == 'income' || type == 'expense') {
        if (!accountIds.contains(row['accountId'])) missingAccounts++;
      } else if (type == 'transfer') {
        if (!accountIds.contains(row['fromAccountId']) ||
            !accountIds.contains(row['toAccountId']) ||
            row['fromAccountId'] == row['toAccountId']) {
          missingAccounts++;
        }
      } else {
        unsupportedTypes++;
      }
      if (row['categoryId'] != null && !categoryIds.contains(row['categoryId'])) {
        missingCategories++;
      }
      if ((row['amount'] as int) <= 0) unusualAmounts++;
    }

    final budgetKeys = <String>{};
    for (final row in budgets) {
      final key = jsonEncode([row['monthKey'], row['categoryId']]);
      if (!budgetKeys.add(key)) duplicateBudgets++;
      if (row['categoryId'] != null && !categoryIds.contains(row['categoryId'])) {
        missingCategories++;
      }
      if ((row['amountLimit'] as int) <= 0 ||
          !RegExp(r'^\d{4}-(0[1-9]|1[0-2])$').hasMatch(row['monthKey'] as String)) {
        unusualBudgets++;
      }
    }

    return [
      if (missingAccounts > 0) '계좌 연결을 확인해야 할 거래 $missingAccounts건',
      if (missingCategories > 0) '카테고리 연결을 확인해야 할 항목 $missingCategories건',
      if (unsupportedTypes > 0) '현재 계산에 반영되지 않는 거래 $unsupportedTypes건',
      if (unusualAmounts > 0) '금액이 0원 이하인 거래 $unusualAmounts건',
      if (unusualBudgets > 0) '예산 금액이나 월을 확인해야 할 항목 $unusualBudgets건',
      if (duplicateBudgets > 0) '같은 달과 항목에 중복된 예산 $duplicateBudgets건',
    ];
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

  Map<String, dynamic> _settingsToJson(AppSetting settings) => {
        'id': settings.id,
        'currencyCode': settings.currencyCode,
        'weekStart': settings.weekStart,
        'themeMode': settings.themeMode,
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
