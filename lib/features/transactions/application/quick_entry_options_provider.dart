import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/providers/database_providers.dart';

class QuickEntryAccountOption {
  const QuickEntryAccountOption({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;
}

class QuickEntryCategoryOption {
  const QuickEntryCategoryOption({
    required this.id,
    required this.name,
    required this.type,
  });

  final String id;
  final String name;
  final String type;
}

/// QuickEntry 화면이 닫히면 DB 스트림 구독 자동 해제 (autoDispose).
final quickEntryAccountsProvider =
    StreamProvider.autoDispose<List<QuickEntryAccountOption>>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return (database.select(database.accounts)
        ..where((tbl) => tbl.isActive.equals(true))
        ..orderBy([(tbl) => OrderingTerm(expression: tbl.name)]))
      .watch()
      .map(
        (rows) => rows
            .map((row) => QuickEntryAccountOption(id: row.localId, name: row.name))
            .toList(),
      );
});

/// 타입별 카테고리 목록 — 화면 종료 시 자동 구독 해제.
final quickEntryCategoriesProvider =
    StreamProvider.autoDispose.family<List<QuickEntryCategoryOption>, String>((ref, type) {
  final database = ref.watch(appDatabaseProvider);
  return (database.select(database.categories)
        ..where((tbl) => tbl.isActive.equals(true) & tbl.type.equals(type))
        ..orderBy([(tbl) => OrderingTerm(expression: tbl.sortOrder)]))
      .watch()
      .map(
        (rows) => rows
            .map(
              (row) => QuickEntryCategoryOption(
                id: row.localId,
                name: row.name,
                type: row.type,
              ),
            )
            .toList(),
      );
});
