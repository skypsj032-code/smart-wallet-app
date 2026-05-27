import 'package:flutter/material.dart';

import '../../core/constants/app_spacing.dart';
import 'app_status_chip.dart';

class AppLedgerAxisIntro extends StatelessWidget {
  const AppLedgerAxisIntro({
    super.key,
    required this.label,
    required this.headline,
    required this.body,
  });

  final String label;
  final String headline;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      key: const Key('ledger-axis-intro-card'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppStatusChip(
              label: label,
              dotColor: theme.colorScheme.primary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              headline,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              body,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
