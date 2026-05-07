import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/providers/database_providers.dart';

class OcrDraftRepository {
  OcrDraftRepository(this._database);

  final AppDatabase _database;

  Future<String> createDraft({
    required String status,
    String? imagePath,
    String? rawText,
    double? confidence,
    String? storeName,
    int? amount,
    String? categoryGuess,
    String? errorMessage,
  }) async {
    final now = DateTime.now();
    final id = 'ocr_${now.microsecondsSinceEpoch}';

    await _database.into(_database.ocrDrafts).insert(
          OcrDraftsCompanion.insert(
            localId: id,
            ocrStatus: status,
            sourceImagePath: Value(imagePath),
            ocrRawText: Value(rawText),
            ocrConfidence: Value(confidence),
            parsedStoreName: Value(storeName),
            parsedTotalAmount: Value(amount),
            parsedTransactionDate: const Value(null),
            parsedCategoryGuess: Value(categoryGuess),
            errorMessage: Value(errorMessage),
            createdAt: now,
            lastModifiedAt: now,
          ),
        );

    return id;
  }

  Future<void> updateDraft({
    required String localId,
    required String status,
    String? imagePath,
    String? rawText,
    double? confidence,
    String? storeName,
    int? amount,
    String? categoryGuess,
    String? errorMessage,
  }) async {
    await (_database.update(_database.ocrDrafts)
          ..where((tbl) => tbl.localId.equals(localId)))
        .write(
      OcrDraftsCompanion(
        ocrStatus: Value(status),
        sourceImagePath: Value(imagePath),
        ocrRawText: Value(rawText),
        ocrConfidence: Value(confidence),
        parsedStoreName: Value(storeName),
        parsedTotalAmount: Value(amount),
        parsedCategoryGuess: Value(categoryGuess),
        errorMessage: Value(errorMessage),
        lastModifiedAt: Value(DateTime.now()),
      ),
    );
  }

  Stream<OcrDraft?> watchLatestDraft() {
    return (_database.select(_database.ocrDrafts)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(1))
        .watchSingleOrNull();
  }
}

final ocrDraftRepositoryProvider = Provider<OcrDraftRepository>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return OcrDraftRepository(database);
});
