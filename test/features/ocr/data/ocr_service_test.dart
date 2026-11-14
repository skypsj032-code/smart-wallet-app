import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet_app/features/ocr/data/ocr_service.dart';

void main() {
  final service = OcrService();

  group('영수증 금액 추천', () {
    test('영수증 표제와 전화번호 뒤에 있는 한글 상호를 찾는다', () {
      final draft = service.parseText('''
영수증
전화 02-1234-5678
동네마트
결제금액 18,000원
''');

      expect(draft.storeName, '동네마트');
    });

    test('상품 합계보다 할인 후 결제금액을 우선한다', () {
      final draft = service.parseText('''
동네마트
전화 02-1234-5678
승인번호 87654321
상품합계 20,000원
할인금액 2,000원
결제금액 18,000원
''');

      expect(draft.storeName, '동네마트');
      expect(draft.amount, 18000);
      expect(draft.categoryGuess, 'expense-groceries');
    });

    test('할인 후 결제금액을 읽고 일반적인 환불 안내문은 무시한다', () {
      final draft = service.parseText('''
동네마트
할인 후 결제금액 18,000원
교환 및 환불은 구매일로부터 7일 이내 가능합니다.
''');

      expect(draft.amount, 18000);
    });

    test('최종 결제금액이 다음 줄에 있으면 읽는다', () {
      final draft = service.parseText('''
카페 봄
총 결제 금액
12,500원
''');

      expect(draft.amount, 12500);
    });

    test('과세합계와 부가세 대신 전체 합계를 읽는다', () {
      final draft = service.parseText('''
동네마트
과세합계 10,000원
부가세 1,000원
합계 11,000원
''');

      expect(draft.amount, 11000);
    });

    test('같은 우선순위의 결제금액이 다르면 직접 입력하도록 남긴다', () {
      final draft = service.parseText('''
카페 봄
결제금액 10,000원
결제금액 12,000원
''');

      expect(draft.storeName, '카페 봄');
      expect(draft.amount, isNull);
      expect(draft.categoryGuess, 'expense-food');
    });

    test('같은 결제금액이 반복되면 그 금액을 사용한다', () {
      final draft = service.parseText('''
카페 봄
결제금액 12,000원
결제금액 12,000원
''');

      expect(draft.amount, 12000);
    });

    test('합계 표시가 없으면 전화번호나 승인번호를 금액으로 쓰지 않는다', () {
      final draft = service.parseText('''
동네마트
전화 02-1234-5678
승인번호 87654321
우유 2,500원
''');

      expect(draft.storeName, '동네마트');
      expect(draft.amount, isNull);
    });

    test('취소 영수증은 지출 금액을 자동 추천하지 않는다', () {
      final draft = service.parseText('''
동네마트
승인취소
결제금액 18,000원
''');

      expect(draft.amount, isNull);
    });

    test('금액 형식이 잘못되었거나 소수점이 있으면 추측하지 않는다', () {
      expect(service.parseText('동네마트\n결제금액 12,34원').amount, isNull);
      expect(service.parseText('Store\nTOTAL 10.50').amount, isNull);
      expect(service.parseText('동네마트\n결제금액 -12,000원').amount, isNull);
    });

    test('영문 합계도 읽는다', () {
      final draft = service.parseText('Store\nTotal 12,000');
      expect(draft.amount, 12000);
    });
  });
}
