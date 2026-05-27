import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet_app/app/theme/app_theme.dart';
import 'package:smart_wallet_app/features/statistics/application/statistics_provider.dart';
import 'package:smart_wallet_app/features/statistics/presentation/statistics_screen.dart';

void main() {
  test('statistics controls semantics label reflects range, month, and filter',
      () {
    final label = statisticsControlsSemanticLabel(
      range: StatisticsRange.month,
      filter: StatisticsTypeFilter.all,
      currentMonth: DateTime(2026, 5, 1),
    );

    expect(
      label,
      'Statistics controls. Range: this month. Reference month: 2026.05. Filter: all transactions.',
    );
  });

  test('statistics metric semantics label includes title and value', () {
    final label = statisticsMetricSemanticLabel(
      title: '총수입',
      value: '300,000원',
    );

    expect(label, 'Statistics metric. 총수입: 300,000원.');
  });

  testWidgets('statistics screen exposes controls and metric semantics',
      (tester) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          statisticsProvider.overrideWith((ref) => Stream.value(_fixture)),
          statisticsMonthProvider.overrideWith(
            (ref) => DateTime(2026, 5, 1),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          home: const StatisticsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.bySemanticsLabel(
        'Statistics controls. Range: this month. Reference month: 2026.05. Filter: all transactions.',
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Statistics metric. 총수입: 300,000원.'),
      findsOneWidget,
    );

    semantics.dispose();
  });
}

const _fixture = StatisticsSnapshot(
  totalExpense: 100000,
  totalIncome: 300000,
  balance: 200000,
  transactionCount: 8,
  incomeTransactionCount: 3,
  expenseTransactionCount: 5,
  periodLabel: '2026.05',
  allCategories: <CategoryStat>[
    CategoryStat(label: '급여', amount: 240000, share: 0.60),
    CategoryStat(label: '식비', amount: 42000, share: 0.10),
    CategoryStat(label: '교통', amount: 18000, share: 0.05),
    CategoryStat(label: '부수입', amount: 60000, share: 0.15),
  ],
  incomeCategories: <CategoryStat>[
    CategoryStat(label: '급여', amount: 240000, share: 0.80),
    CategoryStat(label: '부수입', amount: 60000, share: 0.20),
  ],
  expenseCategories: <CategoryStat>[
    CategoryStat(label: '식비', amount: 42000, share: 0.42),
    CategoryStat(label: '교통', amount: 18000, share: 0.18),
    CategoryStat(label: '쇼핑', amount: 16000, share: 0.16),
    CategoryStat(label: '취미', amount: 14000, share: 0.14),
    CategoryStat(label: '문화', amount: 10000, share: 0.10),
  ],
);
