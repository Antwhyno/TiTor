import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../models/box_color_type.dart';

/// Événements pouvant être envoyés au [BoxBloc].
abstract class BoxEvent extends Equatable {
  const BoxEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Demande le chargement initial (ou le rechargement) des lipos.
class LoadBoxes extends BoxEvent {
  const LoadBoxes();
}

/// Demande la création d'une nouvelle lipo.
class AddBoxRequested extends BoxEvent {
  final String name;
  final IconData icon;
  final BoxColorType color;
  final String? groupId;
  final Duration? customDuration; // <-- Nouveau champ optionnel

  const AddBoxRequested({
    required this.name,
    required this.icon,
    required this.color,
    this.groupId,
    this.customDuration, // <-- Paramètre optionnel
  });

  @override
  List<Object?> get props =>
      <Object?>[name, icon, color, groupId, customDuration];
}

/// Demande la modification d'une lipo existante (nom, icône, groupe).
class UpdateBoxRequested extends BoxEvent {
  final String boxId;
  final String name;
  final IconData icon;
  final BoxColorType color;
  final String? groupId;
  final bool clearGroup;

  const UpdateBoxRequested({
    required this.boxId,
    required this.name,
    required this.icon,
    required this.color,
    this.groupId,
    this.clearGroup = false,
  });

  @override
  List<Object?> get props =>
      <Object?>[boxId, name, icon, color, groupId, clearGroup];
}

/// Demande le changement de couleur d'une lipo : recalcule
/// automatiquement le chronomètre associé.
class ChangeBoxColorRequested extends BoxEvent {
  final String boxId;
  final BoxColorType newColor;

  const ChangeBoxColorRequested({
    required this.boxId,
    required this.newColor,
  });

  @override
  List<Object?> get props => <Object?>[boxId, newColor];
}

/// Demande le changement de la couleur manuelle d'affichage d'une
/// lipo (indépendante de la catégorie [BoxColorType] et de la durée
/// du chronomètre). Ne modifie ni la durée, ni la date d'expiration.
///
/// Passer [manualColor] à `null` réactive le calcul automatique de la
/// couleur par proximité de la date d'expiration.
class ChangeBoxManualColorRequested extends BoxEvent {
  final String boxId;
  final Color? manualColor;

  const ChangeBoxManualColorRequested({
    required this.boxId,
    required this.manualColor,
  });

  @override
  List<Object?> get props => <Object?>[boxId, manualColor];
}

/// Demande la suppression d'une lipo.
class DeleteBoxRequested extends BoxEvent {
  final String boxId;

  const DeleteBoxRequested(this.boxId);

  @override
  List<Object?> get props => <Object?>[boxId];
}
