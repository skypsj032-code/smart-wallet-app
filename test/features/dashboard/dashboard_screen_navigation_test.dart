import 'dart:async';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wallet_app/app/theme/app_theme.dart';
import 'package:smart_wallet_app/core/database/app_database.dart';
import 'package:smart_wallet_app/core/database/providers/database_providers.dart';
import 'package:smart_wallet_app/features/calendar/application/calendar_provider.dart';
import 'package:smart_wallet_app/features/dashboard/application/dashboard_narrative.dart';
import 'package:smart_wallet_app/features/dashboard/application/detected_recurring_spend_provider.dart';
import 'package:smart_wallet_app/features/dashboard/application/recurring_spend_detector.dart';
import 'package:smart_wallet_app/features/dashboard/application/recurring_spend_override_store.dart';
import 'package:smart_wallet_app/features/dashboard/application/recurring_transaction_suggestion_provider.dart';
import 'package:smart_wallet_app/features/dashboard/application/dashboard_summary_provider.dart';
import 'package:smart_wallet_app/features/dashboard/application/wealth_hero_motion.dart';
import 'package:smart_wallet_app/features/dashboard/presentation/dashboard_screen.dart';
import 'package:smart_wallet_app/features/recurring_expenses/application/recurring_expense_service.dart';
import 'package:smart_wallet_app/features/statistics/application/statistics_provider.dart';

import '../../test_support/sqlite_test_setup.dart';

void main() {
  setUpAll(configureSqliteForTests);

  test('pending count includes older pending histories and excludes others',
      () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final firstDay = DateTime(2026, 1, 1);
    await database.batch((batch) {
      batch.insert(
        database.notificationHistories,
        NotificationHistoriesCompanion.insert(
          packageName: 'bank',
          amount: 1000,
          type: 'expense',
          detectedAt: firstDay,
          status: const drift.Value('pending'),
        ),
      );
      for (var i = 1; i <= 101; i++) {
        batch.insert(
          database.notificationHistories,
          NotificationHistoriesCompanion.insert(
            packageName: 'bank',
            amount: 1000,
            type: 'expense',
            detectedAt: firstDay.add(Duration(minutes: i)),
            status: const drift.Value('legacy'),
          ),
        );
      }
      for (final status in ['recorded', 'ignored']) {
        batch.insert(
          database.notificationHistories,
          NotificationHistoriesCompanion.insert(
            packageName: 'bank',
            amount: 1000,
            type: 'expense',
            detectedAt: firstDay.add(const Duration(minutes: 102)),
            status: drift.Value(status),
          ),
        );
      }
      batch.insert(
        database.notificationHistories,
        NotificationHistoriesCompanion.insert(
          packageName: 'bank',
          amount: 2000,
          type: 'income',
          detectedAt: firstDay.add(const Duration(minutes: 103)),
          status: const drift.Value('pending'),
        ),
      );
    });

    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(database),
    ]);
    addTearDown(container.dispose);

    expect(
      await container.read(dashboardPendingNotificationCountProvider.future),
      2,
    );
  });

  testWidgets('dashboard calendar card opens the calendar route',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final router = _buildRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(
      _DashboardTestApp(
        router: router,
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('dashboard-open-calendar')));
    await tester.tap(find.byKey(const Key('dashboard-open-calendar')));
    await tester.pumpAndSettle();

    expect(find.text('Calendar Route'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('dashboard statistics card opens the statistics route',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final router = _buildRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(
      _DashboardTestApp(
        router: router,
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const Key('dashboard-open-statistics')),
    );
    await tester.tap(find.byKey(const Key('dashboard-open-statistics')));
    await tester.pumpAndSettle();

    expect(find.text('Statistics Route'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('notification history stays reachable as pending count changes',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final router = _buildRouter();
    addTearDown(router.dispose);
    final pending = StreamController<int>();
    addTearDown(pending.close);
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(_DashboardTestApp(
        router: router,
        pendingNotifications: pending.stream,
      ));
      pending.add(2);
      await tester.pumpAndSettle();

      expect(find.text('확인 대기 중인 알림 2건'), findsOneWidget);
      expect(
        find.bySemanticsLabel('알림 수신 이력. 확인 대기 중인 알림 2건.'),
        findsOneWidget,
      );

      pending.add(0);
      await tester.pumpAndSettle();
      expect(find.text('확인 대기 중인 알림 0건'), findsOneWidget);
      await tester.ensureVisible(
        find.byKey(const Key('dashboard-open-notification-history')),
      );
      await tester.tap(
        find.byKey(const Key('dashboard-open-notification-history')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Notification History Route'), findsOneWidget);
    } finally {
      semantics.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
  });

  testWidgets('home refreshes spending and budget after app resume',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await _seedMonthlyDashboardData(db);
    var currentTime = DateTime(2026, 1, 31, 23, 59);
    final router = _buildRouter();
    addTearDown(router.dispose);
    try {
      await tester.pumpWidget(_DashboardTestApp(
        router: router,
        database: db,
        currentTime: () => currentTime,
      ));
      await tester.pumpAndSettle();
      expect(find.textContaining('기록된 지출 1건 · ₩10,000'), findsOneWidget);
      expect(find.textContaining('예산 ₩100,000'), findsOneWidget);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      currentTime = DateTime(2026, 2, 1, 8);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(find.textContaining('기록된 지출 1건 · ₩40,000'), findsOneWidget);
      expect(find.textContaining('예산 ₩200,000'), findsOneWidget);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
  });

  testWidgets('home advances its month at midnight while it remains open',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await _seedMonthlyDashboardData(db);
    var currentTime = DateTime(2026, 1, 31, 23, 59, 50);
    final router = _buildRouter();
    addTearDown(router.dispose);
    try {
      await tester.pumpWidget(_DashboardTestApp(
        router: router,
        database: db,
        currentTime: () => currentTime,
      ));
      await tester.pumpAndSettle();
      expect(find.textContaining('기록된 지출 1건 · ₩10,000'), findsOneWidget);

      currentTime = DateTime(2026, 2, 1);
      await tester.pump(const Duration(seconds: 11));
      await tester.pumpAndSettle();

      expect(find.textContaining('기록된 지출 1건 · ₩40,000'), findsOneWidget);
      expect(find.textContaining('예산 ₩200,000'), findsOneWidget);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
  });

  testWidgets('weather header and detected recurring spending coexist',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final now = DateTime.now();
    final transactions = <Transaction>[];
    for (var monthOffset = 0; monthOffset < 3; monthOffset++) {
      final date = DateTime(now.year, now.month - monthOffset, 1);
      transactions.add(Transaction(
        localId: 'rent-$monthOffset', type: 'expense', amount: 700000,
        occurredAt: date, merchantName: '월세', accountId: 'bank',
        createdAt: date, lastModifiedAt: date,
      ));
    }
    final detected = detectRecurringSpendInsight(transactions, now: now);
    final snapshot = DetectedRecurringSpendSnapshot(
      groups: detected.groups, excludedKeys: const {},
      accountNames: const {'bank': '생활비 통장'},
    );
    final router = _buildRouter();
    addTearDown(router.dispose);
    try {
      await tester.pumpWidget(_DashboardTestApp(
        router: router, snapshot: snapshot,
      ));
      await tester.pumpAndSettle();

      final headers = tester.widgetList<SliverPersistentHeader>(
        find.byType(SliverPersistentHeader),
      );
      expect(headers.any((header) => header.pinned), isTrue);
      expect(find.text('거래에서 감지한 반복 지출'), findsOneWidget);
      expect(find.text('월세'), findsOneWidget);
      expect(find.textContaining('생활비 통장'), findsOneWidget);

      const visibleKey = Key('recurring-spend-visible-bank|월세');
      expect(find.byKey(visibleKey), findsOneWidget);
      await tester.tap(find.byTooltip('반복 지출에서 제외'));
      await tester.pumpAndSettle();
      expect(find.byKey(visibleKey), findsNothing);
      expect(find.text('숨긴 반복 지출'), findsOneWidget);
      await tester.tap(find.byTooltip('반복 지출 복구'));
      await tester.pumpAndSettle();
      expect(find.byKey(visibleKey), findsOneWidget);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
  });
}

Future<void> _seedMonthlyDashboardData(AppDatabase db) async {
  for (final entry in [
    ('january', DateTime(2026, 1, 31, 12), 10000, 100000),
    ('february', DateTime(2026, 2, 1, 12), 40000, 200000),
  ]) {
    await db.into(db.transactions).insert(TransactionsCompanion.insert(
          localId: entry.$1,
          type: 'expense',
          amount: entry.$3,
          occurredAt: entry.$2,
          createdAt: entry.$2,
          lastModifiedAt: entry.$2,
        ));
    final monthKey =
        '${entry.$2.year}-${entry.$2.month.toString().padLeft(2, '0')}';
    await db.into(db.budgets).insert(BudgetsCompanion.insert(
          localId: entry.$1,
          monthKey: monthKey,
          amountLimit: entry.$4,
          createdAt: entry.$2,
          lastModifiedAt: entry.$2,
        ));
  }
}

class _DashboardTestApp extends StatelessWidget {
  const _DashboardTestApp({
    required this.router,
    this.snapshot = const DetectedRecurringSpendSnapshot(groups: [], excludedKeys: {}),
    this.pendingNotifications,
    this.database,
    this.currentTime,
  });

  final GoRouter router;
  final DetectedRecurringSpendSnapshot snapshot;
  final Stream<int>? pendingNotifications;
  final AppDatabase? database;
  final DateTime Function()? currentTime;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        if (database != null) appDatabaseProvider.overrideWithValue(database!),
        if (currentTime != null)
          dashboardNowProvider.overrideWithValue(currentTime!),
        dashboardPendingNotificationCountProvider.overrideWith(
          (ref) => pendingNotifications ?? Stream.value(0),
        ),
        detectedRecurringSpendProvider.overrideWith((ref) {
          final excluded = ref.watch(_testExcludedProvider);
          return AsyncData(DetectedRecurringSpendSnapshot(
            groups: snapshot.groups.where((group) => !excluded.contains(group.groupKey)).toList(),
            excludedKeys: excluded,
            accountNames: snapshot.accountNames,
          ));
        }),
        recurringSpendOverrideStoreProvider.overrideWith((ref) => _TestRecurringStore(
          exclude: (key) {
            final state = ref.read(_testExcludedProvider.notifier);
            state.state = {...state.state, key};
          },
          restore: (key) {
            final state = ref.read(_testExcludedProvider.notifier);
            state.state = {...state.state}..remove(key);
          },
        )),
        if (database == null)
          dashboardSummaryProvider.overrideWith(
            (ref) => Stream.value(_fakeDashboardSummary()),
          ),
        totalActiveAccountBalanceProvider.overrideWith(
          (ref) => const AsyncData(0),
        ),
        activeRecurringExpensesProvider.overrideWith(
          (ref) => Stream.value(const <RecurringExpense>[]),
        ),
        recurringTransactionSuggestionProvider.overrideWith(
          (ref) => Future.value(null),
        ),
        calendarHomeSummaryProvider.overrideWith(
          (ref) => Stream.value(
            CalendarHomeSummary(
              date: DateTime(2026, 5, 5),
              transactionCount: 3,
              income: 100000,
              expense: 23000,
            ),
          ),
        ),
        calendarHomeMonthPreviewProvider.overrideWith(
          (ref) => Stream.value(
            CalendarHomeMonthPreview(
              monthStart: DateTime(2026, 5, 1),
              days: [
                CalendarDaySummary(
                  date: DateTime(2026, 5, 5),
                  income: 100000,
                  expense: 23000,
                  transactionCount: 3,
                  matchCount: 3,
                ),
              ],
            ),
          ),
        ),
        statisticsHomePreviewProvider.overrideWith(
          (ref) => Stream.value(
            const [
              CategoryStat(label: '식비', amount: 120000, share: 0.46),
              CategoryStat(label: '교통', amount: 60000, share: 0.23),
              CategoryStat(label: '쇼핑', amount: 40000, share: 0.15),
            ],
          ),
        ),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        routerConfig: router,
      ),
    );
  }
}

final _testExcludedProvider = StateProvider<Set<String>>((ref) => {});

class _TestRecurringStore implements RecurringSpendOverrideStore {
  _TestRecurringStore({required this.exclude, required this.restore});

  final void Function(String) exclude;
  final void Function(String) restore;

  @override
  Future<void> markGroupNotRecurring(String groupKey) async => exclude(groupKey);

  @override
  Future<void> unmarkGroupNotRecurring(String groupKey) async => restore(groupKey);

  @override
  Stream<Set<String>> watchNotRecurringGroupKeys() => Stream.value(const {});
}

GoRouter _buildRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/calendar',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Calendar Route')),
        ),
      ),
      GoRoute(
        path: '/statistics',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Statistics Route')),
        ),
      ),
      GoRoute(
        path: '/notification-history',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Notification History Route')),
        ),
      ),
      GoRoute(
        path: '/timeline',
        builder: (context, state) => const SizedBox.shrink(),
      ),
      GoRoute(
        path: '/quick-entry',
        builder: (context, state) => const SizedBox.shrink(),
      ),
    ],
  );
}

DashboardSummary _fakeDashboardSummary() {
  return const DashboardSummary(
    monthIncome: 3200000,
    monthExpense: 260000,
    todayExpense: 23000,
    todayTransactionCount: 3,
    remainingBudget: 740000,
    totalBudget: 1000000,
    netCashflow: 2940000,
    recentTransactions: <Transaction>[],
    narrative: DashboardNarrativeSnapshot(
      topExpenseCategoryLabel: '식비',
      topExpenseCategoryShare: 0.42,
      expenseTransactionCount: 6,
      averageExpenseAmount: 43000,
      recentExpenseMomentum: RecentExpenseMomentum.steady,
      budgetPressureLevel: BudgetPressureLevel.none,
      loggingConsistencyLevel: LoggingConsistencyLevel.active,
      dominantPattern: DashboardDominantPattern.categoryFocused,
      evidenceParts: <String>[
        '42%가 식비에 모였어요.',
        '오늘 기록도 이어졌어요.',
      ],
      monthExpense: 260000,
      totalBudget: 1000000,
      todayTransactionCount: 3,
    ),
  );
}
