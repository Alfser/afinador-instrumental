import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/entities/instrument.dart';
import '../../domain/entities/pitch_reading.dart';
import '../../domain/entities/tuning_target.dart';
import '../../domain/usecases/get_instruments_usecase.dart';
import '../../domain/usecases/play_instrument_string_usecase.dart';
import '../../domain/usecases/resolve_tuning_target_usecase.dart';
import '../../domain/usecases/set_tuning_range_usecase.dart';
import '../../domain/usecases/start_tuning_usecase.dart';
import '../../domain/usecases/stop_tuning_usecase.dart';
import '../../domain/usecases/watch_pitch_usecase.dart';

/// Presentation state and behaviour for the tuner screen (the "VM" in
/// MVVM). Depends only on domain use cases — never on Flutter audio
/// plugins, `record`, or any widget.
class TunerViewModel extends ChangeNotifier {
  TunerViewModel({
    required GetInstrumentsUseCase getInstruments,
    required StartTuningUseCase startTuning,
    required StopTuningUseCase stopTuning,
    required WatchPitchUseCase watchPitch,
    required ResolveTuningTargetUseCase resolveTuningTarget,
    required SetTuningRangeUseCase setTuningRange,
    required PlayInstrumentStringUseCase playInstrumentString,
  })  : _startTuning = startTuning,
        _stopTuning = stopTuning,
        _watchPitch = watchPitch,
        _resolveTuningTarget = resolveTuningTarget,
        _setTuningRange = setTuningRange,
        _playInstrumentString = playInstrumentString,
        instruments = getInstruments(),
        selectedInstrument = getInstruments().first;

  final StartTuningUseCase _startTuning;
  final StopTuningUseCase _stopTuning;
  final WatchPitchUseCase _watchPitch;
  final ResolveTuningTargetUseCase _resolveTuningTarget;
  final SetTuningRangeUseCase _setTuningRange;
  final PlayInstrumentStringUseCase _playInstrumentString;

  StreamSubscription<PitchReading?>? _subscription;

  final List<Instrument> instruments;
  Instrument selectedInstrument;
  PitchReading? reading;
  TuningTarget? target;
  bool isListening = false;
  String? errorMessage;

  Future<void> toggleListening() => isListening ? _stop() : _start();

  Future<void> _start() async {
    errorMessage = null;
    _applyTuningRange();
    final started = await _startTuning();
    if (!started) {
      errorMessage = 'Permissão de microfone negada.';
      notifyListeners();
      return;
    }
    _subscription = _watchPitch().listen(_onReading);
    isListening = true;
    notifyListeners();
  }

  void _applyTuningRange() {
    _setTuningRange(
      minFrequency: selectedInstrument.minDetectableFrequency,
      maxFrequency: selectedInstrument.maxDetectableFrequency,
    );
  }

  Future<void> _stop() async {
    await _subscription?.cancel();
    _subscription = null;
    await _stopTuning();
    isListening = false;
    reading = null;
    target = null;
    notifyListeners();
  }

  void _onReading(PitchReading? reading) {
    this.reading = reading;
    target =
        reading == null ? null : _resolveTuningTarget(selectedInstrument, reading);
    notifyListeners();
  }

  Future<void> playString(InstrumentString string) async {
    try {
      await _playInstrumentString(string);
    } catch (_) {
      errorMessage = 'Não foi possível reproduzir o som da corda.';
      notifyListeners();
    }
  }

  void selectInstrument(Instrument instrument) {
    selectedInstrument = instrument;
    if (isListening) _applyTuningRange();
    final currentReading = reading;
    target = currentReading == null
        ? null
        : _resolveTuningTarget(selectedInstrument, currentReading);
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _stopTuning();
    super.dispose();
  }
}
