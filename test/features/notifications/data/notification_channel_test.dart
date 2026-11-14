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
        case 'configureCaptureEnabled':
        case 'acknowledgeNotifications':
          return null;
        case 'getPendingNotifications':
          return [
            <String, Object>{
              'eventId': 'event-1',
              'packageName': 'viva.republica.toss',
              'title': '결제 알림',
              'text': '승인 5,000원 카페',
              'timestamp': 123456,
            },
          ];
        case 'getDroppedNotificationCount':
          return 2;
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

  test('pending notifications preserve the event identity and payment fields', () async {
    final pending = await NotificationChannel.getPendingNotifications();

    expect(pending, hasLength(1));
    expect(pending.single, {
      'eventId': 'event-1',
      'packageName': 'viva.republica.toss',
      'title': '결제 알림',
      'text': '승인 5,000원 카페',
      'timestamp': 123456,
    });
  });

  test('acknowledgement forwards only the specified event IDs', () async {
    await NotificationChannel.acknowledgeNotifications(['event-1']);

    expect(calls.single.method, 'acknowledgeNotifications');
    expect(calls.single.arguments, {
      'eventIds': ['event-1'],
    });
  });

  test('disabling capture forwards false to the native channel', () async {
    await NotificationChannel.configureCaptureEnabled(false);

    expect(calls.single.method, 'configureCaptureEnabled');
    expect(calls.single.arguments, {'enabled': false});
  });

  test('enabling capture forwards true to the native channel', () async {
    await NotificationChannel.configureCaptureEnabled(true);

    expect(calls.single.method, 'configureCaptureEnabled');
    expect(calls.single.arguments, {'enabled': true});
  });

  test('native queue errors are reported instead of pretending it is empty', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(code: 'queue_unavailable');
    });

    await expectLater(
      NotificationChannel.getPendingNotifications(),
      throwsA(isA<PlatformException>()),
    );
  });

  test('an empty acknowledgement does not invoke the native channel', () async {
    await NotificationChannel.acknowledgeNotifications([]);

    expect(calls, isEmpty);
  });

  test('a malformed pending event is reported instead of being acknowledged', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => [
              {'title': '결제 알림'},
            ]);

    await expectLater(
      NotificationChannel.getPendingNotifications(),
      throwsA(isA<FormatException>()),
    );
  });

  test('native queue overflow can be surfaced to the user', () async {
    expect(await NotificationChannel.getDroppedNotificationCount(), 2);
  });
}
