import 'note.dart';

/// A single pitch-detection sample produced from live audio input.
class PitchReading {
  const PitchReading({
    required this.frequency,
    required this.note,
    required this.amplitude,
    required this.confidence,
  });

  final double frequency;
  final Note note;

  /// RMS amplitude of the analyzed window (0..1-ish).
  final double amplitude;

  /// 0..1, higher means the detected periodicity was cleaner.
  final double confidence;
}
