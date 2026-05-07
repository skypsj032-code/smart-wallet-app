import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet_app/features/root/presentation/guarded_navigation_overlays.dart';

void main() {
  testWidgets('guarded dialog opens at level 2', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: _GuardedDialogLauncher(currentDepth: 2)),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('dialog body'), findsOneWidget);
  });

  testWidgets('guarded dialog is blocked at level 3', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: _GuardedDialogLauncher(currentDepth: 3)),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pump();

    expect(find.text('dialog body'), findsNothing);
    expect(find.text('더 깊게 들어갈 수 없습니다.'), findsOneWidget);
  });
}

class _GuardedDialogLauncher extends StatelessWidget {
  const _GuardedDialogLauncher({required this.currentDepth});

  final int currentDepth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: () {
          showGuardedDialog<void>(
            context: context,
            currentDepthOverride: currentDepth,
            builder: (_) => const AlertDialog(
              content: Text('dialog body'),
            ),
          );
        },
        child: const Text('open'),
      ),
    );
  }
}
