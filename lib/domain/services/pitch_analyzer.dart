/// Outcome of a single pitch-detection pass over an audio window.
class PitchAnalysisResult {
  const PitchAnalysisResult({
    required this.frequency,
    required this.confidence,
    required this.amplitude,
  });

  final double frequency;
  final double confidence;
  final double amplitude;
}

/// Estimates the fundamental frequency of a windowed audio signal.
///
/// Kept as an interface (Open/Closed + Dependency Inversion) so the
/// estimation algorithm — YIN, autocorrelation, FFT-based, ... — can be
/// swapped or extended without touching the repository or use cases that
/// depend on it.
abstract class PitchAnalyzer {
  PitchAnalysisResult? analyze(
    List<double> samples, {
    required int sampleRate,
    required double minFrequency,
    required double maxFrequency,
  });
}
