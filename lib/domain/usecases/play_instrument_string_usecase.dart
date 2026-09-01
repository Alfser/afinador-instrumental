import '../entities/instrument.dart';
import '../repositories/tone_player_repository.dart';

/// Plays a short reference tone for the given instrument string.
class PlayInstrumentStringUseCase {
  const PlayInstrumentStringUseCase(this._repository);

  final TonePlayerRepository _repository;

  Future<void> call(InstrumentString string) =>
      _repository.playTone(string.frequency);
}
