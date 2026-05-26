import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_wallet_app/app/theme/app_theme.dart';
import 'package:smart_wallet_app/core/database/app_database.dart';
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

  testWidgets(
      'dashboard shows hidden recurring count hint when excluded groups exist',
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
    expect(find.text('숨긴 항목 1개'), findsOneWidget);
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
