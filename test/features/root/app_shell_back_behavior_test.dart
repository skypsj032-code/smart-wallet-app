import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wallet_app/features/root/presentation/app_shell.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('back once from non-home returns to home',
      (WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/calendar',
      routes: [
        ShellRoute(
          builder: (context, state, child) => AppShell(child: child),
          routes: [
            GoRoute(
              path: '/',
              pageBuilder: (_, __) => const NoTransitionPage(
                key: ValueKey('home-page'),
                child: Scaffold(body: Text('home')),
              ),
            ),
            GoRoute(
              path: '/calendar',
              pageBuilder: (_, __) => const NoTransitionPage(
                key: ValueKey('calendar-page'),
                child: Scaffold(body: Text('calendar')),
              ),
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

    expect(find.text('calendar'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('home'), findsOneWidget);
    expect(find.text('calendar'), findsNothing);
  });

  testWidgets('back once from home shows snackbar and does not exit',
      (WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        ShellRoute(
          builder: (context, state, child) => AppShell(child: child),
          routes: [
            GoRoute(
              path: '/',
              pageBuilder: (_, __) => const NoTransitionPage(
                key: ValueKey('home-page'),
                child: Scaffold(body: Text('home')),
              ),
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

    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(find.text('뒤로가기를 한 번 더 누르면 앱이 종료됩니다.'), findsOneWidget);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('back twice from home exits through platform pop',
      (WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        ShellRoute(
          builder: (context, state, child) => AppShell(child: child),
          routes: [
            GoRoute(
              path: '/',
              pageBuilder: (_, __) => const NoTransitionPage(
                key: ValueKey('home-page'),
                child: Scaffold(body: Text('home')),
              ),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        calls.add(call);
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(
      calls.where((call) => call.method == 'SystemNavigator.pop').length,
      1,
    );
  });
}
