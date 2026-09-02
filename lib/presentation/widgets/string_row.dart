import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/entities/instrument.dart';

/// Row of buttons, one per string of the selected [instrument]. Tapping
/// a button plays a reference tone for that string via [onPlay].
class StringRow extends StatelessWidget {
  const StringRow({
    super.key,
    required this.instrument,
    required this.highlightedLabel,
    required this.onPlay,
  });

  final Instrument instrument;
  final String? highlightedLabel;
  final ValueChanged<InstrumentString> onPlay;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: instrument.strings.map((s) {
        final isActive = s.label == highlightedLabel;
        return ActionChip(
          avatar: Icon(
            Icons.volume_up,
            size: 18,
            color: isActive ? AppColors.accentHover : AppColors.textSecondary,
          ),
          label: Text(s.label),
          onPressed: () => onPlay(s),
          backgroundColor: isActive ? AppColors.accentGlow : AppColors.surface,
          // Always reserve the same border width so only the color changes
          // when a string becomes active — an invisible (width-2) border
          // when inactive keeps every chip's size identical, avoiding a
          // layout shift/reflow as the highlighted string changes.
          side: BorderSide(
            color: isActive ? AppColors.accentHover : AppColors.border,
            width: 2,
          ),
        );
      }).toList(),
    );
  }
}
