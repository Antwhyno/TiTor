import 'package:flutter/material.dart';
import 'box_color_type.dart';
import '../utils/icon_catalog.dart';
import '../utils/proximity_color.dart';

/// Modèle représentant une lipo de l'application.
///
/// Encapsule les données d'une lipo ainsi que ses invariants métier.
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

  /// Couleur choisie manuellement par l'utilisateur (valeur ARGB), qui
  /// prime sur la couleur automatique de proximité lorsqu'elle est
  /// définie. `null` signifie que la couleur est calculée
  /// automatiquement en fonction du temps restant avant expiration.
  final int? manualColorValue;

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
    this.manualColorValue,
  }) {
    // Validation des invariants (Programmation défensive)
    if (id.trim().isEmpty) {
      throw ArgumentError(
          'L\'identifiant (id) de la lipo ne peut pas être vide.');
    }
    if (name.trim().isEmpty) {
      throw ArgumentError('Le nom de la lipo ne peut pas être vide.');
    }
    if (expiresAt.isBefore(createdAt)) {
      throw ArgumentError(
        'La date d\'expiration ($expiresAt) ne peut pas être antérieure à la date de création ($createdAt).',
      );
    }
  }

  /// Crée une nouvelle lipo en calculant automatiquement sa date
  /// d'expiration à partir de la durée associée à la couleur choisie.
  factory BoxModel.create({
    required String id,
    required String name,
    required IconData icon,
    required BoxColorType color,
    String? groupId,
    DateTime? now,
    Duration? customDuration,
  }) {
    final DateTime creationDate = now ?? DateTime.now();
    final Duration duration = customDuration ?? color.reminderDuration;
    return BoxModel(
      id: id,
      name: name,
      iconCodePoint: icon.codePoint,
      iconFontFamily: icon.fontFamily ?? 'MaterialIcons',
      iconFontPackage: icon.fontPackage,
      color: color,
      groupId: groupId,
      createdAt: creationDate,
      expiresAt: creationDate
          .add(duration), // <-- Utilise la variable duration calculée
    );
  }

  /// Icône reconstituée pour l'affichage à partir des champs stockés.
  ///
  /// Note : Pas de mot-clé `const` ici car les arguments sont des
  /// propriétés d'instance évaluées dynamiquement à l'exécution.
  IconData get icon => IconCatalog.findByCodePoint(iconCodePoint);

  /// Temps restant avant expiration du chronomètre.
  Duration remaining({DateTime? now}) {
    final DateTime reference = now ?? DateTime.now();
    return expiresAt.difference(reference);
  }

  /// Indique si le chronomètre de la lipo est arrivé à expiration.
  bool isExpired({DateTime? now}) => remaining(now: now) <= Duration.zero;

  /// Indique si une couleur manuelle a été choisie par l'utilisateur,
  /// désactivant ainsi le calcul automatique de couleur par proximité.
  bool get hasManualColor => manualColorValue != null;

  /// Couleur manuelle reconstituée depuis sa valeur ARGB stockée, ou
  /// `null` si aucune couleur manuelle n'est définie.
  Color? get manualColor =>
      manualColorValue != null ? Color(manualColorValue!) : null;

  /// Couleur à afficher dans l'interface pour cette lipo.
  ///
  /// Si l'utilisateur a choisi une couleur manuellement, celle-ci est
  /// utilisée telle quelle. Sinon, la couleur est calculée
  /// automatiquement : plus la lipo approche de sa date d'expiration
  /// (recharge à venir), plus elle tend vers le rouge ; plus elle en
  /// est loin, plus elle tend vers le vert.
  Color displayColor({DateTime? now}) {
    final Color? manual = manualColor;
    if (manual != null) {
      return manual;
    }
    return ProximityColor.compute(
      createdAt: createdAt,
      expiresAt: expiresAt,
      now: now,
    );
  }

  /// Crée une copie avec une couleur manuelle forcée, désactivant le
  /// calcul automatique par proximité.
  BoxModel withManualColor(Color color) {
    return copyWith(manualColorValue: color.toARGB32());
  }

  /// Crée une copie qui revient au calcul automatique de couleur par
  /// proximité, en effaçant toute couleur manuelle précédemment choisie.
  BoxModel clearManualColor() {
    return copyWith(clearManualColor: true);
  }

  /// Crée une copie de l'instance en modifiant certains champs.
  ///
  /// Utilisez [clearIconFontPackage] à true pour effacer le package d'icône.
  /// Utilisez [clearGroup] à true pour effacer l'association à un groupe.
  BoxModel copyWith({
    String? id,
    String? name,
    int? iconCodePoint,
    String? iconFontFamily,
    String? iconFontPackage,
    bool clearIconFontPackage = false,
    BoxColorType? color,
    String? groupId,
    bool clearGroup = false,
    DateTime? createdAt,
    DateTime? expiresAt,
    int? manualColorValue,
    bool clearManualColor = false,
  }) {
    final BoxColorType newColor = color ?? this.color;

    // Si la couleur change sans date d'expiration explicite,
    // recalcul automatique de la durée.
    DateTime newExpiresAt = expiresAt ?? this.expiresAt;
    if (color != null && color != this.color && expiresAt == null) {
      newExpiresAt = DateTime.now().add(newColor.reminderDuration);
    }

    return BoxModel(
      id: id ?? this.id,
      name: name ?? this.name,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      iconFontFamily: iconFontFamily ?? this.iconFontFamily,
      iconFontPackage: clearIconFontPackage
          ? null
          : (iconFontPackage ?? this.iconFontPackage),
      color: newColor,
      groupId: clearGroup ? null : (groupId ?? this.groupId),
      createdAt: createdAt ?? this.createdAt,
      expiresAt: newExpiresAt,
      manualColorValue: clearManualColor
          ? null
          : (manualColorValue ?? this.manualColorValue),
    );
  }

  /// Recalcule la date d'expiration après un changement de couleur.
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
      'manual_color': manualColorValue,
    };
  }

  /// Reconstruit une [BoxModel] depuis une Map (base de données) avec parsing défensif.
  factory BoxModel.fromMap(Map<String, Object?> map) {
    final Object? rawId = map['id'];
    if (rawId is! String || rawId.trim().isEmpty) {
      throw FormatException(
          'Champ obligatoire "id" invalide ou manquant dans la Map: $map');
    }

    final Object? rawName = map['name'];
    if (rawName is! String || rawName.trim().isEmpty) {
      throw FormatException(
          'Champ obligatoire "name" invalide ou manquant dans la Map: $map');
    }

    final Object? rawCodePoint = map['icon_code_point'];
    final int iconCodePoint = rawCodePoint is int
        ? rawCodePoint
        : (rawCodePoint is String
            ? int.tryParse(rawCodePoint) ?? Icons.inbox.codePoint
            : Icons.inbox.codePoint);

    final String iconFontFamily =
        (map['icon_font_family'] as String?) ?? 'MaterialIcons';
    final String? iconFontPackage = map['icon_font_package'] as String?;
    final String? groupId = map['group_id'] as String?;

    final Object? rawCreatedAt = map['created_at'];
    final DateTime createdAt = rawCreatedAt is String
        ? DateTime.tryParse(rawCreatedAt) ?? DateTime.now()
        : DateTime.now();

    final Object? rawExpiresAt = map['expires_at'];
    final DateTime expiresAt = rawExpiresAt is String
        ? DateTime.tryParse(rawExpiresAt) ??
            createdAt.add(const Duration(days: 1))
        : createdAt.add(const Duration(days: 1));

    final BoxColorType color =
        BoxColorType.fromStorageValue(map['color'] as String?);

    final Object? rawManualColor = map['manual_color'];
    final int? manualColorValue = rawManualColor is int
        ? rawManualColor
        : (rawManualColor is String ? int.tryParse(rawManualColor) : null);

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
      manualColorValue: manualColorValue,
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
