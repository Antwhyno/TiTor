import 'package:flutter/material.dart';

/// Calcule une couleur automatique reflétant la proximité de la date
/// d'expiration d'une lipo (recharge à venir).
///
/// Plus la date d'expiration est proche, plus la couleur tend vers le
/// rouge. Plus elle est lointaine, plus la couleur tend vers le vert.
/// La transition est un dégradé continu (et non un simple palier),
/// afin que l'indicateur visuel évolue progressivement dans le temps.
class ProximityColor {
  ProximityColor._();

  /// Couleur lorsque la lipo vient tout juste d'être créée (loin de
  /// l'expiration).
  static const Color farColor = Color(0xFF43A047); // Vert

  /// Couleur lorsque la lipo est proche de l'expiration (ou expirée).
  static const Color nearColor = Color(0xFFE53935); // Rouge

  /// Retourne la progression (entre 0.0 et 1.0) du temps écoulé entre
  /// [createdAt] et [expiresAt], par rapport à [now].
  ///
  /// 0.0 correspond à l'instant de création (loin de l'expiration),
  /// 1.0 correspond à l'instant d'expiration (ou au-delà).
  static double progress({
    required DateTime createdAt,
    required DateTime expiresAt,
    DateTime? now,
  }) {
    final DateTime reference = now ?? DateTime.now();
    final int totalMs = expiresAt.difference(createdAt).inMilliseconds;

    // Garde-fou : si la durée totale est nulle ou négative (invariant
    // normalement déjà validé par BoxModel), on considère la lipo comme
    // arrivée à expiration.
    if (totalMs <= 0) {
      return 1.0;
    }

    final int elapsedMs = reference.difference(createdAt).inMilliseconds;
    final double ratio = elapsedMs / totalMs;
    return ratio.clamp(0.0, 1.0);
  }

  /// Calcule la couleur automatique correspondant à la progression
  /// entre [createdAt] et [expiresAt] au moment [now].
  static Color compute({
    required DateTime createdAt,
    required DateTime expiresAt,
    DateTime? now,
  }) {
    final double t = progress(createdAt: createdAt, expiresAt: expiresAt, now: now);
    return Color.lerp(farColor, nearColor, t) ?? nearColor;
  }
}
