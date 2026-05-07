import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet_app/app/theme/app_theme.dart';
import 'package:smart_wallet_app/core/database/app_database.dart';
import 'package:smart_wallet_app/features/settings/application/settings_provider.dart';
import 'package:smart_wallet_app/features/settings/presentation/settings_screen.dart';
import 'package:smart_wallet_app/features/tools/presentation/tools_screen.dart';

void main() {
  testWidgets('ToolsScreen focuses on money-related actions',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const ToolsScreen(),
        ),
      ),
    );

    await tester.pump();

    expect(find.byType(ToolsScreen), findsOneWidget);
    expect(find.byType(ListTile), findsAtLeastNWidgets(6));
  });

  testWidgets('SettingsScreen focuses on app settings and data management',
      (WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [
        appSettingsProvider.overrideWith(
          (ref) => Stream.value(_testSettings()),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const SettingsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.byKey(const Key('theme-mode-segmented-control')), findsNothing);

    await tester.scrollUntilVisible(
      find.byKey(const Key('theme-mode-segmented-control')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('theme-mode-segmented-control')), findsOneWidget);
  });

  testWidgets('SettingsScreen renders on compact mobile width',
      (WidgetTester tester) async {
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

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const SettingsScreen(),
        ),
      ),
    );

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
