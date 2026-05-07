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
    this.largeTitle = false,
  });

  final Widget? eyebrow;
  final String title;
  final String? body;
  final Widget? footer;
  final Widget? animatedBackdrop;
  final bool largeTitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mood = theme.extension<AppMood>()!;
    final titleStyle = largeTitle
        ? theme.textTheme.displayLarge?.copyWith(
            color: mood.heroForeground,
            fontWeight: FontWeight.w300,
            height: 0.92,
            letterSpacing: -2.4,
            shadows: [
              Shadow(
                color: Colors.white.withValues(alpha: 0.18),
                blurRadius: 16,
              ),
            ],
          )
        : theme.textTheme.headlineMedium?.copyWith(
            color: mood.heroForeground,
            fontWeight: FontWeight.w700,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 12,
              ),
            ],
          );

    return Stack(
      children: [
        if (animatedBackdrop != null)
          Positioned.fill(child: animatedBackdrop!),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (eyebrow != null) eyebrow!,
              if (eyebrow != null) const SizedBox(height: AppSpacing.lg),
              Text(
                title,
                style: titleStyle,
              ),
              if (body != null) ...[
                const SizedBox(height: AppSpacing.md),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: Text(
                    body!,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: mood.heroMutedForeground,
                      height: 1.42,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (footer != null) ...[
                const SizedBox(height: AppSpacing.xl),
                footer!,
              ],
            ],
          ),
        ),
      ],
    );
  }
}
