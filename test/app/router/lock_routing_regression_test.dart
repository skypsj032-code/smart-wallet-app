import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_wallet_app/app/bootstrap/app_bootstrap_provider.dart';
import 'package:smart_wallet_app/app/router/app_router.dart';
import 'package:smart_wallet_app/app/smart_wallet_app.dart';
import 'package:smart_wallet_app/app/theme/app_theme.dart';
import 'package:smart_wallet_app/core/database/app_database.dart';
import 'package:smart_wallet_app/features/calendar/application/calendar_provider.dart';
import 'package:smart_wallet_app/features/settings/application/settings_provider.dart';
import 'package:smart_wallet_app/features/settings/presentation/lock_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(() => SharedPreferences.setMockInitialValues(const {}));

  testWidgets('settings error cannot open home from the lock screen',
      (tester) async {
    final settings = StreamController<AppSetting>();
    final container = ProviderContainer(overrides: [
      appSettingsProvider.overrideWith((ref) => settings.stream),
      calendarTodayProvider.overrideWith((ref) => DateTime(2026, 1, 1)),
    ]);
    final subscription = container.listen(appSettingsProvider, (_, __) {});
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      subscription.close();
      container.dispose();
      await settings.close();
    });
    settings.add(_lockedSettings());
    await tester.pump();
    await tester.pump();
    expect(container.read(appSettingsProvider).asData?.value.appLockEnabled, isTrue);
    final router = container.read(appRouterProvider);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(LockScreen), findsOneWidget);

    settings.addError(StateError('settings unavailable'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(LockScreen), findsOneWidget);
    expect(router.routerDelegate.currentConfiguration.uri.path, '/lock');
    expect(container.read(sessionUnlockedProvider), isFalse);

  });

  testWidgets('settings loading keeps the protected route locked',
      (tester) async {
    final settings = StreamController<AppSetting>();
    final container = ProviderContainer(overrides: [
      appSettingsProvider.overrideWith((ref) => settings.stream),
      calendarTodayProvider.overrideWith((ref) => DateTime(2026, 1, 1)),
    ]);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
      await settings.close();
    });
    final router = container.read(appRouterProvider);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(LockScreen), findsOneWidget);
    expect(router.routerDelegate.currentConfiguration.uri.path, '/lock');
    expect(container.read(sessionUnlockedProvider), isFalse);
  });

  testWidgets('PIN input while settings are loading cannot unlock',
      (tester) async {
    final settings = StreamController<AppSetting>();
    final container = ProviderContainer(overrides: [
      appSettingsProvider.overrideWith((ref) => settings.stream),
    ]);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
      await settings.close();
    });
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: AppTheme.light(), home: const LockScreen()),
    ));
    await tester.pump();

    final listener = tester.widget<KeyboardListener>(find.byType(KeyboardListener));
    for (var i = 0; i < 4; i++) {
      listener.onKeyEvent!(const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.digit1,
        logicalKey: LogicalKeyboardKey.digit1,
        character: '1',
        timeStamp: Duration.zero,
      ));
    }
    await tester.pump();
    expect(container.read(sessionUnlockedProvider), isFalse);

  });

  testWidgets('backgrounding with unknown settings locks the session',
      (tester) async {
    final settings = StreamController<AppSetting>();
    final container = ProviderContainer(overrides: [
      appBootstrapProvider.overrideWith((ref) async {}),
      appSettingsProvider.overrideWith((ref) => settings.stream),
      calendarTodayProvider.overrideWith((ref) => DateTime(2026, 1, 1)),
    ]);
    addTearDown(() async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
      await settings.close();
    });
    container.read(sessionUnlockedProvider.notifier).state = true;
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const SmartWalletApp(),
    ));
    await tester.pump();
    await tester.pump();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(container.read(sessionUnlockedProvider), isFalse);
  });

  testWidgets('unknown settings on resume lock the previous session',
      (tester) async {
    final settings = StreamController<AppSetting>();
    final container = ProviderContainer(overrides: [
      appBootstrapProvider.overrideWith((ref) async {}),
      appSettingsProvider.overrideWith((ref) => settings.stream),
      calendarTodayProvider.overrideWith((ref) => DateTime(2026, 1, 1)),
    ]);
    addTearDown(() async {
      if (tester.binding.lifecycleState == AppLifecycleState.paused) {
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      }
      if (tester.binding.lifecycleState == AppLifecycleState.hidden) {
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      }
      if (tester.binding.lifecycleState == AppLifecycleState.inactive) {
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      }
      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
      await settings.close();
    });
    container.read(sessionUnlockedProvider.notifier).state = true;
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const SmartWalletApp(),
    ));
    await tester.pump();
    settings.add(_lockedSettings().copyWith(appLockEnabled: false));
    await tester.pump();
    await tester.pump();
    expect(container.read(appSettingsProvider).asData?.value.appLockEnabled, isFalse);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    settings.addError(StateError('settings unavailable'));
    await tester.pump();
    expect(container.read(appSettingsProvider).asData, isNull);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(container.read(sessionUnlockedProvider), isFalse);
  });
}

AppSetting _lockedSettings() {
  final now = DateTime(2026);
  return AppSetting(
    id: 1,
    currencyCode: 'KRW',
    weekStart: 'monday',
    themeMode: 'system',
    defaultCategorySeedVersion: 2,
    appLockEnabled: true,
    biometricEnabled: false,
    exportIncludeDeleted: false,
    pinCode: 'stored-pin-hash',
    createdAt: now,
    lastModifiedAt: now,
  );
}
