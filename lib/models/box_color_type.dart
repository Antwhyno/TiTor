import 'package:flutter/material.dart';

/// Représente les trois couleurs possibles d'une boîte.
/// Chaque couleur détermine la durée du chronomètre associé à la boîte.
enum BoxColorType {
  red,
  green,
  yellow,
}

/// Extension utilitaire associant à chaque [BoxColorType] sa durée de
/// chronomètre, sa couleur d'affichage et son libellé lisible.
extension BoxColorTypeX on BoxColorType {
  /// Durée avant expiration du chronomètre, selon la couleur :
  /// Rouge -> 1 jour, Jaune -> 7 jours, Vert -> 14 jours.
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

  /// Couleur Material associée, utilisée pour l'affichage de la boîte.
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

  /// Valeur technique stockée en base de données (nom de l'énumération).
  String get storageValue => name;

  /// Reconstruit un [BoxColorType] à partir de sa valeur stockée.
  /// Si la valeur est nulle ou inconnue (donnée corrompue), retourne
  /// une valeur par défaut plutôt que de lever une exception : c'est
  /// une gestion défensive du cas limite "donnée invalide".
  static BoxColorType fromStorageValue(String? value) {
    return BoxColorType.values.firstWhere(
      (BoxColorType type) => type.storageValue == value,
      orElse: () => BoxColorType.yellow,
    );
  }
}
