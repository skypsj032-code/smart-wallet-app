import 'package:flutter/material.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../shared/widgets/glass_card.dart';
import '../application/dashboard_narrative.dart';

String dashboardNarrativeSemanticLabel(DashboardNarrativeSnapshot snapshot) {
  final weather = buildDashboardWeatherSummary(snapshot);
  final narrative = buildDashboardNarrative(snapshot);
  return 'Dashboard insight. 이번 달 소비 날씨. ${weather.headline} '
      '${weather.evidence} ${narrative.headline} ${narrative.evidence}';
}

class DashboardNarrativeCard extends StatelessWidget {
  const DashboardNarrativeCard({
    super.key,
    required this.snapshot,
  });

  final DashboardNarrativeSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onCard = theme.colorScheme.onSurface;
    final weather = buildDashboardWeatherSummary(snapshot);
    final narrative = buildDashboardNarrative(snapshot);

    return Semantics(
      container: true,
      label: dashboardNarrativeSemanticLabel(snapshot),
      child: GlassCard(
        blur: 20,
        borderRadius: BorderRadius.circular(30),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: Icon(
                    _weatherIcon(weather.kind),
                    color: theme.colorScheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '이번 달 소비 날씨',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        weather.headline,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: onCard,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              weather.evidence,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Divider(color: theme.colorScheme.outlineVariant),
            const SizedBox(height: AppSpacing.sm),
            Text(
              narrative.headline,
              style: theme.textTheme.titleMedium?.copyWith(
                color: onCard,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              narrative.evidence,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

IconData _weatherIcon(DashboardWeatherKind kind) {
  switch (kind) {
    case DashboardWeatherKind.budgetInRange:
      return Icons.wb_sunny_outlined;
    case DashboardWeatherKind.waitingForRecords:
    case DashboardWeatherKind.gatheringRecords:
    case DashboardWeatherKind.budgetNotSet:
    case DashboardWeatherKind.nearBudget:
      return Icons.cloud_queue;
    case DashboardWeatherKind.budgetReached:
    case DashboardWeatherKind.budgetExceeded:
      return Icons.cloud_outlined;
  }
}
