import 'package:flutter/material.dart';

/// Catalogue fermé d'icônes proposées à l'utilisateur pour représenter
/// une lipo.
///
/// On utilise un ensemble fermé d'[IconData] `const` : cela permet à
/// Flutter de continuer à "tree-shaker" les polices d'icônes en mode
/// release. Une lipo ne stocke que le `codePoint` de l'icône choisie ;
/// `BoxModel.icon` retrouve l'[IconData] correspondante via
/// [findByCodePoint] au lieu de la reconstruire dynamiquement.
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

  /// Icône utilisée par défaut lorsque l'utilisateur n'en choisit pas,
  /// ou lorsque le codePoint stocké ne correspond à aucune icône du
  /// catalogue (donnée corrompue, icône retirée depuis, etc.).
  static const IconData fallback = Icons.inbox;

  /// Retrouve l'[IconData] `const` du catalogue dont le `codePoint`
  /// correspond à [codePoint], ou [fallback] si rien ne correspond.
  static IconData findByCodePoint(int codePoint) {
    for (final IconData icon in options) {
      if (icon.codePoint == codePoint) return icon;
    }
    return fallback;
  }
}
