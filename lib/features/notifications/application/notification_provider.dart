import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/notification_channel.dart';
import 'notification_parser.dart';

/// 알림 감지 기능 활성화 여부 (사용자 토글)
final notificationListenerEnabledProvider = StateProvider<bool>((ref) => false);

/// 현재 감지된 거래 (배너 표시용) — null이면 배너 없음
final detectedNotificationTransactionProvider =
    StateProvider<ParsedNotificationTransaction?>((ref) => null);

/// 알림 권한 허용 여부
final notificationPermissionGrantedProvider = FutureProvider<bool>((ref) async {
  return NotificationChannel.isPermissionGranted();
});

/// 알림 스트림을 구독하고 파싱된 거래를 [detectedNotificationTransactionProvider]에 저장
final notificationListenerProvider = Provider<void>((ref) {
  final enabled = ref.watch(notificationListenerEnabledProvider);
  if (!enabled) return;

  StreamSubscription<Map<String, dynamic>>? sub;

  sub = NotificationChannel.stream.listen((event) {
    final parsed = parseNotification(event);
    if (parsed == null) return;
    ref.read(detectedNotificationTransactionProvider.notifier).state = parsed;
  });

  ref.onDispose(() => sub?.cancel());
});
