import '../entities/instrument.dart';
import '../repositories/instrument_repository.dart';

/// Lists the available instrument tuning presets.
class GetInstrumentsUseCase {
  const GetInstrumentsUseCase(this._repository);

  final InstrumentRepository _repository;

  List<Instrument> call() => _repository.getAll();
}
