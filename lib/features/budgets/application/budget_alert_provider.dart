import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'budget_provider.dart';

/// 예산 임계값 초과 이벤트 타입.
enum BudgetAlertLevel {
  /// 50% 이상
  half,

  /// 80% 이상
  warning,

  /// 100% 이상
  exceeded,
}

class BudgetAlertEvent {
  const BudgetAlertEvent({
    required this.level,
    required this.label,
    required this.progress,
  });

  final BudgetAlertLevel level;

  /// 카테고리 이름 (전체 예산은 '전체')
  final String label;

  /// 소진율 (0.0 ~ 1.0+)
  final double progress;
}

/// 세션 내 이미 표시한 알림 키: '{categoryId|all}_{level}_{monthKey}'
typedef _AlertKey = String;

/// 예산 알림 스트림 — 새 임계값 돌파 이벤트를 발행한다.
///
/// 동일 예산 항목의 동일 레벨 알림은 세션당 한 번만 발행한다.
/// AppShell 등 전역 위젯에서 `ref.listen`으로 구독해 SnackBar를 표시한다.
class BudgetAlertNotifier extends Notifier<BudgetAlertEvent?> {
  final _firedKeys = <_AlertKey>{};

  @override
  BudgetAlertEvent? build() {
    ref.listen<AsyncValue<BudgetSummary>>(
      budgetSummaryProvider,
      (previous, next) {
        final summary = next.asData?.value;
        if (summary == null) return;

        _checkThresholds(summary);
      },
      fireImmediately: false,
    );

    return null;
  }

  void _checkThresholds(BudgetSummary summary) {
    for (final item in summary.items) {
      final progress = item.progress;
      final key = item.categoryId ?? 'all';
      final month = summary.monthKey;

      // 100% 초과 — 가장 심각, 먼저 처리
      final key100 = '${key}_100_$month';
      if (progress >= 1.0 && !_firedKeys.contains(key100)) {
        _firedKeys.add(key100);
        state = BudgetAlertEvent(
          level: BudgetAlertLevel.exceeded,
          label: item.label,
          progress: progress,
        );
        return; // 한 번에 하나씩만 발행
      }

      // 80% 이상
      final key80 = '${key}_80_$month';
      if (progress >= 0.8 && !_firedKeys.contains(key80)) {
        _firedKeys.add(key80);
        state = BudgetAlertEvent(
          level: BudgetAlertLevel.warning,
          label: item.label,
          progress: progress,
        );
        return;
      }

      // 50% 이상
      final key50 = '${key}_50_$month';
      if (progress >= 0.5 && !_firedKeys.contains(key50)) {
        _firedKeys.add(key50);
        state = BudgetAlertEvent(
          level: BudgetAlertLevel.half,
          label: item.label,
          progress: progress,
        );
        return;
      }
    }
  }
}

final budgetAlertProvider =
    NotifierProvider<BudgetAlertNotifier, BudgetAlertEvent?>(
  BudgetAlertNotifier.new,
);
