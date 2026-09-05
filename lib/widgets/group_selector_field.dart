import 'package:flutter/material.dart';

import '../models/box_group_model.dart';

/// Sélecteur optionnel de groupe, utilisé lors de la création ou de
/// la modification d'une lipo.
class GroupSelectorField extends StatelessWidget {
  final List<BoxGroupModel> groups;
  final String? selectedGroupId;
  final ValueChanged<String?> onChanged;

  const GroupSelectorField({
    super.key,
    required this.groups,
    required this.selectedGroupId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Cas limite : si le groupe précédemment sélectionné a été
    // supprimé entre-temps (par exemple depuis un autre écran), on
    // évite de fournir à la liste déroulante une valeur qui n'existe
    // plus dans les options, ce qui provoquerait une erreur.
    final bool selectedExists =
        groups.any((BoxGroupModel group) => group.id == selectedGroupId);
    final String? safeValue = selectedExists ? selectedGroupId : null;

    return DropdownButtonFormField<String?>(
      initialValue: safeValue,
      decoration: const InputDecoration(
        labelText: 'Groupe (optionnel)',
        border: OutlineInputBorder(),
      ),
      items: <DropdownMenuItem<String?>>[
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('Aucun groupe'),
        ),
        ...groups.map(
          (BoxGroupModel group) => DropdownMenuItem<String?>(
            value: group.id,
            child: Text(group.name),
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }
}
