import 'dart:math';

/// One harmonic partial used to build a plucked-string-like waveform.
/// [decayFactor] scales how much faster this partial fades relative to
/// the fundamental — real plucked strings lose their upper harmonics
/// quickly while the fundamental keeps ringing, which is what reads as
/// a natural "pluck" instead of a static buzz.
typedef _Harmonic = ({double multiplier, double amplitude, double decayFactor});

/// Synthesizes a short reference tone for a given frequency.
///
/// This is additive synthesis (a fundamental plus a few harmonics, each
/// with its own decay) shaped by an attack/decay envelope — not a
/// recorded instrument sample — used to give the user an audible pitch
/// reference when they tap a string button.
///
/// Low notes get extra treatment: at equal digital amplitude, human
/// hearing is markedly less sensitive to bass (equal-loudness contours),
/// and a fundamental-heavy low tone barely registers on small speakers.
/// So the lowest strings (guitar's low E and below) get both a higher
/// target peak and richer harmonics than notes at or above A4 — which
/// are left as a near-pure tone, unchanged. This loudness compensation
/// is done purely by boosting harmonic amplitude/peak level, never by
/// waveshaping the summed signal — nonlinear shaping of a multi-harmonic
/// waveform creates intermodulation products, which is what made bass
/// notes sound harsh/mechanized before.
class ToneSynthesizer {
  const ToneSynthesizer();

  static const double _baseDecayRate = 2.6;
  static const double _attackSeconds = 0.006;

  static const double _loudnessReferenceFrequency = 440.0; // A4
  // Reaches full boost by ~2.5 octaves below A4 (~78Hz), so guitar's low
  // E (82.4Hz) and anything lower (bass strings) get the full treatment.
  static const double _maxBoostOctaves = 2.5;
  static const double _quietPeak = 0.55; // target peak at/above the reference
  static const double _loudPeak = 0.92; // target peak for the lowest notes

  // Tiny per-harmonic stretch, modelling the slight inharmonicity of a
  // real string (stiffness pushes higher partials a bit sharp of exact
  // integer multiples). Subtle enough not to read as out of tune, but it
  // breaks the perfectly-locked overtone stack that makes pure additive
  // synthesis sound synthetic.
  static const double _inharmonicity = 0.00018;

  /// Returns normalized samples (-1..1) for [frequencyHz] over
  /// [durationSeconds], at [sampleRate] samples per second.
  List<double> synthesize(
    double frequencyHz, {
    required int sampleRate,
    double durationSeconds = 1.5,
  }) {
    final bassFactor = _bassFactor(frequencyHz);
    final harmonics = _harmonicsFor(bassFactor);

    final sampleCount = (sampleRate * durationSeconds).round();
    final samples = List<double>.filled(sampleCount, 0);

    for (var i = 0; i < sampleCount; i++) {
      final t = i / sampleRate;
      final attack = t < _attackSeconds ? sin(pi / 2 * t / _attackSeconds) : 1.0;
      final decayElapsed = t - min(t, _attackSeconds);

      var value = 0.0;
      for (final harmonic in harmonics) {
        final stretchedMultiplier =
            harmonic.multiplier * (1 + _inharmonicity * harmonic.multiplier * harmonic.multiplier);
        final decay = exp(-_baseDecayRate * harmonic.decayFactor * decayElapsed);
        value += harmonic.amplitude *
            decay *
            sin(2 * pi * frequencyHz * stretchedMultiplier * t);
      }
      samples[i] = value * attack;
    }

    var peak = 0.0;
    for (final s in samples) {
      if (s.abs() > peak) peak = s.abs();
    }
    if (peak > 0) {
      final targetPeak = _quietPeak + (_loudPeak - _quietPeak) * bassFactor;
      for (var i = 0; i < sampleCount; i++) {
        samples[i] = samples[i] / peak * targetPeak;
      }
    }
    return samples;
  }

  /// 0 at/above [_loudnessReferenceFrequency], ramping up to 1 for notes
  /// [_maxBoostOctaves] octaves (or more) below it.
  double _bassFactor(double frequencyHz) {
    final octavesBelowReference =
        log(_loudnessReferenceFrequency / frequencyHz) / ln2;
    return (octavesBelowReference / _maxBoostOctaves).clamp(0.0, 1.0);
  }

  /// Harmonic partials for a given [bassFactor]: a near-pure tone when 0
  /// (notes at/above the reference), growing richer/brighter as it
  /// approaches 1 (the lowest strings). Each partial decays faster than
  /// the last, so the richness is front-loaded into the attack and the
  /// tail mellows toward the fundamental, like a real pluck.
  List<_Harmonic> _harmonicsFor(double bassFactor) {
    return [
      (multiplier: 1.0, amplitude: 1.0, decayFactor: 1.0),
      (multiplier: 2.0, amplitude: 0.5 + bassFactor * 0.3, decayFactor: 1.6),
      (multiplier: 3.0, amplitude: 0.22 + bassFactor * 0.28, decayFactor: 2.2),
      (multiplier: 4.0, amplitude: 0.1 + bassFactor * 0.2, decayFactor: 2.8),
      (multiplier: 5.0, amplitude: bassFactor * 0.14, decayFactor: 3.4),
      (multiplier: 6.0, amplitude: bassFactor * 0.09, decayFactor: 4.0),
    ];
  }
}
