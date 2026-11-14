import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet_app/core/database/app_database.dart';
import 'package:smart_wallet_app/core/database/providers/database_providers.dart';
import 'package:smart_wallet_app/features/ocr/application/ocr_capture_provider.dart';
import 'package:smart_wallet_app/features/ocr/data/ocr_draft_repository.dart';
import 'package:smart_wallet_app/features/ocr/data/ocr_image_store.dart';
import 'package:smart_wallet_app/features/ocr/data/ocr_service.dart';

import '../../../test_support/sqlite_test_setup.dart';

class _FakeImageStore extends OcrImageStore {
  @override
  Future<String> importCapturedImage(
    String sourcePath, {
    bool fromCameraCapture = false,
  }) async => sourcePath;

  @override
  Future<String?> validateOwnedPath(String? imagePath) async =>
      imagePath != null && await File(imagePath).exists() ? imagePath : null;

  @override
  Future<void> deleteOwnedImage(String? imagePath) async {
    if (imagePath != null && await File(imagePath).exists()) {
      await File(imagePath).delete();
    }
  }
}

class _FakeOcrService extends OcrService {
  _FakeOcrService({
    required this.capturePath,
    this.rawText = 'Store\nTotal 12,000',
  });

  final String capturePath;
  final String rawText;

  @override
  Future<String> captureReceipt() async => capturePath;

  @override
  Future<OcrExtractedText> extractText(String imagePath) async =>
      OcrExtractedText(
        rawText: rawText,
        confidence: 0.8,
      );
}

class _RetryFailsOcrService extends _FakeOcrService {
  _RetryFailsOcrService({required super.capturePath});

  var extractionCount = 0;

  @override
  Future<OcrExtractedText> extractText(String imagePath) {
    extractionCount++;
    if (extractionCount > 1) {
      throw const OcrCaptureException('읽지 못했어요. 직접 입력해 주세요.');
    }
    return super.extractText(imagePath);
  }
}

class _DelayedRestoreRepository extends OcrDraftRepository {
  _DelayedRestoreRepository(AppDatabase database) : super(database);

  final gate = Completer<void>();

  @override
  Stream<OcrDraft?> watchLatestDraft() async* {
    final previous = await super.watchLatestDraft().first;
    await gate.future;
    yield previous;
  }
}

class _DelayedWriteRepository extends OcrDraftRepository {
  _DelayedWriteRepository(AppDatabase database) : super(database);

  bool blockNext = false;
  final started = Completer<void>();
  final gate = Completer<void>();

  @override
  Future<void> updateDraft({
    required String localId,
    required String status,
    String? imagePath,
    String? rawText,
    double? confidence,
    String? storeName,
    int? amount,
    String? categoryGuess,
    String? errorMessage,
  }) async {
    if (blockNext) {
      blockNext = false;
      started.complete();
      await gate.future;
    }
    await super.updateDraft(
      localId: localId,
      status: status,
      imagePath: imagePath,
      rawText: rawText,
      confidence: confidence,
      storeName: storeName,
      amount: amount,
      categoryGuess: categoryGuess,
      errorMessage: errorMessage,
    );
  }
}

void main() {
  late AppDatabase database;
  ProviderContainer? container;

  setUpAll(() {
    configureSqliteForTests();
  });

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    container?.dispose();
    await database.close();
  });

  test('reset deletes the captured receipt image', () async {
    final tempDir = await Directory.systemTemp.createTemp('ocr_capture_reset');
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final imageFile = File('${tempDir.path}\\receipt.jpg');
    await imageFile.writeAsString('receipt-image', flush: true);

    container = ProviderContainer(
      overrides: [
      ocrImageStoreProvider.overrideWithValue(_FakeImageStore()),
        appDatabaseProvider.overrideWithValue(database),
        ocrServiceProvider.overrideWithValue(
          _FakeOcrService(capturePath: imageFile.path),
        ),
      ],
    );

    final notifier = container!.read(ocrCaptureProvider.notifier);
    await notifier.simulateCapture();

    expect(imageFile.existsSync(), isTrue);

    await notifier.reset();

    expect(imageFile.existsSync(), isFalse);
    expect(container!.read(ocrCaptureProvider).imagePath, isNull);
  });

  test('disposing the provider deletes the last captured receipt image', () async {
    final tempDir = await Directory.systemTemp.createTemp('ocr_capture_dispose');
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final imageFile = File('${tempDir.path}\\receipt.jpg');
    await imageFile.writeAsString('receipt-image', flush: true);

    container = ProviderContainer(
      overrides: [
      ocrImageStoreProvider.overrideWithValue(_FakeImageStore()),
        appDatabaseProvider.overrideWithValue(database),
        ocrServiceProvider.overrideWithValue(
          _FakeOcrService(capturePath: imageFile.path),
        ),
      ],
    );

    await container!.read(ocrCaptureProvider.notifier).simulateCapture();

    expect(imageFile.existsSync(), isTrue);

    container!.dispose();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(imageFile.existsSync(), isFalse);
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
    );
  });

  test('합계가 불확실해도 원문과 직접 수정한 내용이 저장된다', () async {
    const rawText = '동네마트\n전화 02-1234-5678\n승인번호 87654321';
    container = ProviderContainer(
      overrides: [
      ocrImageStoreProvider.overrideWithValue(_FakeImageStore()),
        appDatabaseProvider.overrideWithValue(database),
        ocrServiceProvider.overrideWithValue(
          _FakeOcrService(capturePath: 'receipt.jpg', rawText: rawText),
        ),
      ],
    );
    final subscription = container!.listen(ocrCaptureProvider, (_, __) {});
    final notifier = container!.read(ocrCaptureProvider.notifier);

    await notifier.runCaptureFlow();
    var draft = container!.read(ocrCaptureProvider);
    expect(draft.status, OcrFlowStatus.reviewRequired);
    expect(draft.rawText, rawText);
    expect(draft.storeName, '동네마트');
    expect(draft.amount, isNull);
    expect(draft.canContinueToQuickEntry, isFalse);
    expect(draft.errorMessage, isNotNull);

    final saved = await notifier.saveReviewEdits(
      rawText: '$rawText\n수정 메모',
      storeName: '동네마트 지점',
      amountText: '18,000',
      categoryGuess: 'expense-groceries',
    );
    expect(saved, isTrue);
    draft = container!.read(ocrCaptureProvider);
    expect(draft.rawText, '$rawText\n수정 메모');
    expect(draft.storeName, '동네마트 지점');
    expect(draft.amount, 18000);
    expect(draft.categoryGuess, 'expense-groceries');

    final stored = await database.select(database.ocrDrafts).getSingle();
    expect(stored.ocrRawText, '$rawText\n수정 메모');
    expect(stored.parsedStoreName, '동네마트 지점');
    expect(stored.parsedTotalAmount, 18000);
    subscription.close();
  });

  test('미리보기에서 촬영한 사진으로 OCR 초안을 만든다', () async {
    final tempDir = await Directory.systemTemp.createTemp('ocr_preview_capture');
    addTearDown(() => tempDir.delete(recursive: true));
    final previewPath = '${tempDir.path}/preview.jpg';
    container = ProviderContainer(
      overrides: [
      ocrImageStoreProvider.overrideWithValue(_FakeImageStore()),
        appDatabaseProvider.overrideWithValue(database),
        ocrServiceProvider.overrideWithValue(
          _FakeOcrService(capturePath: '${tempDir.path}/other.jpg'),
        ),
      ],
    );
    final subscription = container!.listen(ocrCaptureProvider, (_, __) {});

    await container!.read(ocrCaptureProvider.notifier).runCaptureFlow(
          captureImage: () async => previewPath,
        );

    final draft = container!.read(ocrCaptureProvider);
    expect(draft.imagePath, previewPath);
    expect(draft.rawText, 'Store\nTotal 12,000');
    expect(draft.amount, 12000);
    expect(draft.status, OcrFlowStatus.reviewRequired);
    subscription.close();
  });

  test('OCR 재시도가 실패해도 기존 원문과 수동 수정값을 보존한다', () async {
    final tempDir = await Directory.systemTemp.createTemp('ocr_retry_failure');
    addTearDown(() => tempDir.delete(recursive: true));
    container = ProviderContainer(
      overrides: [
      ocrImageStoreProvider.overrideWithValue(_FakeImageStore()),
        appDatabaseProvider.overrideWithValue(database),
        ocrServiceProvider.overrideWithValue(
          _RetryFailsOcrService(capturePath: '${tempDir.path}/receipt.jpg'),
        ),
      ],
    );
    final subscription = container!.listen(ocrCaptureProvider, (_, __) {});
    final notifier = container!.read(ocrCaptureProvider.notifier);
    await notifier.runCaptureFlow();
    await notifier.saveReviewEdits(
      rawText: '수정한 영수증 텍스트',
      storeName: '수정한 상호',
      amountText: '13000',
      categoryGuess: 'expense-food',
    );

    await notifier.retryFromCapturedImage();

    final draft = container!.read(ocrCaptureProvider);
    expect(draft.status, OcrFlowStatus.failed);
    expect(draft.rawText, '수정한 영수증 텍스트');
    expect(draft.storeName, '수정한 상호');
    expect(draft.amount, 13000);
    expect(draft.categoryGuess, 'expense-food');
    expect(draft.errorMessage, contains('직접 입력'));
    final stored = await database.select(database.ocrDrafts).getSingle();
    expect(stored.ocrRawText, '수정한 영수증 텍스트');
    expect(stored.parsedTotalAmount, 13000);
    subscription.close();
  });

  test('화면 이탈과 provider 재생성 뒤에도 수정 중인 원문과 금액을 복원한다', () async {
    final tempDir = await Directory.systemTemp.createTemp('ocr_review_restore');
    addTearDown(() => tempDir.delete(recursive: true));
    container = ProviderContainer(overrides: [
      ocrImageStoreProvider.overrideWithValue(_FakeImageStore()),
      appDatabaseProvider.overrideWithValue(database),
      ocrServiceProvider.overrideWithValue(
        _FakeOcrService(capturePath: '${tempDir.path}/receipt.jpg'),
      ),
    ]);
    final first = container!.read(ocrCaptureProvider.notifier);
    await first.waitForRestoration();
    await first.runCaptureFlow();

    first.updateReviewEdits(
      rawText: '원문 수정 중\n둘째 줄',
      storeName: '수정한 상호',
      amountText: '12,',
      categoryGuess: '직접 적은 분류',
    );
    expect(container!.read(ocrCaptureProvider).rawText, '원문 수정 중\n둘째 줄');
    expect(container!.read(ocrCaptureProvider).amountText, '12,');
    await first.flushPendingWrites();
    container!.dispose();

    container = ProviderContainer(overrides: [
      ocrImageStoreProvider.overrideWithValue(_FakeImageStore()),
      appDatabaseProvider.overrideWithValue(database),
    ]);
    final restored = container!.read(ocrCaptureProvider.notifier);
    await restored.waitForRestoration();
    final draft = container!.read(ocrCaptureProvider);
    expect(draft.rawText, '원문 수정 중\n둘째 줄');
    expect(draft.storeName, '수정한 상호');
    expect(draft.amountText, '12,');
    expect(draft.categoryGuess, '직접 적은 분류');
  });

  test('초안을 삭제한 뒤에는 provider를 다시 만들어도 복원하지 않는다', () async {
    container = ProviderContainer(overrides: [
      ocrImageStoreProvider.overrideWithValue(_FakeImageStore()),
      appDatabaseProvider.overrideWithValue(database),
      ocrServiceProvider.overrideWithValue(_FakeOcrService(capturePath: 'missing.jpg')),
    ]);
    final first = container!.read(ocrCaptureProvider.notifier);
    await first.waitForRestoration();
    await first.runCaptureFlow();
    await first.reset();
    container!.dispose();

    container = ProviderContainer(overrides: [appDatabaseProvider.overrideWithValue(database)]);
    final restored = container!.read(ocrCaptureProvider.notifier);
    await restored.waitForRestoration();
    expect(container!.read(ocrCaptureProvider).status, OcrFlowStatus.idle);
    expect(container!.read(ocrCaptureProvider).rawText, isEmpty);
  });

  test('늦게 도착한 복원 결과가 그동안 수정한 내용을 덮지 않는다', () async {
    final normal = OcrDraftRepository(database);
    await normal.createDraft(status: 'reviewRequired', rawText: '이전 원문');
    final delayed = _DelayedRestoreRepository(database);
    container = ProviderContainer(overrides: [
      ocrImageStoreProvider.overrideWithValue(_FakeImageStore()),
      appDatabaseProvider.overrideWithValue(database),
      ocrDraftRepositoryProvider.overrideWithValue(delayed),
    ]);
    final notifier = container!.read(ocrCaptureProvider.notifier);
    notifier.updateReviewEdits(
      rawText: '새로 수정한 원문',
      storeName: '새 상호',
      amountText: '12000',
      categoryGuess: '',
    );
    delayed.gate.complete();
    await notifier.waitForRestoration();
    await notifier.flushPendingWrites();
    expect(container!.read(ocrCaptureProvider).rawText, '새로 수정한 원문');
    expect(container!.read(ocrCaptureProvider).storeName, '새 상호');
  });

  test('느린 이전 저장이 나중에 입력한 내용을 덮지 않는다', () async {
    final delayed = _DelayedWriteRepository(database);
    container = ProviderContainer(overrides: [
      ocrImageStoreProvider.overrideWithValue(_FakeImageStore()),
      appDatabaseProvider.overrideWithValue(database),
      ocrDraftRepositoryProvider.overrideWithValue(delayed),
      ocrServiceProvider.overrideWithValue(_FakeOcrService(capturePath: 'missing.jpg')),
    ]);
    final notifier = container!.read(ocrCaptureProvider.notifier);
    await notifier.waitForRestoration();
    await notifier.runCaptureFlow();
    delayed.blockNext = true;
    notifier.updateReviewEdits(
      rawText: '이전 입력', storeName: '상호', amountText: '10', categoryGuess: '',
    );
    await delayed.started.future;
    notifier.updateReviewEdits(
      rawText: '마지막 입력', storeName: '상호', amountText: '200', categoryGuess: '',
    );
    delayed.gate.complete();
    await notifier.flushPendingWrites();

    final saved = await database.select(database.ocrDrafts).getSingle();
    expect(saved.ocrRawText, '마지막 입력');
    expect(saved.parsedTotalAmount, 200);
  });

  test('백업 복원으로 초안 행이 사라지면 저장 실패를 표시하고 편집 내용을 유지한다', () async {
    container = ProviderContainer(overrides: [
      ocrImageStoreProvider.overrideWithValue(_FakeImageStore()),
      appDatabaseProvider.overrideWithValue(database),
      ocrServiceProvider.overrideWithValue(_FakeOcrService(capturePath: 'missing.jpg')),
    ]);
    final notifier = container!.read(ocrCaptureProvider.notifier);
    await notifier.waitForRestoration();
    await notifier.runCaptureFlow();
    await database.delete(database.ocrDrafts).go();

    notifier.updateReviewEdits(
      rawText: '복원 후 수정', storeName: '상호', amountText: '12000', categoryGuess: '',
    );
    await expectLater(notifier.flushPendingWrites(), throwsA(isA<OcrDraftMissingException>()));
    await Future<void>.delayed(Duration.zero);

    final draft = container!.read(ocrCaptureProvider);
    expect(draft.rawText, '복원 후 수정');
    expect(draft.amount, 12000);
    expect(draft.errorMessage, contains('초안을 찾지 못'));
  });

  test('백업의 외부 파일 경로는 복원하지 않고 reset이나 해제 시 삭제하지 않는다', () async {
    final temp = await Directory.systemTemp.createTemp('ocr_untrusted_backup');
    addTearDown(() => temp.delete(recursive: true));
    final important = File('${temp.path}/smart_wallet.sqlite');
    await important.writeAsString('important');
    final repository = OcrDraftRepository(database);
    final imageStore = OcrImageStore(cacheDirectory: () async => temp);

    await repository.createDraft(
      status: 'reviewRequired', imagePath: important.path, rawText: '복구할 텍스트',
    );
    container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(database),
      ocrImageStoreProvider.overrideWithValue(imageStore),
    ]);
    final first = container!.read(ocrCaptureProvider.notifier);
    await first.waitForRestoration();
    expect(container!.read(ocrCaptureProvider).rawText, '복구할 텍스트');
    expect(container!.read(ocrCaptureProvider).imagePath, isNull);
    await first.reset();
    expect(await important.readAsString(), 'important');
    container!.dispose();

    await repository.createDraft(
      status: 'reviewRequired', imagePath: important.path, rawText: '두 번째 텍스트',
    );
    container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(database),
      ocrImageStoreProvider.overrideWithValue(imageStore),
    ]);
    final second = container!.read(ocrCaptureProvider.notifier);
    await second.waitForRestoration();
    expect(container!.read(ocrCaptureProvider).imagePath, isNull);
    container!.dispose();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(await important.readAsString(), 'important');
    container = null;
  });
}
