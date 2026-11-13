import 'dart:async';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_wallet_app/app/router/app_router.dart';
import 'package:smart_wallet_app/app/theme/app_theme.dart';
import 'package:smart_wallet_app/core/database/app_database.dart';
import 'package:smart_wallet_app/core/database/providers/database_providers.dart';
import 'package:smart_wallet_app/features/settings/application/pin_security.dart';
import 'package:smart_wallet_app/features/settings/application/settings_provider.dart';
import 'package:smart_wallet_app/features/settings/presentation/lock_screen.dart';

import '../../../test_support/sqlite_test_setup.dart';

const _channel = MethodChannel('smart_wallet/device_auth');
const _recoverButton = '휴대폰 잠금으로 PIN 복구';
_Harness? _activeHarness;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    configureSqliteForTests();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  for (final result in [
    'cancelled',
    'notConfigured',
    'unsupported',
    'error',
    'unexpected',
  ]) {
    _testWithPlatform('device authentication $result keeps data and session locked',
        (tester) async {
      _mockDeviceAuth((_) async => result);
      final harness = await _open(tester);

      await tester.tap(find.text(_recoverButton));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNothing);
      if (result == 'notConfigured') {
        expect(find.text('휴대폰에 화면 잠금을 설정한 뒤 다시 시도해 주세요.'), findsOneWidget);
      }
      if (result == 'unsupported') {
        expect(find.text('이 기기에서는 PIN 복구를 지원하지 않습니다.'), findsOneWidget);
      }
      expect(harness.container.read(sessionUnlockedProvider), isFalse);
      await harness.expectUnchanged();
    });
  }

  _testWithPlatform('a platform error never grants recovery', (tester) async {
    _mockDeviceAuth((_) async => throw PlatformException(code: 'failure'));
    final harness = await _open(tester);

    await tester.tap(find.text(_recoverButton));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNothing);
    expect(harness.container.read(sessionUnlockedProvider), isFalse);
    await harness.expectUnchanged();
  });

  _testWithPlatform('a non-Android platform never starts device authentication',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    var attempts = 0;
    _mockDeviceAuth((_) async {
      attempts++;
      return 'success';
    });
    final harness = await _open(tester);

    await tester.tap(find.text(_recoverButton));
    await tester.pumpAndSettle();

    expect(attempts, 0);
    expect(find.byType(TextField), findsNothing);
    expect(find.text('이 기기에서는 PIN 복구를 지원하지 않습니다.'), findsOneWidget);
    expect(harness.container.read(sessionUnlockedProvider), isFalse);
    await harness.expectUnchanged();
  });

  _testWithPlatform('successful recovery changes only the missing PIN',
      (tester) async {
    _mockDeviceAuth((_) async => 'success');
    final harness = await _open(tester);

    await tester.tap(find.text(_recoverButton));
    await _waitForPinSetup(tester);
    expect(find.byType(TextField), findsNWidgets(2));
    await tester.enterText(find.byType(TextField).at(0), '1470');
    await tester.enterText(find.byType(TextField).at(1), '1470');
    await tester.tap(find.text('저장'));
    await _pumpUntil(
      tester,
      () => find.byType(TextField).evaluate().isEmpty,
      'PIN save to finish',
    );
    await tester.pumpAndSettle();

    final settings = await harness.readSettings();
    expect(settings.appLockEnabled, isTrue);
    expect(settings.currencyCode, 'USD');
    expect(settings.pinCode, isNotNull);
    expect(verifyStoredPin('1470', settings.pinCode!).isValid, isTrue);
    expect(harness.container.read(sessionUnlockedProvider), isFalse);
    await harness.expectTransactionPreserved();

    harness.settings.add(settings);
    await tester.pump();
    final listener = tester.widget<KeyboardListener>(find.byType(KeyboardListener));
    for (final (physical, logical, character) in const [
      (PhysicalKeyboardKey.digit1, LogicalKeyboardKey.digit1, '1'),
      (PhysicalKeyboardKey.digit4, LogicalKeyboardKey.digit4, '4'),
      (PhysicalKeyboardKey.digit7, LogicalKeyboardKey.digit7, '7'),
      (PhysicalKeyboardKey.digit0, LogicalKeyboardKey.digit0, '0'),
    ]) {
      listener.onKeyEvent!(KeyDownEvent(
        physicalKey: physical,
        logicalKey: logical,
        character: character,
        timeStamp: Duration.zero,
      ));
    }
    await tester.pump();
    expect(harness.container.read(sessionUnlockedProvider), isTrue);
  });

  _testWithPlatform('cancelling PIN setup leaves the missing PIN and data intact',
      (tester) async {
    _mockDeviceAuth((_) async => 'success');
    final harness = await _open(tester);

    await tester.tap(find.text(_recoverButton));
    await _waitForPinSetup(tester);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();

    expect(harness.container.read(sessionUnlockedProvider), isFalse);
    await harness.expectUnchanged();
  });

  _testWithPlatform('only one device authentication request can run at a time',
      (tester) async {
    final pending = Completer<Object?>();
    var attempts = 0;
    _mockDeviceAuth((_) {
      attempts++;
      return pending.future;
    });
    final harness = await _open(tester);

    await tester.tap(find.text(_recoverButton));
    await tester.pump();
    await tester.tap(find.text(_recoverButton), warnIfMissed: false);
    await tester.pump();
    expect(attempts, 1);
    pending.complete('cancelled');
    await tester.pumpAndSettle();

    expect(harness.container.read(sessionUnlockedProvider), isFalse);
    await harness.expectUnchanged();
  });

  _testWithPlatform('the OS prompt can suspend and resume the app during auth',
      (tester) async {
    final pending = Completer<Object?>();
    _mockDeviceAuth((_) => pending.future);
    final harness = await _open(tester);

    await tester.tap(find.text(_recoverButton));
    await tester.pump();
    _suspend(tester);
    _resume(tester);
    pending.complete('success');
    await _waitForPinSetup(tester);

    expect(find.byType(TextField), findsNWidgets(2));
    expect(harness.container.read(sessionUnlockedProvider), isFalse);
    await harness.expectUnchanged();
  });

  _testWithPlatform('a success delivered while the app is backgrounded is rejected',
      (tester) async {
    final pending = Completer<Object?>();
    _mockDeviceAuth((_) => pending.future);
    final harness = await _open(tester);

    await tester.tap(find.text(_recoverButton));
    await tester.pump();
    _suspend(tester);
    pending.complete('success');
    await tester.pump();
    _resume(tester);
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNothing);
    expect(harness.container.read(sessionUnlockedProvider), isFalse);
    await harness.expectUnchanged();
  });

  _testWithPlatform('backgrounding PIN setup expires the recovery approval',
      (tester) async {
    _mockDeviceAuth((_) async => 'success');
    final harness = await _open(tester);

    await tester.tap(find.text(_recoverButton));
    await _waitForPinSetup(tester);
    await tester.enterText(find.byType(TextField).at(0), '1470');
    await tester.enterText(find.byType(TextField).at(1), '1470');
    _suspend(tester);
    await tester.pump();
    _resume(tester);
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNothing);
    expect(harness.container.read(sessionUnlockedProvider), isFalse);
    await harness.expectUnchanged();
  });

  _testWithPlatform('losing focus during PIN setup expires the recovery approval',
      (tester) async {
    _mockDeviceAuth((_) async => 'success');
    final harness = await _open(tester);

    await tester.tap(find.text(_recoverButton));
    await _waitForPinSetup(tester);
    await tester.enterText(find.byType(TextField).at(0), '1470');
    await tester.enterText(find.byType(TextField).at(1), '1470');
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNothing);
    expect(harness.container.read(sessionUnlockedProvider), isFalse);
    await harness.expectUnchanged();
  });

  _testWithPlatform('a PIN created during recovery is never overwritten',
      (tester) async {
    _mockDeviceAuth((_) async => 'success');
    final harness = await _open(tester);

    await tester.tap(find.text(_recoverButton));
    await _waitForPinSetup(tester);
    await tester.enterText(find.byType(TextField).at(0), '1470');
    await tester.enterText(find.byType(TextField).at(1), '1470');
    final existingPin = hashLegacyPin('9999');
    await _pumpDatabase(tester, () => harness.database
        .update(harness.database.appSettings)
        .write(AppSettingsCompanion(pinCode: drift.Value(existingPin))));
    await tester.tap(find.text('저장'));
    await _pumpUntil(
      tester,
      () => find.text('PIN을 저장하지 못했습니다. 다시 시도해 주세요.')
          .evaluate()
          .isNotEmpty,
      'conflicting PIN save to be rejected',
    );
    await tester.pumpAndSettle();

    final settings = await harness.readSettings();
    expect(settings.pinCode, existingPin);
    expect(harness.container.read(sessionUnlockedProvider), isFalse);
    await harness.expectTransactionPreserved();
  });

  _testWithPlatform('a PIN created during device authentication is never overwritten',
      (tester) async {
    final pending = Completer<Object?>();
    _mockDeviceAuth((_) => pending.future);
    final harness = await _open(tester);

    await tester.tap(find.text(_recoverButton));
    await tester.pump();
    final existingPin = hashLegacyPin('9999');
    await _pumpDatabase(tester, () => harness.database
        .update(harness.database.appSettings)
        .write(AppSettingsCompanion(pinCode: drift.Value(existingPin))));
    pending.complete('success');
    await _pumpUntil(tester, () {
      final button = find.widgetWithText(FilledButton, _recoverButton);
      return button.evaluate().isNotEmpty &&
          tester.widget<FilledButton>(button).onPressed != null;
    }, 'conflicting PIN to stop recovery');
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNothing);
    expect((await harness.readSettings()).pinCode, existingPin);
    expect(harness.container.read(sessionUnlockedProvider), isFalse);
    await harness.expectTransactionPreserved();
  });

  _testWithPlatform('normal PIN protection still rejects wrong input', (tester) async {
    final harness = await _open(tester, pin: hashLegacyPin('1234'));
    final listener = tester.widget<KeyboardListener>(find.byType(KeyboardListener));
    for (var i = 0; i < 4; i++) {
      listener.onKeyEvent!(const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.digit9,
        logicalKey: LogicalKeyboardKey.digit9,
        character: '9',
        timeStamp: Duration.zero,
      ));
    }
    await tester.pump();

    expect(harness.container.read(sessionUnlockedProvider), isFalse);
    expect(find.text('PIN이 맞지 않습니다.'), findsOneWidget);
    final settings = await harness.readSettings();
    expect(settings.pinCode, hashLegacyPin('1234'));
    await harness.expectTransactionPreserved();
  });

  _testWithPlatform('normal PIN protection still accepts the correct PIN',
      (tester) async {
    final pin = hashPin('1234', iterations: 1, salt: [1, 2, 3, 4]);
    final harness = await _open(tester, pin: pin);
    final listener = tester.widget<KeyboardListener>(find.byType(KeyboardListener));
    const keys = [
      (PhysicalKeyboardKey.digit1, LogicalKeyboardKey.digit1, '1'),
      (PhysicalKeyboardKey.digit2, LogicalKeyboardKey.digit2, '2'),
      (PhysicalKeyboardKey.digit3, LogicalKeyboardKey.digit3, '3'),
      (PhysicalKeyboardKey.digit4, LogicalKeyboardKey.digit4, '4'),
    ];
    for (final (physical, logical, character) in keys) {
      listener.onKeyEvent!(KeyDownEvent(
        physicalKey: physical,
        logicalKey: logical,
        character: character,
        timeStamp: Duration.zero,
      ));
    }
    await tester.pump();

    expect(harness.container.read(sessionUnlockedProvider), isTrue);
    expect((await harness.readSettings()).pinCode, pin);
    await harness.expectTransactionPreserved();
  });
}

void _testWithPlatform(
  String description,
  Future<void> Function(WidgetTester) callback,
) {
  testWidgets(description, (tester) async {
    final previousPlatform = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      await callback(tester);
    } finally {
      try {
        final harness = _activeHarness;
        if (harness != null) await harness.dispose();
      } finally {
        _activeHarness = null;
        debugDefaultTargetPlatformOverride = previousPlatform;
      }
    }
  });
}

// NativeDatabase.memory executes on the test isolate. Keep its futures in
// fakeAsync, and pump with a bound rather than bridging them through runAsync.
Future<T> _pumpDatabase<T>(
  WidgetTester tester,
  Future<T> Function() operation,
) async {
  var completed = false;
  late T value;
  Object? failure;
  StackTrace? failureStack;
  operation().then((result) {
    value = result;
    completed = true;
  }, onError: (Object error, StackTrace stack) {
    failure = error;
    failureStack = stack;
    completed = true;
  });
  await _pumpUntil(tester, () => completed, 'database operation');
  if (failure != null) {
    Error.throwWithStackTrace(failure!, failureStack!);
  }
  return value;
}

Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() condition,
  String description,
) async {
  for (var i = 0; i < 200; i++) {
    if (condition()) return;
    await tester.pump(const Duration(milliseconds: 16));
  }
  if (condition()) return;
  fail('Timed out while waiting for $description');
}

Future<void> _waitForPinSetup(WidgetTester tester) async {
  await _pumpUntil(
    tester,
    () => find.byType(TextField).evaluate().length == 2,
    'PIN setup dialog',
  );
  await tester.pumpAndSettle();
}

void _mockDeviceAuth(Future<Object?> Function(MethodCall) handler) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_channel, handler);
}

void _suspend(WidgetTester tester) {
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
}

void _resume(WidgetTester tester) {
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
}

Future<_Harness> _open(WidgetTester tester, {String? pin}) async {
  final database = AppDatabase.forTesting(NativeDatabase.memory());
  final settings = StreamController<AppSetting>.broadcast(sync: true);
  final container = ProviderContainer(overrides: [
    appDatabaseProvider.overrideWithValue(database),
    appSettingsProvider.overrideWith((ref) => settings.stream),
  ]);
  final harness = _Harness(tester, database, container, settings);
  _activeHarness = harness;
  final now = DateTime(2026, 5, 1);
  final initialSettings = await _pumpDatabase(tester, () async {
    await database.into(database.appSettings).insert(AppSettingsCompanion.insert(
          currencyCode: const drift.Value('USD'),
          appLockEnabled: const drift.Value(true),
          pinCode: drift.Value(pin),
          createdAt: now,
          lastModifiedAt: now,
        ));
    await database.into(database.transactions).insert(TransactionsCompanion.insert(
          localId: 'existing-transaction',
          type: 'expense',
          amount: 3800,
          occurredAt: now,
          memo: const drift.Value('keep this record'),
          createdAt: now,
          lastModifiedAt: now,
        ));
    return database.select(database.appSettings).getSingle();
  });
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp(theme: AppTheme.light(), home: const LockScreen()),
  ));
  settings.add(initialSettings);
  await tester.pump();
  await tester.pump();
  return harness;
}

void _resumeIfNeeded(WidgetTester tester) {
  final state = tester.binding.lifecycleState;
  if (state == AppLifecycleState.paused) {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
  }
  if (tester.binding.lifecycleState == AppLifecycleState.hidden) {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
  }
  if (tester.binding.lifecycleState == AppLifecycleState.inactive) {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  }
}

class _Harness {
  _Harness(this.tester, this.database, this.container, this.settings);

  final WidgetTester tester;
  final AppDatabase database;
  final ProviderContainer container;
  final StreamController<AppSetting> settings;

  Future<void> dispose() async {
    _resumeIfNeeded(tester);
    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
    await _pumpDatabase(tester, () async {
      await settings.close();
      await database.close();
    });
  }

  Future<AppSetting> readSettings() => _pumpDatabase(
        tester,
        () => database.select(database.appSettings).getSingle(),
      );

  Future<void> expectUnchanged() async {
    final settings = await readSettings();
    expect(settings.appLockEnabled, isTrue);
    expect(settings.pinCode, isNull);
    expect(settings.currencyCode, 'USD');
    await expectTransactionPreserved();
  }

  Future<void> expectTransactionPreserved() async {
    final transaction = await _pumpDatabase(
      tester,
      () => database.select(database.transactions).getSingle(),
    );
    expect(transaction.localId, 'existing-transaction');
    expect(transaction.amount, 3800);
    expect(transaction.memo, 'keep this record');
  }
}
