import 'package:flutter/material.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../shared/widgets/glass_card.dart';
import '../application/dashboard_narrative.dart';

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
    final narrative = buildDashboardNarrative(snapshot);

    return GlassCard(
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
    );
  }
}
