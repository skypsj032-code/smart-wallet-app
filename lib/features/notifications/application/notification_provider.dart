import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/notification_channel.dart';
import 'notification_parser.dart';

const _kNotificationEnabled = 'notification_listener_enabled';

/// 알림 감지 기능 활성화 여부 — SharedPreferences에 영속화
class NotificationListenerEnabledNotifier extends Notifier<bool> {
  @override
  bool build() {
    // 비동기 초기화: 저장값을 읽어 상태를 갱신
    var disposed = false;
    ref.onDispose(() => disposed = true);

    SharedPreferences.getInstance().then((prefs) {
      if (disposed) return;
      state = prefs.getBool(_kNotificationEnabled) ?? false;
    });
    return false; // 로드 전 기본값
  }

  Future<void> toggle(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotificationEnabled, value);
  }
}

final notificationListenerEnabledProvider =
    NotifierProvider<NotificationListenerEnabledNotifier, bool>(
  NotificationListenerEnabledNotifier.new,
);

/// 현재 감지된 거래 (배너 표시용) — null이면 배너 없음
final detectedNotificationTransa