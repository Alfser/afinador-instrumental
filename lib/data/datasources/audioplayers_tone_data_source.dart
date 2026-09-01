import 'dart:io';

import 'package:audioplayers/audioplayers.dart';

import 'tone_player_data_source.dart';
import 'wav_encoder.dart';

/// [TonePlayerDataSource] backed by the `audioplayers` plugin. This is
/// the only place in the app that imports `package:audioplayers`.
///
/// Samples are encoded to a temporary WAV file because desktop backends
/// need a real file path rather than an in-memory buffer.
class AudioplayersToneDataSource implements TonePlayerDataSource {
  AudioplayersToneDataSource({WavEncoder encoder = const WavEncoder()})
      : _encoder = encoder;

  final WavEncoder _encoder;
  final AudioPlayer _player = AudioPlayer();
  File? _tempFile;

  @override
  Future<void> play(List<double> samples, {required int sampleRate}) async {
    await _player.stop();
    _deleteTempFile();

    final bytes = _encoder.encode(samples, sampleRate: sampleRate);
    final file = File(
      '${Directory.systemTemp.path}/afinador_tone_'
      '${DateTime.now().microsecondsSinceEpoch}.wav',
    );
    await file.writeAsBytes(bytes, flush: true);
    _tempFile = file;

    await _player.play(DeviceFileSource(file.path));
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    _deleteTempFile();
  }

  void _deleteTempFile() {
    final file = _tempFile;
    _tempFile = null;
    if (file != null && file.existsSync()) {
      file.deleteSync();
    }
  }
}
