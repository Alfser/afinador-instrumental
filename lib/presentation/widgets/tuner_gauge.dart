import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// A 270° dial (speedometer-style) showing pitch deviation in cents, from
/// -50 to +50, with colored zones, numbered major ticks and an animated
/// needle — closer to a dedicated tuner's dial than a bare arc.
class TunerGauge extends StatelessWidget {
  const TunerGauge({super.key, required this.cents, required this.active, this.noteName});

  final double cents;
  final bool active;

  /// The detected note's letter name without octave (e.g. "F#") — shown,
  /// translated to solfège (e.g. "Fá#"), below the needle's pivot. The
  /// header above the dial already shows the letter/cifra form; this adds
  /// the do-re-mi form for people who don't read cifra notation.
  final String? noteName;

  static const _solfege = {
    'C': 'Dó', 'C#': 'Dó#',
    'D': 'Ré', 'D#': 'Ré#',
    'E': 'Mi',
    'F': 'Fá', 'F#': 'Fá#',
    'G': 'Sol', 'G#': 'Sol#',
    'A': 'Lá', 'A#': 'Lá#',
    'B': 'Si',
  };

  @override
  Widget build(BuildContext context) {
    final clamped = cents.clamp(-50, 50).toDouble();
    final solfege = active ? _solfege[noteName] : null;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: clamped),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return CustomPaint(
          size: const Size(320, 300),
          painter: _GaugePainter(cents: value, active: active, solfege: solfege),
        );
      },
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({required this.cents, required this.active, this.solfege});

  final double cents;
  final bool active;
  final String? solfege;

  /// Deviation, in cents, within which the pitch counts as "in tune" —
  /// drives the needle/zone color, matching `TuningTarget.isInTune`.
  static const _inTuneThresholdCents = 5.0;

  /// Deviation, in cents, up to which the pitch is merely "close" (amber)
  /// rather than clearly off (red).
  static const _closeThresholdCents = 15.0;

  /// Dial geometry: a 270° sweep starting down-left and ending down-right,
  /// leaving a 90° gap at the bottom — a classic speedometer layout.
  static const _startAngle = 3 * pi / 4;
  static const _sweepAngle = 3 * pi / 2;

  static double _angleFor(double c) => _startAngle + (c + 50) / 100 * _sweepAngle;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.7);
    final radius = min(size.width, size.height * 1.6) / 2 - 26;
    final inTune = active && cents.abs() <= _inTuneThresholdCents;

    _paintZones(canvas, center, radius);
    _paintTicks(canvas, center, radius);
    _paintNeedle(canvas, center, radius, inTune);
    _paintSolfegeLabel(canvas, center, inTune);
  }

  /// Draws the solfège note name in the open 90° wedge below the pivot —
  /// the dial's sweep leaves that space empty, so it reads as "inside the
  /// clock" without overlapping any zone, tick or the needle itself.
  void _paintSolfegeLabel(Canvas canvas, Offset center, bool inTune) {
    if (solfege == null) return;
    final color = inTune
        ? AppColors.inTune
        : (cents.abs() <= _closeThresholdCents ? AppColors.warning : AppColors.danger);
    final painter = TextPainter(
      text: TextSpan(
        text: solfege,
        style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w700),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, center + Offset(-painter.width / 2, 34));
  }

  void _paintZones(Canvas canvas, Offset center, double radius) {
    const bounds = [-50.0, -_closeThresholdCents, -_inTuneThresholdCents,
      _inTuneThresholdCents, _closeThresholdCents, 50.0];
    final colors = [
      AppColors.danger,
      AppColors.warning,
      AppColors.inTune,
      AppColors.warning,
      AppColors.danger,
    ];
    final rect = Rect.fromCircle(center: center, radius: radius);
    for (var i = 0; i < colors.length; i++) {
      final a0 = _angleFor(bounds[i]);
      final a1 = _angleFor(bounds[i + 1]);
      canvas.drawArc(
        rect,
        a0,
        a1 - a0,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 14
          ..strokeCap = StrokeCap.butt
          ..color = colors[i].withValues(alpha: active ? 0.9 : 0.35),
      );
    }
  }

  void _paintTicks(Canvas canvas, Offset center, double radius) {
    for (var c = -50; c <= 50; c += 5) {
      final isMajor = c % 25 == 0;
      final isCenter = c == 0;
      final angle = _angleFor(c.toDouble());
      final tickColor = isCenter
          ? AppColors.inTune
          : (isMajor ? AppColors.textSecondary : AppColors.textMuted);
      final length = isCenter ? 18.0 : (isMajor ? 14.0 : 7.0);
      final outer = _polar(center, radius + 10, angle);
      final inner = _polar(center, radius + 10 - length, angle);
      canvas.drawLine(
        inner,
        outer,
        Paint()
          ..color = tickColor
          ..strokeWidth = isCenter ? 3 : (isMajor ? 2 : 1.4)
          ..strokeCap = StrokeCap.round,
      );

      if (isMajor) {
        final label = c > 0 ? '+$c' : '$c';
        final painter = TextPainter(
          text: TextSpan(
            text: label,
            style: TextStyle(
              color: isCenter ? AppColors.inTune : AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        final labelPos = _polar(center, radius + 26, angle);
        painter.paint(
          canvas,
          labelPos - Offset(painter.width / 2, painter.height / 2),
        );
      }
    }
  }

  void _paintNeedle(Canvas canvas, Offset center, double radius, bool inTune) {
    final needleAngle = _angleFor(cents);
    final needleColor = !active
        ? AppColors.textMuted
        : inTune
            ? AppColors.inTune
            : (cents.abs() <= _closeThresholdCents
                ? AppColors.warning
                : AppColors.danger);

    final tip = _polar(center, radius - 22, needleAngle);
    final tail = _polar(center, 18, needleAngle + pi);

    // Soft glow behind the needle tip, only while actively tracking a pitch.
    if (active) {
      canvas.drawCircle(
        tip,
        14,
        Paint()
          ..color = needleColor.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }

    canvas.drawLine(
      tail,
      tip,
      Paint()
        ..color = needleColor
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(center, 9, Paint()..color = AppColors.bgAlt);
    canvas.drawCircle(
      center,
      9,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = needleColor,
    );
  }

  Offset _polar(Offset center, double radius, double angle) {
    return Offset(center.dx + radius * cos(angle), center.dy + radius * sin(angle));
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.cents != cents ||
        oldDelegate.active != active ||
        oldDelegate.solfege != solfege;
  }
}
