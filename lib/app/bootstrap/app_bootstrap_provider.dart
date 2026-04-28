import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/database/providers/database_providers.dart';

final appBootstrapProvider = FutureProvider<void>((ref) async {
  final database = ref.watch(appDatabaseProvider);
  final now = DateTime.now();

  final appSettings = await database.select(database.appSettings).getSingleOrNull();
  if (appSettings == null) {
    await database.into(database.appSettings).insert(
          AppSettingsCompanion.insert(
            createdAt: now,
            lastModifiedAt: now,
          ),
        );
  }

  final existingAccounts = await database.select(database.accounts).get();
  if (existingAccounts.isEmpty) {
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
            name: '주거래 통장',
            type: 'bank',
            createdAt: now,
            lastModifiedAt: now,
          ),
        );
    await database.into(database.accounts).insert(
          AccountsCompanion.insert(
            localId: 'default-card-account',
            name: '생활 카드',
            type: 'card',
            createdAt: now,
            lastModifiedAt: now,
          ),
        );
  }

  final existingCategories = await database.select(database.categories).get();
  if (existingCategories.isEmpty) {
    const defaults = [
      ('expense-food', '식비', 'expense', 1),
      ('expense-transport', '교통', 'expense', 2),
      ('expense-shopping', '쇼핑', 'expense', 3),
      ('income-salary', '급여', 'income', 1),
      ('income-other', '기타 수입', 'income', 2),
    ];

    for (final item in defaults) {
      await database.into(database.categories).insert(
            CategoriesCompanion.insert(
              localId: item.$1,
              name: item.$2,
              type: item.$3,
              isDefault: const Value(true),
              sortOrder: Value(item.$4),
              createdAt: now,
              lastModifiedAt: now,
            ),
          );
    }
  }
});
