import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class AppFrame extends StatelessWidget {
  const AppFrame({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? const [AppColors.backgroundDark, Color(0xFF181512)]
                  : const [AppColors.backgroundLight, Color(0xFFF2EBDD)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        Positioned(
          top: -120,
          right: -72,
          child: _GlowOrb(
            size: 300,
            color: isDark ? const Color(0x22D1A65A) : const Color(0x14D1A65A),
          ),
        ),
        Positioned(
          left: -100,
          bottom: 96,
          child: _GlowOrb(
            size: 260,
            color: isDark ? const Color(0x106E8AC7) : const Color(0x0C8A7049),
          ),
        ),
        child,
        IgnorePointer(
          child: CustomPaint(
            painter: _GrainPainter(
              color: Colors.white.withValues(alpha: isDark ? 0.025 : 0.018),
            ),
          ),
        ),
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
        ),
      ),
    );
  }
}

class _GrainPainter extends CustomPainter {
  const _GrainPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final width = size.width;
    final height = size.height;

    for (var index = 0; index < 720; index++) {
      final dx = ((index * 73) % 997) / 997 * width;
      final dy = ((index * 191) % 991) / 991 * height;
      final spread = 0.35 + (((index * 17) % 100) / 100) * 1.15;
      canvas.drawRect(Rect.fromLTWH(dx, dy, spread, spread), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
