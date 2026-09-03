import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/entities/instrument.dart';

/// Row of instrument tabs, each a small card (icon + label + a bottom
/// indicator bar for the selected one) rather than a bare Material chip —
/// matching the "peg card" language used by [StringRow].
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
        final color = isSelected ? AppColors.accentHover : AppColors.textSecondary;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => onChanged(instrument),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accentGlow : AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? AppColors.accentHover : AppColors.border,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        instrument.isChromatic ? Icons.graphic_eq : Icons.music_note,
                        size: 15,
                        color: color,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        instrument.name,
                        style: TextStyle(
                          color: isSelected ? AppColors.accentHover : AppColors.text,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 3,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.accentHover : Colors.transparent,
                      borderRadius: BorderRadius.circular(2),
                    ),
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
