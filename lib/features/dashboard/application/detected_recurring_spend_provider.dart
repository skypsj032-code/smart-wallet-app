import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/providers/database_providers.dart';
import 'recurring_spend_detector.dart';
import 'recurring_spend_override_store.dart';

class DetectedRecurringSpendSnapshot {
  const DetectedRecurringSpendSnapshot({
    required this.groups,
    required this.excludedKeys,
    this.accountNames = const {},
  });

  final List<RecurringSpendGroup> groups;
  final Set<String> excludedKeys;
  final Map<String, String> accountNames;
}

final detectedRecurringClockProvider = StreamProvider.autoDispose<DateTime>(
  (ref) => Stream.value(DateTime.now()),
);

final _recentSpendingProvider = StreamProvider<List<Transaction>>((ref) {
  final database = ref.watch(appDatabaseProvider);
  final now = DateTime.now();
  final start = now.subtract(const Duration(days: 90));
  final tomorrow = DateTime(now.year, now.month, now.day + 1);
  return (database.select(database.transactions)
        ..where((tx) =>
            tx.deletedAt.isNull() &
            tx.occurredAt.isBiggerOrEqualValue(start) &
            tx.occurredAt.isSmallerThanValue(tomorrow)))
      .watch();
});

final _excludedRecurringKeysProvider = StreamProvider<Set<String>>((ref) {
  return ref.watch(recurringSpendOverrideStoreProvider)
      .watchNotRecurringGroupKeys();
});

final detectedRecurringSpendProvider =
    Provider<AsyncValue<DetectedRecurringSpendSnapshot>>((ref) {
  final transactions = ref.watch(_recentSpendingProvider);
  final excluded = ref.watch(_excludedRecurringKeysProvider);
  return transactions.when<AsyncValue<DetectedRecurringSpendSnapshot>>(
    data: (items) => excluded.when<AsyncValue<DetectedRecurringSpendSnapshot>>(
      data: (keys) {
        final insight = detectRecurringSpendInsight(items, now: DateTime.now());
        return AsyncData(DetectedRecurringSpendSnapshot(
          groups: insight.groups
              .where((group) => !keys.contains(group.groupKey))
              .toList(),
          excludedKeys: keys,
        ));
      },
      error: (error, stack) => AsyncError(error, stack),
      loading: () => const AsyncLoading(),
    ),
    error: (error, stack) => AsyncError(error, stack),
    loading: () => const AsyncLoading(),
  );
});
