import 'package:flutter/material.dart';

import '../../app/theme/app_radius.dart';
import '../../core/constants/app_spacing.dart';

class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.label,
    required this.value,
    this.caption,
  });

  final String label;
  final String value;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 26,
              height: 3,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(label, style: theme.textTheme.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(value, style: theme.textTheme.headlineSmall),
            if (caption != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                caption!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

