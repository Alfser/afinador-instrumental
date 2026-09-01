/// A musical note mapped from a detected frequency, expressed in
/// equal temperament (A4 = 440Hz).
class Note {
  const Note({
    required this.name,
    required this.octave,
    required this.frequency,
    required this.targetFrequency,
    required this.cents,
  });

  final String name;
  final int octave;
  final double frequency;
  final double targetFrequency;

  /// Deviation from the nearest note in cents. Negative = flat, positive = sharp.
  final double cents;

  String get label => '$name$octave';
}
