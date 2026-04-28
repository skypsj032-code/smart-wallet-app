import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smart_wallet_app/app/bootstrap/app_bootstrap.dart';

void main() {
  testWidgets('App bootstrap builds a MaterialApp shell', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: AppBootstrap(),
      ),
    );

    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
