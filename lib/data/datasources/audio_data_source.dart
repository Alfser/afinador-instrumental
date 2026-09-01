import 'dart:typed_data';

/// Abstraction over a raw PCM audio input device (e.g. the microphone),
/// isolating the concrete recording plugin from the rest of the app.
abstract class AudioDataSource {
  /// Checks (and, if needed, requests) permission to record audio.
  Future<bool> hasPermission();

  /// Starts streaming mono 16-bit little-endian PCM samples at [sampleRate] Hz.
  Future<Stream<Uint8List>> startStream({required int sampleRate});

  Future<void> stop();

  Future<void> dispose();
}
