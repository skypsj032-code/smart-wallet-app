import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/ocr_draft_repository.dart';
import '../data/ocr_image_store.dart';
import '../data/ocr_service.dart';

const _ocrDraftUnset = Object();

enum OcrFlowStatus {
  idle,
  capturing,
  extracted,
  parsed,
  reviewRequired,
  failed,
}

class OcrDraftState {
  const OcrDraftState({
    this.localId,
    this.status = OcrFlowStatus.idle,
    this.imagePath,
    this.rawText = '',
    this.confidence,
    this.storeName,
    this.amount,
    this.amountText,
    this.categoryGuess,
    this.errorMessage,
    this.isRestoring = false,
  });

  final String? localId;
  final OcrFlowStatus status;
  final String? imagePath;
  final String rawText;
  final double? confidence;
  final String? storeName;
  final int? amount;
  final String? amountText;
  final String? categoryGuess;
  final String? errorMessage;
  final bool isRestoring;

  bool get hasImage => imagePath?.trim().isNotEmpty ?? false;

  bool get hasRawText => rawText.trim().isNotEmpty;

  bool get hasParsedStoreName => storeName?.trim().isNotEmpty ?? false;

  bool get hasParsedAmount => amount != null && amount! > 0;

  bool get canContinueToQuickEntry => hasParsedAmount;

  OcrDraftState copyWith({
    Object? localId = _ocrDraftUnset,
    OcrFlowStatus? status,
    Object? imagePath = _ocrDraftUnset,
    String? rawText,
    Object? confidence = _ocrDraftUnset,
    Object? storeName = _ocrDraftUnset,
    Object? amount = _ocrDraftUnset,
    Object? amountText = _ocrDraftUnset,
    Object? categoryGuess = _ocrDraftUnset,
    Object? errorMessage = _ocrDraftUnset,
    bool? isRestoring,
  }) {
    return OcrDraftState(
      localId: identical(localId, _ocrDraftUnset) ? this.localId : localId as String?,
      status: status ?? this.status,
      imagePath: identical(imagePath, _ocrDraftUnset) ? this.imagePath : imagePath as String?,
      rawText: rawText ?? this.rawText,
      confidence: identical(confidence, _ocrDraftUnset)
          ? this.confidence
          : confidence as double?,
      storeName:
          identical(storeName, _ocrDraftUnset) ? this.storeName : storeName as String?,
      amount: identical(amount, _ocrDraftUnset) ? this.amount : amount as int?,
      amountText: identical(amountText, _ocrDraftUnset) ? this.amountText : amountText as String?,
      categoryGuess: identical(categoryGuess, _ocrDraftUnset)
          ? this.categoryGuess
          : categoryGuess as String?,
      errorMessage: identical(errorMessage, _ocrDraftUnset)
          ? this.errorMessage
          : errorMessage as String?,
      isRestoring: isRestoring ?? this.isRestoring,
    );
  }
}

class OcrCaptureController extends AutoDisposeNotifier<OcrDraftState> {
  String? _trackedImagePath;
  late OcrImageStore _imageStore;
  String? _storedDraftId;
  void Function()? _releaseDraft;
  bool _disposed = false;
  int _editRevision = 0;
  late Future<void> _restoration;
  Future<void> _writeTail = Future<void>.value();
  Future<void> _lastWrite = Future<void>.value();

  @override
  OcrDraftState build() {
    _imageStore = ref.read(ocrImageStoreProvider);
    final restoreLease = ref.keepAlive();
    final restoreRevision = _editRevision;
    ref.onDispose(() {
      _disposed = true;
      final imagePath = _trackedImagePath;
      _trackedImagePath = null;
      unawaited(_deleteCapturedImage(imagePath));
    });
    _restoration = Future<void>.microtask(() async {
      try {
        final saved = await ref.read(ocrDraftRepositoryProvider).watchLatestDraft().first;
        if (_disposed || _editRevision != restoreRevision ||
            saved == null || saved.ocrStatus == 'discarded') return;
        final storedPath = saved.sourceImagePath;
        String? safePath;
        if (storedPath != null) {
          try {
            safePath = await _imageStore.validateOwnedPath(storedPath);
          } catch (error, stackTrace) {
            debugPrint('Ignoring unavailable OCR image: $error\n$stackTrace');
          }
        }
        if (_disposed || _editRevision != restoreRevision) return;
        final metadata = OcrReviewMetadata.decode(saved.errorMessage);
        var status = OcrFlowStatus.values.firstWhere(
          (item) => item.name == saved.ocrStatus,
          orElse: () => OcrFlowStatus.reviewRequired,
        );
        if (status == OcrFlowStatus.capturing || status == OcrFlowStatus.parsed) {
          status = OcrFlowStatus.reviewRequired;
        }
        _storedDraftId = saved.localId;
        _trackedImagePath = safePath;
        _retainDraft();
        state = OcrDraftState(
          localId: saved.localId,
          status: status,
          imagePath: safePath,
          rawText: saved.ocrRawText ?? '',
          confidence: saved.ocrConfidence,
          storeName: saved.parsedStoreName,
          amount: saved.parsedTotalAmount,
          amountText: metadata.amountText,
          categoryGuess: saved.parsedCategoryGuess,
          errorMessage: metadata.errorMessage,
          isRestoring: false,
        );
      } catch (error, stackTrace) {
        debugPrint('Restoring the OCR draft failed: $error\n$stackTrace');
        if (!_disposed) {
          state = state.copyWith(errorMessage: '저장된 영수증 초안을 불러오지 못했어요.');
        }
      } finally {
        if (!_disposed && state.isRestoring) {
          state = state.copyWith(isRestoring: false);
        }
        restoreLease.close();
      }
    });
    return const OcrDraftState(isRestoring: true);
  }

  void _retainDraft() {
    if (_releaseDraft != null) return;
    final lease = ref.keepAlive();
    _releaseDraft = lease.close;
  }

  Future<void> waitForRestoration() => _restoration;

  Future<void> flushPendingWrites() => _lastWrite;

  Future<void> runCaptureFlow({Future<String> Function()? captureImage}) async {
    await simulateCapture(captureImage: captureImage);
    if (state.status == OcrFlowStatus.failed) {
      return;
    }

    await simulateExtract();
    if (state.status == OcrFlowStatus.failed) {
      return;
    }

    await simulateParse();
  }

  Future<void> simulateCapture({Future<String> Function()? captureImage}) async {
    _retainDraft();
    await waitForRestoration();
    try {
      await flushPendingWrites();
    } catch (_) {
      if (!_disposed) {
        state = state.copyWith(
          status: OcrFlowStatus.failed,
          errorMessage: '수정 내용을 저장하지 못했어요. 다시 시도해 주세요.',
        );
      }
      return;
    }
    final previousImagePath = state.imagePath;
    state = state.copyWith(status: OcrFlowStatus.capturing, errorMessage: null);

    String? newlyOwnedImage;
    try {
      final capturedPath = captureImage == null
          ? await ref.read(ocrServiceProvider).captureReceipt()
          : await captureImage();
      final imagePath = await _imageStore.importCapturedImage(
        capturedPath,
        fromCameraCapture: true,
      );
      newlyOwnedImage = imagePath;
      final id = await ref.read(ocrDraftRepositoryProvider).createDraft(
            status: OcrFlowStatus.capturing.name,
            imagePath: imagePath,
          );
      _storedDraftId = id;

      state = OcrDraftState(
        localId: id,
        status: OcrFlowStatus.capturing,
        imagePath: imagePath,
      );
      _trackedImagePath = imagePath;
      newlyOwnedImage = null;
      if (previousImagePath != null && previousImagePath != imagePath) {
        await _deleteCapturedImage(previousImagePath);
      }
    } catch (error) {
      if (newlyOwnedImage != null) await _deleteCapturedImage(newlyOwnedImage);
      await fail('Could not capture the receipt. $error');
    }
  }

  Future<void> simulateExtract() async {
    await waitForRestoration();
    if (state.localId == null) {
      await simulateCapture();
    }

    if (state.localId == null || state.imagePath == null) {
      await fail('There is no captured image to run OCR on.');
      return;
    }

    state = state.copyWith(
      status: OcrFlowStatus.capturing,
      errorMessage: null,
    );

    try {
      final extracted = await ref.read(ocrServiceProvider).extractText(state.imagePath!);

      state = state.copyWith(
        status: OcrFlowStatus.extracted,
        rawText: extracted.rawText,
        confidence: extracted.confidence,
        storeName: null,
        amount: null,
        amountText: null,
        categoryGuess: null,
        errorMessage: null,
      );

      await _persistState(status: OcrFlowStatus.extracted);
    } on OcrCaptureException catch (error) {
      await fail(error.message);
    } catch (_) {
      await fail('영수증을 읽지 못했어요. 다시 촬영하거나 직접 입력해 주세요.');
    }
  }

  Future<void> simulateParse() async {
    await waitForRestoration();
    if (state.localId == null) {
      await simulateExtract();
    }

    if (state.localId == null || state.rawText.trim().isEmpty) {
      await fail('There is no extracted text to review.');
      return;
    }

    try {
      final parsed = ref.read(ocrServiceProvider).parseText(state.rawText);

      state = state.copyWith(
        status: OcrFlowStatus.reviewRequired,
        storeName: parsed.storeName,
        amount: parsed.amount,
        amountText: null,
        categoryGuess: parsed.categoryGuess,
        errorMessage: parsed.amount == null
            ? '결제금액을 확실히 찾지 못했어요. 영수증을 확인하고 직접 입력해 주세요.'
            : null,
      );

      await _persistState(
        status: OcrFlowStatus.reviewRequired,
        errorMessage: state.errorMessage,
      );
    } catch (error) {
      state = state.copyWith(
        status: OcrFlowStatus.reviewRequired,
        errorMessage: 'OCR found text, but the draft still needs manual correction. $error',
      );
      await _persistState(
        status: OcrFlowStatus.reviewRequired,
        errorMessage: state.errorMessage,
      );
    }
  }

  Future<void> retryFromCapturedImage() async {
    await waitForRestoration();
    if (!state.hasImage) {
      await fail('Capture a receipt image before retrying OCR.');
      return;
    }

    state = state.copyWith(
      status: OcrFlowStatus.capturing,
      errorMessage: null,
    );
    await _persistState(status: OcrFlowStatus.capturing);
    await simulateExtract();
    if (state.status == OcrFlowStatus.failed) {
      return;
    }
    await simulateParse();
  }

  Future<void> refreshSuggestionsFromRawText(String rawText) async {
    await waitForRestoration();
    final normalizedRawText = rawText.trim();
    if (normalizedRawText.isEmpty) {
      state = state.copyWith(
        status: OcrFlowStatus.reviewRequired,
        rawText: '',
        errorMessage: 'OCR 텍스트를 입력하거나 수정한 뒤 다시 시도해 주세요.',
      );
      await _persistState(
        status: OcrFlowStatus.reviewRequired,
        errorMessage: state.errorMessage,
      );
      return;
    }

    state = state.copyWith(
      status: OcrFlowStatus.parsed,
      rawText: normalizedRawText,
      errorMessage: null,
    );

    try {
      final parsed = ref.read(ocrServiceProvider).parseText(normalizedRawText);

      state = state.copyWith(
        status: OcrFlowStatus.reviewRequired,
        storeName: parsed.storeName,
        amount: parsed.amount,
        amountText: null,
        categoryGuess: parsed.categoryGuess,
        errorMessage: parsed.amount == null
            ? '결제금액을 확실히 찾지 못했어요. 영수증을 확인하고 직접 입력해 주세요.'
            : null,
      );
      await _persistState(
        status: OcrFlowStatus.reviewRequired,
        errorMessage: state.errorMessage,
      );
    } catch (error) {
      state = state.copyWith(
        status: OcrFlowStatus.reviewRequired,
        errorMessage: '텍스트로 추천을 만들지 못했어요. 기존 내용을 확인해 주세요.',
      );
      await _persistState(
        status: OcrFlowStatus.reviewRequired,
        errorMessage: state.errorMessage,
      );
    }
  }

  Future<bool> saveReviewEdits({
    required String rawText,
    required String storeName,
    required String amountText,
    required String categoryGuess,
  }) async {
    await waitForRestoration();
    final normalizedRawText = rawText.trim();
    final normalizedStoreName = storeName.trim();
    final normalizedCategoryGuess = categoryGuess.trim();
    final normalizedAmount = _parseAmount(amountText);

    String? validationMessage;
    if (normalizedAmount == null) {
      validationMessage = 'Enter a valid amount before continuing.';
    } else if (normalizedStoreName.isEmpty && normalizedRawText.isEmpty) {
      validationMessage = 'Provide either a merchant name or some OCR text to review.';
    }

    state = state.copyWith(
      status: OcrFlowStatus.reviewRequired,
      rawText: normalizedRawText,
      storeName: normalizedStoreName.isEmpty ? null : normalizedStoreName,
      amount: normalizedAmount,
      amountText: amountText,
      categoryGuess: normalizedCategoryGuess.isEmpty ? null : normalizedCategoryGuess,
      errorMessage: validationMessage,
    );

    try {
      await _persistState(
        status: OcrFlowStatus.reviewRequired,
        errorMessage: validationMessage,
      );
    } catch (error) {
      if (!_disposed) {
        state = state.copyWith(errorMessage: _saveFailureMessage(error));
      }
      return false;
    }

    return validationMessage == null;
  }

  /// Keep the editable text in memory immediately, then serialize DB writes.
  void updateReviewEdits({
    required String rawText,
    required String storeName,
    required String amountText,
    required String categoryGuess,
  }) {
    _editRevision++;
    _retainDraft();
    state = state.copyWith(
      status: OcrFlowStatus.reviewRequired,
      rawText: rawText,
      storeName: storeName,
      amount: _parseAmount(amountText),
      amountText: amountText,
      categoryGuess: categoryGuess,
      errorMessage: null,
    );
    unawaited(_persistState(status: OcrFlowStatus.reviewRequired).catchError(
      (Object error, StackTrace stackTrace) {
        debugPrint('Saving OCR review edits failed: $error\n$stackTrace');
        if (!_disposed) {
          state = state.copyWith(errorMessage: _saveFailureMessage(error));
        }
      },
    ));
  }

  Future<void> fail(String message) async {
    state = state.copyWith(
      status: OcrFlowStatus.failed,
      errorMessage: message,
    );
    await _persistState(
      status: OcrFlowStatus.failed,
      errorMessage: message,
    );
  }

  Future<void> reset() async {
    await waitForRestoration();
    final previousImagePath = _trackedImagePath ?? state.imagePath;
    final previousStatus = state.status;
    state = state.copyWith(status: OcrFlowStatus.capturing);
    try {
      await flushPendingWrites();
      if (state.localId != null || _storedDraftId != null) {
        await _persistState(status: previousStatus, storedStatus: 'discarded');
      }
    } catch (_) {
      if (!_disposed) {
        state = state.copyWith(
          status: previousStatus,
          errorMessage: '초안을 삭제하지 못했어요. 다시 시도해 주세요.',
        );
      }
      return;
    }
    _trackedImagePath = null;
    _storedDraftId = null;
    state = const OcrDraftState();
    await _deleteCapturedImage(previousImagePath);
    _releaseDraft?.call();
    _releaseDraft = null;
  }

  Future<void> _persistState({
    required OcrFlowStatus status,
    String? errorMessage,
    String? storedStatus,
  }) {
    final snapshot = state.copyWith(status: status, errorMessage: errorMessage);
    final repository = ref.read(ocrDraftRepositoryProvider);
    final write = _writeTail.then((_) async {
      await waitForRestoration();
      var id = snapshot.localId ?? _storedDraftId;
      if (id == null) {
        id = await repository.createDraft(status: status.name);
        _storedDraftId = id;
        if (!_disposed && state.localId == null) {
          state = state.copyWith(localId: id);
        }
      }
      final metadata = OcrReviewMetadata(
        amountText: snapshot.amountText,
        errorMessage: snapshot.errorMessage,
      );
      await repository.updateDraft(
        localId: id,
        status: storedStatus ?? status.name,
        imagePath: snapshot.imagePath,
        rawText: snapshot.rawText,
        confidence: snapshot.confidence,
        storeName: snapshot.storeName,
        amount: snapshot.amount,
        categoryGuess: snapshot.categoryGuess,
        errorMessage: metadata.encode(),
      );
    });
    _lastWrite = write;
    _writeTail = write.catchError((Object error, StackTrace stackTrace) {
      debugPrint('Persisting OCR draft failed: $error\n$stackTrace');
    });
    return write;
  }

  int? _parseAmount(String rawValue) {
    final digitsOnly = rawValue.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) {
      return null;
    }

    return int.tryParse(digitsOnly);
  }

  String _saveFailureMessage(Object error) => error is OcrDraftMissingException
      ? '초안을 찾지 못해 저장할 수 없어요. 입력한 내용은 이 화면에 남아 있어요.'
      : '수정 내용을 저장하지 못했어요. 다시 시도해 주세요.';

  Future<void> _deleteCapturedImage(String? imagePath) async {
    await _imageStore.deleteOwnedImage(imagePath);
  }
}

/// An unfinished draft keeps its provider alive and is also stored in the DB.
final ocrCaptureProvider =
    NotifierProvider.autoDispose<OcrCaptureController, OcrDraftState>(
  OcrCaptureController.new,
);
