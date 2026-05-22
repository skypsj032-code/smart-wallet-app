import '../../../core/database/app_database.dart';

enum RecurringSpendKind {
  fixed,
  subscription,
  lifestyle,
}

enum RecurringSpendConfidence {
  high,
  medium,
}

enum RecurringSpendEvidenceCode {
  monthlyCadence,
  stableAmount,
  subscriptionKeyword,
  recentRepeatCount,
  sameCategoryPattern,
  sameAccountPattern,
}

class RecurringSpendGroup {
  const RecurringSpendGroup({
    required this.groupKey,
    required this.displayName,
    required this.kind,
    required this.score,
    required this.confidence,
    required this.evidenceCodes,
    required this.isVisibleOnHome,
    required this.currentMonthAmount,
    required this.previousMonthAmount,
    required this.transactions,
  });

  final String groupKey;
  final String displayName;
  final RecurringSpendKind kind;
  final int score;
  final RecurringSpendConfidence confidence;
  final List<RecurringSpendEvidenceCode> evidenceCodes;
  final bool isVisibleOnHome;
  final int currentMonthAmount;
  final int previousMonthAmount;
  final List<Transaction> transactions;
}

class RecurringSpendInsight {
  const RecurringSpendInsight({
    required this.groups,
    required this.totalCurrentMonthAmount,
    required this.totalPreviousMonthAmount,
  });

  final List<RecurringSpendGroup> groups;
  final int totalCurrentMonthAmount;
  final int totalPreviousMonthAmount;

  int? get monthDelta {
    if (totalPreviousMonthAmount == 0) {
      return null;
    }

    return totalCurrentMonthAmount - totalPreviousMonthAmount;
  }
}

RecurringSpendInsight detectRecurringSpendInsight(
  List<Transaction> transactions, {
  required DateTime now,
}) {
  final monthStart = DateTime(now.year, now.month, 1);
  final nextMonth = DateTime(now.year, now.month + 1, 1);
  final previousMonthStart = DateTime(now.year, now.month - 1, 1);

  final clusters = <String, List<Transaction>>{};
  for (final tx in transactions) {
    if (!_isEligibleExpense(tx)) {
      continue;
    }

    final normalizedName = _normalizedDisplayName(tx);
    if (normalizedName == null) {
      continue;
    }

    final clusterKey =
        '${tx.accountId ?? ''}|${tx.categoryId ?? ''}|$normalizedName';
    clusters.putIfAbsent(clusterKey, () => []).add(tx);
  }

  final groups = <RecurringSpendGroup>[];
  for (final entry in clusters.entries) {
    final cluster = [...entry.value]..sort(
        (a, b) => a.occurredAt.compareTo(b.occurredAt),
      );
    final classification = _classifyCluster(cluster, now: now);
    if (classification == null) {
      continue;
    }

    final currentMonthAmount = cluster
        .where(
          (tx) =>
              !tx.occurredAt.isBefore(monthStart) &&
              tx.occurredAt.isBefore(nextMonth),
        )
        .fold<int>(0, (sum, tx) => sum + tx.amount);

    if (currentMonthAmount == 0) {
      continue;
    }

    final previousMonthAmount = cluster
        .where(
          (tx) =>
              !tx.occurredAt.isBefore(previousMonthStart) &&
              tx.occurredAt.isBefore(monthStart),
        )
        .fold<int>(0, (sum, tx) => sum + tx.amount);

    groups.add(
      RecurringSpendGroup(
        groupKey: entry.key,
        displayName: _displayName(cluster.first)!,
        kind: classification.kind,
        score: classification.score,
        confidence: _confidenceFor(classification),
        evidenceCodes: classification.evidenceCodes,
        isVisibleOnHome: classification.score >= 80,
        currentMonthAmount: currentMonthAmount,
        previousMonthAmount: previousMonthAmount,
        transactions: cluster,
      ),
    );
  }

  final visibleGroups = groups.where((group) => group.isVisibleOnHome).toList()
    ..sort((a, b) {
      final amountCompare =
          b.currentMonthAmount.compareTo(a.currentMonthAmount);
      if (amountCompare != 0) {
        return amountCompare;
      }

      return b.score.compareTo(a.score);
    });

  return RecurringSpendInsight(
    groups: visibleGroups,
    totalCurrentMonthAmount: visibleGroups.fold<int>(
      0,
      (sum, group) => sum + group.currentMonthAmount,
    ),
    totalPreviousMonthAmount: visibleGroups.fold<int>(
      0,
      (sum, group) => sum + group.previousMonthAmount,
    ),
  );
}

class _Classification {
  const _Classification(this.kind, this.score, this.evidenceCodes);

  final RecurringSpendKind kind;
  final int score;
  final List<RecurringSpendEvidenceCode> evidenceCodes;
}

_Classification? _classifyCluster(
  List<Transaction> cluster, {
  required DateTime now,
}) {
  if (cluster.length < 2) {
    return null;
  }

  final subscription = _classifySubscription(cluster);
  if (subscription != null) {
    return subscription;
  }

  final fixed = _classifyFixed(cluster);
  if (fixed != null) {
    return fixed;
  }

  final lifestyle = _classifyLifestyle(cluster, now: now);
  if (lifestyle != null) {
    return lifestyle;
  }

  return null;
}

_Classification? _classifySubscription(List<Transaction> cluster) {
  final hasKeyword = cluster.any((tx) => _containsSubscriptionKeyword(tx));
  if (!hasKeyword || !_isAmountVarianceWithin(cluster, 0.05)) {
    return null;
  }

  return const _Classification(
    RecurringSpendKind.subscription,
    90,
    [
      RecurringSpendEvidenceCode.subscriptionKeyword,
      RecurringSpendEvidenceCode.stableAmount,
    ],
  );
}

_Classification? _classifyFixed(List<Transaction> cluster) {
  if (!_hasMonthlyCadence(cluster) || !_isAmountVarianceWithin(cluster, 0.05)) {
    return null;
  }

  return const _Classification(
    RecurringSpendKind.fixed,
    92,
    [
      RecurringSpendEvidenceCode.monthlyCadence,
      RecurringSpendEvidenceCode.stableAmount,
    ],
  );
}

_Classification? _classifyLifestyle(
  List<Transaction> cluster, {
  required DateTime now,
}) {
  final recentCutoff = now.subtract(const Duration(days: 45));
  final recentCount =
      cluster.where((tx) => !tx.occurredAt.isBefore(recentCutoff)).length;
  if (recentCount < 3) {
    return null;
  }

  var score = 0;
  if (_normalizedDisplayName(cluster.first) != null) {
    score += 40;
  }
  if (cluster.first.categoryId != null) {
    score += 15;
  }
  if (cluster.first.accountId != null || cluster.first.paymentMethod != null) {
    score += 10;
  }
  if (recentCount >= 3) {
    score += 20;
  }
  if (_isAmountVarianceWithin(cluster, 0.15)) {
    score += 10;
  } else {
    score -= 20;
  }
  if (_hasShortCadence(cluster)) {
    score += 5;
  }

  if (score < 60) {
    return null;
  }

  final evidenceCodes = <RecurringSpendEvidenceCode>[
    RecurringSpendEvidenceCode.recentRepeatCount,
  ];
  if (cluster.first.categoryId != null) {
    evidenceCodes.add(RecurringSpendEvidenceCode.sameCategoryPattern);
  }
  if (cluster.first.accountId != null || cluster.first.paymentMethod != null) {
    evidenceCodes.add(RecurringSpendEvidenceCode.sameAccountPattern);
  }
  if (_isAmountVarianceWithin(cluster, 0.15)) {
    evidenceCodes.add(RecurringSpendEvidenceCode.stableAmount);
  }

  return _Classification(RecurringSpendKind.lifestyle, score, evidenceCodes);
}

RecurringSpendConfidence _confidenceFor(_Classification classification) {
  if (classification.kind == RecurringSpendKind.lifestyle) {
    return RecurringSpendConfidence.medium;
  }

  return classification.score >= 90
      ? RecurringSpendConfidence.high
      : RecurringSpendConfidence.medium;
}

bool _isEligibleExpense(Transaction tx) {
  return tx.deletedAt == null &&
      tx.type == 'expense' &&
      tx.type != 'transfer' &&
      (_normalizedDisplayName(tx) != null);
}

String? _displayName(Transaction tx) {
  final merchant = tx.merchantName?.trim();
  if (merchant != null && merchant.isNotEmpty) {
    return merchant;
  }

  final memo = tx.memo?.trim();
  if (memo != null && memo.isNotEmpty) {
    return memo;
  }

  return null;
}

String? _normalizedDisplayName(Transaction tx) {
  final base = _displayName(tx);
  if (base == null) {
    return null;
  }

  final collapsed = base.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
  final normalized =
      collapsed.replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), '');
  if (normalized.trim().isEmpty) {
    return null;
  }

  return normalized.trim();
}

bool _containsSubscriptionKeyword(Transaction tx) {
  final text = '${tx.merchantName ?? ''} ${tx.memo ?? ''}'.toLowerCase();
  const keywords = [
    'subscription',
    'premium',
    'membership',
    'netflix',
    'spotify',
    'youtube',
    'apple',
    'google',
    '넷플릭스',
    '유튜브',
  ];

  return keywords.any(text.contains);
}

bool _hasMonthlyCadence(List<Transaction> cluster) {
  final intervals = _intervalDays(cluster);
  return intervals.any((days) => days >= 20 && days <= 40);
}

bool _hasShortCadence(List<Transaction> cluster) {
  final intervals = _intervalDays(cluster);
  return intervals.any((days) => days >= 3 && days <= 14);
}

List<int> _intervalDays(List<Transaction> cluster) {
  final intervals = <int>[];
  for (var i = 1; i < cluster.length; i++) {
    intervals.add(
      cluster[i].occurredAt.difference(cluster[i - 1].occurredAt).inDays.abs(),
    );
  }
  return intervals;
}

bool _isAmountVarianceWithin(List<Transaction> cluster, double tolerance) {
  if (cluster.isEmpty) {
    return false;
  }

  final amounts = cluster.map((tx) => tx.amount).toList();
  final minAmount = amounts.reduce((a, b) => a < b ? a : b);
  final maxAmount = amounts.reduce((a, b) => a > b ? a : b);
  if (minAmount == 0) {
    return maxAmount == 0;
  }

  final varianceRatio = (maxAmount - minAmount) / minAmount;
  return varianceRatio <= tolerance;
}
