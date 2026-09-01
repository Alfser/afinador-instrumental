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
}
