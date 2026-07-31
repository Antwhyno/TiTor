import 'package:equatable/equatable.dart';

import '../../models/box_model.dart';

/// États possibles du [BoxBloc].
abstract class BoxState extends Equatable {
  const BoxState();

  @override
  List<Object?> get props => <Object?>[];
}

/// État initial, avant tout chargement.
class BoxInitial extends BoxState {
  const BoxInitial();
}

/// Chargement des boîtes en cours.
class BoxLoading extends BoxState {
  const BoxLoading();
}

/// Boîtes chargées avec succès.
class BoxLoaded extends BoxState {
  final List<BoxModel> boxes;

  const BoxLoaded(this.boxes);

  /// Boîtes n'appartenant à aucun groupe.
  List<BoxModel> get ungroupedBoxes =>
      boxes.where((BoxModel box) => box.groupId == null).toList();

  /// Boîtes appartenant à un groupe donné.
  List<BoxModel> boxesInGroup(String groupId) => boxes
      .where((BoxModel box) => box.groupId == groupId)
      .toList(growable: false);

  @override
  List<Object?> get props => <Object?>[boxes];
}

/// Une erreur est survenue lors d'une opération sur les boîtes.
///
/// [previousBoxes] permet de conserver l'affichage existant à l'écran
/// pendant qu'un message d'erreur est présenté (ex: snackbar), plutôt
/// que d'effacer brutalement la liste visible de l'utilisateur.
class BoxError extends BoxState {
  final String message;
  final List<BoxModel> previousBoxes;

  const BoxError({
    required this.message,
    this.previousBoxes = const <BoxModel>[],
  });

  @override
  List<Object?> get props => <Object?>[message, previousBoxes];
}
