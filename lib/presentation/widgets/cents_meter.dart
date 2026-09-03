import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// A horizontal strobe-style ruler mirroring [TunerGauge]'s reading: a row
/// of ticks from -50 to +50 cents with a marker sliding to the current
/// deviation. Gives the same signal a second, more precise-feeling read.
class CentsMeter extends StatelessWidget {
  const CentsMeter({super.key, required this.cents, required this.active});

  final double cents;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final clamped = cents.clamp(-50, 50).toDouble();
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: clamped),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            return CustomPaint(
              size: Size(constraints.maxWidth, 40),
              painter: _MeterPainter(cents: value, active: active),
            );
          },
        );
      },
    );
  }
}

class _MeterPainter extends CustomPainter {
  _MeterPainter({required this.cents, required this.active});

  final double cents;
  final bool active;

  static const _inTuneThresholdCents = 5.0;
  static const _closeThresholdCents = 15.0;

  @override
  void paint(Canvas canvas, Size size) {
    final midY = size.height * 0.42;
    final usableHalfWidth = size.width / 2 - 12;

    double xFor(double c) => size.width / 2 + (c / 50) * usableHalfWidth;

    for (var c = -50; c <= 50; c += 5) {
      final isCenter = c == 0;
      final isMajor = c % 25 == 0;
      final height = isCenter ? 16.0 : (isMajor ? 12.0 : 7.0);
      final x = xFor(c.toDouble());
      final color = isCenter
          ? AppColors.inTune
          : (isMajor ? AppColors.textSecondary : AppColors.textMuted);
      canvas.drawLine(
        Offset(x, midY - height / 2),
        Offset(x, midY + height / 2),
        Paint()
          ..color = color.withValues(alpha: active ? 1 : 0.4)
          ..strokeWidth = isCenter ? 3 : 1.6
          ..strokeCap = StrokeCap.round,
      );
    }

    if (!active) return;

    final markerColor = cents.abs() <= _inTuneThresholdCents
        ? AppColors.inTune
        : (cents.abs() <= _closeThresholdCents
            ? AppColors.warning
            : AppColors.danger);
    final markerX = xFor(cents);

    canvas.drawCircle(
      Offset(markerX, midY),
      10,
      Paint()
        ..color = markerColor.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    final path = Path()
      ..moveTo(markerX, midY - 16)
      ..lineTo(markerX - 6, midY - 26)
      ..lineTo(markerX + 6, midY - 26)
      ..close();
    canvas.drawPath(path, Paint()..color = markerColor);
  }

  @override
  bool shouldRepaint(covariant _MeterPainter oldDelegate) {
    return oldDelegate.cents != cents || oldDelegate.active != active;
  }
}
