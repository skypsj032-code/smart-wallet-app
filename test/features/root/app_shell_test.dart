import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wallet_app/features/root/presentation/app_shell.dart';

void main() {
  testWidgets('AppShell hides the global quick panel on the quick-entry route',
      (WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/quick-entry',
      routes: [
        ShellRoute(
          builder: (context, state, child) => AppShell(child: child),
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const Scaffold(
                body: Text('Home'),
              ),
            ),
            GoRoute(
              path: '/quick-entry',
              builder: (context, state) => const Scaffold(
                body: Text('Quick Entry'),
              ),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Quick Entry'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('AppShell shows home, timeline, tools, and settings tabs',
      (WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/tools',
      routes: [
        ShellRoute(
          builder: (context, state, child) => AppShell(child: child),
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const Scaffold(body: Text('Home')),
            ),
            GoRoute(
              path: '/timeline',
              builder: (context, state) =>
                  const Scaffold(body: Text('Timeline')),
            ),
            GoRoute(
              path: '/tools',
              builder: (context, state) => const Scaffold(body: Text('Tools')),
            ),
            GoRoute(
              path: '/settings',
              builder: (context, state) =>
                  const Scaffold(body: Text('Settings')),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('홈'), findsOneWidget);
    expect(find.text('내역'), findsOneWidget);
    expect(find.text('도구'), findsOneWidget);
    expect(find.text('설정'), findsOneWidget);
    expect(find.text('Tools'), findsOneWidget);
  });
}
