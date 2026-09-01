import '../repositories/pitch_repository.dart';

/// Starts live pitch detection. Returns false if microphone permission
/// was denied.
class StartTuningUseCase {
  const StartTuningUseCase(this._repository);

  final PitchRepository _repository;

  Future<bool> call() => _repository.start();
}
