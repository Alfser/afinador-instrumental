import '../entities/pitch_reading.dart';
import '../repositories/pitch_repository.dart';

/// Exposes the live stream of pitch readings.
class WatchPitchUseCase {
  const WatchPitchUseCase(this._repository);

  final PitchRepository _repository;

  Stream<PitchReading?> call() => _repository.readings;
}
