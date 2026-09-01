import '../../domain/entities/instrument.dart';
import '../../domain/repositories/instrument_repository.dart';

/// [InstrumentRepository] backed by a static list of built-in tuning
/// presets. Swappable later for a remote or user-editable source without
/// touching any use case or view model.
class InstrumentRepositoryImpl implements InstrumentRepository {
  const InstrumentRepositoryImpl();

  static const _presets = [
    Instrument('Violão / Guitarra', [
      InstrumentString('E2', 82.41),
      InstrumentString('A2', 110.00),
      InstrumentString('D3', 146.83),
      InstrumentString('G3', 196.00),
      InstrumentString('B3', 246.94),
      InstrumentString('E4', 329.63),
    ]),
    Instrument('Baixo', [
      InstrumentString('E1', 41.20),
      InstrumentString('A1', 55.00),
      InstrumentString('D2', 73.42),
      InstrumentString('G2', 98.00),
    ]),
    Instrument('Ukulele', [
      InstrumentString('G4', 392.00),
      InstrumentString('C4', 261.63),
      InstrumentString('E4', 329.63),
      InstrumentString('A4', 440.00),
    ]),
    Instrument('Violino', [
      InstrumentString('G3', 196.00),
      InstrumentString('D4', 293.66),
      InstrumentString('A4', 440.00),
      InstrumentString('E5', 659.25),
    ]),
    Instrument('Cavaquinho', [
      InstrumentString('D4', 293.66),
      InstrumentString('G4', 392.00),
      InstrumentString('B4', 493.88),
      InstrumentString('D5', 587.33),
    ]),
    Instrument('Cromático', []),
  ];

  @override
  List<Instrument> getAll() => _presets;
}
