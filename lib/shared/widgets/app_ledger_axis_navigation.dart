import 'package:flutter/material.dart';

import '../../core/constants/app_spacing.dart';

enum LedgerAxis {
  calendar,
  statistics,
  accounts,
}

class AppLedgerAxisNavigation extends StatelessWidget {
  const AppLedgerAxisNavigation({
    super.key,
    required this.currentAxis,
    required this.onOpenCalendar,
    required this.onOpenStatistics,
    required this.onOpenAccounts,
  });

  final LedgerAxis currentAxis;
  final VoidCallback onOpenCalendar;
  final VoidCallback onOpenStatistics;
  final VoidCallback onOpenAccounts;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const Key('ledger-axis-navigation-card'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            Expanded(
              child: _AxisTile(
                axis: LedgerAxis.calendar,
                currentAxis: currentAxis,
                icon: Icons.calendar_month_rounded,
                label: '달력',
                caption: '날짜',
                onTap: onOpenCalendar,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _AxisTile(
                axis: LedgerAxis.statistics,
                currentAxis: currentAxis,
                icon: Icons.insert_chart_rounded,
                label: '통계',
                caption: '요약',
                onTap: onOpenStatistics,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _AxisTile(
                axis: LedgerAxis.accounts,
                currentAxis: currentAxis,
                icon: Icons.account_balance_wallet_rounded,
                label: '자산',
                caption: '계좌',
                onTap: onOpenAccounts,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AxisTile extends StatelessWidget {
  const _AxisTile({
    required this.axis,
    required this.currentAxis,
    required this.icon,
    required this.label,
    required this.caption,
    required this.onTap,
  });

  final LedgerAxis axis;
  final LedgerAxis currentAxis;
  final IconData icon;
  final String label;
  final String caption;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCurrent = axis == currentAxis;

    return InkWell(
      key: Key('ledger-axis-${axis.name}'),
      onTap: isCurrent ? null : onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isCurrent
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 20,
              color: isCurrent
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.primary,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: isCurrent
                    ? theme.colorScheme.onPrimaryContainer
                    : null,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              caption,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isCurrent
                    ? theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.72)
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


