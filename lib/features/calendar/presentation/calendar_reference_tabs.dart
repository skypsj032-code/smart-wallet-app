import 'package:flutter/material.dart';

import '../../../core/constants/app_spacing.dart';

enum CalendarReferenceTab {
  calendar,
  transactions,
  statistics,
}

class CalendarReferenceTabs extends StatelessWidget {
  const CalendarReferenceTabs({
    super.key,
    required this.activeTab,
    required this.onOpenTimeline,
    required this.onOpenStatistics,
  });

  final CalendarReferenceTab activeTab;
  final VoidCallback onOpenTimeline;
  final VoidCallback onOpenStatistics;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      key: const Key('calendar-reference-tabs'),
      height: 58,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: scheme.outline.withValues(alpha: 0.12)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _CalendarTopTab(
              key: const Key('calendar-tab-calendar'),
              label: '달력',
              active: activeTab == CalendarReferenceTab.calendar,
              activeTextColor: scheme.onSurface,
              activeIndicatorColor: scheme.primary,
              inactiveColor: scheme.onSurfaceVariant,
              onTap: null,
            ),
          ),
          Expanded(
            child: _CalendarTopTab(
              key: const Key('calendar-tab-transactions'),
              label: '거래 내역',
              active: activeTab == CalendarReferenceTab.transactions,
              activeTextColor: scheme.onSurface,
              activeIndicatorColor: scheme.primary,
              inactiveColor: scheme.onSurfaceVariant,
              onTap: onOpenTimeline,
            ),
          ),
          Expanded(
            child: _CalendarTopTab(
              key: const Key('calendar-tab-statistics'),
              label: '소비 분석',
              active: activeTab == CalendarReferenceTab.statistics,
              activeTextColor: scheme.onSurface,
              activeIndicatorColor: scheme.primary,
              inactiveColor: scheme.onSurfaceVariant,
              onTap: onOpenStatistics,
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarTopTab extends StatelessWidget {
  const _CalendarTopTab({
    super.key,
    required this.label,
    required this.active,
    required this.activeTextColor,
    required this.activeIndicatorColor,
    required this.inactiveColor,
    required this.onTap,
  });

  final String label;
  final bool active;
  final Color activeTextColor;
  final Color activeIndicatorColor;
  final Color inactiveColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          color: active ? activeTextColor : inactiveColor,
        );

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: Center(
              child: Text(label, style: textStyle),
            ),
          ),
          AnimatedContainer(
            key: active ? const Key('calendar-tab-active-indicator') : null,
            duration: const Duration(milliseconds: 160),
            height: 3,
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            decoration: BoxDecoration(
              color: active ? activeIndicatorColor : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }
}
