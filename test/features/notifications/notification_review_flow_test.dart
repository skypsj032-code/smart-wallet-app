import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet_app/core/database/app_database.dart';
import 'package:smart_wallet_app/features/notifications/application/notification_provider.dart';
import 'package:smart_wallet_app/features/transactions/application/quick_entry_form_provider.dart';
import 'package:smart_wallet_app/features/transactions/data/transaction_repository.dart';

import '../../test_support/sqlite_test_setup.dart';

void main() {
  late AppDatabase database;

  setUpAll(configureSqliteForTests);
  setUp(() => database = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => database.close());

  Map<String, dynamic> event(String id, String text) => {
        'eventId': id,
        'packageName': 'bank.app',
        'title': '[신한카드]',
        'text': text,
        'timestamp': 1760000000000,
      };

  test('replayed events are idempotent, but equal payments remain distinct', () async {
    final first = await persistNotificationEvent(database, event('one', '승인 5,000원 스타벅스'));
    final replay = await persistNotificationEvent(database, event('one', '승인 5,000원 스타벅스'));
    final second = await persistNotificationEvent(database, event('two', '승인 5,000원 스타벅스'));
    expect(first!.id, replay!.id);
    expect(second!.id, isNot(first.id));
    final rows = await database.select(database.notificationHistories).get();
    expect(rows, hasLength(2));
    expect(rows.every((row) => row.status == 'pending'), isTrue);
  });

  test('foreign and cancellation notices require manual review without inventing a won amount', () async {
    final foreign = await persistNotificationEvent(database, event('foreign', '해외 결제 승인 USD 25.50'));
    final cancelled = await persistNotificationEvent(database, event('cancel', '승인취소 5,000원 스타벅스'));
    expect(foreign!.amount, 0);
    expect(foreign.type, 'unknown');
    expect(cancelled!.amount, 0);
    expect(cancelled.type, 'unknown');
  });

  test('multiple amounts or conflicting directions need manual review', () async {
    final balance = await persistNotificationEvent(
        database, event('balance', '잔액 100,000원 출금 5,000원'));
    final conflicting = await persistNotificationEvent(
        database, event('conflict', '출금 처리 후 입금 5,000원'));
    final balanceOnly = await persistNotificationEvent(
        database, event('balance-only', '출금 완료 잔액 100,000원'));
    final overseasFee = await persistNotificationEvent(
        database, event('overseas-fee', '해외 승인 USD 12.50 해외이용수수료 500원'));
    expect(balance!.type, 'unknown');
    expect(balance.amount, 0);
    expect(conflicting!.type, 'unknown');
    expect(conflicting.amount, 0);
    expect(balanceOnly!.type, 'unknown');
    expect(balanceOnly.amount, 0);
    expect(overseasFee!.type, 'unknown');
    expect(overseasFee.amount, 0);
  });

  test('interest-only bank notices remain reviewable as income', () async {
    final interest = await persistNotificationEvent(
        database, event('interest', '이자 2,500원 지급'));
    expect(interest!.type, 'income');
    expect(interest.amount, 2500);
  });

  test('saving a candidate atomically links it and remembers the chosen category once', () async {
    final now = DateTime(2026, 11, 1);
    await database.into(database.categories).insert(CategoriesCompanion.insert(
      localId: 'food', name: '식비', type: 'expense', createdAt: now, lastModifiedAt: now,
    ));
    final candidate = (await persistNotificationEvent(database, event('one', '승인 5,000원 스타벅스')))!;
    final form = QuickEntryFormState(
      type: TransactionEntryType.expense,
      amount: '5000',
      accountId: 'cash',
      categoryId: 'food',
      notificationHistoryId: candidate.id,
      notificationMerchant: '스타벅스',
    );
    final repository = TransactionRepository(database);
    await repository.createFromQuickEntry(form);
    await expectLater(repository.createFromQuickEntry(form), throwsStateError);
    final tx = await database.select(database.transactions).getSingle();
    final saved = await database.select(database.notificationHistories).getSingle();
    expect(saved.status, 'recorded');
    expect(saved.transactionId, tx.localId);
    expect(await findNotificationCategory(database, '스타벅스', 'expense', null), 'food');
    expect(await database.select(database.transactions).get(), hasLength(1));
  });

  test('invalid remembered category does not get suggested', () async {
    final now = DateTime(2026, 11, 1);
    await database.into(database.categories).insert(CategoriesCompanion.insert(
      localId: 'food', name: '식비', type: 'expense', isActive: const Value(false),
      createdAt: now, lastModifiedAt: now,
    ));
    await database.into(database.merchantCategoryRules).insert(
      MerchantCategoryRulesCompanion.insert(
        merchantKey: '스타벅스', type: 'expense', categoryId: 'food', updatedAt: now,
      ),
    );
    expect(await findNotificationCategory(database, '스타벅스', 'expense', null), isNull);
  });

  test('an insert failure rolls back the claimed candidate', () async {
    final candidate = (await persistNotificationEvent(database, event('rollback', '승인 5,000원 스타벅스')))!;
    await database.customStatement('''
      CREATE TRIGGER fail_transaction BEFORE INSERT ON transactions
      BEGIN SELECT RAISE(ABORT, 'injected failure'); END;
    ''');
    await expectLater(
      TransactionRepository(database).createFromQuickEntry(QuickEntryFormState(
        amount: '5000', accountId: 'cash', notificationHistoryId: candidate.id,
      )),
      throwsA(anything),
    );
    final restored = await database.select(database.notificationHistories).getSingle();
    expect(restored.status, 'pending');
    expect(restored.transactionId, isNull);
    expect(await database.select(database.transactions).get(), isEmpty);
  });

  test('native acknowledgement happens only after durable save and can be retried', () async {
    final received = event('ack', '승인 5,000원 스타벅스');
    var ackCalls = 0;
    Future<void> failFirstAck(List<String> ids) async {
      ackCalls++;
      expect(ids, ['ack']);
      expect(await database.select(database.notificationHistories).get(), hasLength(1));
      if (ackCalls == 1) throw StateError('native acknowledgement failed');
    }
    await expectLater(
      persistAndAcknowledgeNotificationEvent(database, received, failFirstAck),
      throwsStateError,
    );
    await persistAndAcknowledgeNotificationEvent(database, received, failFirstAck);
    expect(ackCalls, 2);
    expect(await database.select(database.notificationHistories).get(), hasLength(1));
  });

  test('a failed database insert never acknowledges the native event', () async {
    await database.customStatement('''
      CREATE TRIGGER fail_history BEFORE INSERT ON notification_histories
      BEGIN SELECT RAISE(ABORT, 'injected failure'); END;
    ''');
    var acknowledged = false;
    await expectLater(
      persistAndAcknowledgeNotificationEvent(
        database, event('not-acked', '승인 5,000원 스타벅스'),
        (_) async { acknowledged = true; },
      ),
      throwsA(anything),
    );
    expect(acknowledged, isFalse);
  });
}
