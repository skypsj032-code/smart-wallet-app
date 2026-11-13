import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
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
  late AppDatabase database;
  setUp(() => database = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() async => database.close());

  testWidgets('dashboard calendar card opens the calendar route',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final router = _buildRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(
      _DashboardTestApp(
        router: router,
        database: database,
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('dashboard-open-calendar')));
    await tester.tap(find.byKey(const Key('dashboard-open-calendar')));
    await tester.pumpAndSettle();

    expect(find.text('Calendar Route'), findsOneWidget);
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
        database: database,
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const Key('dashboard-open-statistics')),
    );
    await tester.tap(find.byKey(const Key('dashboard-open-statistics')));
    await tester.pumpAndSettle();

    expect(find.text('Statistics Route'), findsOneWidget);
  });

  testWidgets('weather header and detected recurring spending coexist',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final now = DateTime.now();
    for (var monthOffset = 0; monthOffset < 3; monthOffset++) {
      final date = DateTime(now.year, now.month - monthOffset, 1);
      await database.into(database.transactions).insert(
            TransactionsCompanion.insert(
              localId: 'rent-$monthOffset',
              type: 'expense',
              amount: 700000,
              occurredAt: date,
              merchantName: const drift.Value('월세'),
              accountId: const drift.Value('bank'),
              createdAt: date,
              lastModifiedAt: date,
            ),
          );
    }
    final transactions = await database.select(database.transactions).get();
    final detected = detectRecurringSpendInsight(transactions, now: now);
    final snapshot = DetectedRecurringSpendSnapshot(
      groups: detected.groups, excludedKeys: const {},
    );
    final router = _buildRouter();
    addTearDown(router.dispose);
    try {
      await tester.pumpWidget(_DashboardTestApp(
        router: router, database: database, snapshot: snapshot,
      ));
      await tester.pumpAndSettle();

      final headers = tester.widgetList<SliverPersistentHeader>(
        find.byType(SliverPersistentHeader),
      );
      expect(headers.any((header) => header.pinned), isTrue);
      expect(find.text('거래에서 감지한 반복 지출'), findsOneWidget);
      expect(find.text('월세'), findsOneWidget);

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

class _DashboardTestApp extends StatelessWidget {
  const _DashboardTestApp({
    required this.router,
    required this.database,
    this.snapshot = const DetectedRecurringSpendSnapshot(groups: [], excludedKeys: {}),
  });

  final GoRouter router;
  final AppDatabase database;
  final DetectedRecurringSpendSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        detectedRecurringSpendProvider.overrideWith((ref) {
          final excluded = ref.watch(_testExcludedProvider);
          return AsyncData(DetectedRecurringSpendSnapshot(
            groups: snapshot.groups.where((group) => !excluded.contains(group.groupKey)).toList(),
            excludedKeys: excluded,
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
