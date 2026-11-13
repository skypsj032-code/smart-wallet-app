import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_wallet_app/app/router/app_router.dart';
import 'package:smart_wallet_app/app/theme/app_theme.dart';
import 'package:smart_wallet_app/core/database/app_database.dart';
import 'package:smart_wallet_app/features/settings/application/settings_provider.dart';
import 'package:smart_wallet_app/features/settings/presentation/lock_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('a missing PIN never unlocks an enabled app lock', (tester) async {
    final container = ProviderContainer(overrides: [
      appSettingsProvider.overrideWith((ref) => Stream.value(_settings())),
    ]);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
    });

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: AppTheme.light(), home: const LockScreen()),
    ));
    await tester.pump();
    await tester.pump();

    expect(container.read(appSettingsProvider).asData?.value.pinCode, isNull);
    expect(container.read(sessionUnlockedProvider), isFalse);
    expect(find.byType(LockScreen), findsOneWidget);
  });

  testWidgets('a disabled app lock continues to open the session',
      (tester) async {
    final container = ProviderContainer(overrides: [
      appSettingsProvider.overrideWith(
        (ref) => Stream.value(_settings(appLockEnabled: false)),
      ),
    ]);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
    });

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: AppTheme.light(), home: const LockScreen()),
    ));
    await tester.pump();
    await tester.pump();

    expect(container.read(sessionUnlockedProvider), isTrue);
  });
}

AppSetting _settings({bool appLockEnabled = true}) {
  final now = DateTime(2026);
  return AppSetting(
    id: 1,
    currencyCode: 'KRW',
    weekStart: 'monday',
    themeMode: 'system',
    defaultCategorySeedVersion: 2,
    appLockEnabled: appLockEnabled,
    biometricEnabled: false,
    exportIncludeDeleted: false,
    pinCode: null,
    createdAt: now,
    lastModifiedAt: now,
  );
}
