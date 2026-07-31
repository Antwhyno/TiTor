import 'package:equatable/equatable.dart';

import '../../models/box_group_model.dart';

/// États possibles du [GroupBloc].
abstract class GroupState extends Equatable {
  const GroupState();

  @override
  List<Object?> get props => <Object?>[];
}

/// État initial, avant tout chargement.
class GroupInitial extends GroupState {
  const GroupInitial();
}

/// Chargement des groupes en cours.
class GroupLoading extends GroupState {
  const GroupLoading();
}

/// Groupes chargés avec succès.
class GroupLoaded extends GroupState {
  final List<BoxGroupModel> groups;

  const GroupLoaded(this.groups);

  @override
  List<Object?> get props => <Object?>[groups];
}

/// Une erreur est survenue lors d'une opération sur les groupes.
/// [previousGroups] permet de conserver l'affichage existant pendant
/// la présentation du message d'erreur.
class GroupError extends GroupState {
  final String message;
  final List<BoxGroupModel> previousGroups;

  const GroupError({
    required this.message,
    this.previousGroups = const <BoxGroupModel>[],
  });

  @override
  List<Object?> get props => <Object?>[message, previousGroups];
}
