import 'dart:math';

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
    required this.confidence,
  });

  final String rawText;
  final double confidence;
}

class ParsedOcrDraft {
  const ParsedOcrDraft({
    required this.storeName,
    required this.amount,
    required this.categoryGuess,
  });

  final String storeName;
  final int amount;
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
    } catch (_) {
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

    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognized = await recognizer.processImage(inputImage);
      final rawText = recognized.text.trim();

      if (rawText.isEmpty) {
        throw const OcrCaptureException(
          'No readable text was found. Retake the receipt or continue with manual entry.',
        );
      }

      final lineCount = recognized.blocks.fold<int>(
        0,
        (sum, block) => sum + block.lines.length,
      );
      final confidence = min(0.99, max(0.1, lineCount / 20));

      return OcrExtractedText(
        rawText: rawText,
        confidence: confidence,
      );
    } on OcrCaptureException {
      rethrow;
    } catch (_) {
      throw const OcrCaptureException(
        'Text extraction failed. Retake the receipt and try again.',
      );
    } finally {
      await recognizer.close();
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
    final amount = _pickAmount(rawText, lines);
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
        lowerLine.contains('approval') ||
        lowerLine.contains('승인') ||
        lowerLine.contains('합계') ||
        lowerLine.contains('total') ||
        lowerLine.contains('amount') ||
        lowerLine.contains('vat') ||
        lowerLine.contains('card') ||
        lowerLine.contains('cash') ||
        RegExp(r'^[\d\W]+$').hasMatch(lowerLine);
  }

  int _pickAmount(String rawText, List<String> lines) {
    final labeledPatterns = <RegExp>[
      RegExp(r'(?:total|amount|sum)[^\d]{0,10}(\d[\d,]*)', caseSensitive: false),
      RegExp(r'(?:합계|총액|결제금액|총 결제금액|금액)[^\d]{0,10}(\d[\d,]*)'),
    ];

    final labeledCandidates = <int>[];
    for (final line in lines) {
      for (final pattern in labeledPatterns) {
        for (final match in pattern.allMatches(line)) {
          final parsed = _parseNumber(match.group(1));
          if (parsed != null) {
            labeledCandidates.add(parsed);
          }
        }
      }
    }

    if (labeledCandidates.isNotEmpty) {
      return labeledCandidates.reduce(max);
    }

    final generalMatches = RegExp(r'\d[\d,]{2,}').allMatches(rawText);
    final values = generalMatches
        .map((match) => _parseNumber(match.group(0)))
        .whereType<int>()
        .where((value) => value > 0 && value < 100000000)
        .toList();

    if (values.isEmpty) {
      throw const OcrCaptureException(
        'A total amount could not be identified from the OCR text.',
      );
    }

    return values.reduce(max);
  }

  int? _parseNumber(String? rawValue) {
    if (rawValue == null) {
      return null;
    }

    final digitsOnly = rawValue.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) {
      return null;
    }

    return int.tryParse(digitsOnly);
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
