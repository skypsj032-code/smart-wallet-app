import 'package:flutter/material.dart';

import '../../../core/constants/app_spacing.dart';

class CalendarReferenceTabs extends StatelessWidget {
  const CalendarReferenceTabs({
    super.key,
    required this.onOpenTimeline,
    required this.onOpenStatistics,
  });

  final VoidCallback onOpenTimeline;
  final VoidCallback onOpenStatistics;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final activeColor = scheme.primary;
    final inactiveColor = scheme.onSurfaceVariant;

    return Container(
      key: const Key('calendar-reference-tabs'),
      height: 56,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: scheme.outline.withValues(alpha: 0.14)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _CalendarTopTab(
              key: const Key('calendar-tab-calendar'),
              label: '달력',
              active: true,
              activeColor: activeColor,
              inactiveColor: inactiveColor,
              onTap: null,
            ),
          ),
          Expanded(
            child: _CalendarTopTab(
              key: const Key('calendar-tab-transactions'),
              label: '거래 내역',
              active: false,
              activeColor: activeColor,
              inactiveColor: inactiveColor,
              onTap: onOpenTimeline,
            ),
          ),
          Expanded(
            child: _CalendarTopTab(
              key: const Key('calendar-tab-statistics'),
              label: '소비 분석',
              active: false,
              activeColor: activeColor,
              inactiveColor: inactiveColor,
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
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  final String label;
  final bool active;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: active ? FontWeight.w800 : FontWeight.w600,
          color: active ? activeColor : inactiveColor,
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
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            decoration: BoxDecoration(
              color: active ? activeColor : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }
}
