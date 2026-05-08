import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet_app/core/database/app_database.dart';
import 'package:smart_wallet_app/features/settings/application/pin_security.dart';

import '../../../test_support/sqlite_test_setup.dart';

void main() {
  late AppDatabase database;

  setUpAll(() {
    configureSqliteForTests();
  });

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('migrateLegacyPinHash upgrades a stored legacy pin in app settings',
      () async {
    final now = DateTime(2026, 5, 8, 12);
    final legacy = hashLegacyPin('1234');

    await database.into(database.appSettings).insert(
          AppSettingsCompanion.insert(
            appLockEnabled: const drift.Value(true),
            pinCode: drift.Value(legacy),
            createdAt: now,
            lastModifiedAt: now,
          ),
        );

    final migrated = await migrateLegacyPinHash(
      database: database,
      pin: '1234',
      previousHash: legacy,
      now: now.add(const Duration(minutes: 1)),
    );

    expect(migrated, isTrue);

    final settings = await database.select(database.appSettings).getSingle();
    expect(settings.pinCode, isNot(legacy));
    expect(settings.pinCode, startsWith('v2\$pbkdf2-sha256\$'));
    expect(verifyStoredPin('1234', settings.pinCode!).isValid, isTrue);
  });
}
