import 'package:flutter/material.dart';

import '../../app/theme/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import 'app_brand_mark.dart';

class BrandSplashScreen extends StatelessWidget {
  const BrandSplashScreen({
    super.key,
    this.title = 'Smart Wallet',
    this.subtitle = '오늘의 흐름을 차분하게 기록하는 지갑',
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(color: theme.colorScheme.outline),
                ),
                child: const Center(
                  child: AppBrandMark(size: 72, withBadge: true),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                title,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              if (trailing != null) ...[
                const SizedBox(height: AppSpacing.xl),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
