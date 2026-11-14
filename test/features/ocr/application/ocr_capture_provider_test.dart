import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet_app/core/database/app_database.dart';
import 'package:smart_wallet_app/core/database/providers/database_providers.dart';
import 'package:smart_wallet_app/features/ocr/application/ocr_capture_provider.dart';
import 'package:smart_wallet_app/features/ocr/data/ocr_service.dart';

import '../../../test_support/sqlite_test_setup.dart';

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
}
