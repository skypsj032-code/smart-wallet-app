/// 카드·은행 알림 텍스트를 파싱해 거래 정보를 추출한다.
///
/// 지원 형식 예시:
///   [신한카드] 5,000원 승인 스타벅스
///   [KB국민카드] 15,000원 사용 이마트24
///   [삼성카드] 결제 22,000원 맥도날드
///   카카오뱅크 출금 100,000원 현금 ATM
///   토스 출금 50,000원
///   [현대카드] 승인 3,500원 GS25
class ParsedNotificationTransaction {
  const ParsedNotificationTransaction({
    required this.amount,
    required this.type,
    required this.merchant,
    required this.rawTitle,
    required this.rawText,
    required this.detectedAt,
    this.cardName,
  });

  /// 금액 (원 단위 정수)
  final int amount;

  /// 'expense' | 'income'
  final String type;

  /// 가맹점/메모
  final String merchant;

  /// 알림 제목 원문
  final String rawTitle;

  /// 알림 본문 원문
  final String rawText;

  /// 감지 시각
  final DateTime detectedAt;

  /// 카드/은행 이름 (예: "신한카드", "카카오뱅크")
  final String? cardName;
}

/// 알림 Map을 받아 [ParsedNotificationTransaction]으로 변환.
/// 파싱에 실패하면 null을 반환한다.
ParsedNotificationTransaction? parseNotification(Map<String, dynamic> event) {
  final title = (event['title'] as String? ?? '').trim();
  final text = (event['text'] as String? ?? '').trim();
  final timestamp = event['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch;
  final detectedAt = DateTime.fromMillisecondsSinceEpoch(timestamp);

  final combined = '$title $text';

  // ── 금액 추출 ──────────────────────────────────────────────────
  // 패턴: 숫자(콤마 포함)원   예) 5,000원 / 50000원
  final amountMatch = RegExp(r'([\d,]+)원').firstMatch(combined);
  if (amountMatch == null) return null;

  final amountStr = amountMatch.group(1)!.replaceAll(',', '');
  final amount = int.tryParse(amountStr);
  if (amount == null || amount <= 0) return null;

  // ── 거래 유형 판단 ─────────────────────────────────────────────
  final isIncome = _containsAny(combined, ['입금', '수신', '급여', '환급', '이자']);
  final isExpense = _containsAny(combined, ['승인', '사용', '결제', '출금', '이체', '출']);
  if (!isIncome && !isExpense) return null;
  final type = isIncome ? 'income' : 'expense';

  // ── 카드/은행 이름 ─────────────────────────────────────────────
  final cardName = _extractCardName(title);

  // ── 가맹점/메모 ───────────────────────────────────────────────
  final merchant = _extractMerchant(combined, amountStr);

  return ParsedNotificationTransaction(
    amount: amount,
    type: type,
    merchant: merchant,
    rawTitle: title,
    rawText: text,
    detectedAt: detectedAt,
    cardName: cardName,
  );
}

// ── 내부 유틸 ──────────────────────────────────────────────────────

bool _containsAny(String text, List<String> keywords) =>
    keywords.any((k) => text.contains(k));

/// 제목에서 카드/은행 이름 추출
/// "[신한카드] ..." → "신한카드"
/// "카카오뱅크 ..." → "카카오뱅크"
String? _extractCardName(String title) {
  // 대괄호 안
  final bracketMatch = RegExp(r'\[(.+?)\]').firstMatch(title);
  if (bracketMatch != null) return bracketMatch.group(1);

  // 알려진 이름 직접 매칭
  const known = [
    '신한카드', 'KB국민카드', '삼성카드', '현대카드', '롯데카드',
    '하나카드', '우리카드', 'NH카드', 'BC카드',
    '카카오뱅크', '카카오페이', '토스', '네이버페이', 'SSG페이',
    '신한은행', 'KB국민은행', '우리은행', '하나은행', '농협',
  ];
  for (final name in known) {
    if (title.contains(name)) return name;
  }
  return null;
}

/// 가맹점명 추출
/// 금액과 거래 유형 키워드를 제거하고 남은 텍스트에서 첫 의미있는 단어
String _extractMerchant(String combined, String amountDigits) {
  // 제거할 패턴들
  var cleaned = combined
      .replaceAll(RegExp(r'\[.+?\]'), '')           // 대괄호 카드명
      .replaceAll(RegExp(r'[\d,]+원'), '')           // 금액
      .replaceAll(RegExp(r'\d{1,2}/\d{1,2}'), '')   // 날짜 5/7
      .replaceAll(RegExp(r'\d{2}:\d{2}'), '')        // 시간 14:32
      .replaceAll(RegExp(r'승인|사용|결제|출금|입금|이체|수신|급여'), '')
      .replaceAll(RegExp(r'[^\w\s가-힣]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  // 남은 단어 중 2글자 이상인 것을 가맹점으로
  final words = cleaned.split(' ').where((w) => w.length >= 2).toList();
  if (words.isEmpty) return '';

  // 카드/은행 이름과 숫자 단어 제외
  const skipWords = {
    '신한카드', 'KB국민카드', '삼성카드', '현대카드', '롯데카드',
    '하나카드', '우리카드', 'NH카드', 'BC카드', '카카오뱅크',
    '카카오페이', '토스', '네이버페이', '신한은행', 'KB국민은행',
    '현금', 'ATM', '자동이체',
  };

  final merchant = words.firstWhere(
    (w) => !skipWords.contains(w) && !RegExp(r'^\d+$').hasMatch(w),
    orElse: () => words.first,
  );
  return merchant;
}
