import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/providers/database_providers.dart';

class QuickEntryCategoryActions {
  const QuickEntryCategoryActions(this._database);

  final AppDatabase _database;

  Future<String> createCategory({
    required String name,
    required String type,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw Exception('카테고리 이름을 입력해 주세요.');
    }

    final existing = await (_database.select(_database.categories)
          ..where(
            (tbl) => tbl.name.equals(trimmedName) & tbl.type.equals(type),
          ))
        .getSingleOrNull();

    if (existing != null) {
      return existing.localId;
    }

    final now = DateTime.now();
    final count = await (_database.select(_database.categories)
          ..where((tbl) => tbl.type.equals(type)))
        .get()
        .then((rows) => rows.length);

    final localId = '${type}_${now.microsecondsSinceEpoch}';

    await _database.into(_database.categories).insert(
          CategoriesCompanion.insert(
            localId: localId,
            name: trimmedName,
            type: type,
            sortOrder: Value(count + 1),
            createdAt: now,
            lastModifiedAt: now,
          ),
        );

    return localId;
  }

  Future<void> renameCategory({
    required String localId,
    required String name,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw Exception('카테고리 이름을 입력해 주세요.');
    }

    final current = await (_database.select(_database.categories)
          ..where((tbl) => tbl.localId.equals(localId)))
        .getSingleOrNull();

    if (current == null) {
      throw Exception('수정할 카테고리를 찾지 못했습니다.');
    }

    final duplicate = await (_database.select(_database.categories)
          ..where(
            (tbl) =>
                tbl.localId.equals(localId).not() &
                tbl.name.equals(trimmedName) &
                tbl.type.equals(current.type),
          ))
        .getSingleOrNull();

    if (duplicate != null) {
      throw Exception('같은 이름의 카테고리가 이미 있습니다.');
    }

    final now = DateTime.now();

    await (_database.update(_database.categories)
          ..where((tbl) => tbl.localId.equals(localId)))
        .write(
          CategoriesCompanion(
            name: Value(trimmedName),
            lastModifiedAt: Value(now),
          ),
        );
  }

  Future<void> deleteCategory({
    required String localId,
  }) async {
    await (_database.delete(_database.categories)
          ..where((tbl) => tbl.localId.equals(localId)))
        .go();
  }
}

final quickEntryCategoryActionsProvider = Provider<QuickEntryCategoryActions>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return QuickEntryCategoryActions(database);
});
