import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class AppBrandMark extends StatelessWidget {
  const AppBrandMark({
    super.key,
    this.size = 72,
    this.withBadge = false,
  });

  final double size;
  final bool withBadge;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _WalletMarkPainter(
          accent: AppColors.primary,
          badge: withBadge,
        ),
      ),
    );
  }
}

class _WalletMarkPainter extends CustomPainter {
  const _WalletMarkPainter({
    required this.accent,
    required this.badge,
  });

  final Color accent;
  final bool badge;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final radius = Radius.circular(size.width * 0.24);
    final shell = RRect.fromRectAndRadius(rect.deflate(size.width * 0.08), radius);

    final basePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF1D1A17), Color(0xFF332922)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);
    canvas.drawRRect(shell, basePaint);

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.022
      ..color = Colors.white.withValues(alpha: 0.08);
    canvas.drawRRect(shell, borderPaint);

    final flapRect = Rect.fromLTWH(
      size.width * 0.2,
      size.height * 0.27,
      size.width * 0.6,
      size.height * 0.2,
    );
    final flap = RRect.fromRectAndRadius(
      flapRect,
      Radius.circular(size.width * 0.16),
    );
    final flapPaint = Paint()..color = accent.withValues(alpha: 0.88);
    canvas.drawRRect(flap, flapPaint);

    final pocketRect = Rect.fromLTWH(
      size.width * 0.22,
      size.height * 0.42,
      size.width * 0.56,
      size.height * 0.22,
    );
    final pocketPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        pocketRect,
        Radius.circular(size.width * 0.14),
      ),
      pocketPaint,
    );

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.width * 0.03;
    canvas.drawLine(
      Offset(size.width * 0.32, size.height * 0.72),
      Offset(size.width * 0.68, size.height * 0.72),
      linePaint,
    );

    if (badge) {
      final badgeCenter = Offset(size.width * 0.76, size.height * 0.28);
      final badgePaint = Paint()..color = AppColors.income;
      canvas.drawCircle(badgeCenter, size.width * 0.08, badgePaint);
      final badgeInner = Paint()..color = Colors.white.withValues(alpha: 0.92);
      canvas.drawCircle(badgeCenter, size.width * 0.028, badgeInner);
    }
  }

  @override
  bool shouldRepaint(covariant _WalletMarkPainter oldDelegate) {
    return oldDelegate.accent != accent || oldDelegate.badge != badge;
  }
}
