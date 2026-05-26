import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_wallet_app/app/theme/app_theme.dart';
import 'package:smart_wallet_app/core/database/app_database.dart';
import 'package:smart_wallet_app/features/budgets/application/budget_provider.dart';
import 'package:smart_wallet_app/features/dashboard/application/dashboard_summary_provider.dart';
import 'package:smart_wallet_app/features/dashboard/application/recurring_spend_detector.dart';
import 'package:smart_wallet_app/features/dashboard/application/recurring_spend_override_store.dart';
import 'package:smart_wallet_app/features/dashboard/application/wealth_hero_motion.dart';
import 'package:smart_wallet_app/features/dashboard/presentation/dashboard_screen.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  late _FakeRecurringSpendOverrideStore overrideStore;

  setUp(() {
    overrideStore = _FakeRecurringSpendOverrideStore();
  });

  testWidgets(
      'dashboard shows recurring spend insight as the first insight card', (
    tester,
  ) async {
    final summary = _summaryWithRecurringGroups();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardSummaryProvider.overrideWith((ref) => Stream.value(summary)),
          totalActiveAccountBalanceProvider.overrideWith(
            (ref) => const AsyncData(4800000),
          ),
          recurringSpendOverrideStoreProvider.overrideWithValue(overrideStore),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const DashboardScreen(),
        ),
      ),
    );

    await tester.pump();

    expect(
        find.byKey(const Key('recurring-spend-insight-card')), findsOneWidget);
    expect(find.textContaining('127,000'), findsWidgets);
    expect(find.textContaining('30%'), findsOneWidget);
    expect(find.text('삼성화재'), findsOneWidget);
    expect(find.text('NETFLIX'), findsOneWidget);
    expect(find.text('새벽배송'), findsOneWidget);
  });

  testWidgets('dashboard shows monthly spend pace reward card', (tester) async {
    tester.view.physicalSize = const Size(1200, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final summary = _summaryWithRecurringGroups();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardSummaryProvider.overrideWith((ref) => Stream.value(summary)),
          totalActiveAccountBalanceProvider.overrideWith(
            (ref) => const AsyncData(4800000),
          ),
          recurringSpendOverrideStoreProvider.overrideWithValue(overrideStore),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const DashboardScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('monthly-spend-pace-card')));

    expect(find.byKey(const Key('monthly-spend-pace-card')), findsOneWidget);
    expect(find.text('이번 달 소비 페이스'), findsOneWidget);
    expect(find.text('지금 속도면 이번 달도 무리 없이 가고 있어요'), findsOneWidget);
    expect(find.textContaining('예산 대비 92% 예상'), findsOneWidget);
    expect(find.textContaining('460,455'), findsOneWidget);
  });

  testWidgets('dashboard shows upcoming recurring card with nearest items first',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final summary = _summaryWithRecurringGroups();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardSummaryProvider.overrideWith((ref) => Stream.value(summary)),
          totalActiveAccountBalanceProvider.overrideWith(
            (ref) => const AsyncData(4800000),
          ),
          recurringSpendOverrideStoreProvider.overrideWithValue(overrideStore),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const DashboardScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('upcoming-recurring-card')));

    expect(find.byKey(const Key('upcoming-recurring-card')), findsOneWidget);
    expect(find.text('곧 나갈 돈'), findsOneWidget);
    expect(find.byKey(const Key('upcoming-recurring-item-insurance')), findsOneWidget);
    expect(find.byKey(const Key('upcoming-recurring-item-netflix')), findsOneWidget);
    expect(find.byKey(const Key('upcoming-recurring-item-dawn-delivery')), findsNothing);

    final insuranceTopLeft =
        tester.getTopLeft(find.byKey(const Key('upcoming-recurring-item-insurance')));
    final netflixTopLeft =
        tester.getTopLeft(find.byKey(const Key('upcoming-recurring-item-netflix')));
    expect(insuranceTopLeft.dy, lessThan(netflixTopLeft.dy));
  });

  testWidgets('dashboard shows category pressure card from budget summary',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final summary = _summaryWithRecurringGroups();
    final budgetSummary = const BudgetSummary(
      monthKey: '2026-05',
      totalBudget: 500000,
      totalSpent: 430000,
      remaining: 70000,
      items: [
        BudgetSummaryItem(
          categoryId: null,
          label: '전체 예산',
          limitAmount: 500000,
          spentAmount: 430000,
        ),
        BudgetSummaryItem(
          categoryId: 'food',
          label: '식비',
          limitAmount: 200000,
          spentAmount: 120000,
        ),
        BudgetSummaryItem(
          categoryId: 'transport',
          label: '교통',
          limitAmount: 50000,
          spentAmount: 45000,
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardSummaryProvider.overrideWith((ref) => Stream.value(summary)),
          budgetSummaryProvider.overrideWith((ref) => Stream.value(budgetSummary)),
          totalActiveAccountBalanceProvider.overrideWith(
            (ref) => const AsyncData(4800000),
          ),
          recurringSpendOverrideStoreProvider.overrideWithValue(overrideStore),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const DashboardScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('category-pressure-card')));

    expect(find.byKey(const Key('category-pressure-card')), findsOneWidget);
    expect(find.text('카테고리 압박'), findsOneWidget);
    expect(find.textContaining('교통'), findsWidgets);
    expect(find.textContaining('예산 대비 90%'), findsOneWidget);
  });

  testWidgets('dashboard shows compact budget status card', (tester) async {
    tester.view.physicalSize = const Size(1200, 2800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final summary = _summaryWithRecurringGroups();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardSummaryProvider.overrideWith((ref) => Stream.value(summary)),
          totalActiveAccountBalanceProvider.overrideWith(
            (ref) => const AsyncData(4800000),
          ),
          recurringSpendOverrideStoreProvider.overrideWithValue(overrideStore),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const DashboardScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('budget-status-card')));

    expect(find.byKey(const Key('today-loop-card')), findsOneWidget);
    expect(find.byKey(const Key('budget-status-card')), findsOneWidget);
    expect(find.textContaining('70,000'), findsWidgets);
    expect(find.textContaining('86%'), findsWidgets);
  });

  testWidgets('dashboard keeps today loop focused on quick entry', (tester) async {
    tester.view.physicalSize = const Size(1200, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final summary = _summaryWithRecurringGroups();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardSummaryProvider.overrideWith((ref) => Stream.value(summary)),
          totalActiveAccountBalanceProvider.overrideWith(
            (ref) => const AsyncData(4800000),
          ),
          recurringSpendOverrideStoreProvider.overrideWithValue(overrideStore),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const DashboardScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('today-loop-card')), findsOneWidget);
    expect(find.byKey(const Key('today-loop-quick-entry-button')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('today-loop-card')),
        matching: find.byType(OutlinedButton),
      ),
      findsNothing,
    );
  });

  testWidgets('dashboard shows only three recent transactions on home',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime(2026, 5, 22, 9);
    final summary = DashboardSummary(
      monthIncome: 3200000,
      monthExpense: 430000,
      todayExpense: 17000,
      todayTransactionCount: 2,
      remainingBudget: 70000,
      totalBudget: 500000,
      netCashflow: 2770000,
      recentTransactions: [
        _tx('tx-1', amount: 12000, occurredAt: now, merchantName: 'A'),
        _tx('tx-2', amount: 15000, occurredAt: now, merchantName: 'B'),
        _tx('tx-3', amount: 18000, occurredAt: now, merchantName: 'C'),
        _tx('tx-4', amount: 21000, occurredAt: now, merchantName: 'D'),
      ],
      repeatSuggestions: const [],
      recurringSpendInsight: const RecurringSpendInsight(
        groups: [],
        totalCurrentMonthAmount: 0,
        totalPreviousMonthAmount: 0,
      ),
      spendPace: const MonthlySpendPace(
        status: MonthlySpendPaceStatus.steady,
        elapsedDays: 22,
        daysInMonth: 31,
        projectedMonthExpense: 460455,
        projectedBudgetUsageRate: 0.921,
      ),
      excludedRecurringSpendGroups: const [],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardSummaryProvider.overrideWith((ref) => Stream.value(summary)),
          budgetSummaryProvider.overrideWith(
            (ref) => Stream.value(
              const BudgetSummary(
                monthKey: '2026-05',
                totalBudget: 0,
                totalSpent: 0,
                remaining: 0,
                items: [],
              ),
            ),
          ),
          totalActiveAccountBalanceProvider.overrideWith(
            (ref) => const AsyncData(4800000),
          ),
          recurringSpendOverrideStoreProvider.overrideWithValue(overrideStore),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const DashboardScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('recent-transactions-card')));

    expect(find.byKey(const Key('recent-transactions-card')), findsOneWidget);
    expect(find.byKey(const Key('recent-transaction-tile-tx-1')), findsOneWidget);
    expect(find.byKey(const Key('recent-transaction-tile-tx-2')), findsOneWidget);
    expect(find.byKey(const Key('recent-transaction-tile-tx-3')), findsOneWidget);
    expect(find.byKey(const Key('recent-transaction-tile-tx-4')), findsNothing);
    expect(find.byKey(const Key('recent-transactions-open-timeline-button')),
        findsOneWidget);
  });

  testWidgets('dashboard hides upcoming recurring card when no scheduled groups exist',
      (tester) async {
    final summary = DashboardSummary(
      monthIncome: 3200000,
      monthExpense: 240000,
      todayExpense: 17000,
      todayTransactionCount: 2,
      remainingBudget: 260000,
      totalBudget: 500000,
      netCashflow: 2960000,
      recentTransactions: const [],
      repeatSuggestions: const [],
      recurringSpendInsight: RecurringSpendInsight(
        groups: [
          RecurringSpendGroup(
            groupKey: 'dawn-delivery',
            displayName: '?덈꼍諛곗넚',
            kind: RecurringSpendKind.lifestyle,
            score: 84,
            confidence: RecurringSpendConfidence.medium,
            evidenceCodes: const [
              RecurringSpendEvidenceCode.recentRepeatCount,
              RecurringSpendEvidenceCode.sameCategoryPattern,
            ],
            isVisibleOnHome: true,
            currentMonthAmount: 24000,
            previousMonthAmount: 0,
            transactions: [
              _tx(
                'delivery-may-1',
                amount: 8000,
                occurredAt: DateTime(2026, 5, 8, 7),
                merchantName: '?덈꼍諛곗넚',
                categoryId: 'groceries',
                accountId: 'card-1',
              ),
              _tx(
                'delivery-may-2',
                amount: 8000,
                occurredAt: DateTime(2026, 5, 15, 7),
                merchantName: '?덈꼍諛곗넚',
                categoryId: 'groceries',
                accountId: 'card-1',
              ),
              _tx(
                'delivery-may-3',
                amount: 8000,
                occurredAt: DateTime(2026, 5, 21, 7),
                merchantName: '?덈꼍諛곗넚',
                categoryId: 'groceries',
                accountId: 'card-1',
              ),
            ],
          ),
        ],
        totalCurrentMonthAmount: 24000,
        totalPreviousMonthAmount: 0,
      ),
      spendPace: const MonthlySpendPace(
        status: MonthlySpendPaceStatus.steady,
        elapsedDays: 22,
        daysInMonth: 31,
        projectedMonthExpense: 338182,
        projectedBudgetUsageRate: 0.676,
      ),
      excludedRecurringSpendGroups: const [],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardSummaryProvider.overrideWith((ref) => Stream.value(summary)),
          totalActiveAccountBalanceProvider.overrideWith(
            (ref) => const AsyncData(4800000),
          ),
          recurringSpendOverrideStoreProvider.overrideWithValue(overrideStore),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const DashboardScreen(),
        ),
      ),
    );

    await tester.pump();

    expect(find.byKey(const Key('upcoming-recurring-card')), findsNothing);
  });

  testWidgets(
      'dashboard shows excluded recurring count hint when excluded groups exist',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final summary = _summaryWithRecurringGroups(
      excludedGroups: [
        RecurringSpendGroup(
          groupKey: 'insurance-hidden',
          displayName: 'KB Insurance',
          kind: RecurringSpendKind.fixed,
          score: 92,
          confidence: RecurringSpendConfidence.high,
          evidenceCodes: const [
            RecurringSpendEvidenceCode.monthlyCadence,
            RecurringSpendEvidenceCode.stableAmount,
          ],
          isVisibleOnHome: true,
          currentMonthAmount: 86000,
          previousMonthAmount: 86000,
          transactions: [
            _tx(
              'insurance-hidden-apr',
              amount: 86000,
              occurredAt: DateTime(2026, 4, 5, 10),
              merchantName: 'KB Insurance',
              categoryId: 'insurance',
              accountId: 'card-1',
            ),
            _tx(
              'insurance-hidden-may',
              amount: 86000,
              occurredAt: DateTime(2026, 5, 5, 10),
              merchantName: 'KB Insurance',
              categoryId: 'insurance',
              accountId: 'card-1',
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardSummaryProvider.overrideWith((ref) => Stream.value(summary)),
          totalActiveAccountBalanceProvider.overrideWith(
            (ref) => const AsyncData(4800000),
          ),
          recurringSpendOverrideStoreProvider.overrideWithValue(overrideStore),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const DashboardScreen(),
        ),
      ),
    );

    await tester.pump();

    expect(
      find.byKey(const Key('recurring-spend-insight-card')),
      findsOneWidget,
    );
    expect(find.text('제외한 항목 1개'), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const Key('recurring-hidden-count-button')),
    );
    await tester.tap(find.byKey(const Key('recurring-hidden-count-button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('recurring-excluded-bottom-sheet')),
      findsOneWidget,
    );
  });

  testWidgets(
      'dashboard opens recurring spend bottom sheet with new and upcoming sections',
      (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final summary = _summaryWithRecurringGroups();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardSummaryProvider.overrideWith((ref) => Stream.value(summary)),
          totalActiveAccountBalanceProvider.overrideWith(
            (ref) => const AsyncData(4800000),
          ),
          recurringSpendOverrideStoreProvider.overrideWithValue(overrideStore),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const DashboardScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.tap(find.byKey(const Key('recurring-spend-insight-card')));
    await tester.pumpAndSettle();

    expect(
        find.byKey(const Key('recurring-spend-bottom-sheet')), findsOneWidget);
    expect(find.text('새로 보이는 반복지출'), findsOneWidget);
    expect(find.text('다가오는 반복지출'), findsOneWidget);
    expect(find.text('이번 달 새로 보였어요'), findsOneWidget);
    expect(find.text('삼성화재'), findsWidgets);
    expect(find.text('NETFLIX'), findsWidgets);
    expect(find.text('새벽배송'), findsWidgets);
  });

  testWidgets(
      'dashboard opens recurring spend detail sheet with reasons and recent transactions',
      (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final summary = _summaryWithRecurringGroups();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardSummaryProvider.overrideWith((ref) => Stream.value(summary)),
          totalActiveAccountBalanceProvider.overrideWith(
            (ref) => const AsyncData(4800000),
          ),
          recurringSpendOverrideStoreProvider.overrideWithValue(overrideStore),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const DashboardScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.tap(find.byKey(const Key('recurring-spend-insight-card')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('recurring-item-insurance')));
    await tester.pumpAndSettle();

    expect(
        find.byKey(const Key('recurring-spend-detail-sheet')), findsOneWidget);
    expect(find.textContaining('높은 신뢰'), findsOneWidget);
    expect(find.text('반복으로 본 이유'), findsOneWidget);
    expect(find.text('최근 거래 내역'), findsOneWidget);
    expect(find.textContaining('비슷한 금액'), findsOneWidget);
    expect(find.textContaining('월간 간격'), findsOneWidget);
    expect(find.textContaining('86,000'), findsWidgets);
    expect(find.textContaining('5/5'), findsWidgets);
  });

  testWidgets(
      'dashboard hides recurring spend insight when there are no visible groups',
      (
    tester,
  ) async {
    final summary = DashboardSummary(
      monthIncome: 1000000,
      monthExpense: 120000,
      todayExpense: 0,
      todayTransactionCount: 0,
      remainingBudget: 80000,
      totalBudget: 200000,
      netCashflow: 880000,
      recentTransactions: const [],
      repeatSuggestions: const [],
      recurringSpendInsight: const RecurringSpendInsight(
        groups: [],
        totalCurrentMonthAmount: 0,
        totalPreviousMonthAmount: 0,
      ),
      spendPace: const MonthlySpendPace(
        status: MonthlySpendPaceStatus.noBudget,
        elapsedDays: 22,
        daysInMonth: 31,
        projectedMonthExpense: 169091,
        projectedBudgetUsageRate: null,
      ),
      excludedRecurringSpendGroups: const [],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardSummaryProvider.overrideWith((ref) => Stream.value(summary)),
          totalActiveAccountBalanceProvider.overrideWith(
            (ref) => const AsyncData(1800000),
          ),
          recurringSpendOverrideStoreProvider.overrideWithValue(overrideStore),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const DashboardScreen(),
        ),
      ),
    );

    await tester.pump();

    expect(find.byKey(const Key('recurring-spend-insight-card')), findsNothing);
  });

  testWidgets(
      'dashboard lets user mark a recurring item as not recurring from detail sheet',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final summary = _summaryWithRecurringGroups();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardSummaryProvider.overrideWith((ref) => Stream.value(summary)),
          totalActiveAccountBalanceProvider.overrideWith(
            (ref) => const AsyncData(4800000),
          ),
          recurringSpendOverrideStoreProvider.overrideWithValue(overrideStore),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const DashboardScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.tap(find.byKey(const Key('recurring-spend-insight-card')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('recurring-item-insurance')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('recurring-not-recurring-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('recurring-not-recurring-dialog')),
        findsOneWidget);

    await tester.tap(
      find.byKey(const Key('recurring-not-recurring-confirm-button')),
    );
    await tester.pumpAndSettle();

    expect(overrideStore.markedGroupKeys, ['insurance']);
    expect(find.text('반복지출에서 제외했어요.'), findsOneWidget);

    final undoExcludeAction =
        tester.widget<SnackBarAction>(find.byType(SnackBarAction));
    undoExcludeAction.onPressed();
    await tester.pumpAndSettle();

    expect(overrideStore.restoredGroupKeys, ['insurance']);
  });

  testWidgets(
      'dashboard opens excluded recurring manager and lets user restore an item',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final summary = _summaryWithRecurringGroups(
      excludedGroups: [
        RecurringSpendGroup(
          groupKey: 'insurance',
          displayName: '?쇱꽦?붿옱',
          kind: RecurringSpendKind.fixed,
          score: 92,
          confidence: RecurringSpendConfidence.high,
          evidenceCodes: const [
            RecurringSpendEvidenceCode.monthlyCadence,
            RecurringSpendEvidenceCode.stableAmount,
          ],
          isVisibleOnHome: true,
          currentMonthAmount: 86000,
          previousMonthAmount: 86000,
          transactions: [
            _tx(
              'insurance-apr',
              amount: 86000,
              occurredAt: DateTime(2026, 4, 5, 10),
              merchantName: '?쇱꽦?붿옱',
              categoryId: 'insurance',
              accountId: 'card-1',
            ),
            _tx(
              'insurance-may',
              amount: 86000,
              occurredAt: DateTime(2026, 5, 5, 10),
              merchantName: '?쇱꽦?붿옱',
              categoryId: 'insurance',
              accountId: 'card-1',
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardSummaryProvider.overrideWith((ref) => Stream.value(summary)),
          totalActiveAccountBalanceProvider.overrideWith(
            (ref) => const AsyncData(4800000),
          ),
          recurringSpendOverrideStoreProvider.overrideWithValue(overrideStore),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const DashboardScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.tap(find.byKey(const Key('recurring-spend-insight-card')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('recurring-excluded-manage-button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('recurring-excluded-bottom-sheet')),
      findsOneWidget,
    );
    expect(find.text('?쇱꽦?붿옱'), findsWidgets);

    await tester
        .tap(find.byKey(const Key('recurring-restore-button-insurance')));
    await tester.pumpAndSettle();

    expect(overrideStore.restoredGroupKeys, ['insurance']);
    expect(find.text('다시 반복지출에 포함했어요.'), findsOneWidget);
    expect(
      find.byKey(const Key('recurring-excluded-bottom-sheet')),
      findsNothing,
    );

    final undoRestoreAction =
        tester.widget<SnackBarAction>(find.byType(SnackBarAction));
    undoRestoreAction.onPressed();
    await tester.pumpAndSettle();

    expect(overrideStore.markedGroupKeys, ['insurance']);
  });

  testWidgets(
      'dashboard shows recurring recovery entry when only excluded groups remain',
      (tester) async {
    final excludedGroup = RecurringSpendGroup(
      groupKey: 'insurance',
      displayName: '?쇱꽦?붿옱',
      kind: RecurringSpendKind.fixed,
      score: 92,
      confidence: RecurringSpendConfidence.high,
      evidenceCodes: const [
        RecurringSpendEvidenceCode.monthlyCadence,
        RecurringSpendEvidenceCode.stableAmount,
      ],
      isVisibleOnHome: true,
      currentMonthAmount: 86000,
      previousMonthAmount: 86000,
      transactions: [
        _tx(
          'insurance-apr',
          amount: 86000,
          occurredAt: DateTime(2026, 4, 5, 10),
          merchantName: '?쇱꽦?붿옱',
          categoryId: 'insurance',
          accountId: 'card-1',
        ),
        _tx(
          'insurance-may',
          amount: 86000,
          occurredAt: DateTime(2026, 5, 5, 10),
          merchantName: '?쇱꽦?붿옱',
          categoryId: 'insurance',
          accountId: 'card-1',
        ),
      ],
    );

    final summary = DashboardSummary(
      monthIncome: 3200000,
      monthExpense: 430000,
      todayExpense: 17000,
      todayTransactionCount: 2,
      remainingBudget: 70000,
      totalBudget: 500000,
      netCashflow: 2770000,
      recentTransactions: const [],
      repeatSuggestions: const [],
      recurringSpendInsight: const RecurringSpendInsight(
        groups: [],
        totalCurrentMonthAmount: 0,
        totalPreviousMonthAmount: 0,
      ),
      spendPace: const MonthlySpendPace(
        status: MonthlySpendPaceStatus.steady,
        elapsedDays: 22,
        daysInMonth: 31,
        projectedMonthExpense: 606364,
        projectedBudgetUsageRate: 1.213,
      ),
      excludedRecurringSpendGroups: [excludedGroup],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardSummaryProvider.overrideWith((ref) => Stream.value(summary)),
          totalActiveAccountBalanceProvider.overrideWith(
            (ref) => const AsyncData(4800000),
          ),
          recurringSpendOverrideStoreProvider.overrideWithValue(overrideStore),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const DashboardScreen(),
        ),
      ),
    );

    await tester.pump();

    expect(find.byKey(const Key('recurring-spend-insight-card')), findsNothing);
    expect(
        find.byKey(const Key('recurring-recovery-entry-card')), findsOneWidget);

    await tester.tap(find.byKey(const Key('recurring-recovery-entry-card')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('recurring-excluded-bottom-sheet')),
      findsOneWidget,
    );
  });
}

class _FakeRecurringSpendOverrideStore implements RecurringSpendOverrideStore {
  final List<String> markedGroupKeys = [];
  final List<String> restoredGroupKeys = [];

  @override
  Future<void> markGroupNotRecurring(String groupKey) async {
    markedGroupKeys.add(groupKey);
  }

  @override
  Future<void> unmarkGroupNotRecurring(String groupKey) async {
    restoredGroupKeys.add(groupKey);
  }

  @override
  Stream<Set<String>> watchNotRecurringGroupKeys() {
    return Stream.value(const <String>{});
  }
}

DashboardSummary _summaryWithRecurringGroups({
  List<RecurringSpendGroup> excludedGroups = const [],
}) {
  return DashboardSummary(
    monthIncome: 3200000,
    monthExpense: 430000,
    todayExpense: 17000,
    todayTransactionCount: 2,
    remainingBudget: 70000,
    totalBudget: 500000,
    netCashflow: 2770000,
    recentTransactions: const [],
    repeatSuggestions: const [],
    recurringSpendInsight: RecurringSpendInsight(
      groups: [
        RecurringSpendGroup(
          groupKey: 'insurance',
          displayName: '삼성화재',
          kind: RecurringSpendKind.fixed,
          score: 92,
          confidence: RecurringSpendConfidence.high,
          evidenceCodes: const [
            RecurringSpendEvidenceCode.monthlyCadence,
            RecurringSpendEvidenceCode.stableAmount,
          ],
          isVisibleOnHome: true,
          currentMonthAmount: 86000,
          previousMonthAmount: 86000,
          transactions: [
            _tx(
              'insurance-apr',
              amount: 86000,
              occurredAt: DateTime(2026, 4, 5, 10),
              merchantName: '삼성화재',
              categoryId: 'insurance',
              accountId: 'card-1',
            ),
            _tx(
              'insurance-may',
              amount: 86000,
              occurredAt: DateTime(2026, 5, 5, 10),
              merchantName: '삼성화재',
              categoryId: 'insurance',
              accountId: 'card-1',
            ),
          ],
        ),
        RecurringSpendGroup(
          groupKey: 'netflix',
          displayName: 'NETFLIX',
          kind: RecurringSpendKind.subscription,
          score: 90,
          confidence: RecurringSpendConfidence.high,
          evidenceCodes: const [
            RecurringSpendEvidenceCode.subscriptionKeyword,
            RecurringSpendEvidenceCode.stableAmount,
          ],
          isVisibleOnHome: true,
          currentMonthAmount: 17000,
          previousMonthAmount: 17000,
          transactions: [
            _tx(
              'netflix-apr',
              amount: 17000,
              occurredAt: DateTime(2026, 4, 10, 8),
              merchantName: 'NETFLIX',
              categoryId: 'subscription',
              accountId: 'card-1',
            ),
            _tx(
              'netflix-may',
              amount: 17000,
              occurredAt: DateTime(2026, 5, 10, 8),
              merchantName: 'NETFLIX',
              categoryId: 'subscription',
              accountId: 'card-1',
            ),
          ],
        ),
        RecurringSpendGroup(
          groupKey: 'dawn-delivery',
          displayName: '새벽배송',
          kind: RecurringSpendKind.lifestyle,
          score: 84,
          confidence: RecurringSpendConfidence.medium,
          evidenceCodes: const [
            RecurringSpendEvidenceCode.recentRepeatCount,
            RecurringSpendEvidenceCode.sameCategoryPattern,
          ],
          isVisibleOnHome: true,
          currentMonthAmount: 24000,
          previousMonthAmount: 0,
          transactions: [
            _tx(
              'delivery-may-1',
              amount: 8000,
              occurredAt: DateTime(2026, 5, 8, 7),
              merchantName: '새벽배송',
              categoryId: 'groceries',
              accountId: 'card-1',
            ),
            _tx(
              'delivery-may-2',
              amount: 8000,
              occurredAt: DateTime(2026, 5, 15, 7),
              merchantName: '새벽배송',
              categoryId: 'groceries',
              accountId: 'card-1',
            ),
            _tx(
              'delivery-may-3',
              amount: 8000,
              occurredAt: DateTime(2026, 5, 21, 7),
              merchantName: '새벽배송',
              categoryId: 'groceries',
              accountId: 'card-1',
            ),
          ],
        ),
      ],
      totalCurrentMonthAmount: 127000,
      totalPreviousMonthAmount: 103000,
    ),
    spendPace: const MonthlySpendPace(
      status: MonthlySpendPaceStatus.steady,
      elapsedDays: 22,
      daysInMonth: 31,
      projectedMonthExpense: 460455,
      projectedBudgetUsageRate: 0.921,
    ),
    excludedRecurringSpendGroups: excludedGroups,
  );
}

Transaction _tx(
  String localId, {
  String type = 'expense',
  required int amount,
  required DateTime occurredAt,
  String? accountId,
  String? categoryId,
  String? merchantName,
}) {
  return Transaction(
    localId: localId,
    type: type,
    amount: amount,
    occurredAt: occurredAt,
    accountId: accountId,
    fromAccountId: null,
    toAccountId: null,
    categoryId: categoryId,
    merchantName: merchantName,
    paymentMethod: 'card',
    memo: null,
    tagJson: null,
    createdAt: occurredAt,
    lastModifiedAt: occurredAt,
    deletedAt: null,
  );
}
