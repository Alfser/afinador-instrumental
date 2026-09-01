import 'package:flutter/material.dart';

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
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: instruments.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final instrument = instruments[index];
          final isSelected = instrument.name == selected.name;
          return ChoiceChip(
            label: Text(instrument.name),
            selected: isSelected,
            onSelected: (_) => onChanged(instrument),
          );
        },
      ),
    );
  }
}
