import 'package:flutter/material.dart';

import '../../app/theme/app_mood.dart';
import '../../core/constants/app_spacing.dart';

class AppHeroPanel extends StatelessWidget {
  const AppHeroPanel({
    super.key,
    this.eyebrow,
    required this.title,
    this.body,
    this.footer,
    this.animatedBackdrop,
  });

  final Widget? eyebrow;
  final String title;
  final String? body;
  final Widget? footer;
  final Widget? animatedBackdrop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mood = theme.extension<AppMood>()!;

    return Stack(
      children: [
        if (animatedBackdrop != null)
          Positioned.fill(child: animatedBackdrop!),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.xl,
            AppSpacing.md,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (eyebrow != null) eyebrow!,
              if (eyebrow != null) const SizedBox(height: AppSpacing.md),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: mood.heroForeground,
                  fontWeight: FontWeight.w700,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 16,
                    ),
                  ],
                ),
              ),
              if (body != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  body!,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: mood.heroMutedForeground,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.22),
                        blurRadius: 8,
                      ),
                    ],
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
    );
  }
}
