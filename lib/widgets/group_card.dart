import 'package:flutter/material.dart';

import '../models/box_group_model.dart';

/// Carte représentant un groupe de boîtes.
class GroupCard extends StatelessWidget {
  final BoxGroupModel group;
  final int boxCount;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const GroupCard({
    super.key,
    required this.group,
    required this.boxCount,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.folder_copy_outlined)),
        title: Text(group.name),
        subtitle: Text('$boxCount boîte(s)'),
        onTap: onTap,
        trailing: PopupMenuButton<String>(
          onSelected: (String value) {
            if (value == 'edit') {
              onEdit();
            } else if (value == 'delete') {
              onDelete();
            }
          },
          itemBuilder: (BuildContext context) => const <PopupMenuEntry<String>>[
            PopupMenuItem<String>(value: 'edit', child: Text('Renommer')),
            PopupMenuItem<String>(value: 'delete', child: Text('Supprimer')),
          ],
        ),
      ),
    );
  }
}
