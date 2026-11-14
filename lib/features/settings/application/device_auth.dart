import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum DeviceAuthResult { success, cancelled, notConfigured, unsupported, error }

/// Requests the device's own PIN, pattern, or password; never accepts a
/// missing plugin, an unexpected response, or a platform error as success.
class DeviceAuth {
  const DeviceAuth();

  static const _channel = MethodChannel('smart_wallet/device_auth');

  Future<DeviceAuthResult> authenticate() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return DeviceAuthResult.unsupported;
    }

    try {
      final result = await _channel.invokeMethod<String>(
        'authenticateDeviceCredential',
      );
      return switch (result) {
        'success' => DeviceAuthResult.success,
        'cancelled' => DeviceAuthResult.cancelled,
        'notConfigured' => DeviceAuthResult.notConfigured,
        'unsupported' => DeviceAuthResult.unsupported,
        _ => DeviceAuthResult.error,
      };
    } catch (_) {
      return DeviceAuthResult.error;
    }
  }

  Future<void> cancel() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    try {
      await _channel.invokeMethod<void>('cancelDeviceCredential');
    } catch (_) {
      // Cancellation never grants recovery, even if the platform is gone.
    }
  }
}
