import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet_app/app/theme/app_theme.dart';
import 'package:smart_wallet_app/shared/widgets/app_ledger_axis_navigation.dart';

void main() {
  testWidgets('highlights current axis and only triggers other callbacks',
      (tester) async {
    var openedCalendar = 0;
    var openedStatistics = 0;
    var openedAccounts = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: AppLedgerAxisNavigation(
            currentAxis: LedgerAxis.statistics,
            onOpenCalendar: () => openedCalendar++,
            onOpenStatistics: () => openedStatistics++,
            onOpenAccounts: () => openedAccounts++,
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('ledger-axis-navigation-card')), findsOneWidget);
    expect(find.byKey(const Key('ledger-axis-calendar')), findsOneWidget);
    expect(find.byKey(const Key('ledger-axis-statistics')), findsOneWidget);
    expect(find.byKey(const Key('ledger-axis-accounts')), findsOneWidget);

    await tester.tap(find.byKey(const Key('ledger-axis-calendar')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('ledger-axis-accounts')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('ledger-axis-statistics')));
    await tester.pump();

    expect(openedCalendar, 1);
    expect(openedAccounts, 1);
    expect(openedStatistics, 0);
  });
}
