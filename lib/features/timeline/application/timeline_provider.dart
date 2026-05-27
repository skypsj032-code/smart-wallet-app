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

/// 타임라인 상태 컨트롤러 — UI 객체(WidgetRef) 없이 비즈니스 로직을 캡슐화합니다.
class TimelineController extends AutoDisposeNotifier<void> {
  @override
  void build() {}

  void selectType(String? type) {
    ref.read(timelineSelectedTypeProvider.notifier).state = type;
    ref.read(timelineVisibleLimitProvider.notifier).state =
        ref.read(timelinePageSizeProvider);
  }

  void loadMore() {
    ref.read(timelineVisibleLimitProvider.notifier).state +=
        ref.read(timelinePageSizeProvider);
  }
}

final timelineControllerProvider =
    NotifierProvider.autoDispose<TimelineController, void>(
  TimelineController.new,
);

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
