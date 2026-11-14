import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet_app/app/router/app_router.dart';
import 'package:smart_wallet_app/core/database/app_database.dart';
import 'package:smart_wallet_app/features/settings/application/settings_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('changing settings preserves the current route', () async {
    final settings = StreamController<AppSetting>();
    final container = ProviderContainer(overrides: [
      appSettingsProvider.overrideWith((ref) => settings.stream),
    ]);
    addTearDown(container.dispose);
    addTearDown(settings.close);

    final subscription = container.listen(appSettingsProvider, (_, __) {});
    addTearDown(subscription.close);
    settings.add(_settings());
    await container.read(appSettingsProvider.future);

    final router = container.read(appRouterProvider);
    router.go('/settings');
    expect(router.routeInformationProvider.value.uri.path, '/settings');

    settings.add(_settings().copyWith(themeMode: 'dark'));
    await Future<void>.delayed(Duration.zero);
    final updated = container.read(appRouterProvider);
    expect(updated.routeInformationProvider.value.uri.path, '/settings');
    expect(identical(updated, router), isTrue);
  });

  test('unlocking does not replace the router', () async {
    final container = ProviderContainer(overrides: [
      appSettingsProvider.overrideWith((ref) => Stream.value(_settings())),
    ]);
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider);
    var refreshes = 0;
    router.routeInformationProvider.addListener(() => refreshes++);
    container.read(sessionUnlockedProvider.notifier).state = true;
    await Future<void>.delayed(Duration.zero);
    expect(identical(container.read(appRouterProvider), router), isTrue);
    expect(refreshes, greaterThan(0));
  });
}

AppSetting _settings() {
  final now = DateTime(2026);
  return AppSetting(
    id: 1,
    currencyCode: 'KRW',
    weekStart: 'monday',
    themeMode: 'system',
    defaultCategorySeedVersion: 2,
    appLockEnabled: false,
    biometricEnabled: false,
    exportIncludeDeleted: false,
    createdAt: now,
    lastModifiedAt: now,
  );
}
