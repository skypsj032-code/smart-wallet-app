import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet_app/app/bootstrap/app_bootstrap_provider.dart';
import 'package:smart_wallet_app/core/database/app_database.dart';
import 'package:smart_wallet_app/core/database/providers/database_providers.dart';

import 'test_support/sqlite_test_setup.dart';

void main() {
  late AppDatabase database;
  late ProviderContainer container;

  setUpAll(configureSqliteForTests);

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await database.close();
  });

  test('bootstrap seeds the expanded default categories on a new install',
      () async {
    await container.read(appBootstrapProvider.future);

    final categories = await database.select(database.categories).get();
    final categoryIds = categories.map((row) => row.localId).toSet();

    expect(categoryIds, _expandedDefaultCategoryIds);
    expect(categories.every((row) => row.isDefault), isTrue);
  });

  test(
      'bootstrap backfills only new default categories for an existing user',
      () async {
    await _insertSettings(database);
    await _insertLegacyDefaultCategory(
      database,
      localId: 'expense-food',
      name: '식비',
      type: 'expense',
      sortOrder: 1,
    );
    await _insertLegacyDefaultCategory(
      database,
      localId: 'expense-transport',
      name: '교통',
      type: 'expense',
      sortOrder: 2,
    );
    await _insertLegacyDefaultCategory(
      database,
      localId: 'income-salary',
      name: '급여',
      type: 'income',
      sortOrder: 1,
    );
    await _insertLegacyDefaultCategory(
      database,
      localId: 'income-other',
      name: '기타 수입',
      type: 'income',
      sortOrder: 2,
    );

    await container.read(appBootstrapProvider.future);

    final categoryIds = await _readCategoryIds(database);
    expect(categoryIds, contains('expense-cafe-snack'));
    expect(categoryIds, contains('income-refund'));
    expect(categoryIds, isNot(contains('expense-shopping')));
  });

  test('bootstrap does not recreate a deleted default category after upgrade',
      () async {
    await _insertSettings(database);
    await _insertLegacyDefaultCategory(
      database,
      localId: 'expense-food',
      name: '식비',
      type: 'expense',
      sortOrder: 1,
    );

    await container.read(appBootstrapProvider.future);

    await (database.delete(database.categories)
          ..where((tbl) => tbl.localId.equals('expense-cafe-snack')))
        .go();

    container.invalidate(appBootstrapProvider);
    await container.read(appBootstrapProvider.future);

    final categoryIds = await _readCategoryIds(database);
    expect(categoryIds, isNot(contains('expense-cafe-snack')));
  });
}

Future<void> _insertSettings(AppDatabase database) {
  final now = DateTime(2026, 5, 5);
  return database.into(database.appSettings).insert(
        AppSettingsCompanion.insert(
          createdAt: now,
          lastModifiedAt: now,
        ),
      );
}

Future<void> _insertLegacyDefaultCategory(
  AppDatabase database, {
  required String localId,
  required String name,
  required String type,
  required int sortOrder,
}) {
  final now = DateTime(2026, 5, 5);
  return database.into(database.categories).insert(
        CategoriesCompanion.insert(
          localId: localId,
          name: name,
          type: type,
          isDefault: const Value(true),
          sortOrder: Value(sortOrder),
          createdAt: now,
          lastModifiedAt: now,
        ),
      );
}

Future<Set<String>> _readCategoryIds(AppDatabase database) async {
  final categories = await database.select(database.categories).get();
  return categories.map((row) => row.localId).toSet();
}

const Set<String> _expandedDefaultCategoryIds = {
  'expense-food',
  'expense-cafe-snack',
  'expense-groceries',
  'expense-transport',
  'expense-housing-utilities',
  'expense-shopping',
  'expense-household',
  'expense-health',
  'expense-leisure',
  'expense-subscriptions',
  'expense-gifts',
  'expense-other',
  'income-salary',
  'income-allowance',
  'income-side-income',
  'income-resale',
  'income-refund',
  'income-interest-dividend',
  'income-other',
};
