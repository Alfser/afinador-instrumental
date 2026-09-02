import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import '../../domain/entities/note.dart';
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
    this.stabilizationWindow = 3,
    this.noteLockStreak = 3,
    this.silenceGrace = const Duration(milliseconds: 400),
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

  /// Number of recent valid analyses whose frequency is median-filtered
  /// into each emitted reading. A single stray frame — e.g. YIN briefly
  /// locking onto a harmonic instead of the fundamental — lands as the
  /// min or max of the window and is outvoted, instead of flashing as a
  /// different note before the real pitch reappears.
  final int stabilizationWindow;

  /// Consecutive analyses that must agree on a *different* note before the
  /// displayed note switches. A harmonic that briefly outvotes the
  /// fundamental in the median window (see [stabilizationWindow]) still
  /// only produces one bad sample at a time, so requiring it to repeat
  /// filters it out; a real note change keeps agreeing and switches after
  /// this many ticks.
  final int noteLockStreak;

  /// How long a dip in amplitude (below the analyzer's silence floor, e.g.
  /// between pick attacks or during a breath) is tolerated before the
  /// reading is cleared, instead of the display blanking on the very first
  /// missed frame.
  final Duration silenceGrace;

  final List<double> _buffer = [];
  final List<double> _recentFrequencies = [];
  final StreamController<PitchReading?> _readingController =
      StreamController<PitchReading?>.broadcast();

  StreamSubscription<Uint8List>? _subscription;
  Timer? _analysisTimer;
  bool _isAnalyzing = false;

  Note? _lockedNote;
  String? _candidateNoteLabel;
  int _candidateStreak = 0;
  int _silenceStreak = 0;

  int get _silenceHoldTicks =>
      (silenceGrace.inMilliseconds / analysisInterval.inMilliseconds)
          .ceil()
          .clamp(1, 1000);

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
    _recentFrequencies.clear();
    _lockedNote = null;
    _candidateNoteLabel = null;
    _candidateStreak = 0;
    _silenceStreak = 0;
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
    )
        // An unexpected error inside the isolate (a malformed buffer, a
        // future edge case in the analyzer) must not crash the app — it's
        // treated the same as "no pitch this tick" and folded into the
        // existing silence handling below, instead of propagating as an
        // unhandled exception in the zone.
        .then(_onAnalysisResult, onError: (_) => _onAnalysisResult(null))
        .whenComplete(() => _isAnalyzing = false);
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
      _silenceStreak++;
      // A single missed frame (pick attack decay, brief breath) is held
      // rather than blanking the display; only a real gap clears it.
      if (_silenceStreak < _silenceHoldTicks) return;
      _recentFrequencies.clear();
      _lockedNote = null;
      _candidateNoteLabel = null;
      _candidateStreak = 0;
      _readingController.add(null);
      return;
    }
    _silenceStreak = 0;

    _recentFrequencies.add(result.frequency);
    if (_recentFrequencies.length > stabilizationWindow) {
      _recentFrequencies.removeAt(0);
    }
    final frequency = _median(_recentFrequencies);
    final detected = _noteMapper.map(frequency);

    final locked = _lockedNote;
    if (locked == null || detected.label == locked.label) {
      // Agrees with (or establishes) the locked note: track pitch in
      // real time so cents feedback stays responsive.
      _lockedNote = detected;
      _candidateNoteLabel = null;
      _candidateStreak = 0;
    } else if (detected.label == _candidateNoteLabel) {
      _candidateStreak++;
      if (_candidateStreak >= noteLockStreak) {
        // A different note agreed with itself enough times in a row to
        // be a real change, not a harmonic blip — switch to it.
        _lockedNote = detected;
        _candidateNoteLabel = null;
        _candidateStreak = 0;
      }
    } else {
      // First sign of a different note: start counting, but keep
      // displaying the locked one until it's confirmed.
      _candidateNoteLabel = detected.label;
      _candidateStreak = 1;
    }

    final displayed = _lockedNote ?? detected;
    _readingController.add(
      PitchReading(
        frequency: displayed.frequency,
        note: displayed,
        amplitude: result.amplitude,
        confidence: result.confidence,
      ),
    );
  }

  double _median(List<double> values) {
    final sorted = [...values]..sort();
    return sorted[sorted.length ~/ 2];
  }

  @override
  Future<void> stop() async {
    _analysisTimer?.cancel();
    _analysisTimer = null;
    await _subscription?.cancel();
    _subscription = null;
    await _audioDataSource.stop();
    _buffer.clear();
    _recentFrequencies.clear();
    _lockedNote = null;
    _candidateNoteLabel = null;
    _candidateStreak = 0;
    _silenceStreak = 0;
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _audioDataSource.dispose();
    await _readingController.close();
  }
}
