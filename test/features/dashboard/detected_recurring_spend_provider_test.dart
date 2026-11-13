import 'dart:async';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet_app/core/database/app_database.dart';
import 'package:smart_wallet_app/core/database/providers/database_providers.dart';
import 'package:smart_wallet_app/features/dashboard/application/detected_recurring_spend_provider.dart';

import '../../test_support/sqlite_test_setup.dart';

void main() {
  setUpAll(configureSqliteForTests);

  test('recalculates the date range after midnight and month change', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    for (final entry in [
      ('dec', DateTime(2025, 12, 1)),
      ('jan', DateTime(2026, 1, 1)),
      ('feb', DateTime(2026, 2, 1)),
    ]) {
      await database.into(database.transactions).insert(
            TransactionsCompanion.insert(
              localId: entry.$1,
              type: 'expense',
              amount: 10000,
              occurredAt: entry.$2,
              accountId: const drift.Value('bank'),
              merchantName: const drift.Value('정기 결제'),
              createdAt: entry.$2,
              lastModifiedAt: entry.$2,
            ),
          );
    }
    final clock = StreamController<DateTime>.broadcast();
    addTearDown(clock.close);
    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(database),
      detectedRecurringClockProvider.overrideWith((ref) => clock.stream),
    ]);
    addTearDown(container.dispose);
    final keepAlive = container.listen(detectedRecurringSpendProvider, (_, __) {});
    addTearDown(keepAlive.close);
    await Future<void>.delayed(Duration.zero);
    clock.add(DateTime(2026, 1, 31, 23, 59));
    final january = await _waitForSnapshot(container);
    expect(january.groups, hasLength(1));
    expect(january.groups.single.transactions.map((tx) => tx.localId),
        isNot(contains('feb')));

    clock.add(DateTime(2026, 2, 1));
    final february = await _waitForSnapshot(
      container,
      when: (value) => value.groups.any(
        (group) => group.transactions.any((tx) => tx.localId == 'feb'),
      ),
    );
    expect(february.groups.single.currentMonthAmount, 10000);
  });
}

Future<DetectedRecurringSpendSnapshot> _waitForSnapshot(
  ProviderContainer container, {
  bool Function(DetectedRecurringSpendSnapshot)? when,
}) async {
  final completer = Completer<DetectedRecurringSpendSnapshot>();
  final subscription = container.listen(detectedRecurringSpendProvider,
      (_, next) {
    final value = next.valueOrNull;
    if (value != null && (when == null || when(value)) && !completer.isCompleted) {
      completer.complete(value);
    }
  }, fireImmediately: true);
  try {
    return await completer.future.timeout(const Duration(seconds: 5));
  } finally {
    subscription.close();
  }
}
