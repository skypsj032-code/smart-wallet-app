import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class AppFrame extends StatelessWidget {
  const AppFrame({
    super.key,
    required this.child,
  });

  static const _desktopBreakpoint = 640.0;
  static const _mobileCanvasWidth = 430.0;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? const [Color(0xFF0C0805), Color(0xFF1A1008), Color(0xFF0E0A05)]
                  : const [Color(0xFFEDD9A3), Color(0xFFF4EBDA), Color(0xFFF7F3EC)],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        Positioned(
          top: -80,
          right: -60,
          child: RepaintBoundary(
            child: _GlowOrb(
              size: 380,
              color: isDark
                  ? const Color(0x4ED1A65A)
                  : const Color(0x28D1A65A),
            ),
          ),
        ),
        Positioned(
          left: -80,
          top: 180,
          child: RepaintBoundary(
            child: _GlowOrb(
              size: 300,
              color: isDark
                  ? const Color(0x28E8A030)
                  : const Color(0x14E8A030),
            ),
          ),
        ),
        Positioned(
          right: 20,
          bottom: 160,
          child: RepaintBoundary(
            child: _GlowOrb(
              size: 220,
              color: isDark
                  ? const Color(0x186E8AC7)
                  : const Color(0x0C6E8AC7),
            ),
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < _desktopBreakpoint) {
              return child;
            }

            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _mobileCanvasWidth),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(
                        alpha: isDark ? 0.92 : 0.95,
                      ),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.5),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.14),
                          blurRadius: 48,
                          offset: const Offset(0, 20),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: child,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        IgnorePointer(
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _GrainPainter(
                color: Colors.white.withValues(alpha: isDark ? 0.028 : 0.022),
              ),
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
