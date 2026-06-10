import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_wallet_app/app/bootstrap/app_bootstrap_provider.dart';
import 'package:smart_wallet_app/app/router/app_router.dart';
import 'package:smart_wallet_app/app/smart_wallet_app.dart';
import 'package:smart_wallet_app/app/theme/app_theme.dart';
import 'package:smart_wallet_app/core/database/app_database.dart';
import 'package:smart_wallet_app/features/settings/application/settings_provider.dart';
import 'package:smart_wallet_app/features/settings/presentation/lock_screen.dart';
import 'package:smart_wallet_app/shared/widgets/brand_splash_screen.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets(
    'SmartWalletApp shows a loading shell while bootstrap is pending',
    (tester) async {
      final completer = Completer<void>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appBootstrapProvider.overrideWith((ref) => completer.future),
          ],
          child: const SmartWalletApp(),
        ),
      );

      await tester.pump();

      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(BrandSplashScreen), findsOneWidget);
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).title,
        '다정가계부',
      );
      expect(find.text('다정가계부'), findsOneWidget);
    },
  );

  testWidgets(
    'SmartWalletApp shows the bootstrap error message when startup fails',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appBootstrapProvider.overrideWith((ref) async {
              throw StateError('bootstrap failed for test');
            }),
          ],
          child: const SmartWalletApp(),
        ),
      );

      await tester.pump();
      await tester.pump();

      expect(find.byType(MaterialApp), findsOneWidget);
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).title,
        '다정가계부',
      );
      expect(find.text('다정가계부'), findsOneWidget);
      expect(find.textContaining('bootstrap failed for test'), findsOneWidget);
    },
  );

  testWidgets('LockScreen auto-unlocks when lock settings are not configured', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        appSettingsProvider.overrideWith(
          (ref) => Stream.value(_testSettings(appLockEnabled: false)),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: AppTheme.light(), home: const LockScreen()),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(container.read(sessionUnlockedProvider), isTrue);
  });
}

AppSetting _testSettings({required bool appLockEnabled, String? pinCode}) {
  final now = DateTime(2026, 1, 1);

  return AppSetting(
    id: 1,
    currencyCode: 'KRW',
    weekStart: 'monday',
    themeMode: 'system',
    appLockEnabled: appLockEnabled,
    biometricEnabled: false,
    exportIncludeDeleted: false,
    pinCode: pinCode,
    createdAt: now,
    lastModifiedAt: now,
  );
}
