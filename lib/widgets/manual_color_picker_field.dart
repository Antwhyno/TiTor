import 'package:flutter/material.dart';

/// Sélecteur de couleur manuelle pour l'indicateur d'une lipo.
///
/// Propose une puce "Automatique" (qui réactive le calcul de couleur
/// par proximité de l'expiration) ainsi qu'une palette de couleurs
/// prédéfinies pouvant être forcées manuellement par l'utilisateur.
class ManualColorPickerField extends StatelessWidget {
  /// Couleur manuelle actuellement sélectionnée, ou `null` si le mode
  /// automatique est actif.
  final Color? selected;

  /// Appelé avec la couleur choisie, ou `null` pour repasser en mode
  /// automatique.
  final ValueChanged<Color?> onChanged;

  const ManualColorPickerField({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  static const List<(Color, String)> _presetColors = <(Color, String)>[
    (Color(0xFFE53935), 'Rouge'),
    (Color(0xFFFB8C00), 'Orange'),
    (Color(0xFFF9A825), 'Jaune'),
    (Color(0xFF43A047), 'Vert'),
    (Color(0xFF00897B), 'Sarcelle'),
    (Color(0xFF1E88E5), 'Bleu'),
    (Color(0xFF5E35B1), 'Violet'),
    (Color(0xFFD81B60), 'Rose'),
    (Color(0xFF6D4C41), 'Marron'),
    (Color(0xFF546E7A), 'Ardoise'),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        ChoiceChip(
          label: const Text('Automatique'),
          avatar: const Icon(Icons.auto_awesome, size: 18),
          selected: selected == null,
          onSelected: (bool value) {
            if (value) {
              onChanged(null);
            }
          },
        ),
        for (final (Color color, String name) in _presetColors)
          ChoiceChip(
            label: Text(name),
            avatar: CircleAvatar(backgroundColor: color, radius: 10),
            selected: selected != null && selected!.toARGB32() == color.toARGB32(),
            onSelected: (bool value) {
              if (value) {
                onChanged(color);
              }
            },
          ),
      ],
    );
  }
}
