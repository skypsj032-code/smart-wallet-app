import 'package:flutter/material.dart';

/// A single, calm sky sits behind every screen in the app.
class AppFrame extends StatelessWidget {
  const AppFrame({super.key, required this.child});

  static const _desktopBreakpoint = 640.0;
  static const _mobileCanvasWidth = 430.0;
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
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? const [Color(0xFF233B65), Color(0xFF1B3557), Color(0xFF101F38)]
                  : const [Color(0xFFAACFEC), Color(0xFFC7E2F4), Color(0xFFE6F3F9)],
              stops: const [0, 0.46, 1],
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: _SkyPainter(isDark: isDark)),
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < _desktopBreakpoint) return child;
            final inset = constraints.maxWidth > 900 ? 32.0 : 20.0;
            final wide = constraints.maxWidth - inset * 2 > _mobileCanvasWidth + 160;
            return Align(
              alignment: wide ? Alignment.centerLeft : Alignment.center,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: inset, vertical: 16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _mobileCanvasWidth),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(34),
                    child: child,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _SkyPainter extends CustomPainter {
  const _SkyPainter({required this.isDark});
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.8, -0.9),
          radius: 1.1,
          colors: [
            Colors.white.withValues(alpha: isDark ? 0.09 : 0.36),
            Colors.transparent,
          ],
        ).createShader(rect),
    );
    // Soft cloud banks provide depth behind the translucent panels.
    final cloud = Paint()
      ..color = Colors.white.withValues(alpha: isDark ? 0.045 : 0.26)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(size.width * 0.10, size.height * 0.30),
          width: size.width * 0.85, height: size.height * 0.12), cloud);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(size.width * 0.88, size.height * 0.57),
          width: size.width * 0.90, height: size.height * 0.14), cloud);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(size.width * 0.18, size.height * 0.88),
          width: size.width, height: size.height * 0.12), cloud);
    if (isDark) {
      final stars = Paint()..color = Colors.white.withValues(alpha: 0.38);
      for (final p in const [Offset(.15, .09), Offset(.68, .05), Offset(.86, .17), Offset(.36, .23)]) {
        canvas.drawCircle(Offset(p.dx * size.width, p.dy * size.height), 1.1, stars);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SkyPainter oldDelegate) => oldDelegate.isDark != isDark;
}
