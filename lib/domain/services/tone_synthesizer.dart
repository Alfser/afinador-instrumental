import 'dart:math';

/// One harmonic partial used to build a plucked-string-like waveform.
typedef _Harmonic = ({double multiplier, double amplitude});

/// Synthesizes a short reference tone for a given frequency.
///
/// This is additive synthesis (a fundamental plus a few harmonics) shaped
/// by an exponential decay envelope — not a recorded instrument sample —
/// used to give the user an audible pitch reference when they tap a
/// string button.
///
/// Low notes get extra treatment: at equal digital amplitude, human
/// hearing is markedly less sensitive to bass (equal-loudness contours),
/// and a fundamental-heavy low tone barely registers on small speakers.
/// So the lowest strings (guitar's low E and below) get both a higher
/// target peak and richer, more audible harmonics than notes at or above
/// A4 — which are left as a near-pure tone, unchanged.
class ToneSynthesizer {
  const ToneSynthesizer();

  static const double _decayRate = 3.5;
  static const double _attackSeconds = 0.005;

  static const double _loudnessReferenceFrequency = 440.0; // A4
  // Reaches full boost by ~2.5 octaves below A4 (~78Hz), so guitar's low
  // E (82.4Hz) and anything lower (bass strings) get the full treatment.
  static const double _maxBoostOctaves = 2.5;
  static const double _quietPeak = 0.55; // target peak at/above the reference
  static const double _loudPeak = 0.98; // target peak for the lowest notes

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
      var value = 0.0;
      for (final harmonic in harmonics) {
        value += harmonic.amplitude *
            sin(2 * pi * frequencyHz * harmonic.multiplier * t);
      }
      final envelope = t < _attackSeconds
          ? t / _attackSeconds
          : exp(-_decayRate * (t - _attackSeconds));
      samples[i] = _compress(value, bassFactor) * envelope;
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

  /// Power-law soft compression: boosts quiet parts of the waveform
  /// relatively more than loud parts, raising the signal's average
  /// (perceived-loudness-correlated) energy without raising its peak.
  /// A no-op at [bassFactor] 0; strongest for the lowest notes.
  double _compress(double value, double bassFactor) {
    if (bassFactor <= 0 || value == 0) return value;
    const maxCompression = 0.4;
    final exponent = 1.0 - bassFactor * maxCompression;
    return value.sign * pow(value.abs(), exponent).toDouble();
  }

  /// Harmonic partials for a given [bassFactor]: a near-pure tone when 0
  /// (notes at/above the reference), growing richer/brighter as it
  /// approaches 1 (the lowest strings), which also reads as louder.
  List<_Harmonic> _harmonicsFor(double bassFactor) {
    return [
      (multiplier: 1.0, amplitude: 1.0),
      (multiplier: 2.0, amplitude: 0.5 + bassFactor * 0.35),
      (multiplier: 3.0, amplitude: 0.25 + bassFactor * 0.35),
      (multiplier: 4.0, amplitude: 0.125 + bassFactor * 0.25),
      (multiplier: 5.0, amplitude: bassFactor * 0.18),
      (multiplier: 6.0, amplitude: bassFactor * 0.12),
    ];
  }
}
