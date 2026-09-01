import 'package:flutter/material.dart';

import '../../domain/entities/instrument.dart';

class StringRow extends StatelessWidget {
  const StringRow({
    super.key,
    required this.instrument,
    required this.highlightedLabel,
  });

  final Instrument instrument;
  final String? highlightedLabel;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: instrument.strings.map((s) {
        final isActive = s.label == highlightedLabel;
        return Chip(
          label: Text(s.label),
          backgroundColor: isActive ? Colors.green.shade100 : null,
          side: isActive
              ? const BorderSide(color: Colors.green, width: 2)
              : null,
        );
      }).toList(),
    );
  }
}
