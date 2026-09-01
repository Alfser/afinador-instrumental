import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/pitch_reading.dart';
import '../viewmodels/tuner_view_model.dart';
import '../widgets/instrument_selector.dart';
import '../widgets/string_row.dart';
import '../widgets/tuner_gauge.dart';

/// The tuner screen (the "V" in MVVM). Purely declarative: it reads state
/// from [TunerViewModel] and forwards user actions to it, with no business
/// logic or audio/plugin access of its own.
class TunerView extends StatelessWidget {
  const TunerView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TunerViewModel>();
    final reading = viewModel.reading;
    final target = viewModel.target;
    final cents = target?.cents ?? 0.0;
    final noteLabel = reading == null
        ? '--'
        : (target?.label ?? reading.note.label);

    return Scaffold(
      appBar: AppBar(title: const Text('Afinador')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          children: [
                            InstrumentSelector(
                              instruments: viewModel.instruments,
                              selected: viewModel.selectedInstrument,
                              onChanged: viewModel.selectInstrument,
                            ),
                            const SizedBox(height: 12),
                            if (!viewModel.selectedInstrument.isChromatic)
                              StringRow(
                                instrument: viewModel.selectedInstrument,
                                highlightedLabel: target?.label,
                                onPlay: viewModel.playString,
                              ),
                          ],
                        ),
                        Column(
                          children: [
                            const SizedBox(height: 24),
                            Text(
                              noteLabel,
                              style: Theme.of(context).textTheme.displayLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              reading == null
                                  ? 'Toque uma nota'
                                  : '${reading.frequency.toStringAsFixed(1)} Hz',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 24),
                            TunerGauge(cents: cents, active: reading != null),
                            const SizedBox(height: 8),
                            Text(
                              _statusText(reading, cents),
                              style: TextStyle(
                                fontSize: 18,
                                color: reading == null
                                    ? Colors.grey
                                    : (cents.abs() <= 5
                                          ? Colors.green
                                          : Colors.orange),
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            const SizedBox(height: 24),
                            if (viewModel.errorMessage != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Text(
                                  viewModel.errorMessage!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            FloatingActionButton.extended(
                              onPressed: viewModel.toggleListening,
                              icon: Icon(
                                viewModel.isListening
                                    ? Icons.mic
                                    : Icons.mic_none,
                              ),
                              label: Text(
                                viewModel.isListening ? 'Parar' : 'Iniciar',
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _statusText(PitchReading? reading, double cents) {
    if (reading == null) return '';
    if (cents.abs() <= 5) return 'Afinado!';
    final direction = cents < 0 ? 'grave' : 'agudo';
    return 'Muito $direction (${cents > 0 ? '+' : ''}${cents.toStringAsFixed(0)}¢)';
  }
}
