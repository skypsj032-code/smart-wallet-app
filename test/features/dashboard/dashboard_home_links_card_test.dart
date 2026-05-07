import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet_app/features/calendar/application/calendar_provider.dart';
import 'package:smart_wallet_app/features/dashboard/presentation/dashboard_home_links_card.dart';
import 'package:smart_wallet_app/features/statistics/application/statistics_provider.dart';

void main() {
  testWidgets('DashboardHomeLinksCard keeps previews folded by default',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DashboardHomeLinksCard(
              onOpenCalendar: _noop,
              onOpenStatistics: _noop,
              calendarSummary: _calendarSummary(),
              calendarMonthPreview: _calendarPreview(),
              monthIncome: 300000,
              monthExpense: 120000,
              topExpenseCategories: _topCategories(),
              topExpenseCategoryLabel: '식비',
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.byKey(const Key('dashboard-calendar-fold')), findsOneWidget);
    expect(find.byKey(const Key('dashboard-statistics-fold')), findsOneWidget);
    expect(find.byKey(const Key('dashboard-open-calendar')), findsNothing);
    expect(find.byKey(const Key('dashboard-open-statistics')), findsNothing);
    expect(find.byKey(const Key('dashboard-calendar-preview-grid')), findsNothing);
    expect(find.byKey(const Key('dashboard-statistics-preview-list')), findsNothing);
  });

  testWidgets('DashboardHomeLinksCard shows mini calendar and mini stats when opened',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DashboardHomeLinksCard(
              onOpenCalendar: _noop,
              onOpenStatistics: _noop,
              calendarSummary: _calendarSummary(),
              calendarMonthPreview: _calendarPreview(),
              monthIncome: 300000,
              monthExpense: 120000,
              topExpenseCategories: _topCategories(),
              topExpenseCategoryLabel: '식비',
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    await tester.tap(find.byKey(const Key('dashboard-calendar-fold')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dashboard-open-calendar')), findsOneWidget);
    expect(find.byKey(const Key('dashboard-calendar-preview-grid')), findsOneWidget);
    expect(find.byKey(const Key('dashboard-calendar-day-5')), findsOneWidget);
    expect(find.byKey(const Key('dashboard-calendar-count')), findsOneWidget);
    expect(find.byKey(const Key('dashboard-calendar-income')), findsOneWidget);
    expect(find.byKey(const Key('dashboard-calendar-expense')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('dashboard-statistics-fold')));
    await tester.tap(find.byKey(const Key('dashboard-statistics-fold')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dashboard-open-statistics')), findsOneWidget);
    expect(find.byKey(const Key('dashboard-statistics-preview-list')), findsOneWidget);
    expect(find.byKey(const Key('dashboard-statistics-income')), findsOneWidget);
    expect(find.byKey(const Key('dashboard-statistics-expense')), findsOneWidget);
    expect(find.byKey(const Key('dashboard-stat-category-0')), findsOneWidget);
    expect(find.text('식비'), findsOneWidget);
  });
}

CalendarHomeSummary _calendarSummary() {
  return CalendarHomeSummary(
    date: DateTime(2026, 5, 5),
    transactionCount: 3,
    income: 100000,
    expense: 23000,
  );
}

CalendarHomeMonthPreview _calendarPreview() {
  return CalendarHomeMonthPreview(
    monthStart: DateTime(2026, 5, 1),
    days: [
      CalendarDaySummary(
        date: DateTime(2026, 5, 5),
        income: 100000,
        expense: 23000,
        transactionCount: 3,
        matchCount: 3,
      ),
      CalendarDaySummary(
        date: DateTime(2026, 5, 12),
        income: 0,
        expense: 18000,
        transactionCount: 1,
        matchCount: 1,
      ),
    ],
  );
}

List<CategoryStat> _topCategories() {
  return const [
    CategoryStat(label: '식비', amount: 72000, share: 0.6),
    CategoryStat(label: '교통', amount: 30000, share: 0.25),
    CategoryStat(label: '쇼핑', amount: 18000, share: 0.15),
  ];
}

void _noop() {}
