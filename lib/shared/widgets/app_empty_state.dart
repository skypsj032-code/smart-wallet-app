import 'package:flutter/material.dart';

import '../../app/theme/app_radius.dart';
import '../../app/theme/app_sizes.dart';
import '../../core/constants/app_spacing.dart';

/// 빈 상태(empty state) 공통 위젯.
/// 아이콘 + 제목 + 선택적 부제목 + 선택적 액션 버튼으로 구성된다.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.iconColor,
    this.iconBackgroundColor,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  final Color? iconColor;
  final Color? iconBackgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedIconColor =
        iconColor ?? theme.colorScheme.onSurfaceVariant;
    final resolvedIconBg =
        iconBackgroundColor ?? theme.colorScheme.surfaceContainerHighest;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: AppSizes.iconXL,
              height: AppSizes.iconXL,
              decoration: BoxDecoration(
                color: resolvedIconBg,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Icon(
                icon,
                size: AppSizes.iconMD,
                color: resolvedIconColor,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppSpacing.md),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
