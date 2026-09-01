import 'dart:math';

import 'package:flutter/material.dart';

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

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 10;
    final inTune = active && cents.abs() <= 5;

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..color = Colors.grey.shade300;
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
        ..color = isCenter ? Colors.green : Colors.grey.shade500
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
        ? Colors.grey
        : inTune
            ? Colors.green
            : (cents.abs() <= 15 ? Colors.orange : Colors.red);
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
