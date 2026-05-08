import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/app_section_intro.dart';
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
          // ── 분석 & 조회 ───────────────────────────────────────────
          const AppSectionIntro(
            title: '분석 & 조회',
            subtitle: '거래 내역을 다양한 방법으로 탐색합니다.',
          ),
          const SizedBox(height: AppSpacing.sm),
          AppUtilityGroup(
            children: [
              _ToolsTile(
                icon: Icons.search_rounded,
                color: AppColors.primary,
                title: '거래 검색',
                subtitle: '키워드·메모·상호명으로 빠르게 찾기',
                onTap: () => context.go('/search'),
              ),
              _ToolsTile(
                icon: Icons.calendar_month_rounded,
                color: AppColors.primary,
                title: '달력',
                subtitle: '일별·월별·연별 달력으로 흐름 확인',
                onTap: () => context.go('/calendar'),
              ),
              _ToolsTile(
                icon: Icons.bar_chart_rounded,
                color: AppColors.primary,
                title: '통계',
                subtitle: '카테고리별 지출 분석 및 추이 확인',
                onTap: () => context.go('/statistics'),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // ── 자산 & 예산 ───────────────────────────────────────────
          const AppSectionIntro(
            title: '자산 & 예산',
            subtitle: '계좌 잔고와 예산 한도를 한 곳에서 관리합니다.',
          ),
          const SizedBox(height: AppSpacing.sm),
          AppUtilityGroup(
            children: [
              _ToolsTile(
                icon: Icons.account_balance_wallet_outlined,
                color: AppColors.primary,
                title: '계좌 관리',
                subtitle: '현금·카드·예금 계좌별 잔고 현황',
                onTap: () => context.go('/accounts'),
              ),
              _ToolsTile(
                icon: Icons.savings_outlined,
                color: AppColors.primary,
                title: '예산 관리',
                subtitle: '이번 달 카테고리별 한도 설정',
                onTap: () => context.go('/budgets'),
              ),
              _ToolsTile(
                icon: Icons.event_repeat_rounded,
                color: AppColors.primary,
                title: '정기 거래',
                subtitle: '구독·월세 등 반복 지출 자동 제안',
                onTap: () => context.go('/recurring-expenses'),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // ── 스마트 기능 ───────────────────────────────────────────
          const AppSectionIntro(
            title: '스마트 기능',
            subtitle: '알림 감지와 영수증 촬영으로 입력을 자동화합니다.',
          ),
          const SizedBox(height: AppSpacing.sm),
          AppUtilityGroup(
            children: [
              _ToolsTile(
                icon: Icons.notifications_active_outlined,
                color: AppColors.income,
                title: '알림 수신 이력',
                subtitle: '카드·은행 알림에서 자동 감지한 내역',
                onTap: () => context.go('/notification-history'),
              ),
              _ToolsTile(
                icon: Icons.document_scanner_outlined,
                color: AppColors.primary,
                title: '영수증 촬영',
                subtitle: '사진으로 찍어 거래 내역 자동 인식',
                onTap: () => context.go('/ocr-capture'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── 개별 타일 ────────────────────────────────────────────────────────────────

class _ToolsTile extends StatelessWidget {
  const _ToolsTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          : null,
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: theme.colorScheme.outlineVariant,
      ),
      onTap: onTap,
    );
  }
}
