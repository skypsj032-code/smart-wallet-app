import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_spacing.dart';

class ThemeModeTile extends StatelessWidget {
  const ThemeModeTile({
    super.key,
    required this.currentMode,
    required this.onChanged,
  });

  final String currentMode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      leading: CircleAvatar(
        backgroundColor: AppColors.primary.withValues(alpha: 0.12),
        child: Icon(_modeIcon(currentMode), color: AppColors.primary),
      ),
      title: Text(
        '화면 모드',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(_modeLabel(currentMode)),
      ),
      minVerticalPadding: 0,
      isThreeLine: true,
      trailing: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 208),
        child: SegmentedButton<String>(
          key: const Key('theme-mode-segmented-control'),
          segments: const [
            ButtonSegment<String>(
              value: 'system',
              icon: Icon(Icons.brightness_auto_outlined),
              label: Text('시스템'),
            ),
            ButtonSegment<String>(
              value: 'light',
              icon: Icon(Icons.light_mode_outlined),
              label: Text('라이트'),
            ),
            ButtonSegment<String>(
              value: 'dark',
              icon: Icon(Icons.dark_mode_outlined),
              label: Text('다크'),
            ),
          ],
          selected: {currentMode},
          onSelectionChanged: (selection) => onChanged(selection.first),
          showSelectedIcon: false,
        ),
      ),
    );
  }

  IconData _modeIcon(String mode) {
    return switch (mode) {
      'dark' => Icons.dark_mode_outlined,
      'light' => Icons.light_mode_outlined,
      _ => Icons.brightness_auto_outlined,
    };
  }

  String _modeLabel(String mode) {
    return switch (mode) {
      'light' => '밝은 화면으로 표시합니다.',
      'dark' => '어두운 화면으로 표시합니다.',
      _ => '기기 설정에 따라 자동으로 맞춥니다.',
    };
  }
}
