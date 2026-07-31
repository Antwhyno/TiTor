import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../models/box_color_type.dart';

/// Événements pouvant être envoyés au [BoxBloc].
abstract class BoxEvent extends Equatable {
  const BoxEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Demande le chargement initial (ou le rechargement) des boîtes.
class LoadBoxes extends BoxEvent {
  const LoadBoxes();
}

/// Demande la création d'une nouvelle boîte.
class AddBoxRequested extends BoxEvent {
  final String name;
  final IconData icon;
  final BoxColorType color;
  final String? groupId;

  const AddBoxRequested({
    required this.name,
    required this.icon,
    required this.color,
    this.groupId,
  });

  @override
  List<Object?> get props => <Object?>[name, icon, color, groupId];
}

/// Demande la modification d'une boîte existante (nom, icône, groupe).
class UpdateBoxRequested extends BoxEvent {
  final String boxId;
  final String name;
  final IconData icon;
  final String? groupId;
  final bool clearGroup;

  const UpdateBoxRequested({
    required this.boxId,
    required this.name,
    required this.icon,
    this.groupId,
    this.clearGroup = false,
  });

  @override
  List<Object?> get props => <Object?>[boxId, name, icon, groupId, clearGroup];
}

/// Demande le changement de couleur d'une boîte : recalcule
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

/// Demande la suppression d'une boîte.
class DeleteBoxRequested extends BoxEvent {
  final String boxId;

  const DeleteBoxRequested(this.boxId);

  @override
  List<Object?> get props => <Object?>[boxId];
}
