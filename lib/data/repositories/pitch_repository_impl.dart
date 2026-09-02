import 'dart:async';
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

  void _analyze() {
    if (_buffer.length < bufferSize) return;
    final window = _buffer.sublist(_buffer.length - bufferSize);
    final result = _pitchAnalyzer.analyze(
      window,
      sampleRate: sampleRate,
      minFrequency: _minFrequency,
      maxFrequency: _maxFrequency,
    );
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
