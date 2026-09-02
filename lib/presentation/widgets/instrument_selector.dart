import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/entities/instrument.dart';

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
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: instruments.map((instrument) {
        final isSelected = instrument.name == selected.name;
        return ChoiceChip(
          label: Text(instrument.name),
          selected: isSelected,
          onSelected: (_) => onChanged(instrument),
          backgroundColor: AppColors.surface,
          selectedColor: AppColors.accentGlow,
          labelStyle: TextStyle(
            color: isSelected ? AppColors.accentHover : AppColors.text,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
          side: BorderSide(
            color: isSelected ? AppColors.accentHover : AppColors.border,
          ),
        );
      }).toList(),
    );
  }
}
