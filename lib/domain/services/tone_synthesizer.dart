import 'dart:math';

/// One harmonic partial used to build a plucked-string-like waveform.
typedef _Harmonic = ({double multiplier, double amplitude});

/// Synthesizes a short reference tone for a given frequency.
///
/// This is additive synthesis (a fundamental plus a few decaying
/// harmonics) shaped by an exponential decay envelope — not a recorded
/// instrument sample — used to give the user an audible pitch reference
/// when they tap a string button.
class ToneSynthesizer {
  const ToneSynthesizer();

  static const List<_Harmonic> _harmonics = [
    (multiplier: 1.0, amplitude: 1.0),
    (multiplier: 2.0, amplitude: 0.5),
    (multiplier: 3.0, amplitude: 0.25),
    (multiplier: 4.0, amplitude: 0.125),
  ];

  static const double _decayRate = 3.5;
  static const double _attackSeconds = 0.005;

  // Human hearing is markedly less sensitive to bass at equal signal
  // amplitude (equal-loudness contours), so a low string's digital peak
  // must be pushed closer to full scale than a high string's for the two
  // to sound comparably loud.
  static const double _loudnessReferenceFrequency = 440.0; // A4
  static const double _maxBoostOctaves = 4.0; // reaches down to ~E1 (41Hz)
  static const double _quietPeak = 0.55; // target peak at/above the reference
  static const double _loudPeak = 0.98; // target peak for the lowest notes

  /// Returns normalized samples (-1..1) for [frequencyHz] over
  /// [durationSeconds], at [sampleRate] samples per second.
  List<double> synthesize(
    double frequencyHz, {
    required int sampleRate,
    double durationSeconds = 1.5,
  }) {
    final sampleCount = (sampleRate * durationSeconds).round();
    final samples = List<double>.filled(sampleCount, 0);

    for (var i = 0; i < sampleCount; i++) {
      final t = i / sampleRate;
      var value = 0.0;
      for (final harmonic in _harmonics) {
        value += harmonic.amplitude *
            sin(2 * pi * frequencyHz * harmonic.multiplier * t);
      }
      final envelope = t < _attackSeconds
          ? t / _attackSeconds
          : exp(-_decayRate * (t - _attackSeconds));
      samples[i] = value * envelope;
    }

    var peak = 0.0;
    for (final s in samples) {
      if (s.abs() > peak) peak = s.abs();
    }
    if (peak > 0) {
      final targetPeak = _targetPeakFor(frequencyHz);
      for (var i = 0; i < sampleCount; i++) {
        samples[i] = samples[i] / peak * targetPeak;
      }
    }
    return samples;
  }

  double _targetPeakFor(double frequencyHz) {
    final octavesBelowReference =
        (log(_loudnessReferenceFrequency / frequencyHz) / ln2).clamp(
      0.0,
      _maxBoostOctaves,
    );
    return _quietPeak +
        (_loudPeak - _quietPeak) * (octavesBelowReference / _maxBoostOctaves);
  }
}
