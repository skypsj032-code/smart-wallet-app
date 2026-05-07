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

    expect(find.text('거래 검색'), findsOneWidget);
    expect(find.text('계좌 관리'), findsOneWidget);
    expect(find.text('예산 관리'), findsOneWidget);
    expect(find.text('영수증 스캔'), findsOneWidget);
    expect(find.text('고정 지출'), findsOneWidget);
    expect(find.text('JSON 백업 만들기'), findsNothing);
    expect(find.text('화면 테마'), findsNothing);
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

    await tester.pump();

    expect(find.text('JSON 백업 만들기'), findsOneWidget);
    expect(find.text('CSV 내보내기'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('앱 안내'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('앱 안내'), findsOneWidget);
    expect(find.text('거래 검색'), findsNothing);
    expect(find.text('계좌 관리'), findsNothing);
    expect(find.text('예산 관리'), findsNothing);
    expect(find.text('영수증 스캔'), findsNothing);
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
