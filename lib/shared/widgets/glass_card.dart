import 'dart:ui';

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_opacity.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_shadows.dart';

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.blur = 12.0,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final double blur;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final br = borderRadius ?? BorderRadius.circular(AppRadius.xxl);

    // RepaintBoundary: BackdropFilter가 scroll tick마다 재계산되지 않도록 격리
    // 외부 DecoratedBox: 그림자 — ClipRRect 밖에 있어야 그림자가 잘림 없이 렌더됨
    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: br,
          boxShadow: AppShadows.sm(isDark: isDark),
        ),
        child: ClipRRect(
          borderRadius: br,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: AppOpacity.glassBackdropDark)
                    : Colors.white.withValues(alpha: AppOpacity.glassBackdropLight),
                borderRadius: br,
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: AppOpacity.borderGlass)
                      : AppColors.primaryDark.withValues(alpha: AppOpacity.borderPrimaryLight),
                  width: 0.8,
                ),
              ),
              child: padding != null
                  ? Padding(padding: padding!, child: child)
                  : child,
            ),
          ),
        ),
      ),
    );
  }
}
