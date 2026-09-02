import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import '../../domain/entities/pitch_reading.dart';
import '../../domain/repositories/pitch_repository.dart';
import '../../domain/services/note_mapper.dart';
import '../../domain/services/pitch_analyzer.dart';
import '../datasources/audio_data_source.dart';

/// [PitchRepository] implementation that turns a raw [AudioDataSource]
/// stream into [PitchReading]s using a [PitchAnalyzer] and [NoteMapper].
///
/// All three collaborators are injected as abstractions, so this class
/// never depends on a concrete audio plugin or detection algorithm.
class PitchRepositoryImpl implements PitchRepository {
  PitchRepositoryImpl({
    required AudioDataSource audioDataSource,
    required PitchAnalyzer pitchAnalyzer,
    required NoteMapper noteMapper,
    this.sampleRate = 44100,
    this.bufferSize = 4096,
    double minFrequency = 30.0,
    double maxFrequency = 1500.0,
    this.analysisInterval = const Duration(milliseconds: 80),
  })  : _audioDataSource = audioDataSource,
        _pitchAnalyzer = pitchAnalyzer,
        _noteMapper = noteMapper,
        _minFrequency = minFrequency,
        _maxFrequency = maxFrequency;

  final AudioDataSource _audioDataSource;
  final PitchAnalyzer _pitchAnalyzer;
  final NoteMapper _noteMapper;

  final int sampleRate;
  final int bufferSize;
  double _minFrequency;
  double _maxFrequency;
  final Duration analysisInterval;

  final List<double> _buffer = [];
  final StreamController<PitchReading?> _readingController =
      StreamController<PitchReading?>.broadcast();

  StreamSubscription<Uint8List>? _subscription;
  Timer? _analysisTimer;
  bool _isAnalyzing = false;

  @override
  Stream<PitchReading?> get readings => _readingController.stream;

  @override
  bool get isListening => _subscription != null;

  @override
  void setFrequencyRange({
    required double minFrequency,
    required double maxFrequency,
  }) {
    _minFrequency = minFrequency;
    _maxFrequency = maxFrequency;
  }

  @override
  Future<bool> start() async {
    final hasPermission = await _audioDataSource.hasPermission();
    if (!hasPermission) return false;

    final stream = await _audioDataSource.startStream(sampleRate: sampleRate);

    _buffer.clear();
    _subscription = stream.listen(_onAudioChunk);
    _analysisTimer = Timer.periodic(analysisInterval, (_) => _analyze());
    return true;
  }

  void _onAudioChunk(Uint8List chunk) {
    final byteData = ByteData.sublistView(chunk);
    final sampleCount = chunk.lengthInBytes ~/ 2;
    for (var i = 0; i < sampleCount; i++) {
      final s = byteData.getInt16(i * 2, Endian.little);
      _buffer.add(s / 32768.0);
    }
    final maxLength = bufferSize * 2;
    if (_buffer.length > maxLength) {
      _buffer.removeRange(0, _buffer.length - maxLength);
    }
  }

  // YIN over a few thousand samples is heavy enough (millions of
  // multiply-adds per pass) to jank the UI if run inline on every timer
  // tick, so each pass is offloaded to a worker isolate. `_isAnalyzing`
  // skips a tick rather than queuing it if the previous pass is still
  // running, so passes never pile up behind a slow one.
  void _analyze() {
    if (_isAnalyzing) return;
    if (_buffer.length < bufferSize) return;
    final window = _buffer.sublist(_buffer.length - bufferSize);

    _isAnalyzing = true;
    _runInIsolate(
      analyzer: _pitchAnalyzer,
      window: window,
      sampleRate: sampleRate,
      minFrequency: _minFrequency,
      maxFrequency: _maxFrequency,
    ).then(_onAnalysisResult).whenComplete(() => _isAnalyzing = false);
  }

  // Must be `static`: the closure passed to `Isolate.run` may only close
  // over its own parameters. Building it inline in `_analyze()` put it in
  // the same lexical scope as `.whenComplete(() => _isAnalyzing = false)`,
  // and Dart shares one capture context between sibling closures in a
  // scope — since that second closure needs `this` (to write the instance
  // field), `this` rode along into the isolate closure too, and with it
  // `_analysisTimer`, which `SendPort.send` rejects as unsendable. A
  // `static` method has no `this` to leak in the first place.
  static Future<PitchAnalysisResult?> _runInIsolate({
    required PitchAnalyzer analyzer,
    required List<double> window,
    required int sampleRate,
    required double minFrequency,
    required double maxFrequency,
  }) {
    return Isolate.run(
      () => analyzer.analyze(
        window,
        sampleRate: sampleRate,
        minFrequency: minFrequency,
        maxFrequency: maxFrequency,
      ),
    );
  }

  void _onAnalysisResult(PitchAnalysisResult? result) {
    // Stopped or disposed while this pass was running in its isolate.
    if (_subscription == null) return;

    if (result == null) {
      _readingController.add(null);
      return;
    }
    _readingController.add(
      PitchReading(
        frequency: result.frequency,
        note: _noteMapper.map(result.frequency),
        amplitude: result.amplitude,
        confidence: result.confidence,
      ),
    );
  }

  @override
  Future<void> stop() async {
    _analysisTimer?.cancel();
    _analysisTimer = null;
    await _subscription?.cancel();
    _subscription = null;
    await _audioDataSource.stop();
    _buffer.clear();
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _audioDataSource.dispose();
    await _readingController.close();
  }
}
