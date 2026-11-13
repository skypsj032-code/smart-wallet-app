import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_wallet_app/app/router/app_router.dart';
import 'package:smart_wallet_app/app/theme/app_theme.dart';
import 'package:smart_wallet_app/core/database/app_database.dart';
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
    ]);
    final subscription = container.listen(appSettingsProvider, (_, __) {});
    settings.add(_lockedSettings());
    await container.read(appSettingsProvider.future);
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
    expect(container.read(sessionUnlockedProvider), isFalse);

    await tester.pumpWidget(const SizedBox.shrink());
    subscription.close();
    container.dispose();
    await settings.close();
  });

  testWidgets('PIN input while settings are loading cannot unlock',
      (tester) async {
    final settings = StreamController<AppSetting>();
    final container = ProviderContainer(overrides: [
      appSettingsProvider.overrideWith((ref) => settings.stream),
    ]);
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

    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
    await settings.close();
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
