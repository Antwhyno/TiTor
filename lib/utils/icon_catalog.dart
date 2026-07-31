import 'package:flutter/material.dart';

/// Catalogue fermé d'icônes proposées à l'utilisateur pour représenter
/// une boîte.
///
/// Utiliser un ensemble fermé d'[IconData] `const` permet de conserver
/// le "tree-shaking" des polices d'icônes activé lors de la
/// compilation en mode release. Comme les boîtes stockent le
/// `codePoint` de l'icône choisie et la reconstruisent dynamiquement
/// (voir `BoxModel.icon`), il est nécessaire de compiler avec le
/// drapeau `--no-tree-shake-icons` (voir README.md) pour garantir que
/// toutes les icônes du catalogue restent disponibles au runtime.
class IconCatalog {
  const IconCatalog._();

  static const List<IconData> options = <IconData>[
    Icons.inbox,
    Icons.archive,
    Icons.folder,
    Icons.work,
    Icons.school,
    Icons.home,
    Icons.shopping_cart,
    Icons.favorite,
    Icons.star,
    Icons.build,
    Icons.local_grocery_store,
    Icons.medical_services,
    Icons.pets,
    Icons.flight,
    Icons.book,
    Icons.music_note,
    Icons.sports_soccer,
    Icons.restaurant,
    Icons.directions_car,
    Icons.attach_money,
  ];

  /// Icône utilisée par défaut lorsque l'utilisateur n'en choisit pas.
  static const IconData fallback = Icons.inbox;
}
