import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_motion.dart';
import '../../../app/theme/app_mood.dart';
import '../../../app/theme/app_opacity.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_shadows.dart';
import '../../../app/theme/app_sizes.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/app_status_chip.dart';

class DesignSystemScreen extends StatefulWidget {
  const DesignSystemScreen({super.key});

  @override
  State<DesignSystemScreen> createState() => _DesignSystemScreenState();
}

class _DesignSystemScreenState extends State<DesignSystemScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = [
    Tab(text: '기초'),
    Tab(text: '색상'),
    Tab(text: '타이포'),
    Tab(text: '컴포넌트'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      title: '디자인 시스템',
      contentPadding: EdgeInsets.zero,
      bottom: TabBar(
        controller: _tabController,
        tabs: _tabs,
        labelStyle: AppTypography.mono(
          brightness: theme.brightness,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
        unselectedLabelStyle: AppTypography.mono(
          brightness: theme.brightness,
          fontSize: 11,
        ),
        indicatorColor: AppColors.primary,
        dividerColor: theme.colorScheme.outline.withValues(alpha: 0.3),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _FoundationTab(),
          _ColorsTab(),
          _TypographyTab(),
          _ComponentsTab(),
        ],
      ),
    );
  }
}

// ── Foundation Tab ──────────────────────────────────────────────────────────

class _FoundationTab extends StatelessWidget {
  const _FoundationTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: const [
        _SectionHeader('간격 (Spacing)'),
        SizedBox(height: AppSpacing.sm),
        _SpacingShowcase(),
        SizedBox(height: AppSpacing.lg),
        _SectionHeader('반경 (Radius)'),
        SizedBox(height: AppSpacing.sm),
        _RadiusShowcase(),
        SizedBox(height: AppSpacing.lg),
        _SectionHeader('그림자 (Shadows)'),
        SizedBox(height: AppSpacing.sm),
        _ShadowShowcase(),
        SizedBox(height: AppSpacing.lg),
        _SectionHeader('모션 (Motion)'),
        SizedBox(height: AppSpacing.sm),
        _MotionShowcase(),
        SizedBox(height: AppSpacing.lg),
        _SectionHeader('불투명도 (Opacity)'),
        SizedBox(height: AppSpacing.sm),
        _OpacityShowcase(),
        SizedBox(height: AppSpacing.lg),
        _SectionHeader('아이콘 크기 (Icon Sizes)'),
        SizedBox(height: AppSpacing.sm),
        _IconSizeShowcase(),
        SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}

class _SpacingShowcase extends StatelessWidget {
  const _SpacingShowcase();

  static const _items = <(String, double)>[
    ('xxs', AppSpacing.xxs),
    ('xs', AppSpacing.xs),
    ('sm', AppSpacing.sm),
    ('md', AppSpacing.md),
    ('lg', AppSpacing.lg),
    ('xl', AppSpacing.xl),
    ('xxl', AppSpacing.xxl),
    ('xxxl', AppSpacing.xxxl),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: _items.map((item) {
            final (name, value) = item;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 48,
                    child: Text(
                      name,
                      style: AppTypography.mono(brightness: theme.brightness, fontSize: 10),
                    ),
                  ),
                  Container(
                    width: value,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '${value.toInt()}dp',
                    style: AppTypography.mono(brightness: theme.brightness, fontSize: 10),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _RadiusShowcase extends StatelessWidget {
  const _RadiusShowcase();

  static const _items = <(String, double)>[
    ('sm', AppRadius.sm),
    ('md', AppRadius.md),
    ('lg', AppRadius.lg),
    ('xl', AppRadius.xl),
    ('xxl', AppRadius.xxl),
    ('xxxl', AppRadius.xxxl),
    ('full', 24),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: _items.map((item) {
        final (name, value) = item;
        final radius = name == 'full' ? AppRadius.full : value;
        return Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
            borderRadius: BorderRadius.circular(radius),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                name,
                style: AppTypography.mono(brightness: theme.brightness, fontSize: 10),
              ),
              Text(
                name == 'full' ? '∞' : '${value.toInt()}',
                style: AppTypography.mono(
                  brightness: theme.brightness,
                  fontSize: 10,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _ShadowShowcase extends StatelessWidget {
  const _ShadowShowcase();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final items = <(String, List<BoxShadow>)>[
      ('none', isDark ? AppShadows.noneDark : AppShadows.noneLight),
      ('sm', isDark ? AppShadows.smDark : AppShadows.smLight),
      ('md', isDark ? AppShadows.mdDark : AppShadows.mdLight),
      ('lg', isDark ? AppShadows.lgDark : AppShadows.lgLight),
      ('xl', isDark ? AppShadows.xlDark : AppShadows.xlLight),
      ('primary\nglow', AppShadows.primaryGlow),
    ];

    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.lg,
      children: items.map((item) {
        final (name, shadow) = item;
        return Container(
          width: 80,
          height: 64,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: shadow,
          ),
          child: Center(
            child: Text(
              name,
              textAlign: TextAlign.center,
              style: AppTypography.mono(brightness: theme.brightness, fontSize: 9),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _MotionShowcase extends StatelessWidget {
  const _MotionShowcase();

  static const _durations = <(String, Duration)>[
    ('instant', AppMotion.instant),
    ('fast', AppMotion.fast),
    ('normal', AppMotion.normal),
    ('medium', AppMotion.medium),
    ('slow', AppMotion.slow),
    ('xslow', AppMotion.xslow),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: _durations.map((item) {
            final (name, duration) = item;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 56,
                    child: Text(
                      name,
                      style: AppTypography.mono(brightness: theme.brightness, fontSize: 10),
                    ),
                  ),
                  Expanded(
                    child: _AnimatedBar(duration: duration),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  SizedBox(
                    width: 48,
                    child: Text(
                      '${duration.inMilliseconds}ms',
                      textAlign: TextAlign.right,
                      style: AppTypography.mono(brightness: theme.brightness, fontSize: 10),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _AnimatedBar extends StatefulWidget {
  const _AnimatedBar({required this.duration});
  final Duration duration;

  @override
  State<_AnimatedBar> createState() => _AnimatedBarState();
}

class _AnimatedBarState extends State<_AnimatedBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: AppMotion.decelerate);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 16,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return AnimatedBuilder(
            animation: _anim,
            builder: (context, _) {
              return Stack(
                children: [
                  Container(
                    width: constraints.maxWidth,
                    height: 4,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Positioned(
                    left: _anim.value * (constraints.maxWidth - 16),
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _OpacityShowcase extends StatelessWidget {
  const _OpacityShowcase();

  static const _items = <(String, double)>[
    ('glassLight', AppOpacity.glassLight),
    ('glassDark', AppOpacity.glassDark),
    ('overlayHighlightLight', AppOpacity.overlayHighlightLight),
    ('overlayHighlightDark', AppOpacity.overlayHighlightDark),
    ('borderGlass', AppOpacity.borderGlass),
    ('iconInactive', AppOpacity.iconInactive),
    ('disabled', AppOpacity.disabled),
    ('chipSelected', AppOpacity.chipSelected),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: _items.map((item) {
            final (name, value) = item;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: AppTypography.mono(brightness: theme.brightness, fontSize: 10),
                    ),
                  ),
                  Container(
                    width: 100,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: value),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  SizedBox(
                    width: 36,
                    child: Text(
                      '${(value * 100).toInt()}%',
                      textAlign: TextAlign.right,
                      style: AppTypography.mono(brightness: theme.brightness, fontSize: 10),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _IconSizeShowcase extends StatelessWidget {
  const _IconSizeShowcase();

  static const _items = <(String, double)>[
    ('iconXS\n14', AppSizes.iconXS),
    ('iconSM\n18', AppSizes.iconSM),
    ('iconMD\n24', AppSizes.iconMD),
    ('iconLG\n32', AppSizes.iconLG),
    ('iconXL\n40', AppSizes.iconXL),
    ('iconXXL\n56', AppSizes.iconXXL),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: _items.map((item) {
        final (name, size) = item;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_rounded, size: size, color: AppColors.primary),
            const SizedBox(height: 4),
            Text(
              name,
              textAlign: TextAlign.center,
              style: AppTypography.mono(brightness: theme.brightness, fontSize: 8),
            ),
          ],
        );
      }).toList(),
    );
  }
}

// ── Colors Tab ───────────────────────────────────────────────────────────────

class _ColorsTab extends StatelessWidget {
  const _ColorsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: const [
        _SectionHeader('브랜드 컬러'),
        SizedBox(height: AppSpacing.sm),
        _ColorGroup(
          items: [
            _ColorItem('primary', AppColors.primary),
            _ColorItem('primaryDark', AppColors.primaryDark),
            _ColorItem('primaryLight', AppColors.primaryLight),
          ],
        ),
        SizedBox(height: AppSpacing.lg),
        _SectionHeader('수입 (Income)'),
        SizedBox(height: AppSpacing.sm),
        _ColorGroup(
          items: [
            _ColorItem('income', AppColors.income),
            _ColorItem('incomeLight', AppColors.incomeLight),
            _ColorItem('incomeDark', AppColors.incomeDark),
          ],
        ),
        SizedBox(height: AppSpacing.lg),
        _SectionHeader('지출 (Expense)'),
        SizedBox(height: AppSpacing.sm),
        _ColorGroup(
          items: [
            _ColorItem('expense', AppColors.expense),
            _ColorItem('expenseLight', AppColors.expenseLight),
            _ColorItem('expenseDark', AppColors.expenseDark),
          ],
        ),
        SizedBox(height: AppSpacing.lg),
        _SectionHeader('경고 / 정보'),
        SizedBox(height: AppSpacing.sm),
        _ColorGroup(
          items: [
            _ColorItem('warning', AppColors.warning),
            _ColorItem('warningLight', AppColors.warningLight),
            _ColorItem('info', AppColors.info),
            _ColorItem('infoLight', AppColors.infoLight),
          ],
        ),
        SizedBox(height: AppSpacing.lg),
        _SectionHeader('배경 / 카드'),
        SizedBox(height: AppSpacing.sm),
        _ColorGroup(
          items: [
            _ColorItem('backgroundLight', AppColors.backgroundLight),
            _ColorItem('backgroundDark', AppColors.backgroundDark),
            _ColorItem('cardLight', AppColors.cardLight),
            _ColorItem('cardDark', AppColors.cardDark),
          ],
        ),
        SizedBox(height: AppSpacing.lg),
        _SectionHeader('텍스트 / 보더'),
        SizedBox(height: AppSpacing.sm),
        _ColorGroup(
          items: [
            _ColorItem('ink', AppColors.ink),
            _ColorItem('mutedInk', AppColors.mutedInk),
            _ColorItem('softHighlight', AppColors.softHighlight),
            _ColorItem('borderLight', AppColors.borderLight),
            _ColorItem('borderDark', AppColors.borderDark),
          ],
        ),
        SizedBox(height: AppSpacing.lg),
        _SectionHeader('그라데이션'),
        SizedBox(height: AppSpacing.sm),
        _GradientShowcase(),
        SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}

class _ColorItem {
  const _ColorItem(this.name, this.color);
  final String name;
  final Color color;
}

class _ColorGroup extends StatelessWidget {
  const _ColorGroup({required this.items});
  final List<_ColorItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: items.map((item) {
        final luminance = item.color.computeLuminance();
        final textColor = luminance > 0.4 ? AppColors.ink : Colors.white;
        return Container(
          width: 100,
          height: 72,
          decoration: BoxDecoration(
            color: item.color,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
              width: 0.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: textColor.withValues(alpha: 0.85),
                  ),
                ),
                Text(
                  '#${item.color.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
                  style: TextStyle(
                    fontSize: 7,
                    color: textColor.withValues(alpha: 0.6),
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _GradientShowcase extends StatelessWidget {
  const _GradientShowcase();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = <(String, Gradient)>[
      ('primaryGradient', AppColors.primaryGradient),
      ('heroGradient', AppColors.heroGradient),
      ('incomeGradient', AppColors.incomeGradient),
      ('expenseGradient', AppColors.expenseGradient),
    ];
    return Column(
      children: items.map((item) {
        final (name, gradient) = item;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  name,
                  style: AppTypography.mono(
                    brightness: theme.brightness,
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Typography Tab ───────────────────────────────────────────────────────────

class _TypographyTab extends StatelessWidget {
  const _TypographyTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tt = theme.textTheme;

    final styles = <(String, TextStyle?)>[
      ('displayLarge — 40px w700', tt.displayLarge),
      ('displayMedium — 32px w700', tt.displayMedium),
      ('headlineLarge — 28px w700', tt.headlineLarge),
      ('headlineMedium — 24px w700', tt.headlineMedium),
      ('headlineSmall — 20px w700', tt.headlineSmall),
      ('titleLarge — 18px w700', tt.titleLarge),
      ('titleMedium — 16px w600', tt.titleMedium),
      ('titleSmall — 14px w600', tt.titleSmall),
      ('bodyLarge — 16px w400', tt.bodyLarge),
      ('bodyMedium — 14px w400', tt.bodyMedium),
      ('bodySmall — 13px w400 muted', tt.bodySmall),
      ('labelLarge — 12px mono', tt.labelLarge),
      ('labelMedium — 11px mono', tt.labelMedium),
      ('labelSmall — 10.5px mono', tt.labelSmall),
    ];

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        const _SectionHeader('텍스트 스케일'),
        const SizedBox(height: AppSpacing.sm),
        ...styles.map((item) {
          final (label, style) = item;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.mono(
                    brightness: theme.brightness,
                    fontSize: 9,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text('가계부 Wallet 123', style: style),
                Divider(
                  height: AppSpacing.md,
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ],
            ),
          );
        }),
        const _SectionHeader('모노스페이스 (JetBrains Mono)'),
        const SizedBox(height: AppSpacing.sm),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '₩ 1,234,567',
                  style: AppTypography.mono(
                    brightness: theme.brightness,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.income,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '₩ -89,000',
                  style: AppTypography.mono(
                    brightness: theme.brightness,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.expense,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'TXN-20260527-001',
                  style: AppTypography.mono(brightness: theme.brightness, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}

// ── Components Tab ───────────────────────────────────────────────────────────

class _ComponentsTab extends StatefulWidget {
  const _ComponentsTab();

  @override
  State<_ComponentsTab> createState() => _ComponentsTabState();
}

class _ComponentsTabState extends State<_ComponentsTab> {
  bool _switchValue = true;
  String _selectedSegment = 'income';
  final _textController = TextEditingController(text: '');

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mood = theme.extension<AppMood>();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // ── Buttons ──────────────────────────────────────
        const _SectionHeader('버튼'),
        const SizedBox(height: AppSpacing.sm),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton(onPressed: () {}, child: const Text('FilledButton')),
                const SizedBox(height: AppSpacing.sm),
                FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add),
                  label: const Text('FilledButton.icon'),
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton(onPressed: () {}, child: const Text('OutlinedButton')),
                const SizedBox(height: AppSpacing.sm),
                TextButton(onPressed: () {}, child: const Text('TextButton')),
                const SizedBox(height: AppSpacing.sm),
                const FilledButton(
                  onPressed: null,
                  child: Text('Disabled'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // ── Status Chips ──────────────────────────────────
        const _SectionHeader('상태 칩 (AppStatusChip)'),
        const SizedBox(height: AppSpacing.sm),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                AppStatusChip(label: 'INCOME', dotColor: AppColors.income),
                AppStatusChip(label: 'EXPENSE', dotColor: AppColors.expense),
                AppStatusChip(label: 'WARNING', dotColor: AppColors.warning),
                AppStatusChip(label: 'INFO', dotColor: AppColors.info),
                AppStatusChip(label: 'PRIMARY', dotColor: AppColors.primary),
                AppStatusChip(label: 'NO DOT'),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // ── Material Chips ────────────────────────────────
        const _SectionHeader('칩 (Material Chip)'),
        const SizedBox(height: AppSpacing.sm),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                FilterChip(label: const Text('전체'), selected: true, onSelected: (_) {}),
                FilterChip(label: const Text('식비'), selected: false, onSelected: (_) {}),
                FilterChip(label: const Text('교통'), selected: false, onSelected: (_) {}),
                InputChip(
                  label: const Text('삭제 가능'),
                  onDeleted: () {},
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // ── Segmented Button ──────────────────────────────
        const _SectionHeader('세그먼트 버튼'),
        const SizedBox(height: AppSpacing.sm),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'income', label: Text('수입')),
                ButtonSegment(value: 'expense', label: Text('지출')),
              ],
              selected: {_selectedSegment},
              onSelectionChanged: (s) =>
                  setState(() => _selectedSegment = s.first),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // ── Switch ────────────────────────────────────────
        const _SectionHeader('스위치 / 체크박스'),
        const SizedBox(height: AppSpacing.sm),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _switchValue,
                  onChanged: (v) => setState(() => _switchValue = v),
                  title: const Text('스위치'),
                  subtitle: const Text('알림 자동 기록 활성화'),
                ),
                CheckboxListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _switchValue,
                  onChanged: (v) => setState(() => _switchValue = v ?? false),
                  title: const Text('체크박스'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // ── Input ─────────────────────────────────────────
        const _SectionHeader('텍스트 입력'),
        const SizedBox(height: AppSpacing.sm),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                TextField(
                  controller: _textController,
                  decoration: const InputDecoration(
                    labelText: '금액',
                    prefixText: '₩ ',
                    hintText: '0',
                    suffixIcon: Icon(Icons.clear_rounded),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: AppSpacing.sm),
                const TextField(
                  decoration: InputDecoration(
                    labelText: '메모',
                    hintText: '거래 메모를 입력하세요',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: AppSpacing.sm),
                const TextField(
                  enabled: false,
                  decoration: InputDecoration(
                    labelText: '비활성화',
                    hintText: '수정 불가 필드',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // ── List Tiles ────────────────────────────────────
        const _SectionHeader('리스트 타일'),
        const SizedBox(height: AppSpacing.sm),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.income.withValues(alpha: 0.12),
                  child: const Icon(Icons.restaurant, color: AppColors.income),
                ),
                title: const Text('스타벅스 아메리카노'),
                subtitle: const Text('식비 · 오늘'),
                trailing: Text(
                  '₩ 5,500',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.expense,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.income.withValues(alpha: 0.12),
                  child: const Icon(Icons.work, color: AppColors.income),
                ),
                title: const Text('5월 급여'),
                subtitle: const Text('수입 · 5월 25일'),
                trailing: Text(
                  '₩ 3,200,000',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.income,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // ── Cards ─────────────────────────────────────────
        const _SectionHeader('카드 변형'),
        const SizedBox(height: AppSpacing.sm),
        _SummaryCardRow(mood: mood),
        const SizedBox(height: AppSpacing.lg),

        // ── Progress ──────────────────────────────────────
        const _SectionHeader('프로그레스 바'),
        const SizedBox(height: AppSpacing.sm),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                LinearProgressIndicator(value: 0.72),
                SizedBox(height: AppSpacing.sm),
                LinearProgressIndicator(
                  value: 0.9,
                  color: AppColors.expense,
                  backgroundColor: AppColors.expenseLight,
                ),
                SizedBox(height: AppSpacing.sm),
                LinearProgressIndicator(
                  value: 0.4,
                  color: AppColors.income,
                  backgroundColor: AppColors.incomeLight,
                ),
                SizedBox(height: AppSpacing.sm),
                LinearProgressIndicator(),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // ── Snackbar / Dialog ─────────────────────────────
        const _SectionHeader('스낵바 / 다이얼로그'),
        const SizedBox(height: AppSpacing.sm),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('거래가 저장되었습니다.')),
                    );
                  },
                  child: const Text('스낵바 표시'),
                ),
                OutlinedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('다이얼로그 제목'),
                        content: const Text('다이얼로그 본문 내용입니다.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('취소'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('확인'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('다이얼로그 열기'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}

class _SummaryCardRow extends StatelessWidget {
  const _SummaryCardRow({required this.mood});
  final AppMood? mood;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              boxShadow: AppShadows.md(isDark: isDark),
              border: Border.all(
                color: AppColors.income.withValues(alpha: 0.25),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: AppSizes.accentBarHeight,
                  decoration: BoxDecoration(
                    color: AppColors.income,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text('이번 달 수입', style: theme.textTheme.labelLarge),
                const SizedBox(height: 2),
                Text(
                  '₩3,200,000',
                  style: AppTypography.mono(
                    brightness: theme.brightness,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.income,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              boxShadow: AppShadows.md(isDark: isDark),
              border: Border.all(
                color: AppColors.expense.withValues(alpha: 0.25),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: AppSizes.accentBarHeight,
                  decoration: BoxDecoration(
                    color: AppColors.expense,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text('이번 달 지출', style: theme.textTheme.labelLarge),
                const SizedBox(height: 2),
                Text(
                  '₩1,847,200',
                  style: AppTypography.mono(
                    brightness: theme.brightness,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.expense,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Shared ───────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: AppTypography.mono(
        brightness: theme.brightness,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
      ),
    );
  }
}
