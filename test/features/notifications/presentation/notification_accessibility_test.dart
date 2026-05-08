import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_wallet_app/core/database/app_database.dart';
import 'package:smart_wallet_app/features/notifications/application/notification_parser.dart';
import 'package:smart_wallet_app/features/notifications/application/notification_provider.dart';
import 'package:smart_wallet_app/features/notifications/presentation/notification_history_screen.dart';
import 'package:smart_wallet_app/features/notifications/presentation/notification_transaction_banner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(const {});
  });

  testWidgets('notification banner exposes a readable summary label',
      (tester) async {
    final container = ProviderContainer();

    container.read(detectedNotificationTransactionProvider.notifier).state =
        ParsedNotificationTransaction(
      amount: 12800,
      type: 'expense',
      merchant: 'Star Coffee',
      rawTitle: 'card',
      rawText: 'text',
      detectedAt: DateTime(2026, 5, 8, 9, 30),
      cardName: 'Visa',
      suggestedCategoryKeyword: 'Cafe',
    );

    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: NotificationTransactionBanner(),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(
      find.bySemanticsLabel(
        RegExp(
          r'Detected expense notification.*12,800 won.*merchant Star Coffee.*card Visa.*quick entry',
        ),
      ),
      findsOneWidget,
    );

    semantics.dispose();
    container.dispose();
  });

  test('notification history semantic label includes summary and action', () {
    final label = notificationHistorySemanticLabel(
      NotificationHistory(
        id: 1,
        packageName: 'com.example.card',
        amount: 5400,
        type: 'expense',
        merchant: 'Lunch Box',
        suggestedCategory: 'Food',
        detectedAt: DateTime(2026, 5, 8, 12, 15),
      ),
    );

    expect(label, contains('Notification history item'));
    expect(label, contains('expense'));
    expect(label, contains('5,400 won'));
    expect(label, contains('merchant Lunch Box'));
    expect(label, contains('suggested category Food'));
    expect(label, contains('double tap to open quick entry.'));
  });
}
