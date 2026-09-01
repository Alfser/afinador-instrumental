import '../entities/instrument.dart';
import '../entities/pitch_reading.dart';
import '../entities/tuning_target.dart';
import '../services/tuning_target_resolver.dart';

/// Resolves the reference (string or nearest chromatic note) a reading
/// should be compared against for the currently selected instrument.
class ResolveTuningTargetUseCase {
  const ResolveTuningTargetUseCase(this._resolver);

  final TuningTargetResolver _resolver;

  TuningTarget call(Instrument instrument, PitchReading reading) =>
      _resolver.resolve(instrument, reading);
}
