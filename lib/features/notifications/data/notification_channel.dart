import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Android EventChannel에서 카드/은행 알림을 수신한다.
class NotificationChannel {
  static const _eventChannel = EventChannel('smart_wallet/notifications');
  static const _methodChannel = MethodChannel('smart_wallet/notification_permission');

  /// 알림 스트림 — 각 이벤트는 {packageName, title, text, timestamp} Map
  static Stream<Map<String, dynamic>> get stream =>
      _eventChannel.receiveBroadcastStream().map(
            (event) => Map<String, dynamic>.from(event as Map),
          );

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
