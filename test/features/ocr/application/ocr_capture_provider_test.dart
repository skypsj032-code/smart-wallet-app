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
  _FakeOcrService({required this.capturePath});

  final String capturePath;

  @override
  Future<String> captureReceipt() async => capturePath;

  @override
  Future<OcrExtractedText> extractText(String imagePath) async =>
      const OcrExtractedText(
        rawText: 'Store\nTotal 12,000',
        confidence: 0.8,
      );
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
}
