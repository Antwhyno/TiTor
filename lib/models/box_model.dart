import 'package:flutter/material.dart';
import 'box_color_type.dart';

/// Modèle représentant une boîte de l'application.
///
/// Encapsule les données d'une boîte ainsi que ses invariants métier.
@immutable
class BoxModel {
  final String id;
  final String name;
  final int iconCodePoint;
  final String iconFontFamily;
  final String? iconFontPackage;
  final BoxColorType color;
  final String? groupId;
  final DateTime createdAt;
  final DateTime expiresAt;

  BoxModel({
    required this.id,
    required this.name,
    required this.iconCodePoint,
    required this.iconFontFamily,
    this.iconFontPackage,
    required this.color,
    this.groupId,
    required this.createdAt,
    required this.expiresAt,
  }) {
    // Validation des invariants (Programmation défensive)
    if (id.trim().isEmpty) {
      throw ArgumentError(
          'L\'identifiant (id) de la boîte ne peut pas être vide.');
    }
    if (name.trim().isEmpty) {
      throw ArgumentError('Le nom de la boîte ne peut pas être vide.');
    }
    if (expiresAt.isBefore(createdAt)) {
      throw ArgumentError(
        'La date d\'expiration ($expiresAt) ne peut pas être antérieure à la date de création ($createdAt).',
      );
    }
  }

  /// Crée une nouvelle boîte en calculant automatiquement sa date
  /// d'expiration à partir de la durée associée à la couleur choisie.
  factory BoxModel.create({
    required String id,
    required String name,
    required IconData icon,
    required BoxColorType color,
    String? groupId,
    DateTime? now,
  }) {
    final DateTime creationDate = now ?? DateTime.now();
    return BoxModel(
      id: id,
      name: name,
      iconCodePoint: icon.codePoint,
      iconFontFamily: icon.fontFamily ?? 'MaterialIcons',
      iconFontPackage: icon.fontPackage,
      color: color,
      groupId: groupId,
      createdAt: creationDate,
      expiresAt: creationDate.add(color.reminderDuration),
    );
  }

  /// Icône reconstituée pour l'affichage à partir des champs stockés.
  /// Les avertissements de type "non-constant" sont normaux et attendus
  /// car les arguments proviennent de variables d'instance.
  IconData get icon => IconData(
        iconCodePoint,
        fontFamily: iconFontFamily,
        fontPackage: iconFontPackage,
      );

  /// Temps restant avant expiration du chronomètre.
  Duration remaining({DateTime? now}) {
    final DateTime reference = now ?? DateTime.now();
    return expiresAt.difference(reference);
  }

  /// Indique si le chronomètre de la boîte est arrivé à expiration.
  /// Retourne true si le temps restant est inférieur ou égal à 0.
  bool isExpired({DateTime? now}) => remaining(now: now) <= Duration.zero;

  /// Crée une copie de l'instance en modifiant certains champs.
  ///
  /// Utilisez [clearFontPackage] à true pour effacer explicitement le package d'icône.
  /// Utilisez [clearGroup] à true pour effacer l'association à un groupe.
  BoxModel copyWith({
    String? id,
    String? name,
    int? iconCodePoint,
    String? iconFontFamily,
    String? iconFontPackage,
    bool clearFontPackage = false,
    BoxColorType? color,
    String? groupId,
    bool clearGroup = false,
    DateTime? createdAt,
    DateTime? expiresAt,
  }) {
    final BoxColorType newColor = color ?? this.color;

    // Si la couleur change et qu'aucune date d'expiration explicite n'est fournie,
    // la date d'expiration est automatiquement recalculée à partir de maintenant.
    DateTime newExpiresAt = expiresAt ?? this.expiresAt;
    if (color != null && color != this.color && expiresAt == null) {
      newExpiresAt = DateTime.now().add(newColor.reminderDuration);
    }

    return BoxModel(
      id: id ?? this.id,
      name: name ?? this.name,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      iconFontFamily: iconFontFamily ?? this.iconFontFamily,
      iconFontPackage:
          clearFontPackage ? null : (iconFontPackage ?? this.iconFontPackage),
      color: newColor,
      groupId: clearGroup ? null : (groupId ?? this.groupId),
      createdAt: createdAt ?? this.createdAt,
      expiresAt: newExpiresAt,
    );
  }

  /// Recalcule la date d'expiration d'urgence après un changement de couleur.
  BoxModel withColor(BoxColorType newColor, {DateTime? changedAt}) {
    final DateTime reference = changedAt ?? DateTime.now();
    return copyWith(
      color: newColor,
      expiresAt: reference.add(newColor.reminderDuration),
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'icon_code_point': iconCodePoint,
      'icon_font_family': iconFontFamily,
      'icon_font_package': iconFontPackage,
      'color': color.storageValue,
      'group_id': groupId,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
    };
  }

  /// Reconstruit une [BoxModel] depuis une Map (base de données) avec parsing défensif.
  factory BoxModel.fromMap(Map<String, Object?> map) {
    // 1. Validation de l'id
    final Object? rawId = map['id'];
    if (rawId is! String || rawId.trim().isEmpty) {
      throw FormatException(
          'Champ obligatoire "id" invalide ou manquant dans la Map: $map');
    }

    // 2. Validation du nom
    final Object? rawName = map['name'];
    if (rawName is! String || rawName.trim().isEmpty) {
      throw FormatException(
          'Champ obligatoire "name" invalide ou manquant dans la Map: $map');
    }

    // 3. Extraction sécurisée du codePoint d'icône
    final Object? rawCodePoint = map['icon_code_point'];
    final int iconCodePoint = rawCodePoint is int
        ? rawCodePoint
        : (rawCodePoint is String
            ? int.tryParse(rawCodePoint) ?? Icons.inbox.codePoint
            : Icons.inbox.codePoint);

    // 4. Extraction des chaînes optionnelles / secondaires
    final String iconFontFamily =
        (map['icon_font_family'] as String?) ?? 'MaterialIcons';
    final String? iconFontPackage = map['icon_font_package'] as String?;
    final String? groupId = map['group_id'] as String?;

    // 5. Extraction des dates avec repli sécurisé
    final Object? rawCreatedAt = map['created_at'];
    final DateTime createdAt = rawCreatedAt is String
        ? DateTime.tryParse(rawCreatedAt) ?? DateTime.now()
        : DateTime.now();

    final Object? rawExpiresAt = map['expires_at'];
    final DateTime expiresAt = rawExpiresAt is String
        ? DateTime.tryParse(rawExpiresAt) ??
            createdAt.add(const Duration(days: 1))
        : createdAt.add(const Duration(days: 1));

    // 6. Extraction de la couleur
    final BoxColorType color =
        BoxColorType.fromStorageValue(map['color'] as String?);

    return BoxModel(
      id: rawId,
      name: rawName,
      iconCodePoint: iconCodePoint,
      iconFontFamily: iconFontFamily,
      iconFontPackage: iconFontPackage,
      color: color,
      groupId: groupId,
      createdAt: createdAt,
      expiresAt: expiresAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BoxModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
