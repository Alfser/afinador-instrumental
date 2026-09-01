import 'dart:math';

import '../entities/instrument.dart';
import '../entities/pitch_reading.dart';
import '../entities/tuning_target.dart';

/// Resolves which reference — an instrument string, or the nearest
/// chromatic note — a [PitchReading] should be compared against.
class TuningTargetResolver {
  const TuningTargetResolver();

  TuningTarget resolve(Instrument instrument, PitchReading reading) {
    if (instrument.isChromatic) {
      return TuningTarget(
        label: reading.note.label,
        cents: reading.note.cents,
      );
    }

    InstrumentString? best;
    var bestCents = double.infinity;
    for (final string in instrument.strings) {
      final cents = 1200 * (log(reading.frequency / string.frequency) / ln2);
      if (cents.abs() < bestCents.abs()) {
        bestCents = cents;
        best = string;
      }
    }
    return TuningTarget(label: best!.label, cents: bestCents);
  }
}
