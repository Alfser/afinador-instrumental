import 'package:get_it/get_it.dart';

import '../../data/datasources/audio_data_source.dart';
import '../../data/datasources/audioplayers_tone_data_source.dart';
import '../../data/datasources/microphone_audio_data_source.dart';
import '../../data/datasources/tone_player_data_source.dart';
import '../../data/repositories/instrument_repository_impl.dart';
import '../../data/repositories/pitch_repository_impl.dart';
import '../../data/repositories/tone_player_repository_impl.dart';
import '../../domain/repositories/instrument_repository.dart';
import '../../domain/repositories/pitch_repository.dart';
import '../../domain/repositories/tone_player_repository.dart';
import '../../domain/services/note_mapper.dart';
import '../../domain/services/pitch_analyzer.dart';
import '../../domain/services/tone_synthesizer.dart';
import '../../domain/services/tuning_target_resolver.dart';
import '../../domain/services/yin_pitch_analyzer.dart';
import '../../domain/usecases/get_instruments_usecase.dart';
import '../../domain/usecases/play_instrument_string_usecase.dart';
import '../../domain/usecases/resolve_tuning_target_usecase.dart';
import '../../domain/usecases/set_tuning_range_usecase.dart';
import '../../domain/usecases/start_tuning_usecase.dart';
import '../../domain/usecases/stop_tuning_usecase.dart';
import '../../domain/usecases/watch_pitch_usecase.dart';
import '../../presentation/viewmodels/tuner_view_model.dart';

final sl = GetIt.instance;

/// Composition root: this is the only place that wires concrete
/// implementations behind their abstractions. Nothing outside this file
/// knows about `record`, `get_it`, or which [PitchAnalyzer] is in use.
void setupDependencies() {
  // Domain services
  sl.registerLazySingleton<PitchAnalyzer>(YinPitchAnalyzer.new);
  sl.registerLazySingleton<NoteMapper>(() => const NoteMapper());
  sl.registerLazySingleton<TuningTargetResolver>(
    () => const TuningTargetResolver(),
  );
  sl.registerLazySingleton<ToneSynthesizer>(() => const ToneSynthesizer());

  // Data sources
  sl.registerLazySingleton<AudioDataSource>(MicrophoneAudioDataSource.new);
  sl.registerLazySingleton<TonePlayerDataSource>(
    AudioplayersToneDataSource.new,
  );

  // Repositories
  sl.registerLazySingleton<PitchRepository>(
    () => PitchRepositoryImpl(
      audioDataSource: sl(),
      pitchAnalyzer: sl(),
      noteMapper: sl(),
    ),
  );
  sl.registerLazySingleton<InstrumentRepository>(
    () => const InstrumentRepositoryImpl(),
  );
  sl.registerLazySingleton<TonePlayerRepository>(
    () => TonePlayerRepositoryImpl(synthesizer: sl(), dataSource: sl()),
  );

  // Use cases
  sl.registerFactory(() => GetInstrumentsUseCase(sl()));
  sl.registerFactory(() => StartTuningUseCase(sl()));
  sl.registerFactory(() => StopTuningUseCase(sl()));
  sl.registerFactory(() => WatchPitchUseCase(sl()));
  sl.registerFactory(() => ResolveTuningTargetUseCase(sl()));
  sl.registerFactory(() => SetTuningRangeUseCase(sl()));
  sl.registerFactory(() => PlayInstrumentStringUseCase(sl()));

  // View models
  sl.registerFactory(
    () => TunerViewModel(
      getInstruments: sl(),
      startTuning: sl(),
      stopTuning: sl(),
      watchPitch: sl(),
      resolveTuningTarget: sl(),
      setTuningRange: sl(),
      playInstrumentString: sl(),
    ),
  );
}
