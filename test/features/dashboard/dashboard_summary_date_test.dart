import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet_app/core/database/app_database.dart';
import 'package:smart_wallet_app/core/database/providers/database_providers.dart';
import 'package:smart_wallet_app/features/dashboard/application/dashboard_narrative.dart';
import 'package:smart_wallet_app/features/dashboard/application/dashboard_summary_provider.dart';
import 'package:smart_wallet_app/features/dashboard/application/detected_recurring_spend_provider.dart';

import '../../test_support/sqlite_test_setup.dart';

void main() {
  setUpAll(configureSqliteForTests);

  test('home summary changes at midnight and uses the new month budget',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    for (final item in [
      ('jan30', DateTime(2026, 1, 30, 12), 10000),
      ('jan31', DateTime(2026, 1, 31, 12), 20000),
      ('feb01', DateTime(2026, 2, 1, 12), 40000),
    ]) {
      await db.into(db.transactions).insert(TransactionsCompanion.insert(
            localId: item.$1,
            type: 'expense',
            amount: item.$3,
            occurredAt: item.$2,
            createdAt: item.$2,
            lastModifiedAt: item.$2,
          ));
    }
    for (final budget in [
      ('2026-01', 100000),
      ('2026-02', 200000),
    ]) {
      await db.into(db.budgets).insert(BudgetsCompanion.insert(
            localId: budget.$1,
            monthKey: budget.$1,
            amountLimit: budget.$2,
            createdAt: DateTime(2026),
            lastModifiedAt: DateTime(2026),
          ));
    }

    final clock = StreamController<DateTime>.broadcast();
    addTearDown(clock.close);
    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      detectedRecurringClockProvider.overrideWith((ref) => clock.stream),
    ]);
    addTearDown(container.dispose);
    final keepAlive = container.listen(dashboardSummaryProvider, (_, __) {});
    addTearDown(keepAlive.close);
    await Future<void>.delayed(Duration.zero);

    clock.add(DateTime(2026, 1, 30, 23, 59));
    final beforeMidnight = await _waitForSummary(
      container,
      when: (summary) => summary.todayExpense == 10000,
    );
    expect(beforeMidnight.monthExpense, 30000);
    expect(beforeMidnight.totalBudget, 100000);
    expect(beforeMidnight.todayTransactionCount, 1);

    clock.add(DateTime(2026, 1, 31));
    final nextDay = await _waitForSummary(
      container,
      when: (summary) => summary.todayExpense == 20000,
    );
    expect(nextDay.monthExpense, 30000);
    expect(nextDay.totalBudget, 100000);
    expect(nextDay.todayTransactionCount, 1);

    clock.add(DateTime(2026, 2, 1));
    final nextMonth = await _waitForSummary(
      container,
      when: (summary) => summary.totalBudget == 200000,
    );
    expect(nextMonth.monthExpense, 40000);
    expect(nextMonth.todayExpense, 40000);
    expect(nextMonth.remainingBudget, 160000);
    expect(nextMonth.narrative.monthExpense, 40000);
    expect(
      buildDashboardWeatherSummary(nextMonth.narrative).evidence,
      contains('₩200,000'),
    );
  });
}

Future<DashboardSummary> _waitForSummary(
  ProviderContainer container, {
  required bool Function(DashboardSummary) when,
}) async {
  final completer = Completer<DashboardSummary>();
  final subscription = container.listen(dashboardSummaryProvider, (_, next) {
    final value = next.asData?.value;
    if (value != null && when(value) && !completer.isCompleted) {
      completer.complete(value);
    }
  }, fireImmediately: true);
  try {
    return await completer.future.timeout(const Duration(seconds: 5));
  } finally {
    subscription.close();
  }
}
