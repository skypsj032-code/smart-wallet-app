import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet_app/app/theme/app_theme.dart';
import 'package:smart_wallet_app/shared/widgets/app_ledger_axis_intro.dart';

void main() {
  testWidgets('renders label headline and body', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: AppLedgerAxisIntro(
            label: '달력',
            headline: '날짜 흐름을 봐요',
            body: '주간, 월간, 연간으로 바로 볼 수 있어요.',
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('ledger-axis-intro-card')), findsOneWidget);
    expect(find.text('달력'), findsOneWidget);
    expect(find.text('날짜 흐름을 봐요'), findsOneWidget);
    expect(
      find.text('주간, 월간, 연간으로 바로 볼 수 있어요.'),
      findsOneWidget,
    );
  });
}
