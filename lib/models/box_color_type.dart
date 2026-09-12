/// Catégorie unique de durée par défaut du chronomètre d'une lipo.
///
/// Auparavant, trois couleurs (rouge/jaune/vert) proposaient chacune
/// une durée différente. Il n'existe désormais plus qu'une seule
/// catégorie, avec une durée par défaut de 15 jours. La durée réelle
/// du chronomètre peut toujours être ajustée manuellement (jours /
/// heures) à la création ou à la modification d'une lipo.
enum BoxColorType {
  standard;

  /// Durée par défaut avant expiration du chronomètre.
  Duration get reminderDuration => const Duration(days: 15);

  /// Valeur technique stockée en base de données.
  String get storageValue => name;

  /// Reconstruit un [BoxColorType] à partir de sa valeur stockée
  /// (gestion défensive : toute ancienne valeur inconnue — par
  /// exemple 'red', 'yellow' ou 'green' d'une version antérieure de
  /// l'application — retombe sur la catégorie unique actuelle).
  static BoxColorType fromStorageValue(String? value) {
    return BoxColorType.values.firstWhere(
      (BoxColorType type) => type.storageValue == value,
      orElse: () => BoxColorType.standard,
    );
  }
}
