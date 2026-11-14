import 'dart:async';

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

final detectedRecurringClockProvider = StreamProvider<DateTime>(
  (ref) {
    late StreamController<DateTime> controller;
    Timer? timer;
    void tick() {
      final now = DateTime.now();
      controller.add(now);
      final nextDay = DateTime(now.year, now.month, now.day + 1);
      timer = Timer(nextDay.difference(now) + const Duration(milliseconds: 50), tick);
    }

    controller = StreamController<DateTime>(
      onListen: tick,
      onCancel: () => timer?.cancel(),
    );
    return controller.stream;
  },
);

final _recentSpendingProvider = StreamProvider.autoDispose<List<Transaction>>((ref) {
  final database = ref.watch(appDatabaseProvider);
  final clock = ref.watch(detectedRecurringClockProvider);
  return clock.when<Stream<List<Transaction>>>(
    data: (now) {
      final start = now.subtract(const Duration(days: 90));
      final tomorrow = DateTime(now.year, now.month, now.day + 1);
      return (database.select(database.transactions)
            ..where((tx) =>
                tx.deletedAt.isNull() &
                tx.occurredAt.isBiggerOrEqualValue(start) &
                tx.occurredAt.isSmallerThanValue(tomorrow)))
          .watch();
    },
    error: (error, stack) => Stream.error(error, stack),
    loading: () => const Stream.empty(),
  );
});

final _excludedRecurringKeysProvider = StreamProvider.autoDispose<Set<String>>((ref) {
  return ref.watch(recurringSpendOverrideStoreProvider)
      .watchNotRecurringGroupKeys();
});

final _recurringAccountNamesProvider =
    StreamProvider.autoDispose<Map<String, String>>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return database.select(database.accounts).watch().map(
        (rows) => {for (final account in rows) account.localId: account.name},
      );
});

final detectedRecurringSpendProvider =
    Provider.autoDispose<AsyncValue<DetectedRecurringSpendSnapshot>>((ref) {
  final clock = ref.watch(detectedRecurringClockProvider);
  final transactions = ref.watch(_recentSpendingProvider);
  final excluded = ref.watch(_excludedRecurringKeysProvider);
  final accounts = ref.watch(_recurringAccountNamesProvider);
  return clock.when<AsyncValue<DetectedRecurringSpendSnapshot>>(
    data: (now) => transactions.when<AsyncValue<DetectedRecurringSpendSnapshot>>(
      data: (items) => excluded.when<AsyncValue<DetectedRecurringSpendSnapshot>>(
        data: (keys) => accounts.when<AsyncValue<DetectedRecurringSpendSnapshot>>(
          data: (names) {
            final insight = detectRecurringSpendInsight(items, now: now);
            return AsyncData(DetectedRecurringSpendSnapshot(
              groups: insight.groups
                  .where((group) => !keys.contains(group.groupKey))
                  .toList(),
              excludedKeys: keys,
              accountNames: names,
            ));
          },
          error: (error, stack) => AsyncError(error, stack),
          loading: () => const AsyncLoading(),
        ),
        error: (error, stack) => AsyncError(error, stack),
        loading: () => const AsyncLoading(),
      ),
      error: (error, stack) => AsyncError(error, stack),
      loading: () => const AsyncLoading(),
    ),
    error: (error, stack) => AsyncError(error, stack),
    loading: () => const AsyncLoading(),
  );
});
