import 'package:flutter/foundation.dart';

/// Modèle représentant un groupe de boîtes.
@immutable
class BoxGroupModel {
  final String id;
  final String name;
  final DateTime createdAt;

  const BoxGroupModel({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  factory BoxGroupModel.create({
    required String id,
    required String name,
    DateTime? now,
  }) {
    return BoxGroupModel(
      id: id,
      name: name,
      createdAt: now ?? DateTime.now(),
    );
  }

  BoxGroupModel copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
  }) {
    return BoxGroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Reconstruit un [BoxGroupModel] à partir d'une ligne de base de
  /// données, en gérant explicitement le cas de données manquantes.
  factory BoxGroupModel.fromMap(Map<String, Object?> map) {
    final Object? rawId = map['id'];
    final Object? rawName = map['name'];

    if (rawId is! String || rawName is! String) {
      throw FormatException('Données de groupe invalides : $map');
    }

    final Object? rawCreatedAt = map['created_at'];
    final DateTime? createdAt =
        rawCreatedAt is String ? DateTime.tryParse(rawCreatedAt) : null;
    if (createdAt == null) {
      throw FormatException('Date de groupe invalide : $map');
    }

    return BoxGroupModel(
      id: rawId,
      name: rawName,
      createdAt: createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is BoxGroupModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
