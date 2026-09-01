/// The reference a [PitchReading] is being compared against: either an
/// instrument string label, or the nearest note in chromatic mode.
class TuningTarget {
  const TuningTarget({required this.label, required this.cents});

  final String label;
  final double cents;

  bool get isInTune => cents.abs() <= 5;
}
