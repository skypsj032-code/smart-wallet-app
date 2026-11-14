import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wallet_app/features/ocr/application/ocr_capture_provider.dart';
import 'package:smart_wallet_app/features/ocr/presentation/ocr_review_screen.dart';
import 'package:smart_wallet_app/features/transactions/application/quick_entry_form_provider.dart';
import 'package:smart_wallet_app/features/transactions/application/quick_entry_options_provider.dart';

class _ReviewController extends OcrCaptureController {
  @override
  OcrDraftState build() => const OcrDraftState(
        status: OcrFlowStatus.reviewRequired,
        rawText: '동네마트\n결제금액 12,000원',
        confidence: 0.8, // 기존 초안에 저장되어 있을 수 있는 값
        storeName: '동네마트',
        amount: 12000,
        categoryGuess: 'expense-groceries',
      );
}

void main() {
  testWidgets('기존 초안에도 검증되지 않은 인식률이나 신뢰도를 표시하지 않는다',
      (tester) async {
    final oldPlatform = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = oldPlatform);

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

  testWidgets('추천을 다시 만들기 전 수정 중인 상호가 덮어써질 수 있음을 알린다',
      (tester) async {
    final oldPlatform = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = oldPlatform);

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
    expect(find.textContaining('저장하지 않은 상호명'), findsOneWidget);
    await tester.tap(find.text('계속 수정하기'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.widgetWithText(TextField, '상호명'),
      -300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('수정 중인 상호'), findsOneWidget);
  });

  testWidgets('변경하지 않은 추천은 이름이 바뀌어도 활성 카테고리 ID로 전달한다',
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

  testWidgets('수동으로 적은 이름이 활성 카테고리와 일치하면 실제 ID를 전달한다',
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

  testWidgets('추천과 일치하는 활성 카테고리가 없으면 임의의 ID를 넘기지 않는다',
      (tester) async {
    final container = await _openReview(tester, Stream.value(const []));

    await _continueFromReview(tester);
    await tester.pumpAndSettle();

    expect(find.text('빠른 입력 화면'), findsOneWidget);
    expect(container.read(quickEntryFormProvider).categoryId, isNull);
  });

  testWidgets('카테고리 목록을 불러오지 못해도 직접 입력으로 계속할 수 있다',
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

  testWidgets('카테고리 목록을 기다리는 동안 직접 선택한 값은 덮어쓰지 않는다',
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

    expect(find.text('빠른 입력 화면'), findsOneWidget);
    expect(container.read(quickEntryFormProvider).categoryId, 'manual-choice');
  });
}

Future<ProviderContainer> _openReview(
  WidgetTester tester,
  Stream<List<QuickEntryCategoryOption>> categories,
) async {
  final oldPlatform = debugDefaultTargetPlatformOverride;
  debugDefaultTargetPlatformOverride = TargetPlatform.android;
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
    debugDefaultTargetPlatformOverride = oldPlatform;
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
