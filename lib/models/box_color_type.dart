import 'package:flutter/material.dart';

/// Représente les trois couleurs possibles d'une lipo.
/// Chaque couleur détermine la durée du chronomètre associé à la lipo.
enum BoxColorType {
  red,
  green,
  yellow; // Le point-virgule est obligatoire ici pour séparer les valeurs des membres.

  /// Durée avant expiration du chronomètre, selon la couleur.
  Duration get reminderDuration {
    switch (this) {
      case BoxColorType.red:
        return const Duration(days: 1);
      case BoxColorType.yellow:
        return const Duration(days: 7);
      case BoxColorType.green:
        return const Duration(days: 14);
    }
  }

  /// Couleur Material associée, utilisée pour l'affichage de la lipo.
  Color get materialColor {
    switch (this) {
      case BoxColorType.red:
        return const Color(0xFFE53935);
      case BoxColorType.green:
        return const Color(0xFF43A047);
      case BoxColorType.yellow:
        return const Color(0xFFF9A825);
    }
  }

  /// Libellé français affiché dans l'interface, avec la durée associée.
  String get label {
    switch (this) {
      case BoxColorType.red:
        return 'Rouge (1 jour)';
      case BoxColorType.green:
        return 'Vert (14 jours)';
      case BoxColorType.yellow:
        return 'Jaune (7 jours)';
    }
  }

  /// Valeur technique stockée en base de données.
  String get storageValue => name;

  /// Reconstruit un [BoxColorType] à partir de sa valeur stockée (gestion défensive).
  static BoxColorType fromStorageValue(String? value) {
    return BoxColorType.values.firstWhere(
      (BoxColorType type) => type.storageValue == value,
      orElse: () => BoxColorType.yellow,
    );
  }
}
