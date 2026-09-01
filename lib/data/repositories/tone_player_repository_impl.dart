import '../../domain/repositories/tone_player_repository.dart';
import '../../domain/services/tone_synthesizer.dart';
import '../datasources/tone_player_data_source.dart';

/// [TonePlayerRepository] implementation that synthesizes a reference
/// tone (via [ToneSynthesizer]) and plays it through a
/// [TonePlayerDataSource]. Both collaborators are injected as
/// abstractions, so this class never depends on a concrete synthesis
/// algorithm or playback plugin.
class TonePlayerRepositoryImpl implements TonePlayerRepository {
  TonePlayerRepositoryImpl({
    required ToneSynthesizer synthesizer,
    required TonePlayerDataSource dataSource,
    this.sampleRate = 44100,
    this.durationSeconds = 1.5,
  })  : _synthesizer = synthesizer,
        _dataSource = dataSource;

  final ToneSynthesizer _synthesizer;
  final TonePlayerDataSource _dataSource;
  final int sampleRate;
  final double durationSeconds;

  @override
  Future<void> playTone(double frequencyHz) {
    final samples = _synthesizer.synthesize(
      frequencyHz,
      sampleRate: sampleRate,
      durationSeconds: durationSeconds,
    );
    return _dataSource.play(samples, sampleRate: sampleRate);
  }

  @override
  Future<void> stop() => _dataSource.stop();
}
