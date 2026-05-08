import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/providers/database_providers.dart';

class TimelineSnapshot {
  const TimelineSnapshot({
    required this.items,
    required this.totalCount,
  });

  final List<Transaction> items;
  final int totalCount;

  bool get hasMore => items.length < totalCount;
}

final timelinePageSizeProvider = Provider<int>((ref) => 50);

final timelineSelectedTypeProvider = StateProvider.autoDispose<String?>(
  (ref) => null,
);

final timelineVisibleLimitProvider = StateProvider.autoDispose<int>((ref) {
  return ref.watch(timelinePageSizeProvider);
});

final timelineTransactionsProvider =
    StreamProvider.autoDispose<TimelineSnapshot>((ref) {
  final database = ref.watch(appDatabaseProvider);
  final selectedType = ref.watch(timelineSelectedTypeProvider);
  final limit = ref.watch(timelineVisibleLimitProvider);

  return _combineLatest(
    database.watchTimelineTransactions(limit: limit, typeFilter: selectedType),
    database.watchTimelineTransactionCount(typeFilter: selectedType),
    (items, totalCount) =>
        TimelineSnapshot(items: items, totalCount: totalCount),
  );
});

void selectTimelineType(WidgetRef ref, String? type) {
  ref.read(timelineSelectedTypeProvider.notifier).state = type;
  ref.read(timelineVisibleLimitProvider.notifier).state =
      ref.read(timelinePageSizeProvider);
}

void loadMoreTimelineItems(WidgetRef ref) {
  ref.read(timelineVisibleLimitProvider.notifier).state +=
      ref.read(timelinePageSizeProvider);
}

Stream<R> _combineLatest<A, B, R>(
  Stream<A> a,
  Stream<B> b,
  R Function(A a, B b) combiner,
) {
  late A latestA;
  late B latestB;
  var hasA = false;
  var hasB = false;

  final controller = StreamController<R>.broadcast();
  late StreamSubscription<A> subA;
  late StreamSubscription<B> subB;

  void emitIfReady() {
    if (hasA && hasB) {
      controller.add(combiner(latestA, latestB));
    }
  }

  subA = a.listen(
    (value) {
      latestA = value;
      hasA = true;
      emitIfReady();
    },
    onError: controller.addError,
  );

  subB = b.listen(
    (value) {
      latestB = value;
      hasB = true;
      emitIfReady();
    },
    onError: controller.addError,
  );

  controller.onCancel = () async {
    await subA.cancel();
    await subB.cancel();
  };

  return controller.stream;
}
