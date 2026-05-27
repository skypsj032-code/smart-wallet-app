import 'package:flutter_test/flutter_test.dart';

import 'package:smart_wallet/features/notifications/application/notification_parser.dart';

// ---------------------------------------------------------------------------
// 헬퍼 — 이벤트 맵 생성
// ---------------------------------------------------------------------------
Map<String, dynamic> _evt(String title, String text, {int? ts}) => {
      'title': title,
      'text': text,
      'timestamp': ts ?? DateTime(2024, 5, 7, 14, 30).millisecondsSinceEpoch,
    };

void main() {
  group('parseNotification — 지출 케이스', () {
    test('신한카드 대괄호 형식 + 콤마 금액', () {
      final result = parseNotification(
        _evt('[신한카드]', '5,000원 승인 스타벅스'),
      );

      expect(result, isNotNull);
      expect(result!.amount, 5000);
      expect(result.type, 'expense');
      expect(result.cardName, '신한카드');
      expect(result.merchant, '스타벅스');
      expect(result.suggestedCategoryKeyword, '카페');
    });

    test('KB국민카드 사용 형식', () {
      final result = parseNotification(
        _evt('[KB국민카드]', '15,000원 사용 이마트24'),
      );

      expect(result, isNotNull);
      expect(result!.amount, 15000);
      expect(result.type, 'expense');
      expect(result.cardName, 'KB국민카드');
      expect(result.suggestedCategoryKeyword, '식비');
    });

    test('삼성카드 결제 형식 — 키워드 앞에 금액', () {
      final result = parseNotification(
        _evt('[삼성카드]', '결제 22,000원 맥도날드'),
      );

      expect(result, isNotNull);
      expect(result!.amount, 22000);
      expect(result.type, 'expense');
      expect(result.cardName, '삼성카드');
      expect(result.suggestedCategoryKeyword, '식비');
    });

    test('현대카드 승인 + 편의점 GS25', () {
      final result = parseNotification(
        _evt('[현대카드]', '승인 3,500원 GS25'),
      );

      expect(result, isNotNull);
      expect(result!.amount, 3500);
      expect(result.type, 'expense');
      expect(result.cardName, '현대카드');
    });

    test('카카오뱅크 출금 — 대괄호 없음', () {
      final result = parseNotification(
        _evt('카카오뱅크', '출금 100,000원 현금 ATM'),
      );

      expect(result, isNotNull);
      expect(result!.amount, 100000);
      expect(result.type, 'expense');
      expect(result.cardName, '카카오뱅크');
    });

    test('토스 출금 — 상호명 없음', () {
      final result = parseNotification(
        _evt('토스', '출금 50,000원'),
      );

      expect(result, isNotNull);
      expect(result!.amount, 50000);
      expect(result.type, 'expense');
      expect(result.cardName, '토스');
    });

    test('네이버페이 결제 + 쇼핑 카테고리', () {
      final result = parseNotification(
        _evt('네이버페이', '결제 35,900원 쿠팡'),
      );

      expect(result, isNotNull);
      expect(result!.amount, 35900);
      expect(result.type, 'expense');
      expect(result.suggestedCategoryKeyword, '쇼핑');
    });

    test('병원 → 의료 카테고리 추측', () {
      final result = parseNotification(
        _evt('[신한카드]', '승인 12,000원 서울치과의원'),
      );

      expect(result, isNotNull);
      expect(result!.suggestedCategoryKeyword, '의료');
    });

    test('영화관 → 문화 카테고리 추측', () {
      final result = parseNotification(
        _evt('[롯데카드]', '승인 14,000원 CGV강남'),
      );

      expect(result, isNotNull);
      expect(result!.suggestedCategoryKeyword, '문화');
    });

    test('주유소 → 교통 카테고리 추측', () {
      final result = parseNotification(
        _evt('[현대카드]', '승인 80,000원 SK주유소'),
      );

      expect(result, isNotNull);
      expect(result!.suggestedCategoryKeyword, '교통');
    });
  });

  group('parseNotification — 수입 케이스', () {
    test('급여 입금', () {
      final result = parseNotification(
        _evt('신한은행', '입금 3,200,000원 ㈜회사급여'),
      );

      expect(result, isNotNull);
      expect(result!.amount, 3200000);
      expect(result.type, 'income');
    });

    test('카카오뱅크 이자 지급', () {
      final result = parseNotification(
        _evt('카카오뱅크', '이자 2,500원 입금'),
      );

      expect(result, isNotNull);
      expect(result!.amount, 2500);
      expect(result.type, 'income');
    });

    test('환급 처리', () {
      final result = parseNotification(
        _evt('[신한카드]', '환급 5,000원'),
      );

      expect(result, isNotNull);
      expect(result!.amount, 5000);
      expect(result.type, 'income');
    });
  });

  group('parseNotification — 파싱 불가 케이스 (null 반환)', () {
    test('금액 없음 → null', () {
      expect(
        parseNotification(_evt('[신한카드]', '이벤트 당첨을 축하합니다')),
        isNull,
      );
    });

    test('0원 금액 → null', () {
      expect(
        parseNotification(_evt('[신한카드]', '0원 승인')),
        isNull,
      );
    });

    test('거래 유형 키워드 없음 → null', () {
      expect(
        parseNotification(_evt('[신한카드]', '5,000원 적립 완료')),
        isNull,
      );
    });

    test('빈 제목·본문 → null', () {
      expect(
        parseNotification(_evt('', '')),
        isNull,
      );
    });

    test('숫자만 있는 알림 → null', () {
      expect(
        parseNotification(_evt('앱 알림', '12345 코드를 입력하세요')),
        isNull,
      );
    });
  });

  group('parseNotification — 엣지 케이스', () {
    test('콤마 없는 큰 금액 처리', () {
      final result = parseNotification(
        _evt('[삼성카드]', '승인 1000000원 항공권'),
      );

      expect(result, isNotNull);
      expect(result!.amount, 1000000);
    });

    test('영문 상호명 처리', () {
      final result = parseNotification(
        _evt('[KB국민카드]', '승인 4,500원 STARBUCKS'),
      );

      expect(result, isNotNull);
      expect(result!.amount, 4500);
      expect(result.type, 'expense');
    });

    test('title + text 결합 파싱 — 금액이 title에 있음', () {
      final result = parseNotification(
        _evt('[하나카드] 승인 8,800원', 'GS편의점'),
      );

      expect(result, isNotNull);
      expect(result!.amount, 8800);
      expect(result.type, 'expense');
    });

    test('timestamp가 없으면 현재 시각으로 대체', () {
      final before = DateTime.now().subtract(const Duration(seconds: 1));
      final result = parseNotification({
        'title': '[신한카드]',
        'text': '1,000원 승인 테스트',
        // timestamp 키 없음
      });

      expect(result, isNotNull);
      expect(result!.detectedAt.isAfter(before), isTrue);
    });

    test('카드명을 제외한 cardName = null (알 수 없는 앱)', () {
      final result = parseNotification(
        _evt('알 수 없는 앱', '5,000원 결제 처리'),
      );

      // 파싱은 성공해야 하고, cardName은 null
      expect(result, isNotNull);
      expect(result!.cardName, isNull);
    });
  });

  group('parseNotification — 외화 결제 케이스', () {
    test('USD 달러 결제 파싱', () {
      final result = parseNotification(
        _evt('[신한카드]', '해외 결제 USD 25 AMAZON'),
      );

      expect(result, isNotNull);
      expect(result!.amount, 25);
      expect(result.type, 'expense');
    });

    test('\$ 기호 달러 결제', () {
      final result = parseNotification(
        _evt('[현대카드]', '승인 \$19.99 Netflix'),
      );

      expect(result, isNotNull);
      expect(result!.amount, 19);
      expect(result.type, 'expense');
    });

    test('JPY 엔화 결제', () {
      final result = parseNotification(
        _evt('[롯데카드]', '해외 결제 JPY 1,500 편의점'),
      );

      expect(result, isNotNull);
      expect(result!.amount, 1500);
      expect(result.type, 'expense');
    });

    test('¥ 기호 엔화 결제', () {
      final result = parseNotification(
        _evt('[삼성카드]', '승인 ¥800 라멘집'),
      );

      expect(result, isNotNull);
      expect(result!.amount, 800);
    });

    test('EUR 유로 결제', () {
      final result = parseNotification(
        _evt('[KB국민카드]', '결제 EUR 50 booking.com'),
      );

      expect(result, isNotNull);
      expect(result!.amount, 50);
    });

    test('원화 있으면 외화보다 원화 우선', () {
      // "5,000원"과 "USD 100" 둘 다 있을 경우 원화 우선
      final result = parseNotification(
        _evt('[신한카드]', '승인 5,000원 환전수수료 USD 100'),
      );

      expect(result, isNotNull);
      expect(result!.amount, 5000); // 원화 우선
    });
  });
}
