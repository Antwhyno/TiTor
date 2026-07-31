import 'package:flutter/material.dart';

import '../models/box_color_type.dart';

/// Sélecteur des trois couleurs disponibles pour une boîte, sous
/// forme de puces (chips) indiquant la durée du chronomètre associée.
class ColorPickerField extends StatelessWidget {
  final BoxColorType selected;
  final ValueChanged<BoxColorType> onChanged;

  const ColorPickerField({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: BoxColorType.values.map((BoxColorType type) {
        final bool isSelected = type == selected;
        return ChoiceChip(
          label: Text(type.label),
          selected: isSelected,
          avatar: CircleAvatar(backgroundColor: type.materialColor),
          onSelected: (bool value) {
            if (value) {
              onChanged(type);
            }
          },
        );
      }).toList(growable: false),
    );
  }
}
