import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet_app/features/settings/presentation/theme_mode_tile.dart';

void main() {
  testWidgets('theme tile shows system light and dark as one grouped control',
      (tester) async {
    var changedTo = '';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ThemeModeTile(
            currentMode: 'system',
            onChanged: (value) => changedTo = value,
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('theme-mode-segmented-control')), findsOneWidget);
    expect(find.text('시스템'), findsOneWidget);
    expect(find.text('라이트'), findsOneWidget);
    expect(find.text('다크'), findsOneWidget);

    await tester.tap(find.text('다크'));
    await tester.pumpAndSettle();

    expect(changedTo, 'dark');
  });
}
