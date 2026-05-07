import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/database/providers/database_providers.dart';

final appBootstrapProvider = FutureProvider<void>((ref) async {
  final database = ref.watch(appDatabaseProvider);
  final now = DateTime.now();

  final appSettings = await _ensureAppSettings(database, now);

  await _seedDefaultAccounts(database, now);
  await _seedDefaultCategories(database, appSettings, now);
});

const int _defaultCategorySeedVersion = 2;

const Set<String> _legacyDefaultCategoryIds = {
  'expense-food',
  'expense-transport',
  'expense-shopping',
  'income-salary',
  'income-other',
};

const List<_DefaultCategorySeed> _defaultCategorySeeds = [
  _DefaultCategorySeed('expense-food', '식비', 'expense', 1),
  _DefaultCategorySeed('expense-cafe-snack', '카페/간식', 'expense', 2),
  _DefaultCategorySeed('expense-groceries', '장보기', 'expense', 3),
  _DefaultCategorySeed('expense-transport', '교통', 'expense', 4),
  _DefaultCategorySeed('expense-housing-utilities', '주거/통신', 'expense', 5),
  _DefaultCategorySeed('expense-shopping', '쇼핑/패션', 'expense', 6),
  _DefaultCategorySeed('expense-household', '생활용품', 'expense', 7),
  _DefaultCategorySeed('expense-health', '의료/건강', 'expense', 8),
  _DefaultCategorySeed('expense-leisure', '취미/여가', 'expense', 9),
  _DefaultCategorySeed('expense-subscriptions', '구독/디지털', 'expense', 10),
  _DefaultCategorySeed('expense-gifts', '경조사/선물', 'expense', 11),
  _DefaultCategorySeed('expense-other', '기타 지출', 'expense', 12),
  _DefaultCategorySeed('income-salary', '급여', 'income', 1),
  _DefaultCategorySeed('income-allowance', '용돈/지원', 'income', 2),
  _DefaultCategorySeed('income-side-income', '부수입', 'income', 3),
  _DefaultCategorySeed('income-resale', '중고판매', 'income', 4),
  _DefaultCategorySeed('income-refund', '환급/캐시백', 'income', 5),
  _DefaultCategorySeed('income-interest-dividend', '이자/배당', 'income', 6),
  _DefaultCategorySeed('income-other', '기타 수입', 'income', 7),
];

Future<AppSetting> _ensureAppSettings(
  AppDatabase database,
  DateTime now,
) async {
  final existing = await database.select(database.appSettings).getSingleOrNull();
  if (existing != null) {
    return existing;
  }

  await database.into(database.appSettings).insert(
        AppSettingsCompanion.insert(
          createdAt: now,
          lastModifiedAt: now,
        ),
      );

  return database.select(database.appSettings).getSingle();
}

Future<void> _seedDefaultAccounts(AppDatabase database, DateTime now) async {
  final existingAccounts = await database.select(database.accounts).get();
  if (existingAccounts.isNotEmpty) {
    return;
  }

  await database.into(database.accounts).insert(
        AccountsCompanion.insert(
          localId: 'default-cash-account',
          name: '현금',
          type: 'cash',
          createdAt: now,
          lastModifiedAt: now,
        ),
      );
  await database.into(database.accounts).insert(
        AccountsCompanion.insert(
          localId: 'default-bank-account',
          name: '기본 입출금',
          type: 'bank',
          createdAt: now,
          lastModifiedAt: now,
        ),
      );
  await database.into(database.accounts).insert(
        AccountsCompanion.insert(
          localId: 'default-card-account',
          name: '대표 카드',
          type: 'card',
          createdAt: now,
          lastModifiedAt: now,
        ),
      );
}

Future<void> _seedDefaultCategories(
  AppDatabase database,
  AppSetting appSettings,
  DateTime now,
) async {
  if (appSettings.defaultCategorySeedVersion >= _defaultCategorySeedVersion) {
    return;
  }

  final existingCategories = await database.select(database.categories).get();
  final existingIds = existingCategories.map((row) => row.localId).toSet();

  final seedsToInsert = existingCategories.isEmpty
      ? _defaultCategorySeeds
      : _defaultCategorySeeds.where(
          (seed) =>
              !_legacyDefaultCategoryIds.contains(seed.localId) &&
              !existingIds.contains(seed.localId),
        );

  for (final seed in seedsToInsert) {
    await database.into(database.categories).insert(
          CategoriesCompanion.insert(
            localId: seed.localId,
            name: seed.name,
            type: seed.type,
            isDefault: const Value(true),
            sortOrder: Value(seed.sortOrder),
            createdAt: now,
            lastModifiedAt: now,
          ),
        );
  }

  await database.update(database.appSettings).replace(
        appSettings.copyWith(
          defaultCategorySeedVersion: _defaultCategorySeedVersion,
          lastModifiedAt: now,
        ),
      );
}

class _DefaultCategorySeed {
  const _DefaultCategorySeed(
    this.localId,
    this.name,
    this.type,
    this.sortOrder,
  );

  final String localId;
  final String name;
  final String type;
  final int sortOrder;
}
