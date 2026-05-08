import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/database/providers/database_providers.dart';
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
final detectedNotificationTransactionProvider =
    StateProvider<ParsedNotificationTransaction?>((ref) => null);

/// 알림 권한 허용 여부
final notificationPermissionGrantedProvider = FutureProvider<bool>((ref) async {
  return NotificationChannel.isPermissionGranted();
});

/// 배터리 최적화 예외 적용 여부
final notificationBatteryOptimizationIgnoredProvider =
    FutureProvider<bool>((ref) async {
  return NotificationChannel.isBatteryOptimizationIgnored();
});

/// 마지막으로 처리한 알림의 (금액, 타임스탬프) — 중복 방지용
final _lastNotificationKey = StateProvider<String?>((ref) => null);

/// 알림 스트림을 구독하고 파싱된 거래를 [detectedNotificationTransactionProvider]에 저장
final notificationListenerProvider = Provider<void>((ref) {
  final enabled = ref.watch(notificationListenerEnabledProvider);
  if (!enabled) return;

  StreamSubscription<Map<String, dynamic>>? sub;

  sub = NotificationChannel.stream.listen((event) {
    final parsed = parseNotification(event);
    if (parsed == null) return;

    // 동일 금액 + 3초 이내 중복 알림 무시
    final key = '${parsed.amount}_${parsed.detectedAt.millisecondsSinceEpoch ~/ 3000}';
    final lastKey = ref.read(_lastNotificationKey);
    if (key == lastKey) return;
    ref.read(_lastNotificationKey.notifier).state = key;

    ref.read(detectedNotificationTransactionProvider.notifier).state = parsed;

    // 이력 DB 저장 (최대 200건 유지)
    final db = ref.read(appDatabaseProvider);
    db
        .insertNotificationHistory(
          packageName: event['package'] as String? ?? '',
          amount: parsed.amount,
          type: parsed.type,
          merchant: parsed.merchant.isEmpty ? null : parsed.merchant,
          suggestedCategory: parsed.suggestedCategoryKeyword,
          detectedAt: parsed.detectedAt,
        )
        .then((_) => db.deleteOldNotificationHistories());
  });

  ref.onDispose(() => sub?.cancel());
});
