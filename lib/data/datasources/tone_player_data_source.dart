/// Abstraction over playing raw PCM audio samples through the device's
/// audio output, isolating the concrete playback plugin from the rest
/// of the app.
abstract class TonePlayerDataSource {
  Future<void> play(List<double> samples, {required int sampleRate});

  Future<void> stop();
}
