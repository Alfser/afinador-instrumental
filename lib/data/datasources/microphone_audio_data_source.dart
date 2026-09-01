import 'dart:typed_data';

import 'package:record/record.dart';

import 'audio_data_source.dart';

/// [AudioDataSource] backed by the `record` plugin. This is the only
/// place in the app that imports `package:record`.
class MicrophoneAudioDataSource implements AudioDataSource {
  final AudioRecorder _recorder = AudioRecorder();

  @override
  Future<bool> hasPermission() => _recorder.hasPermission();

  @override
  Future<Stream<Uint8List>> startStream({required int sampleRate}) {
    return _recorder.startStream(
      RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: sampleRate,
        numChannels: 1,
      ),
    );
  }

  @override
  Future<void> stop() async {
    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }
  }

  @override
  Future<void> dispose() => _recorder.dispose();
}
