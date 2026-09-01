import '../entities/instrument.dart';

/// Abstraction over where instrument tuning presets come from (local
/// constants today; could become a remote or user-editable source later
/// without changing any use case or view model).
abstract class InstrumentRepository {
  List<Instrument> getAll();
}
