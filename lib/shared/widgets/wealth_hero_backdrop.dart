import 'dart:math' as math;

import 'package:flutter/material.dart';

enum WealthBackdropDirection {
  increase,
  decrease,
}

enum WealthBackdropReactionIntensity {
  tiny,
  small,
  medium,
  large,
}

class WealthHeroBackdrop extends StatelessWidget {
  const WealthHeroBackdrop({
    super.key,
    this.coinDensity = 0,
    this.billDensity = 0,
    this.vaultIntensity = 0,
    this.direction = WealthBackdropDirection.increase,
    this.reactionIntensity = WealthBackdropReactionIntensity.small,
    this.progress = 0,
    this.reducedMotion = false,
    this.collapseProgress = 0,
    this.showSkySymbol = true,
    this.borderRadius = const BorderRadius.all(Radius.circular(28)),
  });

  final double coinDensity;
  final double billDensity;
  final double vaultIntensity;
  final WealthBackdropDirection direction;
  final WealthBackdropReactionIntensity reactionIntensity;
  final double progress;
  final bool reducedMotion;
  final double collapseProgress;
  final bool showSkySymbol;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return IgnorePointer(
      child: RepaintBoundary(
        child: ClipRRect(
          borderRadius: borderRadius,
          child: CustomPaint(
            painter: _WealthHeroBackdropPainter(
              theme: theme,
              coinDensity: coinDensity.clamp(0.0, 1.0),
              billDensity: billDensity.clamp(0.0, 1.0),
              vaultIntensity: vaultIntensity.clamp(0.0, 1.0),
              direction: direction,
              reactionIntensity: reactionIntensity,
              progress: progress.clamp(0.0, 1.0),
              reducedMotion: reducedMotion,
              collapseProgress: collapseProgress.clamp(0.0, 1.0),
              showSkySymbol: showSkySymbol,
            ),
            size: Size.infinite,
            isComplex: true,
            willChange: !reducedMotion &&
                (progress > 0 || (collapseProgress > 0 && collapseProgress < 1)),
          ),
        ),
      ),
    );
  }
}

class _WealthHeroBackdropPainter extends CustomPainter {
  const _WealthHeroBackdropPainter({
    required this.theme,
    required this.coinDensity,
    required this.billDensity,
    required this.vaultIntensity,
    required this.direction,
    required this.reactionIntensity,
    required this.progress,
    required this.reducedMotion,
    required this.collapseProgress,
    required this.showSkySymbol,
  });

  final ThemeData theme;
  final double coinDensity;
  final double billDensity;
  final double vaultIntensity;
  final WealthBackdropDirection direction;
  final WealthBackdropReactionIntensity reactionIntensity;
  final double progress;
  final bool reducedMotion;
  final double collapseProgress;
  final bool showSkySymbol;

  static const int _assetSlots = 5;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }

    final scheme = theme.colorScheme;
    final baseProgress = reducedMotion ? 0.0 : progress;
    final reactionScale = _reactionScale(reactionIntensity) * baseProgress;
    final decreaseScale = direction == WealthBackdropDirection.decrease
        ? reactionScale
        : 0.0;
    final increaseScale = direction == WealthBackdropDirection.increase
        ? reactionScale
        : 0.0;

    final brightnessLift = 0.16 * vaultIntensity - 0.18 * decreaseScale;
    final sceneBase = Color.lerp(
      scheme.surface.withValues(alpha: 0.0),
      scheme.primaryContainer.withValues(alpha: 0.22 + brightnessLift),
      0.32 + 0.35 * vaultIntensity,
    )!;

    canvas.drawRect(Offset.zero & size, Paint()..color = sceneBase);

    canvas.save();
    canvas.translate(0, -size.height * 0.010 * collapseProgress);
    _paintAmbientLight(canvas, size, scheme, vaultIntensity, increaseScale, decreaseScale);
    canvas.restore();

    if (showSkySymbol) {
      _paintSkySymbol(canvas, size, increaseScale, decreaseScale);
    }

    canvas.save();
    canvas.translate(0, -size.height * 0.008 * collapseProgress);
    _paintScenicScene(canvas, size, scheme, increaseScale, decreaseScale);
    canvas.restore();

    canvas.save();
    canvas.translate(0, -size.height * 0.018 * collapseProgress);
    _paintPiggyBank(canvas, size, scheme, increaseScale, decreaseScale);
    canvas.restore();

    canvas.save();
    canvas.translate(0, -size.height * 0.014 * collapseProgress);
    _paintVaultAssets(canvas, size, scheme, vaultIntensity, increaseScale, decreaseScale);
    canvas.restore();

    canvas.save();
    canvas.translate(0, -size.height * 0.016 * collapseProgress);
    _paintBills(canvas, size, scheme, increaseScale, decreaseScale);
    canvas.restore();

    canvas.save();
    canvas.translate(0, -size.height * 0.012 * collapseProgress);
    _paintCoins(canvas, size, scheme, increaseScale, decreaseScale);
    canvas.restore();

    _paintEdgeVignette(canvas, size, scheme, decreaseScale);
  }

  void _paintAmbientLight(
    Canvas canvas,
    Size size,
    ColorScheme scheme,
    double vaultLevel,
    double increaseScale,
    double decreaseScale,
  ) {
    final glowAlpha = (0.16 + vaultLevel * 0.26 + increaseScale * 0.08) - decreaseScale * 0.12;
    final glowColor = Color.lerp(
      scheme.tertiary.withValues(alpha: 0.0),
      Colors.white.withValues(alpha: glowAlpha.clamp(0.04, 0.32)),
      0.45,
    )!;

    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.7, -0.3),
        radius: 1.0,
        colors: [glowColor, Colors.transparent],
        stops: const [0.0, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, glowPaint);

    final horizonPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.03 + increaseScale * 0.03),
          Colors.transparent,
          Colors.black.withValues(alpha: 0.04 + decreaseScale * 0.08),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, horizonPaint);
  }

  void _paintSkySymbol(
    Canvas canvas,
    Size size,
    double increaseScale,
    double decreaseScale,
  ) {
    final isDark = theme.brightness == Brightness.dark;
    final center = Offset(size.width * 0.82, size.height * 0.16);
    final glowRadius = size.width * 0.12;

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: isDark
            ? [
                Colors.white.withValues(alpha: 0.12 - decreaseScale * 0.03),
                const Color(0xFFBFD8FF).withValues(alpha: 0.08),
                Colors.transparent,
              ]
            : [
                Colors.white.withValues(alpha: 0.18 + increaseScale * 0.04),
                const Color(0xFFFFF2B4).withValues(alpha: 0.10),
                Colors.transparent,
              ],
        stops: const [0.0, 0.24, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: glowRadius));
    canvas.drawCircle(center, glowRadius, glowPaint);

    if (isDark) {
      final radius = size.width * 0.024;
      canvas.drawCircle(
        center,
        radius,
        Paint()..color = const Color(0xFFF4F7FF).withValues(alpha: 0.9),
      );
      canvas.drawCircle(
        center + Offset(radius * 0.34, -radius * 0.02),
        radius * 0.82,
        Paint()..color = theme.colorScheme.primaryContainer.withValues(alpha: 0.72),
      );
    } else {
      final corePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.88 - decreaseScale * 0.10);
      canvas.drawCircle(center, size.width * 0.02, corePaint);

      final rayPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.16 + increaseScale * 0.05)
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 1.1;
      for (var index = 0; index < 8; index++) {
        final angle = index / 8 * math.pi * 2;
        final start = center + Offset(math.cos(angle), math.sin(angle)) * size.width * 0.026;
        final end = center + Offset(math.cos(angle), math.sin(angle)) * size.width * 0.05;
        canvas.drawLine(start, end, rayPaint);
      }
    }
  }

  void _paintScenicScene(
    Canvas canvas,
    Size size,
    ColorScheme scheme,
    double increaseScale,
    double decreaseScale,
  ) {
    final isDark = theme.brightness == Brightness.dark;
    final rect = Offset.zero & size;
    final horizonY = size.height * 0.56;

    final hazePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? [
                const Color(0xFF94A8C8).withValues(alpha: 0.08),
                const Color(0xFF7CB2D6).withValues(alpha: 0.10),
                Colors.transparent,
              ]
            : [
                Colors.white.withValues(alpha: 0.12),
                const Color(0xFFAED8F2).withValues(alpha: 0.16),
                Colors.transparent,
              ],
      ).createShader(rect);
    canvas.drawRect(rect, hazePaint);

    final waterRect = Rect.fromLTWH(0, size.height * 0.46, size.width, size.height * 0.20);
    canvas.drawRect(
      waterRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [
                  const Color(0xFF4E82A3).withValues(alpha: 0.18),
                  const Color(0xFF2D536E).withValues(alpha: 0.08),
                ]
              : [
                  const Color(0xFF78BDEB).withValues(alpha: 0.24),
                  const Color(0xFF5EA6D9).withValues(alpha: 0.10),
                ],
        ).createShader(waterRect),
    );

    final farHill = Path()
      ..moveTo(-size.width * 0.1, horizonY)
      ..quadraticBezierTo(
        size.width * 0.18,
        size.height * 0.50,
        size.width * 0.42,
        size.height * 0.56,
      )
      ..quadraticBezierTo(
        size.width * 0.72,
        size.height * 0.62,
        size.width * 1.1,
        size.height * 0.54,
      )
      ..lineTo(size.width * 1.1, size.height)
      ..lineTo(-size.width * 0.1, size.height)
      ..close();
    canvas.drawPath(
      farHill,
      Paint()
        ..color = isDark
            ? const Color(0xFF5D8294).withValues(alpha: 0.10)
            : const Color(0xFF9DDDB8).withValues(alpha: 0.16),
    );

    final frontHill = Path()
      ..moveTo(-size.width * 0.1, size.height * 0.76)
      ..quadraticBezierTo(
        size.width * 0.18,
        size.height * 0.68 - size.height * 0.02 * increaseScale,
        size.width * 0.42,
        size.height * 0.75,
      )
      ..quadraticBezierTo(
        size.width * 0.76,
        size.height * 0.84 + size.height * 0.02 * decreaseScale,
        size.width * 1.1,
        size.height * 0.72,
      )
      ..lineTo(size.width * 1.1, size.height)
      ..lineTo(-size.width * 0.1, size.height)
      ..close();
    canvas.drawPath(
      frontHill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [
                  const Color(0xFF2F5463).withValues(alpha: 0.22),
                  const Color(0xFF1E3943).withValues(alpha: 0.10),
                ]
              : [
                  const Color(0xFF86D7A7).withValues(alpha: 0.22),
                  const Color(0xFF5DB08C).withValues(alpha: 0.12),
                ],
        ).createShader(rect),
    );
  }

  void _paintVaultAssets(
    Canvas canvas,
    Size size,
    ColorScheme scheme,
    double vaultLevel,
    double increaseScale,
    double decreaseScale,
  ) {
    final width = size.width;
    final height = size.height;
    final floorY = height * (0.76 - increaseScale * 0.02);
    final panelHeight = height * 0.12;
    final panelRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(-width * 0.04, floorY, width * 1.08, panelHeight),
      Radius.circular(panelHeight * 0.42),
    );

    final panelPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          scheme.surfaceContainerHighest.withValues(
            alpha: 0.13 + vaultLevel * 0.14 - decreaseScale * 0.04,
          ),
          scheme.surface.withValues(alpha: 0.05),
        ],
      ).createShader(panelRect.outerRect);
    canvas.drawRRect(panelRect, panelPaint);

    for (var index = 0; index < _assetSlots; index++) {
      final t = index / (_assetSlots - 1);
      final shapeSeed = 17 + index * 29;
      final x = width * (0.60 + 0.07 * index);
      final assetWidth = width * (0.06 + _noise(shapeSeed) * 0.022);
      final assetHeightFactor = 0.14 + vaultLevel * 0.18 + _noise(shapeSeed + 1) * 0.08;
      final assetHeight = height * assetHeightFactor;
      final y = floorY - assetHeight + height * 0.03;
      final lift = reducedMotion ? 0.0 : math.sin((t + 0.2) * math.pi) * height * 0.015 * increaseScale;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          x - assetWidth / 2,
          y - lift,
          assetWidth,
          assetHeight,
        ),
        Radius.circular(assetWidth * 0.28),
      );

      final fill = Color.lerp(
        scheme.secondary.withValues(alpha: 0.08),
        scheme.secondaryContainer.withValues(
          alpha: 0.07 + vaultLevel * 0.07 - decreaseScale * 0.03,
        ),
        0.45 + 0.4 * t,
      )!;
      canvas.drawRRect(rect, Paint()..color = fill);

      final highlightRect = Rect.fromLTWH(
        rect.left + rect.width * 0.12,
        rect.top + rect.height * 0.14,
        rect.width * 0.24,
        rect.height * 0.52,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(highlightRect, Radius.circular(rect.width * 0.08)),
        Paint()..color = Colors.white.withValues(alpha: 0.05 + vaultLevel * 0.05),
      );
    }

    final vaultRadius = math.min(width, height) * 0.062;
    final vaultCenter = Offset(width * 0.88, height * 0.28);
    final vaultColor = scheme.primary.withValues(
      alpha: (0.02 + vaultLevel * 0.04 - decreaseScale * 0.02).clamp(0.015, 0.07),
    );
    canvas.drawCircle(vaultCenter, vaultRadius, Paint()..color = vaultColor);
    canvas.drawCircle(
      vaultCenter,
      vaultRadius * 0.68,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = vaultRadius * 0.16
        ..color = Colors.white.withValues(alpha: 0.05 + vaultLevel * 0.04),
    );

    final spokesPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = vaultRadius * 0.08
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.04 + vaultLevel * 0.04 - decreaseScale * 0.02);
    for (var index = 0; index < 4; index++) {
      final angle = math.pi / 4 * index + increaseScale * 0.08;
      final dx = math.cos(angle) * vaultRadius * 0.38;
      final dy = math.sin(angle) * vaultRadius * 0.38;
      canvas.drawLine(vaultCenter - Offset(dx, dy), vaultCenter + Offset(dx, dy), spokesPaint);
    }
  }

  void _paintPiggyBank(
    Canvas canvas,
    Size size,
    ColorScheme scheme,
    double increaseScale,
    double decreaseScale,
  ) {
    final piggyLevel = ((1 - billDensity) * (1 - vaultIntensity) * 1.15)
        .clamp(0.0, 1.0);
    if (piggyLevel <= 0.02) {
      return;
    }

    final width = size.width;
    final height = size.height;
    final center = Offset(width * 0.84, height * 0.76);
    final bodyWidth = width * (0.11 + piggyLevel * 0.02);
    final bodyHeight = height * (0.11 + piggyLevel * 0.02);
    final bodyRect = Rect.fromCenter(
      center: Offset(
        center.dx,
        center.dy - increaseScale * height * 0.02 + decreaseScale * height * 0.01,
      ),
      width: bodyWidth,
      height: bodyHeight,
    );
    final pigColor = Color.lerp(
      const Color(0xFFC48A8A),
      const Color(0xFFE7B1A8),
      piggyLevel,
    )!.withValues(
      alpha: (0.04 + piggyLevel * 0.04 - decreaseScale * 0.02).clamp(0.025, 0.07),
    );

    final bodyPaint = Paint()..color = pigColor;
    canvas.drawOval(bodyRect, bodyPaint);

    final headRect = Rect.fromCenter(
      center: Offset(bodyRect.right - bodyWidth * 0.18, bodyRect.top + bodyHeight * 0.42),
      width: bodyWidth * 0.34,
      height: bodyHeight * 0.28,
    );
    canvas.drawOval(headRect, bodyPaint);

    final snoutRect = Rect.fromCenter(
      center: Offset(headRect.right - headRect.width * 0.06, headRect.center.dy),
      width: headRect.width * 0.40,
      height: headRect.height * 0.5,
    );
    canvas.drawOval(
      snoutRect,
      Paint()..color = Colors.white.withValues(alpha: 0.14 + piggyLevel * 0.08),
    );

    final earPath = Path()
      ..moveTo(headRect.left + headRect.width * 0.18, headRect.top + headRect.height * 0.1)
      ..lineTo(headRect.left + headRect.width * 0.32, headRect.top - headRect.height * 0.28)
      ..lineTo(headRect.left + headRect.width * 0.5, headRect.top + headRect.height * 0.04)
      ..close();
    canvas.drawPath(earPath, bodyPaint);

    final slotPaint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = bodyHeight * 0.045
      ..color = Colors.white.withValues(alpha: 0.18 + piggyLevel * 0.08);
    canvas.drawLine(
      Offset(bodyRect.center.dx - bodyWidth * 0.12, bodyRect.top + bodyHeight * 0.16),
      Offset(bodyRect.center.dx + bodyWidth * 0.06, bodyRect.top + bodyHeight * 0.16),
      slotPaint,
    );

    final legPaint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = bodyWidth * 0.08
      ..color = pigColor.withValues(alpha: pigColor.a);
    for (final xFactor in const [0.28, 0.68]) {
      final x = bodyRect.left + bodyWidth * xFactor;
      canvas.drawLine(
        Offset(x, bodyRect.bottom - bodyHeight * 0.04),
        Offset(x - bodyWidth * 0.02, bodyRect.bottom + bodyHeight * 0.14),
        legPaint,
      );
    }

    final tailPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = bodyWidth * 0.026
      ..color = pigColor.withValues(alpha: pigColor.a);
    final tailPath = Path()
      ..moveTo(bodyRect.left + bodyWidth * 0.02, bodyRect.center.dy + bodyHeight * 0.05)
      ..quadraticBezierTo(
        bodyRect.left - bodyWidth * 0.12,
        bodyRect.center.dy - bodyHeight * 0.02,
        bodyRect.left - bodyWidth * 0.04,
        bodyRect.center.dy - bodyHeight * 0.12,
      );
    canvas.drawPath(tailPath, tailPaint);

    final eyePaint = Paint()..color = Colors.white.withValues(alpha: 0.26);
    canvas.drawCircle(
      Offset(headRect.left + headRect.width * 0.42, headRect.top + headRect.height * 0.38),
      bodyHeight * 0.024,
      eyePaint,
    );
  }

  void _paintBills(
    Canvas canvas,
    Size size,
    ColorScheme scheme,
    double increaseScale,
    double decreaseScale,
  ) {
    final width = size.width;
    final height = size.height;
    final visibleRatio = (billDensity * (1 - 0.5 * decreaseScale)).clamp(0.0, 1.0);
    final visibleCount = (visibleRatio * 8).round();

    for (var index = 0; index < visibleCount; index++) {
      final seed = 101 + index * 37;
      final row = index ~/ 4;
      final column = index % 4;
      final x = width * (0.58 + column * 0.08 + _noiseSigned(seed) * 0.014);
      final y = height * (0.24 + row * 0.07 + _noiseSigned(seed + 1) * 0.012);
      final billWidth = width * (0.10 + _noise(seed + 2) * 0.025);
      final billHeight = billWidth * 0.56;
      final driftX = reducedMotion
          ? 0.0
          : (_noiseSigned(seed + 3) * width * 0.014) * increaseScale;
      final driftY = reducedMotion
          ? 0.0
          : (height * 0.038 + _noise(seed + 4) * height * 0.016) * increaseScale;
      final settleY = height * 0.012 * decreaseScale;
      final angle = (_noiseSigned(seed + 5) * 0.18) + increaseScale * 0.05;
      final rect = Rect.fromCenter(
        center: Offset(x + driftX, y - driftY + settleY),
        width: billWidth,
        height: billHeight,
      );

      canvas.save();
      canvas.translate(rect.center.dx, rect.center.dy);
      canvas.rotate(angle);
      canvas.translate(-rect.center.dx, -rect.center.dy);

      final fill = Color.lerp(
        scheme.tertiaryContainer.withValues(alpha: 0.06),
        scheme.tertiary.withValues(
          alpha: (0.025 + billDensity * 0.04 - decreaseScale * 0.02).clamp(0.015, 0.06),
        ),
        0.35,
      )!;
      final billRRect = RRect.fromRectAndRadius(rect, Radius.circular(billHeight * 0.18));
      canvas.drawRRect(billRRect, Paint()..color = fill);

      final innerRect = Rect.fromCenter(
        center: rect.center,
        width: billWidth * 0.72,
        height: billHeight * 0.54,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(innerRect, Radius.circular(billHeight * 0.14)),
        Paint()..color = Colors.white.withValues(alpha: 0.06 + billDensity * 0.04),
      );
      canvas.restore();
    }
  }

  void _paintCoins(
    Canvas canvas,
    Size size,
    ColorScheme scheme,
    double increaseScale,
    double decreaseScale,
  ) {
    final width = size.width;
    final height = size.height;
    final floorY = height * 0.80;
    final visibleRatio = (coinDensity * (1 - 0.42 * decreaseScale)).clamp(0.0, 1.0);
    final visibleCount = (visibleRatio * 18).round();

    for (var index = 0; index < visibleCount; index++) {
      final seed = 211 + index * 19;
      final row = index ~/ 6;
      final column = index % 6;
      final baseX = width * (0.50 + column * 0.055 + _noiseSigned(seed) * 0.010);
      final stackLift = row * height * (0.018 + _noise(seed + 1) * 0.005);
      final rise = reducedMotion
          ? 0.0
          : (height * 0.06 + _noise(seed + 2) * height * 0.018) * increaseScale;
      final looseness = reducedMotion
          ? 0.0
          : _noiseSigned(seed + 3) * width * 0.008 * increaseScale;
      final y = floorY - stackLift - rise + decreaseScale * height * 0.006 * row;
      final radius = width * (0.017 + _noise(seed + 4) * 0.007);
      final color = Color.lerp(
        scheme.primaryContainer.withValues(alpha: 0.12),
        const Color(0xFFD6A756).withValues(
          alpha: (0.06 + coinDensity * 0.07 - decreaseScale * 0.03).clamp(0.035, 0.10),
        ),
        0.68,
      )!;

      final coinCenter = Offset(baseX + looseness, y);
      canvas.drawOval(
        Rect.fromCenter(
          center: coinCenter,
          width: radius * 2.3,
          height: radius * 1.18,
        ),
        Paint()..color = color,
      );

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(coinCenter.dx, coinCenter.dy - radius * 0.14),
          width: radius * 1.76,
          height: radius * 0.68,
        ),
        Paint()..color = Colors.white.withValues(alpha: 0.08 + coinDensity * 0.05),
      );
    }
  }

  void _paintEdgeVignette(
    Canvas canvas,
    Size size,
    ColorScheme scheme,
    double decreaseScale,
  ) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.015),
            Colors.transparent,
            Colors.black.withValues(alpha: 0.08 + decreaseScale * 0.08),
          ],
          stops: const [0.0, 0.52, 1.0],
        ).createShader(rect),
    );
  }

  double _reactionScale(WealthBackdropReactionIntensity intensity) {
    switch (intensity) {
      case WealthBackdropReactionIntensity.tiny:
        return 0.3;
      case WealthBackdropReactionIntensity.small:
        return 0.5;
      case WealthBackdropReactionIntensity.medium:
        return 0.78;
      case WealthBackdropReactionIntensity.large:
        return 1.0;
    }
  }

  double _noise(int seed) {
    final value = math.sin(seed * 12.9898) * 43758.5453;
    return value - value.floorToDouble();
  }

  double _noiseSigned(int seed) => (_noise(seed) * 2) - 1;

  @override
  bool shouldRepaint(covariant _WealthHeroBackdropPainter oldDelegate) {
    return oldDelegate.theme.brightness != theme.brightness ||
        oldDelegate.theme.colorScheme != theme.colorScheme ||
        oldDelegate.coinDensity != coinDensity ||
        oldDelegate.billDensity != billDensity ||
        oldDelegate.vaultIntensity != vaultIntensity ||
        oldDelegate.direction != direction ||
        oldDelegate.reactionIntensity != reactionIntensity ||
        oldDelegate.progress != progress ||
        oldDelegate.reducedMotion != reducedMotion ||
        oldDelegate.collapseProgress != collapseProgress ||
        oldDelegate.showSkySymbol != showSkySymbol;
  }
}
