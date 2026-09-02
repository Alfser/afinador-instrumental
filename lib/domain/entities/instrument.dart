import 'dart:math' as math;

/// A single tuned string (or course) that belongs to an [Instrument].
class InstrumentString {
  const InstrumentString(this.label, this.frequency);

  final String label;
  final double frequency;
}

/// A tuning preset: either a fixed set of strings, or the chromatic
/// mode (empty [strings]) which compares against the nearest note of
/// the full chromatic scale instead.
class Instrument {
  const Instrument(this.name, this.strings);

  final String name;
  final List<InstrumentString> strings;

  bool get isChromatic => strings.isEmpty;

  // A whole tone (200 cents) of headroom on each side of the strings'
  // range: enough to still catch a string that's flat/sharp while
  // tuning, without opening the door to ambient noise well outside the
  // instrument's actual range (e.g. sub-bass hum being mistaken for a
  // guitar's low E because nothing bounds it from below).
  static const _wholeToneDown = 0.8909; // 2^(-200/1200)
  static const _wholeToneUp = 1.1225; // 2^(200/1200)

  /// Lower bound to search for a pitch in, given this instrument's
  /// strings. Chromatic mode has no strings to anchor to, so it keeps a
  /// generous default spanning any realistic instrument.
  double get minDetectableFrequency {
    if (isChromatic) return 40.0;
    final lowest = strings.map((s) => s.frequency).reduce(math.min);
    return lowest * _wholeToneDown;
  }

  /// Upper bound to search for a pitch in — see [minDetectableFrequency].
  double get maxDetectableFrequency {
    if (isChromatic) return 1500.0;
    final highest = strings.map((s) => s.frequency).reduce(math.max);
    return highest * _wholeToneUp;
  }
}
