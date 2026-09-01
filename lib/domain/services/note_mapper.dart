import 'dart:math';

import '../entities/note.dart';

/// Maps a raw frequency to the nearest equal-tempered [Note] (A4 = 440Hz).
class NoteMapper {
  const NoteMapper();

  static const double a4 = 440.0;
  static const List<String> _names = [
    'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B',
  ];

  Note map(double frequency) {
    final semitonesFromA4 = 12 * (log(frequency / a4) / ln2);
    final rounded = semitonesFromA4.round();
    final midi = rounded + 69;
    final noteIndex = midi % 12;
    final octave = (midi / 12).floor() - 1;
    final targetFrequency = a4 * pow(2, rounded / 12);
    final cents = (semitonesFromA4 - rounded) * 100;
    return Note(
      name: _names[noteIndex],
      octave: octave,
      frequency: frequency,
      targetFrequency: targetFrequency.toDouble(),
      cents: cents,
    );
  }
}
