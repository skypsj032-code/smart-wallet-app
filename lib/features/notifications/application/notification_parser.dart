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
    this.suggestedCategoryKeyword,
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

  /// 추측 카테고리 이름 키워드 (예: "카페", "식비") — null이면 미확정
  final String? suggestedCategoryKeyword;
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
  final isExpense = _containsAny(combined, ['승인', '사용', '결제', '출금', '이체']);
  if (!isIncome && !isExpense) return null;
  final type = isIncome ? 'income' : 'expense';

  // ── 카드/은행 이름 ─────────────────────────────────────────────
  final cardName = _extractCardName(title);

  // ── 가맹점/메모 ───────────────────────────────────────────────
  final merchant = _extractMerchant(combined, amountStr);

  final suggestedCategoryKeyword = _guessCategoryKeyword(merchant, combined);

  return ParsedNotificationTransaction(
    amount: amount,
    type: type,
    merchant: merchant,
    rawTitle: title,
    rawText: text,
    detectedAt: detectedAt,
    cardName: cardName,
    suggestedCategoryKeyword: suggestedCategoryKeyword,
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
    '카카오뱅크', '카카오페이', '토스뱅크', '토스', '케이뱅크',
    '네이버페이', 'SSG페이', '페이코',
    '신한은행', 'KB국민은행', '우리은행', '하나은행', '농협', '기업은행', '우체국',
  ];
  for (final name in known) {
    if (title.contains(name)) return name;
  }
  return null;
}

/// 상호명·원문을 바탕으로 카테고리 키워드를 추측한다.
/// 반환값은 DB의 카테고리 이름과 부분 매칭에 쓰인다.
String? _guessCategoryKeyword(String merchant, String combined) {
  final text = '$merchant $combined'.toLowerCase();

  // 카페/음료
  if (_containsAny(text, ['스타벅스', '커피', '카페', '이디야', '빽다방', '할리스', '투썸', '엔제리너스', '폴바셋', '커피빈'])) {
    return '카페';
  }
  // 교통
  if (_containsAny(text, ['택시', '주유', '주차', '버스', '지하철', '기차', '티머니', 'kt m모빌리티', '카카오택시', 'uber'])) {
    return '교통';
  }
  // 편의점 → 식비
  if (_containsAny(text, ['gs25', 'cu ', 'cu\t', '세븐일레븐', '미니스톱', '이마트24'])) {
    return '식비';
  }
  // 식비 (배달·외식)
  if (_containsAny(text, ['맥도날드', '버거킹', 'kfc', '롯데리아', '배달의민족', '요기요', '쿠팡이츠', '피자', '치킨', '떡볶이', '분식', '식당', '