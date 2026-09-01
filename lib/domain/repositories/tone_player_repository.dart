/// Abstraction over playing a short reference tone for a given frequency
/// (used when the user taps an instrument string button).
abstract class TonePlayerRepository {
  Future<void> playTone(double frequencyHz);

  Future<void> stop();
}
