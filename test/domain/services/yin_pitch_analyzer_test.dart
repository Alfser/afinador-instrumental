import 'dart:math';

import 'package:afinador_flutter/domain/services/yin_pitch_analyzer.dart';
import 'package:flutter_test/flutter_test.dart';

/// A synthesized tone with a second harmonic and mic-level background
/// noise. The noise is what actually triggers the octave-down bug: it's
/// what pushes CMND at the true period just *above* the absolute
/// threshold (dropping the search into the "global minimum" fallback),
/// at which point the doubled-period lag — which the fallback has no bias
/// against — can score just as well or better. A clean tone never
/// exercises this path, which is why a noiseless version of this test
/// doesn't catch the bug at all.
List<double> _noisyTone(
  double frequency,
  int sampleRate,
  int length, {
  double secondHarmonicAmplitude = 0.5,
  double noiseAmplitude = 0.0,
  Random? random,
}) {
  final rng = random ?? Random(7);
  return List.generate(length, (i) {
    final t = i / sampleRate;
    final noise = noiseAmplitude == 0
        ? 0.0
        : (rng.nextDouble() * 2 - 1) * noiseAmplitude;
    return sin(2 * pi * frequency * t) +
        secondHarmonicAmplitude * sin(2 * pi * 2 * frequency * t) +
        noise;
  });
}

void main() {
  const sampleRate = 44100;
  const bufferSize = 4096;
  final analyzer = YinPitchAnalyzer();

  test('detects E4 instead of locking an octave down onto E3', () {
    final samples = _noisyTone(
      329.63,
      sampleRate,
      bufferSize,
      noiseAmplitude: 0.6,
      random: Random(1),
    );
    final result = analyzer.analyze(
      samples,
      sampleRate: sampleRate,
      minFrequency: 73.0, // guitar's whole-instrument search range
      maxFrequency: 370.0,
    );
    expect(result, isNotNull);
    expect(result!.frequency, closeTo(329.63, 5));
  });

  test('detects B3 instead of locking an octave down onto B2', () {
    final samples = _noisyTone(
      246.94,
      sampleRate,
      bufferSize,
      noiseAmplitude: 0.6,
      random: Random(2),
    );
    final result = analyzer.analyze(
      samples,
      sampleRate: sampleRate,
      minFrequency: 73.0,
      maxFrequency: 370.0,
    );
    expect(result, isNotNull);
    expect(result!.frequency, closeTo(246.94, 5));
  });

  test('still detects a real low note with a strong 2nd harmonic', () {
    final samples = _noisyTone(82.41, sampleRate, bufferSize);
    final result = analyzer.analyze(
      samples,
      sampleRate: sampleRate,
      minFrequency: 73.0,
      maxFrequency: 370.0,
    );
    expect(result, isNotNull);
    expect(result!.frequency, closeTo(82.41, 2));
  });

  // Regression: on a real guitar's rich harmonic series (fundamental +
  // several overtones, not just one), the octave-down correction's local
  // minimum search could accept a boundary artifact that wasn't a true
  // local minimum. That fed the parabolic interpolation a center point
  // whose neighbor was *lower* than it, occasionally producing an offset
  // far outside the mathematically valid (-0.5, 0.5) range — sometimes
  // enough to make `betterTau`, and therefore the reported frequency,
  // negative. A negative frequency reaches `NoteMapper.map` as
  // `log(negative)`, which is NaN, and `.round()` on NaN crashes the app.
  // This was most visible on A2 and D3, which is why they're covered
  // here across many noise seeds alongside the strings from the tests
  // above.
  test(
    'never returns a non-finite/non-positive frequency, and never jumps '
    'an octave, across many noisy passes on every string',
    () {
      const harmonics = [1.0, 0.6, 0.4, 0.25, 0.15, 0.08];
      const strings = {
        'E2': 82.41,
        'A2': 110.00,
        'D3': 146.83,
        'G3': 196.00,
        'B3': 246.94,
        'E4': 329.63,
      };

      for (final entry in strings.entries) {
        for (var seed = 0; seed < 100; seed++) {
          final rng = Random(seed);
          final samples = List<double>.generate(bufferSize, (i) {
            final t = i / sampleRate;
            var v = 0.0;
            for (var h = 0; h < harmonics.length; h++) {
              v += harmonics[h] * sin(2 * pi * entry.value * (h + 1) * t);
            }
            return v + (rng.nextDouble() * 2 - 1) * 0.5;
          });

          final result = analyzer.analyze(
            samples,
            sampleRate: sampleRate,
            minFrequency: 73.0,
            maxFrequency: 370.0,
          );
          if (result == null) continue;

          expect(
            result.frequency.isFinite && result.frequency > 0,
            isTrue,
            reason: '${entry.key} seed=$seed gave ${result.frequency}',
          );
          // A single 80ms window under heavy noise can land a few percent
          // off the true pitch — that's ordinary jitter the repository's
          // median filter and note lock smooth out. What must never
          // happen is an octave (1200 cents) or greater jump, which is
          // the actual regression this test guards against.
          final cents = 1200 * (log(result.frequency / entry.value) / ln2);
          expect(
            cents.abs(),
            lessThan(150),
            reason: '${entry.key} seed=$seed jumped to ${result.frequency}',
          );
        }
      }
    },
  );
}
