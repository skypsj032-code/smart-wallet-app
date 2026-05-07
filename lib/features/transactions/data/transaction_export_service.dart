import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/database/providers/database_providers.dart';

class CsvExportPayload {
  const CsvExportPayload({
    required this.csv,
    required this.rowCount,
    required this.fileName,
    this.filterDescription,
  });

  final String csv;
  final int rowCount;
  final String fileName;
  final String? filterDescription;
}

class TransactionCsvExportOptions {
  const TransactionCsvExportOptions({
    this.startDate,
    this.endDate,
    this.label,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final String? label;

  bool get hasDateFilter => startDate != null || endDate != null;
}

class TransactionExportService {
  TransactionExportService(this._ref);

  final Ref _ref;

  static const List<String> _csvHeaders = [
    'Transaction ID',
    'Type',
    'Amount',
    'Occurred At',
    'Account ID',
    'Category ID',
    'Merchant Name',
    'Payment Method',
    'Memo',
    'Created At',
    'Last Modified At',
  ];

  Future<CsvExportPayload> exportTransactionsCsv({
    TransactionCsvExportOptions options = const TransactionCsvExportOptions(),
  }) async {
    final database = _ref.read(appDatabaseProvider);
    final query = database.select(database.transactions)
      ..where((tx) => tx.deletedAt.isNull());

    if (options.startDate != null) {
      query.where(
        (tx) => tx.occurredAt.isBiggerOrEqualValue(
          _startOfDay(options.startDate!),
        ),
      );
    }

    if (options.endDate != null) {
      query.where(
        (tx) => tx.occurredAt.isSmallerOrEqualValue(
          _endOfDay(options.endDate!),
        ),
      );
    }

    query.orderBy([
      (tx) => OrderingTerm.asc(tx.occurredAt),
      (tx) => OrderingTerm.asc(tx.createdAt),
    ]);

    final transactions = await query.get();
    final exportedAt = DateTime.now();
    final fileName = _buildFileName(exportedAt, options);

    final buffer = StringBuffer()..writeln(_csvHeaders.join(','));

    for (final row in transactions) {
      buffer.writeln(_buildCsvRow(row).join(','));
    }

    return CsvExportPayload(
      csv: buffer.toString(),
      rowCount: transactions.length,
      fileName: fileName,
      filterDescription: _buildFilterDescription(options),
    );
  }

  Future<File> saveCsvFile(CsvExportPayload payload) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(p.join(directory.path, payload.fileName));
    await file.writeAsString(payload.csv);
    return file;
  }

  Future<void> shareCsvFile(
    File file, {
    String? text,
  }) async {
    await Share.shareXFiles([
      XFile(file.path),
    ], text: text?.trim().isNotEmpty == true ? text : _defaultShareText(file));
  }

  String _buildFileName(
    DateTime exportedAt,
    TransactionCsvExportOptions options,
  ) {
    final timestamp = DateFormat('yyyyMMdd-HHmmss').format(exportedAt);
    if (!options.hasDateFilter) {
      return 'smart-wallet-transactions-$timestamp.csv';
    }

    final startLabel = options.startDate == null
        ? 'start'
        : DateFormat('yyyyMMdd').format(options.startDate!);
    final endLabel = options.endDate == null
        ? 'latest'
        : DateFormat('yyyyMMdd').format(options.endDate!);
    return 'smart-wallet-transactions-$startLabel-to-$endLabel-$timestamp.csv';
  }

  List<String> _buildCsvRow(dynamic row) {
    return [
      _csv(row.localId),
      _csv(row.type),
      row.amount.toString(),
      _csv(row.occurredAt.toIso8601String()),
      _csv(row.accountId),
      _csv(row.categoryId),
      _csv(row.merchantName),
      _csv(row.paymentMethod),
      _csv(row.memo),
      _csv(row.createdAt.toIso8601String()),
      _csv(row.lastModifiedAt.toIso8601String()),
    ];
  }

  String _defaultShareText(File file) {
    final fileName = p.basename(file.path);
    return 'Smart Wallet transactions CSV attached: $fileName';
  }

  String? _buildFilterDescription(TransactionCsvExportOptions options) {
    if (options.label != null && options.label!.trim().isNotEmpty) {
      return options.label;
    }

    if (!options.hasDateFilter) {
      return null;
    }

    final startLabel = options.startDate == null
        ? '처음부터'
        : DateFormat('yyyy.MM.dd').format(options.startDate!);
    final endLabel = options.endDate == null
        ? '최근까지'
        : DateFormat('yyyy.MM.dd').format(options.endDate!);
    return '$startLabel - $endLabel';
  }

  DateTime _startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  DateTime _endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  String _csv(String? value) {
    if (value == null) {
      return '""';
    }

    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }
}

final transactionExportServiceProvider = Provider<TransactionExportService>(
  TransactionExportService.new,
);
