import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_mood.dart';
import '../../app/theme/app_radius.dart';
import '../../core/constants/app_spacing.dart';

class AppHeroPanel extends StatelessWidget {
  const AppHeroPanel({
    super.key,
    this.eyebrow,
    required this.title,
    this.body,
    this.footer,
  });

  final Widget? eyebrow;
  final String title;
  final String? body;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mood = theme.extension<AppMood>()!;

    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: theme.colorScheme.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            top: -22,
            child: Container(
              width: 116,
              height: 116,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            left: 32,
            bottom: -30,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.03),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eyebrow != null) eyebrow!,
                if (eyebrow != null) const SizedBox(height: AppSpacing.md),
                Text(
                  title,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: mood.heroForeground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (body != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    body!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: mood.heroMutedForeground,
                    ),
                  ),
                ],
                if (footer != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  footer!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
