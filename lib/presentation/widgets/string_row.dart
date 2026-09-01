import 'package:flutter/material.dart';

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
          avatar: const Icon(Icons.volume_up, size: 18),
          label: Text(s.label),
          onPressed: () => onPlay(s),
          backgroundColor: isActive ? Colors.green.shade100 : null,
          side: isActive
              ? const BorderSide(color: Colors.green, width: 2)
              : null,
        );
      }).toList(),
    );
  }
}
