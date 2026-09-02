import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// A semicircular gauge showing pitch deviation in cents, from -50 to +50.
class TunerGauge extends StatelessWidget {
  const TunerGauge({super.key, required this.cents, required this.active});

  final double cents;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(280, 160),
      painter: _GaugePainter(cents: cents.clamp(-50, 50), active: active),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({required this.cents, required this.active});

  final double cents;
  final bool active;

  /// Deviation, in cents, within which the pitch counts as "in tune" —
  /// drives the needle color, matching `TuningTarget.isInTune`.
  static const _inTuneThresholdCents = 5.0;

  /// Half-width, in cents, of the highlighted target wedge — matches the
  /// tick spacing so the wedge's edges land exactly on the two ticks
  /// flanking center, rather than an arbitrary width.
  static const _zoneHalfWidthCents = 10.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 10;
    final inTune = active && cents.abs() <= _inTuneThresholdCents;

    // Target zone as a solid pie slice from the pivot out to the arc, sized
    // to the gap between the two ticks nearest center, so it reads as a
    // wedge to aim for rather than a thin line to chase.
    final bandSweep = 2 * _zoneHalfWidthCents / 100 * pi;
    final bandStart = pi + pi / 2 - bandSweep / 2;
    final bandPath = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius),
        bandStart,
        bandSweep,
        false,
      )
      ..close();
    canvas.drawPath(
      bandPath,
      Paint()
        ..style = PaintingStyle.fill
        ..color = AppColors.inTune.withValues(alpha: 0.18),
    );

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..color = AppColors.borderHover;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi,
      pi,
      false,
      arcPaint,
    );

    for (var c = -50; c <= 50; c += 10) {
      final angle = pi + (c + 50) / 100 * pi;
      final isCenter = c == 0;
      final tickPaint = Paint()
        ..color = isCenter ? AppColors.inTune : AppColors.textMuted
        ..strokeWidth = isCenter ? 3 : 2;
      final outer = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
      final inner = Offset(
        center.dx + (radius - 14) * cos(angle),
        center.dy + (radius - 14) * sin(angle),
      );
      canvas.drawLine(inner, outer, tickPaint);
    }

    final needleAngle = pi + (cents + 50) / 100 * pi;
    final needleColor = !active
        ? AppColors.textMuted
        : inTune
            ? AppColors.inTune
            : (cents.abs() <= 15 ? AppColors.warning : AppColors.danger);
    final needlePaint = Paint()
      ..color = needleColor
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final needleEnd = Offset(
      center.dx + (radius - 20) * cos(needleAngle),
      center.dy + (radius - 20) * sin(needleAngle),
    );
    canvas.drawLine(center, needleEnd, needlePaint);
    canvas.drawCircle(center, 6, Paint()..color = needleColor);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.cents != cents || oldDelegate.active != active;
  }
}
