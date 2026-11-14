import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrCaptureException implements Exception {
  const OcrCaptureException(this.message);

  final String message;

  @override
  String toString() => message;
}

class OcrExtractedText {
  const OcrExtractedText({
    required this.rawText,
    this.confidence,
  });

  final String rawText;
  final double? confidence;
}

class ParsedOcrDraft {
  const ParsedOcrDraft({
    required this.storeName,
    required this.amount,
    required this.categoryGuess,
  });

  final String storeName;
  final int? amount;
  final String categoryGuess;
}

class OcrService {
  Future<String> captureReceipt() async {
    if (!_supportsNativeOcr()) {
      throw const OcrCaptureException(
        'Receipt OCR capture is only available on Android and iOS devices.',
      );
    }

    late final List<CameraDescription> cameras;

    try {
      cameras = await availableCameras();
    } catch (error, stackTrace) {
      debugPrint('Loading cameras failed: $error\n$stackTrace');
      throw const OcrCaptureException(
        'Could not load the camera list. Check the camera permission and device state.',
      );
    }

    if (cameras.isEmpty) {
      throw const OcrCaptureException('No available camera was found on this device.');
    }

    final camera = cameras.firstWhere(
      (item) => item.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );
    final controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await controller.initialize();
      final file = await controller.takePicture();
      return file.path;
    } on CameraException catch (error) {
      throw OcrCaptureException(
        'The camera could not capture the receipt. ${error.description ?? error.code}',
      );
    } finally {
      await controller.dispose();
    }
  }

  Future<OcrExtractedText> extractText(String imagePath) async {
    if (!_supportsNativeOcr()) {
      throw const OcrCaptureException(
        'Receipt OCR text extraction is only available on Android and iOS devices.',
      );
    }

    // Android already bundles ML Kit's Korean model. Keep the existing iOS
    // recognizer until its Korean model has also been configured and tested.
    final script = defaultTargetPlatform == TargetPlatform.android
        ? TextRecognitionScript.korean
        : TextRecognitionScript.latin;
    final recognizer = TextRecognizer(script: script);

    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognized = await recognizer.processImage(inputImage);
      final rawText = recognized.text.trim();

      if (rawText.isEmpty) {
        throw const OcrCaptureException(
          '읽을 수 있는 글자를 찾지 못했어요. 다시 촬영하거나 직접 입력해 주세요.',
        );
      }

      // ML Kit does not provide a reliable receipt-level accuracy score here.
      return OcrExtractedText(rawText: rawText);
    } on OcrCaptureException {
      rethrow;
    } catch (error, stackTrace) {
      debugPrint('OCR text extraction failed: $error\n$stackTrace');
      throw const OcrCaptureException(
        '영수증을 읽지 못했어요. 다시 촬영하거나 직접 입력해 주세요.',
      );
    } finally {
      try {
        await recognizer.close();
      } catch (error, stackTrace) {
        debugPrint('Closing the OCR recognizer failed: $error\n$stackTrace');
      }
    }
  }

  ParsedOcrDraft parseText(String rawText) {
    final lines = rawText
        .split(RegExp(r'\r?\n'))
        .map(_normalizeLine)
        .where((line) => line.isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      throw const OcrCaptureException(
        'There is no OCR text to parse. Add manual details instead.',
      );
    }

    final storeName = _pickStoreName(lines);
    final amount = _pickAmount(lines);
    final categoryGuess = _guessCategory(rawText, storeName);

    return ParsedOcrDraft(
      storeName: storeName,
      amount: amount,
      categoryGuess: categoryGuess,
    );
  }

  String _normalizeLine(String line) {
    return line.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _pickStoreName(List<String> lines) {
    for (final line in lines) {
      final lowerLine = line.toLowerCase();
      if (_looksLikeNoise(lowerLine)) {
        continue;
      }

      return line;
    }

    return lines.first;
  }

  bool _looksLikeNoise(String lowerLine) {
    return lowerLine.startsWith('tel') ||
        lowerLine.startsWith('fax') ||
        RegExp(r'^(?:전화|팩스|사업자|주소|영수증|카드\s*영수증|신용카드\s*매출전표|고객용)')
            .hasMatch(lowerLine) ||
        lowerLine.contains('approval') ||
        lowerLine.contains('승인') ||
        lowerLine.contains('합계') ||
        lowerLine.contains('total') ||
        lowerLine.contains('amount') ||
        lowerLine.contains('vat') ||
        lowerLine.contains('card') ||
        lowerLine.contains('cash') ||
        RegExp(r'^[\d\s,.:;()\[\]#*/+%₩￦-]+$').hasMatch(lowerLine);
  }

  int? _pickAmount(List<String> lines) {
    // A cancellation/refund is not necessarily an expense. Ask the user to
    // choose the amount instead of silently treating it as a new purchase.
    final cancellation = RegExp(
      r'^\s*(?:승인\s*취소|결제\s*취소|취소\s*영수증|'
      r'환불(?:\s*(?:영수증|금액|완료))?|반품(?:\s*(?:영수증|금액|완료))?|'
      r'refund(?:ed)?|cancelled|canceled)(?=\s|$|[:：])',
      caseSensitive: false,
    );
    if (lines.any(cancellation.hasMatch)) {
      return null;
    }

    final paymentLabel = RegExp(
      r'(?:최종\s*|총\s*|실\s*)?결제\s*(?:할\s*)?(?:금액|합계)|'
      r'지불\s*금액|청구\s*금액|받을\s*금액|'
      r'amount\s*due|balance\s*due|payment\s*amount',
      caseSensitive: false,
    );
    final totalLabel = RegExp(
      r'(?:최종\s*|총\s*)?합계|총\s*금액|총액|\btotal\b',
      caseSensitive: false,
    );
    final nonFinalPrefix = RegExp(
      r'상품|할인|쿠폰|공급|과세|면세|부가세|세금|소계|포인트|잔액|'
      r'subtotal|discount|vat|tax',
      caseSensitive: false,
    );

    // An explicit amount due is more useful than a pre-discount total. If
    // equally strong labels conflict, leave the amount empty for review.
    for (final label in [paymentLabel, totalLabel]) {
      final amounts = <int>{};
      var foundLabel = false;
      var hasUnreadableAmount = false;
      for (var index = 0; index < lines.length; index++) {
        final line = lines[index];
        for (final match in label.allMatches(line)) {
          final prefix = line.substring(0, match.start);
          final isAfterDiscount = identical(label, paymentLabel) &&
              RegExp(r'할인\s*(?:적용\s*)?후\s*$').hasMatch(prefix);
          if (nonFinalPrefix.hasMatch(prefix) && !isAfterDiscount) {
            continue;
          }
          foundLabel = true;
          final amount = _amountAfterLabel(line, match.end, lines, index);
          if (amount == null) {
            hasUnreadableAmount = true;
          } else {
            amounts.add(amount);
          }
        }
      }
      if (foundLabel) {
        return !hasUnreadableAmount && amounts.length == 1 ? amounts.single : null;
      }
    }

    return null;
  }

  int? _amountAfterLabel(String line, int labelEnd, List<String> lines, int index) {
    final remainder = line.substring(labelEnd);
    final sameLine = RegExp(
      r'^\s*[:：=]?\s*[₩￦]?\s*(\d[\d,]*)(?:\s*원)?(?=\s|$)',
    ).firstMatch(remainder);
    if (sameLine != null) {
      return _parseAmountNumber(sameLine.group(1)!);
    }

    // OCR may split a label and its value into consecutive lines. Do not use
    // a line containing additional text, which could be an item or a phone.
    if (RegExp(r'^\s*[:：=]?\s*$').hasMatch(remainder) && index + 1 < lines.length) {
      final nextLine = RegExp(
        r'^\s*[₩￦]?\s*(\d[\d,]*)(?:\s*원)?\s*$',
      ).firstMatch(lines[index + 1]);
      if (nextLine != null) {
        return _parseAmountNumber(nextLine.group(1)!);
      }
    }
    return null;
  }

  int? _parseAmountNumber(String rawValue) {
    if (!RegExp(r'^(?:\d{1,3}(?:,\d{3})+|\d+)$').hasMatch(rawValue)) {
      return null;
    }
    final value = int.tryParse(rawValue.replaceAll(',', ''));
    return value != null && value > 0 && value < 100000000 ? value : null;
  }

  /// 영수증 텍스트를 분석해 가장 가까운 기본 카테고리 ID를 반환한다.
  /// 반환값은 앱 기본 카테고리의 localId와 동일한 형식이다.
  String _guessCategory(String rawText, String storeName) {
    final lowerText = '${storeName.toLowerCase()}\n${rawText.toLowerCase()}';

    // 카테고리 ID → 매칭 키워드 목록
    const categories = <String, List<String>>{
      'expense-food': [
        'coffee', 'cafe', 'restaurant', 'burger', 'pizza', 'bbq', 'grill',
        'boba', 'ramen', 'sushi', 'chicken', 'noodle', 'bakery', 'bingsu',
        '스타벅스', '카페', '식당', '치킨', '피자', '분식', '냉면', '국밥',
        '도시락', '버거', '맥도날드', '롯데리아', '교촌',
      ],
      'expense-cafe-snack': [
        'starbucks', 'twosome', 'ediya', 'hollys', 'megacoffee', 'paik',
        '투썸', '이디야', '할리스', '메가커피', '빽다방', '커피빈',
        'dessert', 'bakery', 'snack', '디저트', '베이커리', '케이크',
      ],
      'expense-groceries': [
        'mart', 'market', 'grocery', 'super', 'emart', 'homeplus',
        'lotte mart', 'costco', 'traders',
        '마트', '홈플러스', '이마트', '코스트코', '롯데마트', '슈퍼',
      ],
      'expense-transport': [
        'taxi', 'uber', 'kakao t', 'bus', 'subway', 'train', 'ktx', 'gas',
        'parking', 'toll', 'highway',
        '택시', '버스', '지하철', '기차', 'ktx', '주유', '주차', '교통', '통행료',
      ],
      'expense-shopping': [
        'store', 'mall', 'shop', 'olive young', 'daiso', 'musinsa',
        'shein', 'zara', 'h&m', 'uniqlo', 'nike', 'adidas',
        '무신사', '올리브영', '다이소', '쇼핑', '패션', '의류', '신발',
      ],
      'expense-household': [
        'ikea', 'electro', 'home', 'hardware', 'furniture',
        '이케아', '가구', '생활용품', '청소', '전자', '다이소',
      ],
      'expense-health': [
        'pharmacy', 'hospital', 'clinic', 'dental', 'drug', 'medicine',
        '약국', '병원', '의원', '치과', '한의원', '의료', '헬스',
      ],
      'expense-leisure': [
        'cinema', 'movie', 'theater', 'gym', 'sport', 'game', 'book',
        'concert', 'ticket',
        '영화', '헬스장', '스포츠', '게임', '도서', '공연', '콘서트',
      ],
      'expense-subscriptions': [
        'netflix', 'spotify', 'apple', 'google', 'youtube', 'naver',
        'kakao', 'subscription', 'membership',
        '구독', '넷플릭스', '스포티파이', '유튜브',
      ],
    };

    for (final entry in categories.entries) {
      if (entry.value.any(lowerText.contains)) {
        return entry.key;
      }
    }

    return 'expense-other';
  }

  bool _supportsNativeOcr() {
    if (kIsWeb) {
      return false;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return true;
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return false;
    }
  }
}

final ocrServiceProvider = Provider<OcrService>((ref) {
  return OcrService();
});
