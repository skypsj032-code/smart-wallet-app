import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../accounts/application/accounts_provider.dart';

enum WealthStage {
  coins,
  coinsAndBills,
  coinsBillsAndAssets,
}

enum WealthReactionDirection {
  increase,
  decrease,
}

enum WealthReactionIntensity {
  tiny,
  small,
  medium,
  large,
}

class WealthVisualState {
  const WealthVisualState({
    required this.totalBalance,
    required this.stage,
    required this.coinDensity,
    required this.billDensity,
    required this.assetIntensity,
  });

  final int totalBalance;
  final WealthStage stage;
  final double coinDensity;
  final double billDensity;
  final double assetIntensity;
}

class WealthReaction {
  const WealthReaction({
    required this.direction,
    required this.intensity,
    required this.deltaAmount,
  });

  final WealthReactionDirection direction;
  final WealthReactionIntensity intensity;
  final int deltaAmount;
}

final totalActiveAccountBalanceProvider = Provider<AsyncValue<int>>((ref) {
  final balancesAsync = ref.watch(accountBalancesProvider);
  return balancesAsync.whenData(
    (balances) => balances.fold<int>(0, (sum, item) => sum + item.balance),
  );
});

WealthVisualState buildWealthVisualState(int totalBalance) {
  if (totalBalance < 1000000) {
    final progress = (totalBalance / 1000000).clamp(0.0, 1.0);
    return WealthVisualState(
      totalBalance: totalBalance,
      stage: WealthStage.coins,
      coinDensity: _lerp(0.24, 0.78, progress),
      billDensity: 0,
      assetIntensity: 0,
    );
  }

  if (totalBalance < 5000000) {
    final progress = ((totalBalance - 1000000) / 4000000).clamp(0.0, 1.0);
    return WealthVisualState(
      totalBalance: totalBalance,
      stage: WealthStage.coinsAndBills,
      coinDensity: _lerp(0.64, 0.92, progress),
      billDensity: _lerp(0.18, 0.82, progress),
      assetIntensity: 0,
    );
  }

  final progress = ((totalBalance - 5000000) / 10000000).clamp(0.0, 1.0);
  return WealthVisualState(
    totalBalance: totalBalance,
    stage: WealthStage.coinsBillsAndAssets,
    coinDensity: 0.9,
    billDensity: _lerp(0.72, 1.0, progress),
    assetIntensity: _lerp(0.18, 1.0, progress),
  );
}

WealthReaction? classifyWealthReaction({
  required int previousBalance,
  required int nextBalance,
}) {
  final delta = nextBalance - previousBalance;
  if (delta == 0) {
    return null;
  }

  final deltaAmount = delta.abs();
  final baseline = previousBalance.abs().clamp(1, 1 << 30);
  final deltaRatio = deltaAmount / baseline;

  final intensity = switch ((deltaAmount, deltaRatio)) {
    _ when deltaAmount >= 1000000 || deltaRatio >= 0.25 =>
      WealthReactionIntensity.large,
    _ when deltaAmount >= 300000 || deltaRatio >= 0.10 =>
      WealthReactionIntensity.medium,
    _ when deltaAmount >= 50000 || deltaRatio >= 0.03 =>
      WealthReactionIntensity.small,
    _ => WealthReactionIntensity.tiny,
  };

  return WealthReaction(
    direction: delta > 0
        ? WealthReactionDirection.increase
        : WealthReactionDirection.decrease,
    intensity: intensity,
    deltaAmount: deltaAmount,
  );
}

double _lerp(double a, double b, double t) {
  return a + ((b - a) * t);
}
