import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/entities/instrument.dart';

/// Row of "peg" cards, one per string of the selected [instrument]. Tapping
/// a card plays a reference tone for that string via [onPlay]; the string
/// currently matching [highlightedLabel] shows a direction arrow (or a
/// check once within [highlightedCents] of being in tune).
class StringRow extends StatelessWidget {
  const StringRow({
    super.key,
    required this.instrument,
    required this.highlightedLabel,
    required this.onPlay,
    this.highlightedCents,
  });

  final Instrument instrument;
  final String? highlightedLabel;
  final double? highlightedCents;
  final ValueChanged<InstrumentString> onPlay;

  static const _inTuneThresholdCents = 5.0;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: instrument.strings.map((s) {
        final isActive = s.label == highlightedLabel;
        final cents = isActive ? highlightedCents : null;
        final inTune = cents != null && cents.abs() <= _inTuneThresholdCents;
        final borderColor = inTune
            ? AppColors.inTune
            : (isActive ? AppColors.accentHover : AppColors.border);
        final bgColor = inTune
            ? AppColors.inTuneGlow
            : (isActive ? AppColors.accentGlow : AppColors.surface);

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => onPlay(s),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 56,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor, width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 16,
                    child: cents == null
                        ? null
                        : Icon(
                            inTune
                                ? Icons.check
                                : (cents < 0
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down),
                            size: 16,
                            color: inTune ? AppColors.inTune : AppColors.warning,
                          ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    s.label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isActive ? AppColors.accentHover : AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(
                    Icons.volume_up,
                    size: 14,
                    color: isActive ? AppColors.accentHover : AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
