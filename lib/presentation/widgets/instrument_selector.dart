import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/entities/instrument.dart';
import 'instrument_icon.dart';

/// Row of instrument buttons: compact icon-only circles, each wrapped in
/// a [Tooltip] carrying the full name. Replaces the previous icon+label
/// cards, which took up too much horizontal space for a row that can
/// grow with more presets.
class InstrumentSelector extends StatelessWidget {
  const InstrumentSelector({
    super.key,
    required this.instruments,
    required this.selected,
    required this.onChanged,
  });

  final List<Instrument> instruments;
  final Instrument selected;
  final ValueChanged<Instrument> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: instruments.map((instrument) {
        final isSelected = instrument.name == selected.name;
        final background = isSelected ? AppColors.accentGlow : AppColors.surface;
        final color = isSelected ? AppColors.accentHover : AppColors.textSecondary;

        return Tooltip(
          message: instrument.name,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => onChanged(instrument),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: background,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AppColors.accentHover : AppColors.border,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: InstrumentIcon(
                  instrument: instrument,
                  color: color,
                  background: background,
                  size: 22,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
