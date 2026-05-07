import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../shared/widgets/app_hero_panel.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/app_status_chip.dart';
import '../../../shared/widgets/app_utility_group.dart';

class ToolsScreen extends ConsumerWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppScaffold(
      title: '도구',
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          const _ToolsHeroCard(),
          const SizedBox(height: AppSpacing.lg),
          AppUtilityGroup(
            children: [
              _ToolsActionTile(
                icon: Icons.search_rounded,
                color: AppColors.primary,
                title: '거래 검색',
                onTap: () => context.go('/search'),
              ),
              _ToolsActionTile(
                icon: Icons.account_balance_wallet_outlined,
                color: AppColors.primary,
                title: '계좌 관리',
                onTap: () => context.go('/accounts'),
              ),
              _ToolsActionTile(
                icon: Icons.savings_outlined,
                color: AppColors.primary,
                title: '예산 관리',
                onTap: () => context.go('/budgets'),
              ),
              _ToolsActionTile(
                icon: Icons.event_repeat_rounded,
                color: AppColors.primary,
                title: '고정 지출',
                onTap: () => context.go('/recurring-expenses'),
              ),
              _ToolsActionTile(
                icon: Icons.document_scanner_outlined,
                color: AppColors.primary,
                title: '영수증 스캔',
                onTap: () => context.go('/ocr-capture'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          AppUtilityGroup(
            children: [
              _ToolsActionTile(
                icon: Icons.calendar_month_rounded,
                color: AppColors.primary,
                title: '달력',
                onTap: () => context.go('/calendar'),
              ),
              _ToolsActionTile(
                icon: Icons.bar_chart_rounded,
                color: AppColors.primary,
                title: '통계',
                onTap: () => context.go('/statistics'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ToolsHeroCard extends StatelessWidget {
  const _ToolsHeroCard();

  @override
  Widget build(BuildContext context) {
    return const AppHeroPanel(
      eyebrow: AppStatusChip(
        label: 'MONEY TOOLS',
        dotColor: AppColors.primary,
      ),
      title: '도구',
    );
  }
}

class _ToolsActionTile extends StatelessWidget {
  const _ToolsActionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final foreground = isDark ? Colors.white : theme.colorScheme.onSurface;
    final mutedForeground = isDark
        ? Colors.white.withValues(alpha: 0.76)
        : theme.colorScheme.onSurfaceVariant;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.12),
        child: Icon(icon, color: color),
      ),
      title: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: mutedForeground,
      ),
    );
  }
}
