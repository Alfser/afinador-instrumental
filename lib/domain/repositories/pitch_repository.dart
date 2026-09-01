import '../entities/pitch_reading.dart';

/// Abstraction over the live pitch-detection source (e.g. the microphone).
///
/// The domain and presentation layers depend only on this contract, never
/// on the concrete audio plugin used to implement it (Dependency
/// Inversion Principle).
abstract class PitchRepository {
  Stream<PitchReading?> get readings;

  bool get isListening;

  /// Starts listening. Returns false if permission was denied.
  Future<bool> start();

  Future<void> stop();

  Future<void> dispose();
}
