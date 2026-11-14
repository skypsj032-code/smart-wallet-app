import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet_app/features/notifications/application/notification_parser.dart';

void main() {
  test('a foreign-currency-only alert is not recorded as Korean won', () {
    final result = parseNotification({
      'title': '[카드 해외 승인]',
      'text': 'USD 12.50 승인 Netflix',
      'timestamp': 0,
    });
    expect(result, isNull);
  });

  test('a separately stated Korean won amount is still detected', () {
    final result = parseNotification({
      'title': '[카드 해외 승인]',
      'text': 'USD 12.50 승인 Netflix (17,500원)',
      'timestamp': 0,
    });
    expect(result?.amount, 17500);
  });
}
