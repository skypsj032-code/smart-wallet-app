import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/providers/database_providers.dart';

// ── 결과 모델 ─────────────────────────────────────────────────────────────────

class CsvImportResult {
  const CsvImportResult({
    required this.imported,
    required this.skipped,
    required this.errors,
  });

  final int imported;
  final int skipped;
  final List<String> errors;

  bool get hasErrors => errors.isNotEmpty;
  bool get success => imported > 0;
}

// ── 매핑 설정 ─────────────────────────────────────────────────────────────────

/// 사용자가 CSV 열을 어떤 필드에 매핑할지 결정하는 설정.
/// null이면 해당 필드는 무시.
class CsvColumnMapping {
  const CsvColumnMapping({
    required this.typeCol,
    required this.amountCol,
    required this.occurredAtCol,
    this.memoCol,
    this.merchantCol,
    this.accountIdCol,
    this.categoryIdCol,
    this.hasHeader = true,
    this.delimiter = ',',
    this.defaultType = 'expense',
  });

  final int typeCol;
  final int amountCol;
  final int occurredAtCol;
  final int? memoCol;
  final int? merchantCol;
  final int? accountIdCol;
  final int? categoryIdCol;
  final bool hasHeader;
  final String delimiter;
  final String defaultType; // 타입 열이 없을 때 기본값

  /// 스마트 월렛 자체 내보내기 CSV 형식
  static const smartWalletExport = CsvColumnMapping(
    typeCol: 1,
    amountCol: 2,
    occurredAtCol: 3,
    accountIdCol: 4,
    categoryIdCol: 5,
    merchantCol: 6,
    memoCol: 8,
    hasHeader: true,
  );

  /// 단순 3열(날짜,금액,메모) 형식
  static const simpleThreeColumn = CsvColumnMapping(
    typeCol: -1, // 없음 → defaultType 사용
    amountCol: 1,
    occurredAtCol: 0,
    memoCol: 2,
    hasHeader: true,
    defaultType: 'expense',
  );
}

// ── 서비스 ────────────────────────────────────────────────────────────────────

class CsvImportService {
  CsvImportService(this._database);

  final AppDatabase _database;

  /// 파일을 선택하고 내용을 반환. 취소하면 null.
  Future<String?> pickCsvFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'txt'],
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final file = result.files.first;

    // 모바일: path / 데스크탑: bytes
    if (file.path != null) {
      return File(file.path!).readAsString();
    }

    if (file.bytes != null) {
      return String.fromCharCodes(file.bytes!);
    }

    return null;
  }

  /// CSV 텍스트에서 헤더를 읽어 열 목록을 반환
  List<String> parseHeaders(String csvText, {String delimiter = ','}) {
    final lines = _splitLines(csvText);
    if (lines.isEmpty) return [];
    return _parseCsvRow(lines.first, delimiter);
  }

  /// CSV를 파싱하여 DB에 삽입
  Future<CsvImportResult> importCsv(
    String csvText,
    CsvColumnMapping mapping,
  ) async {
    final lines = _splitLines(csvText);
    if (lines.isEmpty) {
      return const CsvImportResult(imported: 0, skipped: 0, errors: ['파일이 비어 있습니다.']);
    }

    final dataLines = mapping.hasHeader ? lines.skip(1).toList() : lines;
    int skipped = 0;
    final errors = <String>[];
    final companions = <TransactionsCompanion>[];

    for (var i = 0; i < dataLines.length; i++) {
      final lineNum = i + (mapping.hasHeader ? 2 : 1);
      final raw = dataLines[i].trim();
      if (raw.isEmpty) {
        skipped++;
        continue;
      }

      try {
        final cols = _parseCsvRow(raw, mapping.delimiter);
        final companion = _buildCompanion(cols, mapping, lineNum);
        if (companion == null) {
          skipped++;
          continue;
        }
        companions.add(companion);
      } catch (e) {
        errors.add('행 $lineNum: $e');
        if (errors.length >= 20) {
          errors.add('…오류가 너무 많아 나머지는 생략합니다.');
          break;
        }
      }
    }

    // 배치 삽입 — insertOrIgnore로 중복 자동 건너뜀
    int imported = 0;
    if (companions.isNotEmpty) {
      await _database.batch((batch) {
        batch.insertAll(
          _database.transactions,
          companions,
          mode: InsertMode.insertOrIgnore,
        );
      });
      // insertOrIgnore는 실제 삽입 건수를 반환하지 않으므로 companions 수로 근사
      imported = companions.length;
    }

    return CsvImportResult(imported: imported, skipped: skipped, errors: errors);
  }

  TransactionsCompanion? _buildCompanion(
    List<String> cols,
    CsvColumnMapping mapping,
    int lineNum,
  ) {
    String? safeGet(int? col) {
      if (col == null || col < 0 || col >= cols.length) return null;
      final v = cols[col].trim();
      return v.isEmpty ? null : v;
    }

    // 금액 (필수)
    final rawAmount = safeGet(mapping.amountCol);
    if (rawAmount == null) return null;
    final amount = _parseAmount(rawAmount);
    if (amount == null || amount <= 0) {
      throw FormatException('금액을 인식할 수 없습니다: "$rawAmount"');
    }

    // 날짜 (필수)
    final rawDate = safeGet(mapping.occurredAtCol);
    if (rawDate == null) return null;
    final occurredAt = _parseDate(rawDate);
    if (occurredAt == null) {
      throw FormatException('날짜를 인식할 수 없습니다: "$rawDate"');
    }

    // 타입
    final rawType = safeGet(mapping.typeCol);
    final type = _normalizeType(rawType) ?? mapping.defaultType;

    // SHA-256 기반 localId: 동일 내용 재 임포트 시 insertOrIgnore로 자동 건너뜀
    final dedupeSource =
        '${occurredAt.toIso8601String()}|$amount|$type|${safeGet(mapping.memoCol) ?? ''}|${safeGet(mapping.merchantCol) ?? ''}';
    final localId =
        'csv_${sha256.convert(utf8.encode(dedupeSource)).toString().substring(0, 16)}';

    final now = DateTime.now();

    return TransactionsCompanion.insert(
      localId: localId,
      type: type,
      amount: amount,
      occurredAt: occurredAt,
      memo: Value(safeGet(mapping.memoCol)),
      merchantName: Value(safeGet(mapping.merchantCol)),
      accountId: Value(safeGet(mapping.accountIdCol)),
      categoryId: Value(safeGet(mapping.categoryIdCol)),
      createdAt: now,
      lastModifiedAt: now,
    );
  }

  // ── 파싱 헬퍼 ───────────────────────────────────────────────────────────────

  List<String> _splitLines(String text) {
    return text
        .split(RegExp(r'\r?\n'))
        .where((l) => l.trim().isNotEmpty)
        .toList();
  }

  /// RFC 4180 준수 CSV 열 파싱 (따옴표, 이스케이프 처리)
  List<String> _parseCsvRow(String row, String delimiter) {
    final result = <String>[];
    var current = StringBuffer();
    var inQuotes = false;
    var i = 0;

    while (i < row.length) {
      final ch = row[i];
      if (ch == '"') {
        if (inQuotes && i + 1 < row.length && row[i + 1] == '"') {
          current.write('"');
          i += 2;
          continue;
        }
        inQuotes = !inQuotes;
      } else if (ch == delimiter && !inQuotes) {
        result.add(current.toString());
        current = StringBuffer();
      } else {
        current.write(ch);
      }
      i++;
    }
    result.add(current.toString());
    return result;
  }

  int? _parseAmount(String raw) {
    final digitsOnly = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) return null;
    return int.tryParse(digitsOnly);
  }

  DateTime? _parseDate(String raw) {
    // ISO 8601
    try {
      return DateTime.parse(raw.replaceAll('/', '-').replaceAll('.', '-'));
    } catch (_) {}

    // yyyy-mm-dd / yyyymmdd
    final compact = RegExp(r'^(\d{4})[-./]?(\d{2})[-./]?(\d{2})').firstMatch(raw);
