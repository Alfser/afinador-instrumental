import '../repositories/pitch_repository.dart';

/// Stops live pitch detection and releases the microphone.
class StopTuningUseCase {
  const StopTuningUseCase(this._repository);

  final PitchRepository _repository;

  Future<void> call() => _repository.stop();
}
