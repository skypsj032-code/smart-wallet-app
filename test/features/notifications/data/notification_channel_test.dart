import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet_app/features/notifications/data/notification_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('smart_wallet/notification_permission');
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      switch (call.method) {
        case 'isPermissionGranted':
          return true;
        case 'isBatteryOptimizationIgnored':
          return false;
        case 'openPermissionSettings':
        case 'openBatteryOptimizationSettings':
          return null;
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('isBatteryOptimizationIgnored forwards to the native channel', () async {
    final ignored = await NotificationChannel.isBatteryOptimizationIgnored();

    expect(ignored, isFalse);
    expect(
      calls.map((call) => call.method),
      contains('isBatteryOptimizationIgnored'),
    );
  });

  test('openBatteryOptimizationSettings forwards to the native channel', () async {
    await NotificationChannel.openBatteryOptimizationSettings();

    expect(
      calls.map((call) => call.method),
      contains('openBatteryOptimizationSettings'),
    );
  });
}
