import 'dart:math' as math;

import 'package:flutter/material.dart';

class AppFrame extends StatefulWidget {
  const AppFrame({
    super.key,
    required this.child,
  });

  static const _desktopBreakpoint = 640.0;
  static const _mobileCanvasWidth = 430.0;

  final Widget child;

  @override
  State<AppFrame> createState() => _AppFrameState();
}

class _AppFrameState extends State<AppFrame>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 앱이 백그라운드/비활성 → 애니메이션 즉시 정지 (배터리 및 GPU 절약)
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      if (_controller.isAnimating) _controller.stop();
    } else if (state == AppLifecycleState.resumed) {
      if (!_controller.isAnimating) _controller.repeat();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? const [
                      Color(0xFF0C1220),
                      Color(0xFF111832),
                      Color(0xFF151D38),
                      Color(0xFF0E1525),
                    ]
                  : const [
                      Color(0xFFF9F3E8),
                      Color(0xFFF2E8D0),
                      Color(0xFFECDFC4),
                      Color(0xFFE6D5B4),
                    ],
              stops: const [0.0, 0.38, 0.70, 1.0],
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _AtmospherePainter(
                      isDark: isDark,
                      time: _controller.value,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < AppFrame._desktopBreakpoint) {
              return widget.child;
            }

            final horizontalInset = constraints.maxWidth > 900 ? 32.0 : 20.0;
            final availableWidth = constraints.maxWidth - (horizontalInset * 2);
            final shouldUseWideSafeLayout =
                availableWidth > AppFrame._mobileCanvasWidth + 160;

            return Align(
              alignment: shouldUseWideSafeLayout
                  ? Alignment.centerLeft
                  : Alignment.center,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalInset,
                  vertical: 16,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                      maxWidth: AppFrame._mobileCanvasWidth),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color:
                          Colors.white.withValues(alpha: isDark ? 0.07 : 0.36),
                      borderRadius: BorderRadius.circular(34),
                      border: Border.all(
                        color: Colors.white
                            .withValues(alpha: isDark ? 0.12 : 0.54),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withValues(alpha: isDark ? 0.24 : 0.08),
                          blurRadius: 34,
                          offset: const Offset(0, 20),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(34),
                      child: widget.child,
                    ),
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

class _AtmospherePainter extends CustomPainter {
  const _AtmospherePainter({
    required this.isDark,
    required this.time,
  });

  final bool isDark;
  final double time;

  double _pulse(double offset, {double speed = 1.0}) =>
      math.sin((time + offset) * math.pi * 2 * speed) * 0.5 + 0.5;

  double _pulseSigned(double offset, {double speed = 1.0}) =>
      math.sin((time + offset) * math.pi * 2 * speed);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    if (isDark) {
      _paintDark(canvas, size, rect);
    } else {
      _paintLight(canvas, size, rect);
    }
  }

  void _paintDark(Canvas canvas, Size size, Rect rect) {
    final topGlowAlpha = 0.22 + _pulse(0.0) * 0.12;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.0, -0.7),
          radius: 0.9,
          colors: [
            const Color(0xFF4B5EC6).withValues(alpha: topGlowAlpha),
            const Color(0xFF6B4FD8).withValues(alpha: topGlowAlpha * 0.5),
            Colors.transparent,
          ],
          stops: const [0.0, 0.42, 1.0],
        ).createShader(rect),
    );

    final wealthAlpha = 0.10 + _pulse(0.33) * 0.10;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.72, 0.54),
          radius: 0.72,
          colors: [
            const Color(0xFFD4A843).withValues(alpha: wealthAlpha),
            const Color(0xFFB8860B).withValues(alpha: wealthAlpha * 0.5),
            Colors.transparent,
          ],
          stops: const [0.0, 0.46, 1.0],
        ).createShader(rect),
    );

    _paintBand(
      canvas,
      size,
      topFactor: 0.44,
      heightFactor: 0.18,
      color:
          const Color(0xFF3B4BC8).withValues(alpha: 0.05 + _pulse(0.17) * 0.04),
      blur: 32,
    );
    _paintBand(
      canvas,
      size,
      topFactor: 0.72,
      heightFactor: 0.20,
      color:
          const Color(0xFFD4A843).withValues(alpha: 0.04 + _pulse(0.50) * 0.04),
      blur: 40,
    );

    const starConfigs = [
      (0.18, 0.08, 1.2, 0.00),
      (0.72, 0.06, 1.0, 0.14),
      (0.88, 0.14, 0.8, 0.28),
      (0.44, 0.11, 0.9, 0.42),
      (0.08, 0.19, 0.7, 0.57),
      (0.62, 0.19, 0.8, 0.71),
    ];
    for (final star in starConfigs) {
      final twinkle = 0.18 + _pulse(star.$4, speed: 0.6) * 0.22;
      final starPaint = Paint()
        ..color = Colors.white.withValues(alpha: twinkle)
        ..strokeWidth = 0.9
        ..strokeCap = StrokeCap.round;
      final center = Offset(size.width * star.$1, size.height * star.$2);
      final r = star.$3 * 1.8;
      canvas.drawLine(center - Offset(0, r), center + Offset(0, r), starPaint);
      canvas.drawLine(center - Offset(r, 0), center + Offset(r, 0), starPaint);
    }

    const dustConfigs = [
      (0.14, 0.34, 1.4, 0.0),
      (0.82, 0.28, 1.1, 0.2),
      (0.54, 0.52, 0.9, 0.4),
      (0.26, 0.64, 1.2, 0.6),
      (0.76, 0.68, 1.0, 0.8),
    ];
    for (final dot in dustConfigs) {
      final drift = _pulseSigned(dot.$4, speed: 0.4) * size.height * 0.008;
      final alpha = 0.12 + _pulse(dot.$4, speed: 0.5) * 0.10;
      canvas.drawCircle(
        Offset(size.width * dot.$1, size.height * dot.$2 + drift),
        dot.$3,
        Paint()..color = const Color(0xFFD4A843).withValues(alpha: alpha),
      );
    }
  }

  void _paintLight(Canvas canvas, Size size, Rect rect) {
    final warmAlpha = 0.62 + _pulse(0.0) * 0.14;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.2, -0.8),
          radius: 1.1,
          colors: [
            Colors.white.withValues(alpha: warmAlpha),
            const Color(0xFFFAE8C0).withValues(alpha: warmAlpha * 0.5),
            Colors.transparent,
          ],
          stops: const [0.0, 0.36, 1.0],
        ).createShader(rect),
    );

    final amberAlpha = 0.12 + _pulse(0.33) * 0.10;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.8, 0.7),
          radius: 0.68,
          colors: [
            const Color(0xFFD4A843).withValues(alpha: amberAlpha),
            const Color(0xFFE8C87A).withValues(alpha: amberAlpha * 0.5),
            Colors.transparent,
          ],
          stops: const [0.0, 0.44, 1.0],
        ).createShader(rect),
    );

    _paintBand(
      canvas,
      size,
      topFactor: 0.50,
      heightFactor: 0.16,
      color:
          const Color(0xFFF0D8A0).withValues(alpha: 0.22 + _pulse(0.17) * 0.10),
      blur: 28,
    );
    _paintBand(
      canvas,
      size,
      topFactor: 0.68,
      heightFactor: 0.14,
      color:
          const Color(0xFFE8C87A).withValues(alpha: 0.14 + _pulse(0.50) * 0.08),
      blur: 32,
    );

    final shimmerAngleOffset = time * math.pi * 2 * 0.05;
    final shimmerAlpha = 0.16 + _pulse(0.0, speed: 0.5) * 0.10;
    final shimmerPaint = Paint()
      ..color = const Color(0xFFD4A843).withValues(alpha: shimmerAlpha)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 6; i++) {
      final angle = i / 6 * math.pi * 2 + shimmerAngleOffset;
      final center = Offset(size.width * 0.78, size.height * 0.22);
      canvas.drawLine(
        center + Offset(math.cos(angle), math.sin(angle)) * 10.0,
        center + Offset(math.cos(angle), math.sin(angle)) * 20.0,
        shimmerPaint,
      );
    }

    const dustConfigs = [
      (0.22, 0.42, 1.3, 0.0),
      (0.66, 0.36, 1.0, 0.2),
      (0.44, 0.58, 1.1, 0.4),
      (0.82, 0.54, 0.9, 0.6),
      (0.12, 0.62, 1.2, 0.8),
    ];
    for (final dot in dustConfigs) {
      final drift = _pulseSigned(dot.$4, speed: 0.35) * size.height * 0.007;
      final alpha = 0.14 + _pulse(dot.$4, speed: 0.45) * 0.10;
      canvas.drawCircle(
        Offset(size.width * dot.$1, size.height * dot.$2 + drift),
        dot.$3,
        Paint()..color = const Color(0xFFB8860B).withValues(alpha: alpha),
      );
    }
  }

  void _paintBand(
    Canvas canvas,
    Size size, {
    required double topFactor,
    required double heightFactor,
    required Color color,
    required double blur,
  }) {
    final top = size.height * topFactor;
    final height = size.height * heightFactor;
    final rect =
        Rect.fromLTWH(-size.width * 0.08, top, size.width * 1.16, height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(height));
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = color
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur),
    );
  }

  @override
  bool shouldRepaint(covariant _AtmospherePainter oldDelegate) {
    return oldDelegate.isDark != isDark || oldDelegate.time != time;
  }
}
