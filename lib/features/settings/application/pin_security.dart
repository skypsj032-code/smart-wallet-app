import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' show Value;

import '../../../core/database/app_database.dart';

const _currentPinHashVersion = 'v2';
const _currentPinHashAlgorithm = 'pbkdf2-sha256';
const _defaultIterations = 120000;
const _defaultSaltLength = 16;
const _derivedKeyLength = 32;

class PinVerificationResult {
  const PinVerificationResult({
    required this.isValid,
    required this.needsUpgrade,
  });

  final bool isValid;
  final bool needsUpgrade;
}

String hashLegacyPin(String pin) {
  final bytes = utf8.encode(pin);
  return sha256.convert(bytes).toString();
}

String hashPin(
  String pin, {
  int iterations = _defaultIterations,
  List<int>? salt,
}) {
  final normalizedSalt = List<int>.from(salt ?? _generateSalt());
  final derived = _pbkdf2HmacSha256(
    utf8.encode(pin),
    normalizedSalt,
    iterations,
    _derivedKeyLength,
  );

  final saltValue = base64Url.encode(normalizedSalt);
  final hashValue = base64Url.encode(derived);
  return '$_currentPinHashVersion\$$_currentPinHashAlgorithm\$$iterations\$$saltValue\$$hashValue';
}

PinVerificationResult verifyStoredPin(String pin, String stored) {
  if (_isLegacyHash(stored)) {
    return PinVerificationResult(
      isValid: _constantTimeEquals(
        utf8.encode(hashLegacyPin(pin)),
        utf8.encode(stored),
      ),
      needsUpgrade: true,
    );
  }

  final parsed = _parseStoredHash(stored);
  if (parsed == null) {
    return const PinVerificationResult(isValid: false, needsUpgrade: false);
  }

  final derived = _pbkdf2HmacSha256(
    utf8.encode(pin),
    parsed.salt,
    parsed.iterations,
    parsed.expected.length,
  );

  return PinVerificationResult(
    isValid: _constantTimeEquals(derived, parsed.expected),
    needsUpgrade: false,
  );
}

Future<bool> migrateLegacyPinHash({
  required AppDatabase database,
  required String pin,
  required String previousHash,
  DateTime? now,
}) async {
  if (!_isLegacyHash(previousHash)) {
    return false;
  }

  final settings =
      await database.select(database.appSettings).getSingleOrNull();
  if (settings == null || settings.pinCode != previousHash) {
    return false;
  }

  await database.update(database.appSettings).replace(
        settings.copyWith(
          pinCode: Value(hashPin(pin)),
          lastModifiedAt: now ?? DateTime.now(),
        ),
      );
  return true;
}

bool _isLegacyHash(String value) {
  return RegExp(r'^[a-f0-9]{64}$').hasMatch(value);
}

List<int> _generateSalt() {
  final random = Random.secure();
  return List<int>.generate(_defaultSaltLength, (_) => random.nextInt(256));
}

_ParsedPinHash? _parseStoredHash(String stored) {
  final parts = stored.split('\$');
  if (parts.length != 5) {
    return null;
  }
  if (parts[0] != _currentPinHashVersion ||
      parts[1] != _currentPinHashAlgorithm) {
    return null;
  }

  final iterations = int.tryParse(parts[2]);
  if (iterations == null || iterations <= 0) {
    return null;
  }

  try {
    final salt = base64Url.decode(parts[3]);
    final expected = base64Url.decode(parts[4]);
    if (salt.isEmpty || expected.isEmpty) {
      return null;
    }

    return _ParsedPinHash(
      iterations: iterations,
      salt: salt,
      expected: expected,
    );
  } catch (_) {
    return null;
  }
}

List<int> _pbkdf2HmacSha256(
  List<int> password,
  List<int> salt,
  int iterations,
  int keyLength,
) {
  final hmac = Hmac(sha256, password);
  final blockLength = hmac.convert(const []).bytes.length;
  final blockCount = (keyLength / blockLength).ceil();
  final output = <int>[];

  for (var blockIndex = 1; blockIndex <= blockCount; blockIndex++) {
    final block = _pbkdf2Block(hmac, salt, iterations, blockIndex);
    output.addAll(block);
  }

  return output.take(keyLength).toList(growable: false);
}

List<int> _pbkdf2Block(
  Hmac hmac,
  List<int> salt,
  int iterations,
  int blockIndex,
) {
  final initial = <int>[
    ...salt,
    (blockIndex >> 24) & 0xff,
    (blockIndex >> 16) & 0xff,
    (blockIndex >> 8) & 0xff,
    blockIndex & 0xff,
  ];

  var value = hmac.convert(initial).bytes;
  final result = List<int>.from(value);

  for (var round = 1; round < iterations; round++) {
    value = hmac.convert(value).bytes;
    for (var i = 0; i < result.length; i++) {
      result[i] ^= value[i];
    }
  }

  return result;
}

bool _constantTimeEquals(List<int> left, List<int> right) {
  if (left.length != right.length) {
    return false;
  }

  var diff = 0;
  for (var i = 0; i < left.length; i++) {
    diff |= left[i] ^ right[i];
  }
  return diff == 0;
}

class _ParsedPinHash {
  const _ParsedPinHash({
    required this.iterations,
    required this.salt,
    required this.expected,
  });

  final int iterations;
  final List<int> salt;
  final List<int> expected;
}
