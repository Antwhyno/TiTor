import 'package:flutter/material.dart';
import 'box_color_type.dart';

/// Modèle représentant une boîte de l'application.
///
/// Une boîte possède un nom, une icône, une couleur (qui détermine la
/// durée de son chronomètre), une date de création, une date
/// d'expiration calculée, et peut appartenir à un groupe.
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

  const BoxModel({
    required this.id,
    required this.name,
    required this.iconCodePoint,
    required this.iconFontFamily,
    this.iconFontPackage,
    required this.color,
    this.groupId,
    required this.createdAt,
    required this.expiresAt,
  });

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
  IconData get icon => IconData(
        iconCodePoint,
        fontFamily: iconFontFamily,
        fontPackage: iconFontPackage,
      );

  /// Temps restant avant expiration du chronomètre.
  /// Peut être négatif si le délai est déjà dépassé.
  Duration remaining({DateTime? now}) {
    final DateTime reference = now ?? DateTime.now();
    return expiresAt.difference(reference);
  }

  /// Indique si le chronomètre de la boîte est arrivé à expiration.
  bool isExpired({DateTime? now}) => remaining(now: now).isNegative;

  BoxModel copyWith({
    String? id,
    String? name,
    int? iconCodePoint,
    String? iconFontFamily,
    String? iconFontPackage,
    BoxColorType? color,
    String? groupId,
    bool clearGroup = false,
    DateTime? createdAt,
    DateTime? expiresAt,
  }) {
    return BoxModel(
      id: id ?? this.id,
      name: name ?? this.name,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      iconFontFamily: iconFontFamily ?? this.iconFontFamily,
      iconFontPackage: iconFontPackage ?? this.iconFontPackage,
      color: color ?? this.color,
      groupId: clearGroup ? null : (groupId ?? this.groupId),
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  /// Change la couleur de la boîte et recalcule sa date d'expiration.
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

  /// Reconstruit une [BoxModel] à partir d'une ligne de base de données.
  factory BoxModel.fromMap(Map<String, Object?> map) {
    final Object? rawId = map['id'];
    final Object? rawName = map['name'];

    if (rawId == null || rawName == null) {
      throw FormatException('Données de boîte invalides : $map');
    }

    final Object? rawCreatedAt = map['created_at'];
    final Object? rawExpiresAt = map['expires_at'];

    final DateTime createdAt = rawCreatedAt is String
        ? DateTime.tryParse(rawCreatedAt) ?? DateTime.now()
        : DateTime.now();
    final DateTime expiresAt = rawExpiresAt is String
        ? DateTime.tryParse(rawExpiresAt) ?? createdAt
        : createdAt;

    return BoxModel(
      id: rawId as String,
      name: rawName as String,
      iconCodePoint: (map['icon_code_point'] as int?) ?? Icons.inbox.codePoint,
      iconFontFamily: (map['icon_font_family'] as String?) ?? 'MaterialIcons',
      iconFontPackage: map['icon_font_package'] as String?,
      color: BoxColorType.fromStorageValue(map['color'] as String?),
      groupId: map['group_id'] as String?,
      createdAt: createdAt,
      expiresAt: expiresAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is BoxModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
