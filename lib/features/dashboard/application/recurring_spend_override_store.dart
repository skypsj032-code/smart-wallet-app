import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/providers/database_providers.dart';

abstract class RecurringSpendOverrideStore {
  Stream<Set<String>> watchNotRecurringGroupKeys();
  Future<void> markGroupNotRecurring(String groupKey);
  Future<void> unmarkGroupNotRecurring(String groupKey);
}

class DriftRecurringSpendOverrideStore implements RecurringSpendOverrideStore {
  const DriftRecurringSpendOverrideStore(this._database);

  final AppDatabase _database;

  @override
  Future<void> markGroupNotRecurring(String groupKey) {
    return _database.markRecurringSpendGroupNotRecurring(groupKey);
  }

  @override
  Future<void> unmarkGroupNotRecurring(String groupKey) {
    return _database.unmarkRecurringSpendGroupNotRecurring(groupKey);
  }

  @override
  Stream<Set<String>> watchNotRecurringGroupKeys() {
    return _database.watchNotRecurringGroupKeys();
  }
}

final recurringSpendOverrideStoreProvider =
    Provider<RecurringSpendOverrideStore>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return DriftRecurringSpendOverrideStore(database);
});
