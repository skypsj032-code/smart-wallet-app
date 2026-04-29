import 'package:flutter/material.dart';

import '../../app/theme/app_radius.dart';
import '../../core/constants/app_spacing.dart';

class AppMetricStrip extends StatelessWidget {
  const AppMetricStrip({
    super.key,
    required this.label,
    required this.value,
    this.caption,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final String? caption;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: emphasize
            ? theme.colorScheme.primary.withValues(alpha: 0.1)
            : theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: emphasize
              ? theme.colorScheme.primary.withValues(alpha: 0.18)
              : theme.colorScheme.outline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(
              color: emphasize
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              caption!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
