import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wallet_app/app/theme/app_theme.dart';
import 'package:smart_wallet_app/core/database/app_database.dart';
import 'package:smart_wallet_app/features/root/presentation/app_shell.dart';
import 'package:smart_wallet_app/features/settings/application/settings_provider.dart';
import 'package:smart_wallet_app/features/settings/presentation/settings_screen.dart';

void main() {
  testWidgets('bottom settings tab opens the real settings screen',
      (tester) async {
    tester.view.physicalSize = const Size(340, 737);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [
        appSettingsProvider.overrideWith(
          (ref) => Stream.value(_testSettings()),
        ),
      ],
    );
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: '/',
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
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(SettingsScreen), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const Key('theme-mode-segmented-control')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('theme-mode-segmented-control')), findsOneWidget);
  });
}

AppSetting _testSettings() {
  final now = DateTime(2026, 1, 1);

  return AppSetting(
    id: 1,
    currencyCode: 'KRW',
    weekStart: 'monday',
    themeMode: 'system',
    defaultCategorySeedVersion: 0,
    appLockEnabled: false,
    biometricEnabled: false,
    exportIncludeDeleted: false,
    pinCode: null,
    createdAt: now,
    lastModifiedAt: now,
  );
}
