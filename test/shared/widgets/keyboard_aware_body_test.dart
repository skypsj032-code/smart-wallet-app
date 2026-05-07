import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet_app/shared/widgets/keyboard_aware_body.dart';

void main() {
  testWidgets('adds bottom padding from keyboard insets', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            viewInsets: EdgeInsets.only(bottom: 280),
          ),
          child: KeyboardAwareBody(
            child: SizedBox(height: 120, child: Text('field')),
          ),
        ),
      ),
    );

    final padding = tester.widget<AnimatedPadding>(
      find.byKey(const Key('keyboard-aware-body-padding')),
    );

    expect((padding.padding as EdgeInsets).bottom, 280);
  });
}
