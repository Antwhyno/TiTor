import 'package:equatable/equatable.dart';

/// Événements pouvant être envoyés au [GroupBloc].
abstract class GroupEvent extends Equatable {
  const GroupEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Demande le chargement initial (ou le rechargement) des groupes.
class LoadGroups extends GroupEvent {
  const LoadGroups();
}

/// Demande la création d'un nouveau groupe.
class AddGroupRequested extends GroupEvent {
  final String name;

  const AddGroupRequested(this.name);

  @override
  List<Object?> get props => <Object?>[name];
}

/// Demande le renommage d'un groupe existant.
class UpdateGroupRequested extends GroupEvent {
  final String groupId;
  final String name;

  const UpdateGroupRequested({required this.groupId, required this.name});

  @override
  List<Object?> get props => <Object?>[groupId, name];
}

/// Demande la suppression d'un groupe. Les lipos qu'il contient sont
/// automatiquement détachées (elles redeviennent "sans groupe") plutôt
/// que d'être supprimées.
class DeleteGroupRequested extends GroupEvent {
  final String groupId;

  const DeleteGroupRequested(this.groupId);

  @override
  List<Object?> get props => <Object?>[groupId];
}
