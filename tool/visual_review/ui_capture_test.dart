import 'dart:async';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_wallet_app/features/budgets/application/budget_provider.dart';
import 'package:smart_wallet_app/features/root/presentation/app_shell.dart';
import 'package:smart_wallet_app/features/settings/application/settings_provider.dart';
import 'package:smart_wallet_app/features/settings/presentation/settings_screen.dart';
import 'package:smart_wallet_app/features/tools/presentation/tools_screen.dart';
import 'package:smart_wallet_app/features/transactions/application/quick_entry_options_provider.dart';
import 'package:smart_wallet_app/features/transactions/presentation/quick_entry_screen.dart';
import 'package:smart_wallet_app/shared/widgets/app_frame.dart';

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



Future<void> main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });

  testWidgets('capture manual preview at phone dimensions', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final router = _buildRouter();
    addTearDown(router.dispose);
    const boundaryKey = Key('visual-review-screen');
    await tester.pumpWidget(RepaintBoundary(
      key: boundaryKey, child: _DashboardTestApp(router: router)));
    for (var i=0; i<12; i++) { await tester.pump(const Duration(milliseconds: 100)); }
    await expectLater(find.byKey(boundaryKey), matchesGoldenFile('goldens/home.png'));
    await tester.pumpWidget(RepaintBoundary(
      key: boundaryKey, child: _DashboardTestApp(router: router, themeMode: ThemeMode.dark)));
    for (var i=0; i<8; i++) { await tester.pump(const Duration(milliseconds: 100)); }
    await expectLater(find.byKey(boundaryKey), matchesGoldenFile('goldens/home-dark.png'));
    await tester.pumpWidget(RepaintBoundary(
      key: boundaryKey, child: _DashboardTestApp(router: router, textScale: 1.2)));
    for (var i=0; i<8; i++) { await tester.pump(const Duration(milliseconds: 100)); }
    await expectLater(find.byKey(boundaryKey), matchesGoldenFile('goldens/home-large-text.png'));
    await tester.pumpWidget(RepaintBoundary(
      key: boundaryKey, child: _DashboardTestApp(router: router)));
    for (var i=0; i<8; i++) { await tester.pump(const Duration(milliseconds: 100)); }
    await tester.drag(find.byType(CustomScrollView).first, const Offset(0, -500));
    for (var i=0; i<6; i++) { await tester.pump(const Duration(milliseconds: 100)); }
    await expectLater(find.byKey(boundaryKey), matchesGoldenFile('goldens/home-scrolled.png'));
    router.go('/quick-entry');
    for (var i=0; i<8; i++) { await tester.pump(const Duration(milliseconds: 100)); }
    await expectLater(find.byKey(boundaryKey), matchesGoldenFile('goldens/entry.png'));
    router.go('/tools');
    for (var i=0; i<8; i++) { await tester.pump(const Duration(milliseconds: 100)); }
    await expectLater(find.byKey(boundaryKey), matchesGoldenFile('goldens/tools.png'));
    router.go('/settings');
    for (var i=0; i<8; i++) { await tester.pump(const Duration(milliseconds: 100)); }
    await expectLater(find.byKey(boundaryKey), matchesGoldenFile('goldens/settings.png'));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}

class _DashboardTestApp extends StatelessWidget {
  const _DashboardTestApp({
    required this.router,
    this.snapshot = const DetectedRecurringSpendSnapshot(groups: [], excludedKeys: {}),
    this.pendingNotifications,
    this.database,
    this.currentTime,
    this.themeMode = ThemeMode.light,
    this.textScale = 1.0,
  });

  final GoRouter router;
  final DetectedRecurringSpendSnapshot snapshot;
  final Stream<int>? pendingNotifications;
  final AppDatabase? database;
  final DateTime Function()? currentTime;
  final ThemeMode themeMode;
  final double textScale;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        appSettingsProvider.overrideWith((ref) => Stream.value(_testSettings())),
        budgetSummaryProvider.overrideWith((ref) => Stream.value(const BudgetSummary(
          monthKey: '2026-11', totalBudget: 0, totalSpent: 0, remaining: 0, items: [],
        ))),
        quickEntryAccountsProvider.overrideWith((ref) => Stream.value(const [
          QuickEntryAccountOption(id: 'cash', name: '현금'),
        ])),
        quickEntryCategoriesProvider('expense').overrideWith((ref) => Stream.value(const [
          QuickEntryCategoryOption(id: 'food', name: '식비', type: 'expense'),
        ])),
        quickEntryCategoriesProvider('income').overrideWith((ref) => Stream.value(const [
          QuickEntryCategoryOption(id: 'salary', name: '급여', type: 'income'),
        ])),
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
          (ref) => const AsyncData(2940000),
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
        debugShowCheckedModeBanner: false,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
          child: AppFrame(child: child ?? const SizedBox.shrink()),
        ),
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: themeMode,
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
  return GoRouter(initialLocation: '/', routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child, showNotificationFeatures: false),
      routes: [
        GoRoute(path: '/', builder: (_, __) => const DashboardScreen(showNotificationFeatures: false)),
        GoRoute(path: '/quick-entry', builder: (_, __) => const QuickEntryScreen()),
        GoRoute(path: '/tools', builder: (_, __) => const ToolsScreen()),
        GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
        GoRoute(path: '/timeline', builder: (_, __) => const Scaffold(body: Text('내역'))),
        GoRoute(path: '/notification-history', builder: (_, __) => const Scaffold(body: Text('알림 수신 이력'))),
        GoRoute(path: '/calendar', builder: (_, __) => const Scaffold(body: Text('달력'))),
        GoRoute(path: '/statistics', builder: (_, __) => const Scaffold(body: Text('통계'))),
      ],
    ),
  ]);
}

AppSetting _testSettings() {
  final now = DateTime(2026, 11, 14);
  return AppSetting(id: 1, currencyCode: 'KRW', weekStart: 'monday', themeMode: 'system',
    defaultCategorySeedVersion: 2, appLockEnabled: false, biometricEnabled: false,
    exportIncludeDeleted: false, pinCode: null, createdAt: now, lastModifiedAt: now);
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
