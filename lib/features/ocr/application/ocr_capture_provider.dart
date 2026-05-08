import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/ocr_draft_repository.dart';
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
    this.categoryGuess,
    this.errorMessage,
  });

  final String? localId;
  final OcrFlowStatus status;
  final String? imagePath;
  final String rawText;
  final double? confidence;
  final String? storeName;
  final int? amount;
  final String? categoryGuess;
  final String? errorMessage;

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
    Object? categoryGuess = _ocrDraftUnset,
    Object? errorMessage = _ocrDraftUnset,
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
      categoryGuess: identical(categoryGuess, _ocrDraftUnset)
          ? this.categoryGuess
          : categoryGuess as String?,
      errorMessage: identical(errorMessage, _ocrDraftUnset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

class OcrCaptureController extends AutoDisposeNotifier<OcrDraftState> {
  @override
  OcrDraftState build() => const OcrDraftState();

  Future<void> runCaptureFlow() async {
    await simulateCapture();
    if (state.status == OcrFlowStatus.failed) {
      return;
    }

    await simulateExtract();
    if (state.status == OcrFlowStatus.failed) {
      return;
    }

    await simulateParse();
  }

  Future<void> simulateCapture() async {
    state = const OcrDraftState(status: OcrFlowStatus.capturing);

    try {
      final imagePath = await ref.read(ocrServiceProvider).captureReceipt();
      final id = await ref.read(ocrDraftRepositoryProvider).createDraft(
            status: OcrFlowStatus.capturing.name,
            imagePath: imagePath,
          );

      state = OcrDraftState(
        localId: id,
        status: OcrFlowStatus.capturing,
        imagePath: imagePath,
      );
    } catch (error) {
      await fail('Could not capture the receipt. $error');
    }
  }

  Future<void> simulateExtract() async {
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
        categoryGuess: null,
        errorMessage: null,
      );

      await _persistState(status: OcrFlowStatus.extracted);
    } catch (error) {
      await fail('Text extraction failed. $error');
    }
  }

  Future<void> simulateParse() async {
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
        categoryGuess: parsed.categoryGuess,
        errorMessage: null,
      );

      await _persistState(status: OcrFlowStatus.reviewRequired);
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
    if (!state.hasImage) {
      await fail('Capture a receipt image before retrying OCR.');
      return;
    }

    state = state.copyWith(
      status: OcrFlowStatus.capturing,
      rawText: '',
      confidence: null,
      storeName: null,
      amount: null,
      categoryGuess: null,
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
    final normalizedRawText = rawText.trim();
    if (normalizedRawText.isEmpty) {
      state = state.copyWith(
        status: OcrFlowStatus.reviewRequired,
        rawText: '',
        storeName: null,
        amount: null,
        categoryGuess: null,
        errorMessage: 'Paste or edit the OCR text first, then try again.',
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
        categoryGuess: parsed.categoryGuess,
        errorMessage: null,
      );
      await _persistState(status: OcrFlowStatus.reviewRequired);
    } catch (error) {
      state = state.copyWith(
        status: OcrFlowStatus.reviewRequired,
        storeName: null,
        amount: null,
        categoryGuess: null,
        errorMessage: 'The text was updated, but the suggestion still needs manual fixes. $error',
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
      categoryGuess: normalizedCategoryGuess.isEmpty ? null : normalizedCategoryGuess,
      errorMessage: validationMessage,
    );

    await _persistState(
      status: OcrFlowStatus.reviewRequired,
      errorMessage: validationMessage,
    );

    return validationMessage == null;
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

  void reset() {
    state = const OcrDraftState();
  }

  Future<void> _persistState({
    required OcrFlowStatus status,
    String? errorMessage,
  }) async {
    if (state.localId == null) {
      return;
    }

    await ref.read(ocrDraftRepositoryProvider).updateDraft(
          localId: state.localId!,
          status: status.name,
          imagePath: state.imagePath,
          rawText: state.rawText,
          confidence: state.confidence,
          storeName: state.storeName,
          amount: state.amount,
          categoryGuess: state.categoryGuess,
          errorMessage: errorMessage,
        );
  }

  int? _parseAmount(String rawValue) {
    final digitsOnly = rawValue.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) {
      return null;
    }

    return int.tryParse(digitsOnly);
  }
}

/// OCR 화면 종료 시 draft 상태 자동 해제 (DB에 이미 영속화되므로 안전).
final ocrCaptureProvider =
    NotifierProvider.autoDispose<OcrCaptureController, OcrDraftState>(
  OcrCaptureController.new,
);
