import 'dart:io';

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
  });

  final String csv;
  final int rowCount;
  final String fileName;
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

  Future<CsvExportPayload> exportTransactionsCsv() async {
    final database = _ref.read(appDatabaseProvider);
    final rows = await database.select(database.transactions).get();
    final transactions = rows.where((tx) => tx.deletedAt == null).toList();
    final exportedAt = DateTime.now();
    final fileName = _buildFileName(exportedAt);

    final buffer = StringBuffer()..writeln(_csvHeaders.join(','));

    for (final row in transactions) {
      buffer.writeln(_buildCsvRow(row).join(','));
    }

    return CsvExportPayload(
      csv: buffer.toString(),
      rowCount: transactions.length,
      fileName: fileName,
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

  String _buildFileName(DateTime exportedAt) {
    final timestamp = DateFormat('yyyyMMdd-HHmmss').format(exportedAt);
    return 'smart-wallet-transactions-$timestamp.csv';
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
