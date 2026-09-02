import 'dart:math';

import 'pitch_analyzer.dart';

/// Fundamental frequency estimator based on the YIN algorithm
/// (de Cheveigné & Kawahara, 2002), restricted to a target frequency
/// range so it stays cheap enough to run several times per second.
///
/// This is the only concrete [PitchAnalyzer] today; a different algorithm
/// can be added as a sibling class and swapped in at the composition root
/// without any other code changing (Liskov Substitution Principle).
class YinPitchAnalyzer implements PitchAnalyzer {
  YinPitchAnalyzer({this.threshold = 0.15, this.silenceRms = 0.02});

  final double threshold;
  final double silenceRms;

  /// How much worse (relative to the chosen lag's CMND value) a shorter
  /// lag's own local minimum is allowed to be and still be preferred, when
  /// correcting an octave-down error. See the correction step in
  /// [analyze] for why this is needed.
  static const double _octaveTolerance = 1.25;

  @override
  PitchAnalysisResult? analyze(
    List<double> samples, {
    required int sampleRate,
    required double minFrequency,
    required double maxFrequency,
  }) {
    final n = samples.length;

    var sumSquares = 0.0;
    for (final s in samples) {
      sumSquares += s * s;
    }
    final rms = sqrt(sumSquares / n);
    if (rms < silenceRms) return null;

    final tauMin = (sampleRate / maxFrequency).floor().clamp(2, n - 2);
    final tauMax = (sampleRate / minFrequency).ceil().clamp(tauMin + 1, n - 2);
    final window = n - tauMax;
    if (window < tauMax || window < 32) return null;

    // Difference function: d(tau) = sum (x[j] - x[j+tau])^2
    final diff = List<double>.filled(tauMax + 1, 0);
    for (var tau = 1; tau <= tauMax; tau++) {
      var sum = 0.0;
      for (var j = 0; j < window; j++) {
        final delta = samples[j] - samples[j + tau];
        sum += delta * delta;
      }
      diff[tau] = sum;
    }

    // Cumulative mean normalized difference function.
    final cmnd = List<double>.filled(tauMax + 1, 1.0);
    var runningSum = 0.0;
    for (var tau = 1; tau <= tauMax; tau++) {
      runningSum += diff[tau];
      cmnd[tau] = runningSum == 0 ? 1.0 : diff[tau] * tau / runningSum;
    }

    // Absolute threshold: first local minimum below the threshold.
    var bestTau = -1;
    for (var tau = tauMin; tau < tauMax; tau++) {
      if (cmnd[tau] < threshold) {
        while (tau + 1 < tauMax && cmnd[tau + 1] < cmnd[tau]) {
          tau++;
        }
        bestTau = tau;
        break;
      }
    }

    // Fallback: global minimum in range, only if reasonably periodic. Kept
    // tight (relative to `threshold`) so broadband external noise — which
    // rarely dips much below that bar at any lag — is dropped as silence
    // instead of being reported as a wandering, noisy pitch.
    if (bestTau == -1) {
      var minValue = double.infinity;
      for (var tau = tauMin; tau < tauMax; tau++) {
        if (cmnd[tau] < minValue) {
          minValue = cmnd[tau];
          bestTau = tau;
        }
      }
      if (minValue > threshold * 2) return null;
    }

    // Octave-down correction: CMND's normalization tends to dig a deeper
    // dip at a multiple of the true period than at the period itself,
    // which the forward threshold search above has no defense against
    // once it happens — most noticeably for the shortest (highest-pitch)
    // lags, where the dip at tau0 often sits just above `threshold` while
    // the dip at 2*tau0 clears it easily. Walk back down an octave at a
    // time whenever the shorter lag's own local minimum is comparably
    // deep; a real note at the longer lag has no such echo, so this only
    // fires on the doubling artifact.
    while (true) {
      final half = bestTau ~/ 2;
      if (half < tauMin) break;
      var candidate = half;
      while (candidate > tauMin && cmnd[candidate - 1] < cmnd[candidate]) {
        candidate--;
      }
      while (candidate + 1 < bestTau && cmnd[candidate + 1] < cmnd[candidate]) {
        candidate++;
      }
      // The walk above can also stop simply because it hit `bestTau`'s
      // boundary while still descending — i.e. there was no separate dip
      // near `half` at all, just a monotonic slope up to `bestTau`. That's
      // not a real competing period, and treating it as one would hand
      // the parabolic interpolation below a center point whose neighbor
      // is lower than it — breaking the "true local minimum" assumption
      // it relies on, which can send it wildly out of range.
      final isLocalMinimum =
          (candidate == tauMin || cmnd[candidate - 1] >= cmnd[candidate]) &&
              cmnd[candidate] <= cmnd[candidate + 1];
      if (isLocalMinimum && cmnd[candidate] <= cmnd[bestTau] * _octaveTolerance) {
        bestTau = candidate;
      } else {
        break;
      }
    }

    // Parabolic interpolation around the chosen lag for sub-sample precision.
    var betterTau = bestTau.toDouble();
    if (bestTau > tauMin && bestTau < tauMax - 1) {
      final y0 = cmnd[bestTau - 1];
      final y1 = cmnd[bestTau];
      final y2 = cmnd[bestTau + 1];
      final denom = y0 - 2 * y1 + y2;
      if (denom != 0) {
        // A genuine local minimum bounds this offset to (-0.5, 0.5); a
        // wider swing only happens when `denom` is a near-zero artifact of
        // floating-point noise rather than a real parabola, so it's
        // clamped rather than trusted.
        final offset = ((y0 - y2) / (2 * denom)).clamp(-0.5, 0.5);
        betterTau = bestTau + offset;
      }
    }

    final frequency = sampleRate / betterTau;
    if (!frequency.isFinite || frequency <= 0) return null;
    final confidence = (1 - cmnd[bestTau]).clamp(0.0, 1.0);
    return PitchAnalysisResult(
      frequency: frequency,
      confidence: confidence,
      amplitude: rms,
    );
  }
}
