import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_wallet_app/app/theme/app_theme.dart';
import 'package:smart_wallet_app/core/database/app_database.dart';
import 'package:smart_wallet_app/features/budgets/application/budget_provider.dart';
import 'package:smart_wallet_app/features/notifications/application/notification_parser.dart';
import 'package:smart_wallet_app/features/notifications/application/notification_provider.dart';
import 'package:smart_wallet_app/features/root/presentation/app_shell.dart';
import 'package:smart_wallet_app/features/transactions/application/quick_entry_form_provider.dart';
import 'package:smart_wallet_app/features/transactions/application/quick_entry_options_provider.dart';
import 'package:smart_wallet_app/features/transactions/data/transaction_repository.dart';
import 'package:smart_wallet_app/features/transactions/data/transaction_repository_interface.dart';
import 'package:smart_wallet_app/features/transactions/presentation/quick_entry_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(() => SharedPreferences.setMockInitialValues(const {}));

  testWidgets('back asks before discarding a transaction edit', (tester) async {
    final harness = await _Harness.open(tester);
    await harness.edit(tester);
    await harness.enterAmount(tester, '8700');

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('수정 내용을 저장할까요?'), findsOneWidget);

    await tester.tap(find.text('계속 수정'));
    await tester.pumpAndSettle();
    expect(find.byType(QuickEntryScreen), findsOneWidget);
    expect(harness.container.read(quickEntryFormProvider).amount, '8700');
    expect(harness.repository.updates, isEmpty);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.text('저장 안 함'));
    await tester.pumpAndSettle();
    expect(find.text('home screen'), findsOneWidget);
    expect(harness.repository.updates, isEmpty);
    expect(harness.container.read(quickEntryFormProvider).editingId, isNull);
  });

  testWidgets('switching tabs can save an edit before navigating', (tester) async {
    final harness = await _Harness.open(tester);
    await harness.edit(tester);
    await harness.enterAmount(tester, '12900');

    await tester.tap(find.text('도구'));
    await tester.pumpAndSettle();
    expect(find.text('수정 내용을 저장할까요?'), findsOneWidget);
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    expect(find.text('tools screen'), findsOneWidget);
    expect(harness.repository.updates, hasLength(1));
    expect(harness.repository.updates.single.editingId, 'tx-original');
    expect(harness.repository.updates.single.amount, '12900');
  });

  testWidgets('failed save keeps the edit and does not navigate', (tester) async {
    final harness = await _Harness.open(tester, failSave: true);
    await harness.edit(tester);
    await harness.enterAmount(tester, '5600');

    await tester.tap(find.text('도구'));
    await tester.pumpAndSettle();
    expect(find.text('수정 내용을 저장할까요?'), findsOneWidget);
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    expect(find.byType(QuickEntryScreen), findsOneWidget);
    expect(find.text('tools screen'), findsNothing);
    expect(harness.container.read(quickEntryFormProvider).editingId, 'tx-original');
    expect(harness.container.read(quickEntryFormProvider).amount, '5600');
    expect(find.text('거래를 수정하지 못했어요.'), findsOneWidget);
  });

  testWidgets('editing banner asks before resetting the form', (tester) async {
    final harness = await _Harness.open(tester);
    await harness.edit(tester);
    await harness.enterAmount(tester, '7100');
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();

    expect(find.text('수정 내용을 저장할까요?'), findsOneWidget);
    await tester.tap(find.text('계속 수정'));
    await tester.pumpAndSettle();
    expect(harness.container.read(quickEntryFormProvider).amount, '7100');
    expect(harness.container.read(quickEntryFormProvider).editingId, 'tx-original');
  });

  testWidgets('app bar back offers to keep editing', (tester) async {
    final harness = await _Harness.open(tester);
    await harness.edit(tester);
    await harness.enterAmount(tester, '6500');
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('수정 내용을 저장할까요?'), findsOneWidget);
    await tester.tap(find.text('계속 수정'));
    await tester.pumpAndSettle();
    expect(harness.container.read(quickEntryFormProvider).amount, '6500');
  });

  testWidgets('back from a new entry does not ask about editing', (tester) async {
    final harness = await _Harness.open(tester);
    harness.container.read(quickEntryFormProvider.notifier).reset();
    harness.router.push('/quick-entry');
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('home screen'), findsOneWidget);
    expect(find.text('수정 내용을 저장할까요?'), findsNothing);
  });

  testWidgets('switching tabs from an opened subpage protects the edit',
      (tester) async {
    final harness = await _Harness.open(tester);
    await harness.edit(tester);
    await harness.enterAmount(tester, '6300');
    harness.router.push('/accounts');
    await tester.pumpAndSettle();
    expect(find.text('기록'), findsNothing);
    expect(harness.container.read(quickEntryFormProvider).amount, '6300');
    await tester.tap(find.text('도구'));
    await tester.pumpAndSettle();
    expect(find.text('수정 내용을 저장할까요?'), findsOneWidget);
    await tester.tap(find.text('계속 수정'));
    await tester.pumpAndSettle();
    expect(find.text('accounts screen'), findsOneWidget);
    expect(harness.container.read(quickEntryFormProvider).amount, '6300');
  });

  testWidgets('the normal save button still saves once and leaves', (tester) async {
    final harness = await _Harness.open(tester);
    await harness.edit(tester);
    await harness.enterAmount(tester, '9400');
    await tester.ensureVisible(find.text('거래 수정하기'));
    await tester.tap(find.text('거래 수정하기'));
    await tester.pumpAndSettle();
    expect(find.text('home screen'), findsOneWidget);
    expect(harness.repository.updates, hasLength(1));
    expect(harness.repository.updates.single.amount, '9400');
    expect(find.text('수정 내용을 저장할까요?'), findsNothing);
  });

  testWidgets('a new notification cannot silently replace an edit', (tester) async {
    final harness = await _Harness.open(tester);
    await harness.edit(tester);
    await harness.enterAmount(tester, '8200');
    harness.container.read(detectedNotificationTransactionProvider.notifier).state =
        ParsedNotificationTransaction(
      amount: 2000,
      type: 'expense',
      merchant: '새 알림',
      rawTitle: 'card',
      rawText: 'payment',
      detectedAt: DateTime(2026, 5, 5),
    );
    await tester.pump();
    await tester.tap(find.text('새 알림'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('수정 내용을 저장할까요?'), findsOneWidget);
    await tester.tap(find.text('계속 수정'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(harness.container.read(quickEntryFormProvider).amount, '8200');
    expect(harness.container.read(quickEntryFormProvider).editingId, 'tx-original');
  });

  testWidgets('a notification cannot replace a new entry while it is saving',
      (tester) async {
    final pendingSave = Completer<void>();
    final harness = await _Harness.open(tester, pendingCreate: pendingSave);
    addTearDown(() {
      if (!pendingSave.isCompleted) pendingSave.complete();
    });
    harness.router.push('/quick-entry');
    await tester.pumpAndSettle();
    await harness.enterAmount(tester, '4200');
    await tester.ensureVisible(find.text('거래 저장하기'));
    await tester.tap(find.text('거래 저장하기'));
    await tester.pump();
    expect(harness.container.read(quickEntrySubmitStateProvider), isTrue);

    harness.container.read(detectedNotificationTransactionProvider.notifier).state =
        ParsedNotificationTransaction(
      amount: 2000,
      type: 'expense',
      merchant: '저장 중 알림',
      rawTitle: 'card',
      rawText: 'payment',
      detectedAt: DateTime(2026, 5, 5),
    );
    await tester.pump();
    await tester.tap(find.text('저장 중 알림'));
    await tester.pump();
    expect(harness.container.read(quickEntryFormProvider).amount, '4200');
    expect(harness.container.read(detectedNotificationTransactionProvider), isNotNull);

    harness.container.read(detectedNotificationTransactionProvider.notifier).state = null;
    await tester.pump();
    pendingSave.complete();
    await tester.pumpAndSettle();
    expect(harness.repository.creates, hasLength(1));
    expect(harness.repository.creates.single.amount, '4200');
  });

  testWidgets('locked screen preserves the pending edit until it is reopened',
      (tester) async {
    final harness = await _Harness.open(tester);
    await harness.edit(tester);
    await harness.enterAmount(tester, '7800');
    harness.router.go('/lock');
    await tester.pumpAndSettle();
    expect(find.text('locked screen'), findsOneWidget);

    harness.router.go('/quick-entry');
    await tester.pumpAndSettle();
    expect(harness.container.read(quickEntryFormProvider).editingId, 'tx-original');
    expect(harness.container.read(quickEntryFormProvider).amount, '7800');
    expect(find.byType(QuickEntryScreen), findsOneWidget);
    final amountField = tester.widget<TextField>(find.byWidgetPredicate((widget) =>
        widget is TextField && widget.decoration?.hintText == '0'));
    expect(amountField.controller?.text, '7800');
  });

  testWidgets('locking while the exit dialog is open keeps the edit usable',
      (tester) async {
    final harness = await _Harness.open(tester);
    await harness.edit(tester);
    await harness.enterAmount(tester, '7900');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('수정 내용을 저장할까요?'), findsOneWidget);

    harness.router.go('/lock');
    await tester.pumpAndSettle();
    expect(find.text('locked screen'), findsOneWidget);
    expect(find.text('수정 내용을 저장할까요?'), findsNothing);
    harness.router.go('/quick-entry');
    await tester.pumpAndSettle();
    expect(harness.container.read(quickEntryFormProvider).amount, '7900');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('수정 내용을 저장할까요?'), findsOneWidget);
    await tester.tap(find.text('계속 수정'));
    await tester.pumpAndSettle();
    expect(harness.container.read(quickEntryFormProvider).editingId, 'tx-original');
  });
}

class _Harness {
  _Harness(this.container, this.router, this.repository);
  final ProviderContainer container;
  final GoRouter router;
  final _FakeRepository repository;

  static Future<_Harness> open(WidgetTester tester,
      {bool failSave = false, Completer<void>? pendingCreate}) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    final repository = _FakeRepository(failSave: failSave, pendingCreate: pendingCreate);
    final container = ProviderContainer(overrides: [
      transactionRepositoryProvider.overrideWithValue(repository),
      quickEntryAccountsProvider.overrideWith((ref) => Stream.value(const [
        QuickEntryAccountOption(id: 'cash', name: '현금'),
      ])),
      quickEntryCategoriesProvider('expense').overrideWith((ref) => Stream.value(const [
        QuickEntryCategoryOption(id: 'food', name: '식비', type: 'expense'),
      ])),
      budgetSummaryProvider.overrideWith((ref) => Stream.value(const BudgetSummary(
        monthKey: '2026-05', totalBudget: 0, totalSpent: 0, remaining: 0, items: [],
      ))),
    ]);
    final now = DateTime(2026, 5, 5);
    final transaction = Transaction(
      localId: 'tx-original', type: 'expense', amount: 5000,
      occurredAt: now, accountId: 'cash', categoryId: 'food',
      createdAt: now, lastModifiedAt: now,
    );
    final router = GoRouter(initialLocation: '/', routes: [
      GoRoute(path: '/lock', builder: (_, __) => const Scaffold(body: Text('locked screen'))),
      ShellRoute(
        builder: (_, __, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (context, state) => Scaffold(
            body: Center(child: TextButton(
              onPressed: () {
                container.read(quickEntryFormProvider.notifier).loadTransaction(transaction);
                context.push('/quick-entry');
              },
              child: const Text('home screen'),
            )),
          )),
          GoRoute(path: '/quick-entry', builder: (_, __) => const QuickEntryScreen()),
          GoRoute(path: '/tools', builder: (_, __) => const Scaffold(body: Text('tools screen'))),
          GoRoute(path: '/timeline', builder: (_, __) => const Scaffold(body: Text('timeline screen'))),
          GoRoute(path: '/settings', builder: (_, __) => const Scaffold(body: Text('settings screen'))),
          GoRoute(path: '/accounts', builder: (_, __) => const Scaffold(body: Text('accounts screen'))),
        ],
      ),
    ]);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      router.dispose();
      container.dispose();
      await tester.binding.setSurfaceSize(null);
    });
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
    ));
    await tester.pumpAndSettle();
    return _Harness(container, router, repository);
  }

  Future<void> edit(WidgetTester tester) async {
    await tester.tap(find.text('home screen'));
    await tester.pumpAndSettle();
    expect(find.byType(QuickEntryScreen), findsOneWidget);
  }

  Future<void> enterAmount(WidgetTester tester, String amount) async {
    final amountField = find.byWidgetPredicate((widget) =>
        widget is TextField && widget.decoration?.hintText == '0');
    await tester.ensureVisible(amountField);
    await tester.enterText(amountField, amount);
    await tester.pump();
    expect(container.read(quickEntryFormProvider).amount, amount);
  }
}

class _FakeRepository implements ITransactionRepository {
  _FakeRepository({required this.failSave, this.pendingCreate});
  final bool failSave;
  final Completer<void>? pendingCreate;
  final creates = <QuickEntryFormState>[];
  final updates = <QuickEntryFormState>[];

  @override
  Future<void> updateFromQuickEntry(QuickEntryFormState form) async {
    if (failSave) throw StateError('save failed');
    updates.add(form);
  }

  @override
  Future<void> createFromQuickEntry(QuickEntryFormState form) async {
    creates.add(form);
    if (pendingCreate != null) await pendingCreate!.future;
  }
  @override
  Future<void> softDeleteTransaction(String localId) async {}
  @override
  Future<void> undoDeleteTransaction(String localId) async {}
}
