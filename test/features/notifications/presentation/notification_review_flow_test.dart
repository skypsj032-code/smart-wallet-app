import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wallet_app/core/database/app_database.dart';
import 'package:smart_wallet_app/core/database/providers/database_providers.dart';
import 'package:smart_wallet_app/features/notifications/application/notification_provider.dart';
import 'package:smart_wallet_app/features/notifications/presentation/notification_history_screen.dart';
import 'package:smart_wallet_app/features/transactions/application/quick_entry_form_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async => database.close());

  Future<int> addHistory({
    required String status,
    String? merchant,
    String type = 'expense',
    int amount = 5400,
    DateTime? at,
  }) {
    return database.into(database.notificationHistories).insert(
          NotificationHistoriesCompanion.insert(
            packageName: 'card.app',
            amount: amount,
            type: type,
            merchant: Value(merchant),
            status: Value(status),
            detectedAt: at ?? DateTime(2026, 5, 8, 12),
          ),
        );
  }

  Future<ProviderContainer> open(WidgetTester tester) async {
    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(database),
    ]);
    final router = GoRouter(routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const NotificationHistoryScreen(),
      ),
      GoRoute(
        path: '/quick-entry',
        builder: (_, __) => const Scaffold(body: Text('입력 화면')),
      ),
    ]);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      router.dispose();
      container.dispose();
    });
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('pending items can be ignored and restored', (tester) async {
    final id = await addHistory(status: 'pending', merchant: '커피집');
    await open(tester);

    expect(find.textContaining('· 확인 필요'), findsOneWidget);
    await tester.tap(find.byTooltip('이 알림 제외'));
    await tester.pumpAndSettle();
    expect(find.textContaining('제외됨'), findsOneWidget);
    var row = await (database.select(database.notificationHistories)
          ..where((t) => t.id.equals(id)))
        .getSingle();
    expect(row.status, 'ignored');

    await tester.tap(find.byTooltip('다시 확인하기'));
    await tester.pumpAndSettle();
    row = await (database.select(database.notificationHistories)
          ..where((t) => t.id.equals(id)))
        .getSingle();
    expect(row.status, 'pending');
  });

  testWidgets('recorded items cannot open another transaction', (tester) async {
    await addHistory(status: 'recorded', merchant: '이미 기록한 상점');
    await open(tester);
    await tester.tap(find.text('이미 기록한 상점'));
    await tester.pump();
    expect(find.textContaining('이미 기록'), findsWidgets);
    expect(find.text('입력 화면'), findsNothing);
  });

  testWidgets('legacy item needs explicit confirmation before entering',
      (tester) async {
    final id = await addHistory(status: 'legacy', merchant: '예전 상점');
    final container = await open(tester);
    await tester.tap(find.text('예전 상점'));
    await tester.pumpAndSettle();
    expect(find.text('이전 알림 확인'), findsOneWidget);
    expect(find.text('입력 화면'), findsNothing);
    await tester.tap(find.text('확인 후 기록'));
    await tester.pumpAndSettle();
    expect(find.text('입력 화면'), findsOneWidget);
    expect(container.read(quickEntryFormProvider).notificationHistoryId, id);
  });

  testWidgets('unknown amount stays blank for a person to review',
      (tester) async {
    await addHistory(status: 'pending', merchant: '확인할 알림', type: 'unknown', amount: 0);
    final container = await open(tester);
    expect(find.text('금액 확인 필요'), findsOneWidget);
    await tester.tap(find.text('확인할 알림'));
    await tester.pumpAndSettle();
    expect(find.text('거래 정보 확인'), findsOneWidget);
    await tester.tap(find.text('직접 확인하기'));
    await tester.pumpAndSettle();
    expect(container.read(quickEntryFormProvider).amount, isEmpty);
  });

  testWidgets('opening a candidate asks before replacing a new draft',
      (tester) async {
    final candidateId = await addHistory(status: 'pending', merchant: '새 결제');
    final container = await open(tester);
    container.read(quickEntryFormProvider.notifier).setAmount('7800');
    container.read(quickEntryFormProvider.notifier).setMemo('작성하던 내용');

    await tester.tap(find.text('새 결제'));
    await tester.pumpAndSettle();
    expect(find.text('작성 중인 내용을 버리고 알림을 열까요?'), findsOneWidget);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(container.read(quickEntryFormProvider).amount, '7800');
    expect(container.read(quickEntryFormProvider).memo, '작성하던 내용');
    expect(find.text('입력 화면'), findsNothing);

    await tester.tap(find.text('새 결제'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('알림 열기'));
    await tester.pumpAndSettle();
    expect(find.text('입력 화면'), findsOneWidget);
    expect(container.read(quickEntryFormProvider).notificationHistoryId, candidateId);
  });

  testWidgets('similar recorded payment warns without discarding the new one',
      (tester) async {
    final at = DateTime(2026, 5, 8, 12);
    await addHistory(status: 'recorded', merchant: '별다방', at: at);
    final candidateId = await addHistory(
      status: 'pending', merchant: '별다방', at: at.add(const Duration(minutes: 1)),
    );
    final container = await open(tester);
    await tester.tap(find.text('별다방').first);
    await tester.pumpAndSettle();
    expect(find.text('비슷한 결제가 있어요'), findsOneWidget);
    await tester.tap(find.text('확인 후 계속'));
    await tester.pumpAndSettle();
    expect(find.text('입력 화면'), findsOneWidget);
    expect(container.read(quickEntryFormProvider).notificationHistoryId, candidateId);
  });

  testWidgets('same amount at a different merchant is not treated as duplicate',
      (tester) async {
    final at = DateTime(2026, 5, 8, 12);
    await addHistory(status: 'recorded', merchant: '별다방', at: at);
    final candidateId = await addHistory(
      status: 'pending', merchant: '김밥집', at: at.add(const Duration(minutes: 1)),
    );
    final container = await open(tester);
    await tester.tap(find.text('김밥집'));
    await tester.pumpAndSettle();
    expect(find.text('비슷한 결제가 있어요'), findsNothing);
    expect(find.text('입력 화면'), findsOneWidget);
    expect(container.read(quickEntryFormProvider).notificationHistoryId, candidateId);
  });

  testWidgets('overflow and capture failures are visible when history is empty',
      (tester) async {
    final container = await open(tester);
    container.read(notificationDroppedCountProvider.notifier).state = 3;
    container.read(notificationCaptureErrorProvider.notifier).state = true;
    await tester.pump();
    expect(find.textContaining('알림 3건을 놓쳤어요'), findsOneWidget);
    expect(find.textContaining('알림을 불러오지 못했어요'), findsOneWidget);
  });
}
