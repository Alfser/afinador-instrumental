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
  YinPitchAnalyzer({this.threshold = 0.15, this.silenceRms = 0.01});

  final double threshold;
  final double silenceRms;

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

    // Fallback: global minimum in range, only if reasonably periodic.
    if (bestTau == -1) {
      var minValue = double.infinity;
      for (var tau = tauMin; tau < tauMax; tau++) {
        if (cmnd[tau] < minValue) {
          minValue = cmnd[tau];
          bestTau = tau;
        }
      }
      if (minValue > 0.5) return null;
    }

    // Parabolic interpolation around the chosen lag for sub-sample precision.
    var betterTau = bestTau.toDouble();
    if (bestTau > tauMin && bestTau < tauMax - 1) {
      final y0 = cmnd[bestTau - 1];
      final y1 = cmnd[bestTau];
      final y2 = cmnd[bestTau + 1];
      final denom = y0 - 2 * y1 + y2;
      if (denom != 0) {
        betterTau = bestTau + (y0 - y2) / (2 * denom);
      }
    }

    final frequency = sampleRate / betterTau;
    final confidence = (1 - cmnd[bestTau]).clamp(0.0, 1.0);
    return PitchAnalysisResult(
      frequency: frequency,
      confidence: confidence,
      amplitude: rms,
    );
  }
}
