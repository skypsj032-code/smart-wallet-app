import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Android EventChannel에서 카드/은행 알림을 수신한다.
class NotificationChannel {
  static const _eventChannel = EventChannel('smart_wallet/notifications');
  static const _methodChannel = MethodChannel('smart_wallet/notification_permission');

  /// 알림 스트림 — 각 이벤트는 eventId, packageName, title, text, timestamp 포함.
  static Stream<Map<String, dynamic>> get stream =>
      _eventChannel.receiveBroadcastStream().map(
            (event) => Map<String, dynamic>.from(event as Map),
          );

  /// Enables native capture only after the user has chosen to use it. Turning
  /// it off also erases any raw, not-yet-processed native notifications.
  static Future<void> configureCaptureEnabled(bool enabled) async {
    await _methodChannel.invokeMethod<void>(
      'configureCaptureEnabled',
      {'enabled': enabled},
    );
  }

  /// Reads a snapshot without removing it. Call [acknowledgeNotifications]
  /// only after each corresponding event is durably handled by the app.
  static Future<List<Map<String, dynamic>>> getPendingNotifications() async {
    final events = await _methodChannel.invokeListMethod<dynamic>(
      'getPendingNotifications',
    );
    if (events == null) {
      throw const FormatException('Native notification queue was unavailable');
    }
    return events.map((event) {
      if (event is! Map) {
        throw const FormatException('Invalid notification queue item');
      }
      final value = Map<String, dynamic>.from(event);
      if (value['eventId'] is! String ||
          (value['eventId'] as String).isEmpty ||
          value['packageName'] is! String ||
          value['title'] is! String ||
          value['text'] is! String ||
          value['timestamp'] is! int) {
        throw const FormatException('Invalid notification queue fields');
      }
      return value;
    }).toList(growable: false);
  }

  /// Removes exactly the IDs whose contents have already been persisted.
  /// An empty list cannot clear the queue.
  static Future<void> acknowledgeNotifications(List<String> eventIds) async {
    if (eventIds.isEmpty) return;
    if (eventIds.any((id) => id.isEmpty)) {
      throw ArgumentError('Notification event IDs must not be empty');
    }
    await _methodChannel.invokeMethod<void>(
      'acknowledgeNotifications',
      {'eventIds': eventIds},
    );
  }

  /// Counts events lost because the bounded native queue was already full.
  static Future<int> getDroppedNotificationCount() async {
    final value = await _methodChannel.invokeMethod<int>(
      'getDroppedNotificationCount',
    );
    if (value == null || value < 0) {
      throw const FormatException('Invalid notification queue overflow count');
    }
    return value;
  }

  /// 현재 알림 접근 권한이 허용되어 있는지 확인
  static Future<bool> isPermissionGranted() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('isPermissionGranted');
      return result ?? false;
    } catch (error, stackTrace) {
      debugPrint('Notification permission check failed: $error\n$stackTrace');
      return false;
    }
  }

  /// 시스템 알림 접근 권한 설정 화면으로 이동
  static Future<void> openPermissionSettings() async {
    try {
      await _methodChannel.invokeMethod('openPermissionSettings');
    } catch (error, stackTrace) {
      debugPrint('Opening notification settings failed: $error\n$stackTrace');
    }
  }

  /// 배터리 최적화 예외가 적용되어 있는지 확인
  static Future<bool> isBatteryOptimizationIgnored() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        'isBatteryOptimizationIgnored',
      );
      return result ?? false;
    } catch (error, stackTrace) {
      debugPrint(
        'Battery optimization status check failed: $error\n$stackTrace',
      );
      return false;
    }
  }

  /// 배터리 최적화 예외 설정 화면으로 이동
  static Future<void> openBatteryOptimizationSettings() async {
    try {
      await _methodChannel.invokeMethod('openBatteryOptimizationSettings');
    } catch (error, stackTrace) {
      debugPrint(
        'Opening battery optimization settings failed: $error\n$stackTrace',
      );
    }
  }
}
