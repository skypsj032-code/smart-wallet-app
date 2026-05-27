import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet_app/features/settings/application/pin_security.dart';

void main() {
  test('hashPin stores versioned PBKDF2 values that verify successfully', () {
    final stored = hashPin(
      '1234',
      iterations: 10,
      salt: List<int>.generate(16, (index) => index + 1),
    );

    expect(stored, startsWith('v2\$pbkdf2-sha256\$10\$'));
    expect(verifyStoredPin('1234', stored).isValid, isTrue);
    expect(verifyStoredPin('9999', stored).isValid, isFalse);
    expect(verifyStoredPin('1234', stored).needsUpgrade, isFalse);
  });

  test('legacy sha256 pins still verify but are marked for upgrade', () {
    final legacy = hashLegacyPin('1234');

    final success = verifyStoredPin('1234', legacy);
    final failure = verifyStoredPin('9999', legacy);

    expect(success.isValid, isTrue);
    expect(success.needsUpgrade, isTrue);
    expect(failure.isValid, isFalse);
  });
}
