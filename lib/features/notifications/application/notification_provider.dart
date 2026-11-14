import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/providers/database_providers.dart';
import '../data/notification_channel.dart';
import 'notification_merchant.dart';
import 'notification_parser.dart';

const _kNotificationEnabled = 'notification_listener_enabled';

/// Settings are loaded before native capture is configured: the initial false
/// state is only a loading default and must not erase the native queue.
class NotificationListenerEnabledNotifier extends Notifier<bool> {
  bool _disposed = false;
  int _revision = 0;
  Future<void> _operations = Future<void>.value();

  @override
  bool build() {
    ref.onDispose(() => _disposed = true);
    _enqueue(() async {
      final prefs = await SharedPreferences.getInstance();
      if (_disposed || _revision != 0) return;
      final enabled = prefs.getBool(_kNotificationEnabled) ?? false;
      await NotificationChannel.configureCaptureEnabled(enabled);
      if (!_disposed && _revision == 0) state = enabled;
    });
    return false;
  }

  Future<void> _enqueue(Future<void> Function() action) {
    _operations = _operations.then((_) async {
      try {
        await action();
      } catch (error) {
        if (!_disposed) {
          ref.read(notificationCaptureErrorProvider.notifier).state = true;
        }
        // Do not print notification content or treat a failed native call as a
        // successfully configured listener.
        debugPrint('Notification capture configuration failed: $error');
      }
    });
    return _operations;
  }

  Future<void> toggle(bool value) {
    final revision = ++_revision;
    if (!value) {
      state = false;
      ref.read(notificationDroppedCountProvider.notifier).state = 0;
    }
    return _enqueue(() async {
      final prefs = await SharedPreferences.getInstance();
      if (_disposed || revision != _revision) return;
      await prefs.setBool(_kNotificationEnabled, value);
      try {
        await NotificationChannel.configureCaptureEnabled(value);
      } catch (_) {
        if (value) await prefs.setBool(_kNotificationEnabled, false);
        rethrow;
      }
      if (!_disposed && revision == _revision) {
        state = value;
        ref.read(notificationCaptureErrorProvider.notifier).state = false;
      }
    });
  }
}

final notificationListenerEnabledProvider =
    NotifierProvider<NotificationListenerEnabledNotifier, bool>(
  NotificationListenerEnabledNotifier.new,
);

final detectedNotificationTransactionProvider =
    StateProvider<ParsedNotificationTransaction?>((ref) => null);
final notificationDroppedCountProvider = StateProvider<int>((ref) => 0);
final notificationCaptureErrorProvider = StateProvider<bool>((ref) => false);

final notificationPermissionGrantedProvider = FutureProvider<bool>((ref) async {
  return NotificationChannel.isPermissionGranted();
});

final notificationBatteryOptimizationIgnoredProvider =
    FutureProvider<bool>((ref) async {
  return NotificationChannel.isBatteryOptimizationIgnored();
});

/// Save only transaction-like notices. Unclear amounts, cancellations and
/// foreign currency are retained as unclassified candidates, never invented
/// as a KRW transaction. Other bank-app notifications are acknowledged without
/// preserving their potentially sensitive contents.
Future<NotificationHistory?> persistNotificationEvent(
  AppDatabase database,
  Map<String, dynamic> event,
) async {
  final eventId = event['eventId'];
  if (eventId is! String || eventId.isEmpty ||
      event['packageName'] is! String || event['timestamp'] is! int ||
      event['title'] is! String || event['text'] is! String) {
    throw const FormatException('Invalid notification event');
  }
  return database.transaction(() async {
    final existing = await (database.select(database.notificationHistories)
          ..where((h) => h.eventId.equals(eventId)))
        .getSingleOrNull();
    if (existing != null) return existing;

    final title = event['title'] as String;
    final text = event['text'] as String;
    final combined = '$title $text';
    final transactionLike = RegExp(
      r'승인|결제|사용|출금|입금|이체|환급|환불|취소|거절|실패|급여|수신|이자',
    ).hasMatch(combined);
    if (!transactionLike) return null;

    // A balance and a payment can appear in the same notice. Never present
    // the first number or a conflicting direction as a confirmed suggestion.
    final amountCount = RegExp(r'[\d,]+\s*원').allMatches(combined).length;
    final hasIncome = RegExp(r'입금|수신|급여|환급|이자').hasMatch(combined);
    final hasExpense = RegExp(r'승인|사용|결제|출금|이체').hasMatch(combined);
    final ambiguous = RegExp(r'취소|거절|실패|환불|잔액|한도|누적|잔여|포인트|마일리지')
            .hasMatch(combined) ||
        amountCount > 1 || (hasIncome && hasExpense);
    final parsed = ambiguous ? null : parseNotification(event);
    final safeTitle = title.trim();
    final fallbackTitle = safeTitle.length > 50
        ? safeTitle.substring(0, 50)
        : safeTitle;
    final id = await database.into(database.notificationHistories).insert(
      NotificationHistoriesCompanion.insert(
        packageName: event['packageName'] as String,
        amount: parsed?.amount ?? 0,
        type: parsed?.type ?? 'unknown',
        merchant: Value(parsed == null
            ? (fallbackTitle.isEmpty ? null : fallbackTitle)
            : (parsed.merchant.isEmpty ? null : parsed.merchant)),
        suggestedCategory: Value(parsed?.suggestedCategoryKeyword),
        detectedAt: DateTime.fromMillisecondsSinceEpoch(event['timestamp'] as int),
        eventId: Value(eventId),
        status: const Value('pending'),
      ),
    );
    return (database.select(database.notificationHistories)
          ..where((h) => h.id.equals(id)))
        .getSingle();
  });
}

/// Keep the native copy until the local transaction commits. If native
/// acknowledgement fails, retrying the same event returns the existing row.
Future<NotificationHistory?> persistAndAcknowledgeNotificationEvent(
  AppDatabase database,
  Map<String, dynamic> event,
  Future<void> Function(List<String>) acknowledge,
) async {
  final saved = await persistNotificationEvent(database, event);
  await acknowledge([event['eventId'] as String]);
  return saved;
}

/// Previously confirmed category choices stay on the device and are used only
/// while the category still exists, is active, and matches the transaction type.
Future<String?> findNotificationCategory(
  AppDatabase database,
  String? merchant,
  String type,
  String? keyword,
) async {
  if (type != 'expense' && type != 'income') return null;
  final key = normalizeNotificationMerchant(merchant ?? '');
  if (key.isNotEmpty) {
    final rule = await (database.select(database.merchantCategoryRules)
          ..where((r) => r.merchantKey.equals(key) & r.type.equals(type)))
        .getSingleOrNull();
    if (rule != null) {
      final category = await (database.select(database.categories)
            ..where((c) => c.localId.equals(rule.categoryId) &
                c.type.equals(type) & c.isActive.equals(true)))
          .getSingleOrNull();
      if (category != null) return category.localId;
    }
  }
  if (keyword == null || keyword.isEmpty) return null;
  final categories = await (database.select(database.categories)
        ..where((c) => c.type.equals(type) & c.isActive.equals(true))
        ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
      .get();
  for (final category in categories) {
    if (category.name.contains(keyword)) return category.localId;
  }
  return null;
}

class _NotificationResumeObserver with WidgetsBindingObserver {
  _NotificationResumeObserver(this.onResume);
  final VoidCallback onResume;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) onResume();
  }
}

/// The native queue is acknowledged only after each candidate is committed to
/// the local database. Replays are safe because eventId has a unique index.
final notificationListenerProvider = Provider<void>((ref) {
  if (!ref.watch(notificationListenerEnabledProvider)) return;

  final database = ref.read(appDatabaseProvider);
  var disposed = false;
  Future<void> work = Future<void>.value();

  Future<void> handle(Map<String, dynamic> event) async {
    final saved = await persistAndAcknowledgeNotificationEvent(
      database, event, NotificationChannel.acknowledgeNotifications,
    );
    if (disposed || saved == null || saved.status != 'pending' || saved.type == 'unknown') return;
    final parsed = parseNotification(event);
    if (parsed == null) return;
    ref.read(detectedNotificationTransactionProvider.notifier).state =
        ParsedNotificationTransaction(
      amount: saved.amount,
      type: saved.type,
      merchant: saved.merchant ?? '',
      rawTitle: parsed.rawTitle,
      rawText: parsed.rawText,
      detectedAt: saved.detectedAt,
      cardName: parsed.cardName,
      suggestedCategoryKeyword: saved.suggestedCategory,
      historyId: saved.id,
    );
  }

  void enqueue(Future<void> Function() action) {
    work = work.then((_) async {
      if (disposed) return;
      try {
        await action();
        if (!disposed) ref.read(notificationCaptureErrorProvider.notifier).state = false;
      } catch (error) {
        if (!disposed) ref.read(notificationCaptureErrorProvider.notifier).state = true;
        debugPrint('Notification capture processing failed: $error');
      }
    });
  }

  void drain() => enqueue(() async {
        final pending = await NotificationChannel.getPendingNotifications();
        for (final event in pending) {
          await handle(event);
        }
        final dropped = await NotificationChannel.getDroppedNotificationCount();
        if (!disposed) ref.read(notificationDroppedCountProvider.notifier).state = dropped;
      });

  // Start listening before taking a snapshot; a periodic drain also closes any
  // race while the native stream subscription is being established.
  final subscription = NotificationChannel.stream.listen(
    (event) => enqueue(() => handle(event)),
    onError: (Object error, StackTrace stackTrace) {
      if (!disposed) ref.read(notificationCaptureErrorProvider.notifier).state = true;
    },
  );
  final observer = _NotificationResumeObserver(drain);
  WidgetsBinding.instance.addObserver(observer);
  final retry = Timer.periodic(const Duration(seconds: 30), (_) => drain());
  drain();
  ref.onDispose(() {
    disposed = true;
    retry.cancel();
    WidgetsBinding.instance.removeObserver(observer);
    subscription.cancel();
  });
});
