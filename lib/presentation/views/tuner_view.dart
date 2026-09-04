import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/entities/pitch_reading.dart';
import '../viewmodels/tuner_view_model.dart';
import '../widgets/cents_meter.dart';
import '../widgets/instrument_selector.dart';
import '../widgets/mic_button.dart';
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
    final inTune = reading != null && (target?.isInTune ?? false);
    final (noteName, octave) = _splitLabel(noteLabel);

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
                                highlightedCents: target?.cents,
                                onPlay: viewModel.playString,
                              ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.symmetric(
                            vertical: 20,
                            horizontal: 24,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: inTune ? AppColors.inTune : AppColors.border,
                              width: inTune ? 2 : 1,
                            ),
                            boxShadow: inTune
                                ? [
                                    BoxShadow(
                                      color: AppColors.inTuneGlow,
                                      blurRadius: 24,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : const [],
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    noteName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .displayLarge
                                        ?.copyWith(
                                          color: inTune ? AppColors.inTune : null,
                                        ),
                                  ),
                                  if (octave != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 10),
                                      child: Text(
                                        octave,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontSize: 22,
                                              color: inTune
                                                  ? AppColors.inTune
                                                  : AppColors.textSecondary,
                                            ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                reading == null
                                    ? 'TOQUE UMA NOTA'
                                    : '${reading.frequency.toStringAsFixed(1)} HZ',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(letterSpacing: 0.05),
                              ),
                              const SizedBox(height: 12),
                              TunerGauge(
                                cents: cents,
                                active: reading != null,
                                noteName: reading == null ? null : noteName,
                              ),
                              const SizedBox(height: 8),
                              CentsMeter(cents: cents, active: reading != null),
                              const SizedBox(height: 16),
                              _StatusBadge(
                                text: _statusText(reading, cents),
                                color: reading == null
                                    ? AppColors.textMuted
                                    : (inTune
                                          ? AppColors.inTune
                                          : AppColors.warning),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            const SizedBox(height: 24),
                            if (viewModel.errorMessage != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Text(
                                  viewModel.errorMessage!,
                                  style: const TextStyle(
                                    color: AppColors.danger,
                                  ),
                                ),
                              ),
                            MicButton(
                              listening: viewModel.isListening,
                              onPressed: viewModel.toggleListening,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              viewModel.isListening ? 'Ouvindo…' : 'Toque para iniciar',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
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

  /// Splits a note label like "F#4" into its note name ("F#") and octave
  /// ("4") for a note-plus-superscript-octave display; "--" (no reading
  /// yet) has no trailing digits and is returned as-is with no octave.
  (String, String?) _splitLabel(String label) {
    final match = RegExp(r'^(.*?)(-?\d+)$').firstMatch(label);
    if (match == null) return (label, null);
    return (match.group(1)!, match.group(2));
  }

  String _statusText(PitchReading? reading, double cents) {
    if (reading == null) return 'Aguardando sinal';
    if (cents.abs() <= 5) return 'Afinado!';
    final direction = cents < 0 ? 'grave' : 'agudo';
    return 'Muito $direction (${cents > 0 ? '+' : ''}${cents.toStringAsFixed(0)}¢)';
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
