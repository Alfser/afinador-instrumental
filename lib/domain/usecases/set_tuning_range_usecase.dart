import '../repositories/pitch_repository.dart';

/// Narrows live pitch detection to the frequency range relevant to the
/// selected instrument, so ambient noise outside that range can't be
/// mistaken for one of its notes.
class SetTuningRangeUseCase {
  const SetTuningRangeUseCase(this._repository);

  final PitchRepository _repository;

  void call({required double minFrequency, required double maxFrequency}) {
    _repository.setFrequencyRange(
      minFrequency: minFrequency,
      maxFrequency: maxFrequency,
    );
  }
}
