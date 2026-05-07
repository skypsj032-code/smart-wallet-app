import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet_app/app/theme/app_theme.dart';
import 'package:smart_wallet_app/features/statistics/application/statistics_provider.dart';
import 'package:smart_wallet_app/features/statistics/presentation/statistics_screen.dart';

void main() {
  testWidgets('shows interpretation-first statistics layout',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          statisticsProvider.overrideWith((ref) => Stream.value(_fixture)),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          home: const StatisticsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const Key('statistics-controls-panel')), findsOneWidget);
    expect(find.text('이번 기간 흐름 해석'), findsWidgets);
    expect(find.text('상위 흐름 카테고리'), findsOneWidget);
    expect(find.text('핵심 숫자'), findsOneWidget);
    expect(find.text('차트로 다시 보기'), findsOneWidget);
    expect(find.text('바로 이어보기'), findsNothing);

    expect(find.text('급여'), findsWidgets);
    expect(find.text('식비'), findsWidgets);
  });

  testWidgets('switches the whole statistics screen by filter',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          statisticsProvider.overrideWith((ref) => Stream.value(_fixture)),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          home: const StatisticsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('statistics-type-filter')),
        matching: find.text('수입'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('이번 기간 수입 해석'), findsWidgets);
    expect(find.text('상위 수입 카테고리'), findsOneWidget);
    expect(find.text('수입 건수'), findsWidgets);
    expect(find.text('급여'), findsWidgets);

    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('statistics-type-filter')),
        matching: find.text('지출'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('이번 기간 소비 해석'), findsWidgets);
    expect(find.text('상위 지출 카테고리'), findsOneWidget);
    expect(find.text('지출 건수'), findsWidgets);
    expect(find.text('식비'), findsWidgets);
    expect(find.text('교통'), findsWidgets);
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
