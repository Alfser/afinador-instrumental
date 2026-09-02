import '../entities/pitch_reading.dart';

/// Abstraction over the live pitch-detection source (e.g. the microphone).
///
/// The domain and presentation layers depend only on this contract, never
/// on the concrete audio plugin used to implement it (Dependency
/// Inversion Principle).
abstract class PitchRepository {
  Stream<PitchReading?> get readings;

  bool get isListening;

  /// Narrows detection to `[minFrequency, maxFrequency]`, so audio outside
  /// the current instrument's range can't be mistaken for one of its
  /// notes. Takes effect from the next analysis, whether or not currently
  /// listening.
  void setFrequencyRange({required double minFrequency, required double maxFrequency});

  /// Starts listening. Returns false if permission was denied.
  Future<bool> start();

  Future<void> stop();

  Future<void> dispose();
}
