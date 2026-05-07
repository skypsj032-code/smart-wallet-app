import 'package:flutter/material.dart';

import '../../core/constants/app_spacing.dart';
import 'glass_card.dart';

class AppUtilityGroup extends StatelessWidget {
  const AppUtilityGroup({
    super.key,
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GlassCard(
      blur: 16,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        children: [
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index != children.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Divider(
                  height: 1,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.18)
                      : theme.colorScheme.outline.withValues(alpha: 0.56),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
