import 'package:flutter/material.dart';

import '../utils/icon_catalog.dart';

/// Grille de sélection d'icône pour représenter une boîte.
class IconPickerField extends StatelessWidget {
  final IconData selected;
  final ValueChanged<IconData> onChanged;

  const IconPickerField({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemCount: IconCatalog.options.length,
        itemBuilder: (BuildContext context, int index) {
          final IconData icon = IconCatalog.options[index];
          final bool isSelected = icon == selected;
          return InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => onChanged(icon),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: isSelected
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                border: isSelected
                    ? Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      )
                    : null,
              ),
              child: Icon(icon),
            ),
          );
        },
      ),
    );
  }
}
