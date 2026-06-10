import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet_app/core/database/app_database.dart';
import 'package:smart_wallet_app/features/dashboard/application/recurring_spend_detector.dart';

void main() {
  group('detectRecurringSpendInsight', () {
    test('classifies stable monthly insurance as fixed recurring spend', () {
      final now = DateTime(2026, 5, 22, 9);
      final transactions = [
        _tx(
          'insurance-mar',
          amount: 86000,
          occurredAt: DateTime(2026, 3, 5, 10),
          merchantName: '삼성화재',
          categoryId: 'insurance',
          accountId: 'card-1',
        ),
        _tx(
          'insurance-apr',
          amount: 86000,
          occurredAt: DateTime(2026, 4, 5, 10),
          merchantName: '삼성화재',
          categoryId: 'insurance',
          accountId: 'card-1',
        ),
        _tx(
          'insurance-may',
          amount: 86000,
          occurredAt: DateTime(2026, 5, 5, 10),
          merchantName: '삼성화재',
          categoryId: 'insurance',
          accountId: 'card-1',
        ),
      ];

      final insight = detectRecurringSpendInsight(transactions, now: now);

      expect(insight.groups, hasLength(1));
      expect(insight.groups.single.kind, RecurringSpendKind.fixed);
      expect(insight.groups.single.displayName, '삼성화재');
      expect(insight.groups.single.confidence, RecurringSpendConfidence.high);
      expect(
        insight.groups.single.evidenceCodes,
        containsAll([
          RecurringSpendEvidenceCode.monthlyCadence,
          RecurringSpendEvidenceCode.stableAmount,
        ]),
      );
      expect(insight.groups.single.currentMonthAmount, 86000);
      expect(insight.groups.single.isVisibleOnHome, isTrue);
      expect(insight.totalCurrentMonthAmount, 86000);
    });

    test('classifies subscription keyword matches as subscription', () {
      final now = DateTime(2026, 5, 22, 9);
      final transactions = [
        _tx(
          'netflix-apr',
          amount: 17000,
          occurredAt: DateTime(2026, 4, 10, 8),
          merchantName: 'NETFLIX',
          categoryId: 'subscription',
          accountId: 'card-1',
        ),
        _tx(
          'netflix-may',
          amount: 17000,
          occurredAt: DateTime(2026, 5, 10, 8),
          merchantName: 'NETFLIX',
          categoryId: 'subscription',
          accountId: 'card-1',
        ),
      ];

      final insight = detectRecurringSpendInsight(transactions, now: now);

      expect(insight.groups, hasLength(1));
      expect(insight.groups.single.kind, RecurringSpendKind.subscription);
      expect(insight.groups.single.score, greaterThanOrEqualTo(80));
      expect(insight.groups.single.confidence, RecurringSpendConfidence.high);
      expect(
        insight.groups.single.evidenceCodes,
        containsAll([
          RecurringSpendEvidenceCode.subscriptionKeyword,
          RecurringSpendEvidenceCode.stableAmount,
        ]),
      );
      expect(insight.groups.single.currentMonthAmount, 17000);
    });

    test(
        'classifies repeated cafe spending as lifestyle recurring only after enough repeats',
        () {
      final now = DateTime(2026, 5, 22, 9);
      final transactions = [
        _tx(
          'cafe-1',
          amount: 5200,
          occurredAt: DateTime(2026, 5, 2, 8),
          merchantName: 'STARBUCKS',
          categoryId: 'cafe',
          accountId: 'card-1',
        ),
        _tx(
          'cafe-2',
          amount: 5400,
          occurredAt: DateTime(2026, 5, 9, 8),
          merchantName: 'STARBUCKS',
          categoryId: 'cafe',
          accountId: 'card-1',
        ),
        _tx(
          'cafe-3',
          amount: 5300,
          occurredAt: DateTime(2026, 5, 16, 8),
          merchantName: 'STARBUCKS',
          categoryId: 'cafe',
          accountId: 'card-1',
        ),
      ];

      final insight = detectRecurringSpendInsight(transactions, now: now);

      expect(insight.groups, hasLength(1));
      expect(insight.groups.single.kind, RecurringSpendKind.lifestyle);
      expect(insight.groups.single.confidence, RecurringSpendConfidence.medium);
      expect(
        insight.groups.single.evidenceCodes,
        containsAll([
          RecurringSpendEvidenceCode.recentRepeatCount,
          RecurringSpendEvidenceCode.sameCategoryPattern,
        ]),
      );
      expect(insight.groups.single.currentMonthAmount, 15900);
      expect(insight.groups.single.isVisibleOnHome, isTrue);
    });

    test('does not classify two similar one-off spends as recurring', () {
      final now = DateTime(2026, 5, 22, 9);
      final transactions = [
        _tx(
          'shopping-1',
          amount: 42000,
          occurredAt: DateTime(2026, 5, 3, 16),
          merchantName: '무신사',
          categoryId: 'shopping',
          accountId: 'card-1',
        ),
        _tx(
          'shopping-2',
          amount: 42500,
          occurredAt: DateTime(2026, 5, 18, 16),
          merchantName: '무신사',
          categoryId: 'shopping',
          accountId: 'card-1',
        ),
      ];

      final insight = detectRecurringSpendInsight(transactions, now: now);

      expect(insight.groups, isEmpty);
      expect(insight.totalCurrentMonthAmount, 0);
    });

    test('ignores transfers and entries without merchant or memo', () {
      final now = DateTime(2026, 5, 22, 9);
      final transactions = [
        _tx(
          'transfer-1',
          type: 'transfer',
          amount: 20000,
          occurredAt: DateTime(2026, 5, 4, 12),
          merchantName: '이체',
          accountId: 'bank-1',
        ),
        _tx(
          'blank-1',
          amount: 9900,
          occurredAt: DateTime(2026, 5, 7, 12),
        ),
        _tx(
          'blank-2',
          amount: 9900,
          occurredAt: DateTime(2026, 5, 14, 12),
        ),
      ];

      final insight = detectRecurringSpendInsight(transactions, now: now);

      expect(insight.groups, isEmpty);
    });
  });
}

Transaction _tx(
  String localId, {
  String type = 'expense',
  required int amount,
  required DateTime occurredAt,
  String? accountId,
  String? categoryId,
  String? merchantName,
  String? memo,
}) {
  return Transaction(
    localId: localId,
    type: type,
    amount: amount,
    occurredAt: occurredAt,
    accountId: accountId,
    fromAccountId: null,
    toAccountId: null,
    categoryId: categoryId,
    merchantName: merchantName,
    paymentMethod: 'card',
    memo: memo,
    tagJson: null,
    createdAt: occurredAt,
    lastModifiedAt: occurredAt,
    deletedAt: null,
  );
}
