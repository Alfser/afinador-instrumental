import 'package:flutter/material.dart';

import '../../domain/entities/instrument.dart';

/// Self-contained vector glyph for one instrument type.
///
/// Drawn with [CustomPainter] instead of an emoji (glyphs like 🎸/🪕 render
/// as empty "tofu" boxes on Linux desktops, which typically ship without a
/// color-emoji font) or a Material Icon (the bundled font has no
/// guitar/violin/ukulele glyphs at all). A painted path always renders,
/// on every platform, with no font dependency.
class InstrumentIcon extends StatelessWidget {
  const InstrumentIcon({
    super.key,
    required this.instrument,
    required this.color,
    required this.background,
    this.size = 22,
  });

  final Instrument instrument;
  final Color color;
  final Color background;
  final double size;

  _Glyph get _glyph {
    switch (instrument.name) {
      case 'Violão / Guitarra':
        return _Glyph.guitar;
      case 'Baixo':
        return _Glyph.bass;
      case 'Ukulele':
        return _Glyph.ukulele;
      case 'Violino':
        return _Glyph.violin;
      case 'Cavaquinho':
        return _Glyph.cavaquinho;
      default:
        return _Glyph.chromatic;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _InstrumentGlyphPainter(
          glyph: _glyph,
          color: color,
          background: background,
        ),
      ),
    );
  }
}

enum _Glyph { guitar, bass, ukulele, violin, cavaquinho, chromatic }

/// All shapes are authored on a fixed 24x24 design grid, then scaled to
/// the actual canvas size — coordinates below are grid units, not pixels.
class _InstrumentGlyphPainter extends CustomPainter {
  _InstrumentGlyphPainter({
    required this.glyph,
    required this.color,
    required this.background,
  });

  final _Glyph glyph;
  final Color color;
  final Color background;

  static const _grid = 24.0;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / _grid, size.height / _grid);

    final fill = Paint()
      ..color = color
      ..isAntiAlias = true;
    final cutout = Paint()
      ..color = background
      ..isAntiAlias = true;
    final thinStroke = Paint()
      ..color = background
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    switch (glyph) {
      case _Glyph.guitar:
        _bodyNeckInstrument(
          canvas,
          fill,
          cutout,
          waisted: true,
          upperBoutRadius: 3.6,
          upperBoutCenterY: 14.5,
          lowerBoutRadius: 4.6,
          lowerBoutCenterY: 19.2,
          neckTop: 3,
          neckWidth: 2.2,
          headTop: 1,
          headWidth: 5.2,
          headHeight: 2.4,
          headRadius: 0.8,
          soundHoleCenter: const Offset(12, 18.4),
          soundHoleRadius: 1.1,
        );
        break;
      case _Glyph.cavaquinho:
        _bodyNeckInstrument(
          canvas,
          fill,
          cutout,
          waisted: true,
          upperBoutRadius: 3.0,
          upperBoutCenterY: 14.8,
          lowerBoutRadius: 3.8,
          lowerBoutCenterY: 18.6,
          neckTop: 6.5,
          neckWidth: 1.8,
          headTop: 4.6,
          headWidth: 4.8,
          headHeight: 2.0,
          headRadius: 0.2,
          soundHoleCenter: const Offset(12, 18.1),
          soundHoleRadius: 0.9,
        );
        break;
      case _Glyph.bass:
        _bodyNeckInstrument(
          canvas,
          fill,
          cutout,
          waisted: false,
          ovalRect: const Rect.fromLTWH(6.8, 12.5, 10.4, 10),
          neckTop: 1,
          neckWidth: 1.9,
          headTop: -0.4,
          headWidth: 4.4,
          headHeight: 2.2,
          headRadius: 0.8,
        );
        break;
      case _Glyph.ukulele:
        _bodyNeckInstrument(
          canvas,
          fill,
          cutout,
          waisted: false,
          ovalRect: const Rect.fromLTWH(7.4, 13, 9.2, 8),
          neckTop: 6,
          neckWidth: 1.8,
          headTop: 4.2,
          headWidth: 4.4,
          headHeight: 2.0,
          headRadius: 0.8,
          soundHoleCenter: const Offset(12, 17.4),
          soundHoleRadius: 1.0,
        );
        break;
      case _Glyph.violin:
        _paintViolin(canvas, fill, cutout, thinStroke);
        break;
      case _Glyph.chromatic:
        _paintTuningFork(canvas, fill);
        break;
    }

    canvas.restore();
  }

  /// Shared "neck + headstock + body" builder used by every fretted
  /// instrument. Bodies are either a waisted figure-8 (two unioned
  /// circles) or a plain oval, keeping guitar/cavaquinho visually
  /// distinct from bass/ukulele at a glance.
  void _bodyNeckInstrument(
    Canvas canvas,
    Paint fill,
    Paint cutout, {
    required bool waisted,
    double upperBoutRadius = 0,
    double upperBoutCenterY = 0,
    double lowerBoutRadius = 0,
    double lowerBoutCenterY = 0,
    Rect? ovalRect,
    required double neckTop,
    required double neckWidth,
    required double headTop,
    required double headWidth,
    required double headHeight,
    required double headRadius,
    Offset? soundHoleCenter,
    double soundHoleRadius = 0,
  }) {
    const centerX = 12.0;

    late final Path bodyPath;
    late final double neckBottom;
    if (waisted) {
      final upper = Path()
        ..addOval(Rect.fromCircle(
          center: Offset(centerX, upperBoutCenterY),
          radius: upperBoutRadius,
        ));
      final lower = Path()
        ..addOval(Rect.fromCircle(
          center: Offset(centerX, lowerBoutCenterY),
          radius: lowerBoutRadius,
        ));
      bodyPath = Path.combine(PathOperation.union, upper, lower);
      neckBottom = upperBoutCenterY + 1;
    } else {
      bodyPath = Path()..addOval(ovalRect!);
      neckBottom = ovalRect.top + ovalRect.height * 0.28;
    }
    canvas.drawPath(bodyPath, fill);

    canvas.drawRect(
      Rect.fromLTRB(
        centerX - neckWidth / 2,
        neckTop,
        centerX + neckWidth / 2,
        neckBottom,
      ),
      fill,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          centerX - headWidth / 2,
          headTop,
          headWidth,
          headHeight,
        ),
        Radius.circular(headRadius),
      ),
      fill,
    );

    if (soundHoleCenter != null) {
      canvas.drawCircle(soundHoleCenter, soundHoleRadius, cutout);
    }
  }

  /// Violin gets its own shape: an angular hourglass body (pointed bouts,
  /// unlike the round-cornered figure-8 of the other strings), a pair of
  /// f-hole slits, and a round scroll pegbox instead of a flat headstock.
  void _paintViolin(Canvas canvas, Paint fill, Paint cutout, Paint thinStroke) {
    final body = Path()
      ..moveTo(8, 10)
      ..lineTo(16, 10)
      ..lineTo(14.6, 13.2)
      ..lineTo(16.6, 17)
      ..lineTo(14, 22)
      ..lineTo(10, 22)
      ..lineTo(7.4, 17)
      ..lineTo(9.4, 13.2)
      ..close();
    canvas.drawPath(body, fill);

    canvas.drawRect(const Rect.fromLTRB(11.2, 3, 12.8, 11), fill);
    canvas.drawCircle(const Offset(12, 2.6), 1.4, fill);

    canvas.drawLine(const Offset(10.3, 14.6), const Offset(10.9, 17.2), thinStroke);
    canvas.drawLine(const Offset(13.7, 14.6), const Offset(13.1, 17.2), thinStroke);
  }

  /// Chromatic mode isn't a physical instrument — a tuning-fork glyph
  /// reads as "detects any pitch" without borrowing another body shape.
  void _paintTuningFork(Canvas canvas, Paint fill) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTRB(9.3, 3, 10.9, 14),
        const Radius.circular(0.8),
      ),
      fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTRB(13.1, 3, 14.7, 14),
        const Radius.circular(0.8),
      ),
      fill,
    );
    canvas.drawRect(const Rect.fromLTRB(9.3, 13, 14.7, 15.2), fill);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTRB(11.2, 14.6, 12.8, 21),
        const Radius.circular(0.8),
      ),
      fill,
    );
  }

  @override
  bool shouldRepaint(covariant _InstrumentGlyphPainter oldDelegate) {
    return oldDelegate.glyph != glyph ||
        oldDelegate.color != color ||
        oldDelegate.background != background;
  }
}
