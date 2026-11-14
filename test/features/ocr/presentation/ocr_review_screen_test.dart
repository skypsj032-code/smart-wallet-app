import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wallet_app/features/ocr/application/ocr_capture_provider.dart';
import 'package:smart_wallet_app/features/ocr/presentation/ocr_capture_screen.dart';
import 'package:smart_wallet_app/features/ocr/presentation/ocr_review_screen.dart';
import 'package:smart_wallet_app/features/transactions/application/quick_entry_form_provider.dart';
import 'package:smart_wallet_app/features/transactions/application/quick_entry_options_provider.dart';

class _ReviewController extends OcrCaptureController {
  @override
  OcrDraftState build() => const OcrDraftState(
        status: OcrFlowStatus.reviewRequired,
        imagePath: 'fake-receipt.jpg',
        rawText: '동네마트\n결제금액 12,000원',
        confidence: 0.8, // 기존 초안에 저장되어 있을 수 있는 값
        storeName: '동네마트',
        amount: 12000,
        categoryGuess: 'expense-groceries',
      );

  @override
  void updateReviewEdits({
    required String rawText,
    required String storeName,
    required String amountText,
    required String categoryGuess,
  }) {
    state = state.copyWith(
      rawText: rawText,
      storeName: storeName,
      amount: int.tryParse(amountText.replaceAll(RegExp(r'[^0-9]'), '')),
      amountText: amountText,
      categoryGuess: categoryGuess,
    );
  }

  @override
  Future<bool> saveReviewEdits({
    required String rawText,
    required String storeName,
    required String amountText,
    required String categoryGuess,
  }) async {
    updateReviewEdits(
      rawText: rawText,
      storeName: storeName,
      amountText: amountText,
      categoryGuess: categoryGuess,
    );
    return state.amount != null;
  }

  @override
  Future<void> flushPendingWrites() async {}
}

void main() {
  _testAndroidWidgets('기존 초안에도 검증되지 않은 인식률이나 신뢰도를 표시하지 않는다',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [ocrCaptureProvider.overrideWith(_ReviewController.new)],
        child: const MaterialApp(home: OcrReviewScreen()),
      ),
    );

    expect(find.textContaining('신뢰도'), findsNothing);
    expect(find.textContaining('인식률'), findsNothing);
    expect(find.text('금액 확인 필요'), findsOneWidget);
  });

  _testAndroidWidgets('추천을 다시 만들기 전 수정 중인 상호가 덮어써질 수 있음을 알린다',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [ocrCaptureProvider.overrideWith(_ReviewController.new)],
        child: const MaterialApp(home: OcrReviewScreen()),
      ),
    );

    await tester.enterText(find.widgetWithText(TextField, '상호명'), '수정 중인 상호');
    await tester.scrollUntilVisible(
      find.text('추천 다시 만들기'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('추천 다시 만들기'));
    await tester.pumpAndSettle();

    expect(find.text('추천을 다시 만들까요?'), findsOneWidget);
    expect(find.textContaining('현재 상호명'), findsOneWidget);
    await tester.tap(find.text('계속 수정하기'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.widgetWithText(TextField, '상호명'),
      -300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('수정 중인 상호'), findsOneWidget);
  });

  _testAndroidWidgets('변경하지 않은 추천은 이름이 바뀌어도 활성 카테고리 ID로 전달한다',
      (tester) async {
    final container = await _openReview(
      tester,
      Stream.value(const [
        QuickEntryCategoryOption(
          id: 'expense-groceries',
          name: '직접 바꾼 장보기 이름',
          type: 'expense',
        ),
      ]),
    );

    await _continueFromReview(tester);
    await tester.pumpAndSettle();

    expect(find.text('빠른 입력 화면'), findsOneWidget);
    expect(container.read(quickEntryFormProvider).categoryId, 'expense-groceries');
    expect(container.read(ocrCaptureProvider).categoryGuess, 'expense-groceries');
  });

  _testAndroidWidgets('수동으로 적은 이름이 활성 카테고리와 일치하면 실제 ID를 전달한다',
      (tester) async {
    final container = await _openReview(
      tester,
      Stream.value(const [
        QuickEntryCategoryOption(id: 'custom-food', name: '식비', type: 'expense'),
      ]),
    );
    await tester.scrollUntilVisible(
      find.widgetWithText(TextField, '예상 카테고리'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(find.widgetWithText(TextField, '예상 카테고리'), '식비');
    await _continueFromReview(tester);
    await tester.pumpAndSettle();

    expect(container.read(quickEntryFormProvider).categoryId, 'custom-food');
    expect(container.read(ocrCaptureProvider).categoryGuess, '식비');
  });

  _testAndroidWidgets('추천과 일치하는 활성 카테고리가 없으면 임의의 ID를 넘기지 않는다',
      (tester) async {
    final container = await _openReview(tester, Stream.value(const []));

    await _continueFromReview(tester);
    await tester.pumpAndSettle();

    expect(find.text('빠른 입력 화면'), findsOneWidget);
    expect(container.read(quickEntryFormProvider).categoryId, isNull);
  });

  _testAndroidWidgets('카테고리 목록을 불러오지 못해도 직접 입력으로 계속할 수 있다',
      (tester) async {
    final container = await _openReview(
      tester,
      Stream.error(StateError('category loading failed')),
    );

    await _continueFromReview(tester);
    await tester.pumpAndSettle();

    expect(find.text('빠른 입력 화면'), findsOneWidget);
    expect(container.read(quickEntryFormProvider).categoryId, isNull);
  });

  _testAndroidWidgets('카테고리 목록을 기다리는 동안 직접 선택한 값은 덮어쓰지 않는다',
      (tester) async {
    final categories = StreamController<List<QuickEntryCategoryOption>>();
    addTearDown(categories.close);
    final container = await _openReview(tester, categories.stream);

    await _continueFromReview(tester);
    expect(find.text('빠른 입력 화면'), findsNothing);
    container.read(quickEntryFormProvider.notifier).setCategory('manual-choice');
    categories.add(const [
      QuickEntryCategoryOption(
        id: 'expense-groceries',
        name: '장보기',
        type: 'expense',
      ),
      QuickEntryCategoryOption(
        id: 'manual-choice',
        name: '수동 선택',
        type: 'expense',
      ),
    ]);
    await tester.pumpAndSettle();

    expect(find.text('작성 중인 거래를 바꿀까요?'), findsOneWidget);
    await tester.tap(find.text('계속 작성하기'));
    await tester.pumpAndSettle();
    expect(find.text('빠른 입력 화면'), findsNothing);
    expect(container.read(quickEntryFormProvider).categoryId, 'manual-choice');
  });

  _testAndroidWidgets('기존 알림 초안 교체를 취소하거나 확인하면 출처가 안전하게 처리된다',
      (tester) async {
    final container = await _openReview(tester, Stream.value(const []));
    final existing = container.read(quickEntryFormProvider.notifier);
    existing.setAmount('5000');
    existing.setNotificationOrigin(42, '이전 알림');

    await _continueFromReview(tester);
    await tester.pumpAndSettle();
    expect(find.text('작성 중인 거래를 바꿀까요?'), findsOneWidget);
    await tester.tap(find.text('계속 작성하기'));
    await tester.pumpAndSettle();
    expect(container.read(quickEntryFormProvider).notificationHistoryId, 42);
    expect(container.read(quickEntryFormProvider).amount, '5000');

    await _continueFromReview(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('거래 바꾸기'));
    await tester.pumpAndSettle();
    final next = container.read(quickEntryFormProvider);
    expect(find.text('빠른 입력 화면'), findsOneWidget);
    expect(next.amount, '12000');
    expect(next.notificationHistoryId, isNull);
    expect(next.notificationMerchant, isNull);
  });

  _testAndroidWidgets('검토 화면을 다시 열어도 저장된 수정은 재인식 전 확인한다', (tester) async {
    final container = await _openReview(tester, Stream.value(const []));
    await tester.enterText(find.widgetWithText(TextField, '상호명'), '보존할 상호');
    final router = GoRouter.of(tester.element(find.byType(OcrReviewScreen)));
    router.go('/quick-entry');
    await tester.pumpAndSettle();
    router.go('/');
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('추천 다시 만들기'), 300, scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('추천 다시 만들기'));
    await tester.pumpAndSettle();
    expect(find.text('추천을 다시 만들까요?'), findsOneWidget);
    await tester.tap(find.text('계속 수정하기'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('OCR 다시 실행'), 300, scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('OCR 다시 실행'));
    await tester.pumpAndSettle();
    expect(find.text('저장된 사진으로 OCR을 다시 실행할까요?'), findsOneWidget);
    await tester.tap(find.text('계속 수정하기'));
    await tester.pumpAndSettle();
    expect(container.read(ocrCaptureProvider).storeName, '보존할 상호');
  });

  _testAndroidWidgets('촬영 화면에서 저장 사진을 다시 인식하기 전 기존 초안 교체를 확인한다',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1;
    try {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [ocrCaptureProvider.overrideWith(_ReviewController.new)],
          child: const MaterialApp(home: OcrCaptureScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('저장된 사진으로 OCR 재시도'));
      await tester.pumpAndSettle();
      expect(find.text('기존 영수증 초안을 바꿀까요?'), findsOneWidget);
      await tester.tap(find.text('초안 유지'));
      await tester.pumpAndSettle();
      expect(find.text('기존 영수증 초안을 바꿀까요?'), findsNothing);
    } finally {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    }
  });
}

Future<ProviderContainer> _openReview(
  WidgetTester tester,
  Stream<List<QuickEntryCategoryOption>> categories,
) async {
  final container = ProviderContainer(overrides: [
    ocrCaptureProvider.overrideWith(_ReviewController.new),
    quickEntryCategoriesProvider('expense').overrideWith((_) => categories),
  ]);
  final quickEntrySubscription = container.listen(quickEntryFormProvider, (_, __) {});
  final draftSubscription = container.listen(ocrCaptureProvider, (_, __) {});
  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (_, __) => const OcrReviewScreen()),
    GoRoute(
      path: '/quick-entry',
      builder: (_, __) => const Scaffold(body: Text('빠른 입력 화면')),
    ),
  ]);
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    router.dispose();
    draftSubscription.close();
    quickEntrySubscription.close();
    container.dispose();
  });
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(routerConfig: router),
  ));
  await tester.pumpAndSettle();
  return container;
}

Future<void> _continueFromReview(WidgetTester tester) async {
  final continueButton = find.textContaining('빠른 입력으로 이동');
  await tester.scrollUntilVisible(
    continueButton,
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(continueButton);
  await tester.pump();
}

void _testAndroidWidgets(String description, WidgetTesterCallback callback) {
  testWidgets(description, (tester) async {
    final oldPlatform = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      await callback(tester);
    } finally {
      debugDefaultTargetPlatformOverride = oldPlatform;
    }
  });
}
