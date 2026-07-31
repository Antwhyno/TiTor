import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../data/app_exceptions.dart';
import '../../data/box_repository.dart';
import '../../data/group_repository.dart';
import '../../models/box_group_model.dart';
import 'group_event.dart';
import 'group_state.dart';

/// Gère le cycle de vie des groupes de boîtes : chargement, création,
/// renommage et suppression.
///
/// La suppression d'un groupe détache d'abord ses boîtes (elles
/// deviennent "sans groupe") avant de supprimer le groupe lui-même,
/// afin de ne jamais perdre de données utilisateur.
class GroupBloc extends Bloc<GroupEvent, GroupState> {
  final GroupRepository _groupRepository;
  final BoxRepository _boxRepository;
  final Uuid _uuid;

  GroupBloc({
    GroupRepository? groupRepository,
    BoxRepository? boxRepository,
    Uuid? uuid,
  })  : _groupRepository = groupRepository ?? GroupRepository(),
        _boxRepository = boxRepository ?? BoxRepository(),
        _uuid = uuid ?? const Uuid(),
        super(const GroupInitial()) {
    on<LoadGroups>(_onLoadGroups);
    on<AddGroupRequested>(_onAddGroupRequested);
    on<UpdateGroupRequested>(_onUpdateGroupRequested);
    on<DeleteGroupRequested>(_onDeleteGroupRequested);
  }

  List<BoxGroupModel> get _currentGroups {
    final GroupState currentState = state;
    if (currentState is GroupLoaded) {
      return currentState.groups;
    }
    if (currentState is GroupError) {
      return currentState.previousGroups;
    }
    return const <BoxGroupModel>[];
  }

  Future<void> _onLoadGroups(
    LoadGroups event,
    Emitter<GroupState> emit,
  ) async {
    emit(const GroupLoading());
    try {
      final List<BoxGroupModel> groups = await _groupRepository.fetchAll();
      emit(GroupLoaded(groups));
    } on AppException catch (error) {
      emit(GroupError(message: error.message));
    } on Exception {
      emit(const GroupError(
        message: 'Une erreur inattendue est survenue lors du chargement.',
      ));
    }
  }

  Future<void> _onAddGroupRequested(
    AddGroupRequested event,
    Emitter<GroupState> emit,
  ) async {
    final String trimmedName = event.name.trim();
    if (trimmedName.isEmpty) {
      emit(GroupError(
        message: 'Le nom du groupe ne peut pas être vide.',
        previousGroups: _currentGroups,
      ));
      return;
    }
    try {
      final BoxGroupModel newGroup = BoxGroupModel.create(
        id: _uuid.v4(),
        name: trimmedName,
      );
      await _groupRepository.insert(newGroup);
      emit(GroupLoaded(<BoxGroupModel>[newGroup, ..._currentGroups]));
    } on AppException catch (error) {
      emit(GroupError(message: error.message, previousGroups: _currentGroups));
    } on Exception {
      emit(GroupError(
        message: 'Impossible de créer le groupe.',
        previousGroups: _currentGroups,
      ));
    }
  }

  Future<void> _onUpdateGroupRequested(
    UpdateGroupRequested event,
    Emitter<GroupState> emit,
  ) async {
    final List<BoxGroupModel> groups = _currentGroups;
    final int index = groups.indexWhere(
      (BoxGroupModel group) => group.id == event.groupId,
    );
    if (index == -1) {
      emit(GroupError(
        message: 'Le groupe à modifier est introuvable.',
        previousGroups: groups,
      ));
      return;
    }
    final String trimmedName = event.name.trim();
    if (trimmedName.isEmpty) {
      emit(GroupError(
        message: 'Le nom du groupe ne peut pas être vide.',
        previousGroups: groups,
      ));
      return;
    }
    try {
      final BoxGroupModel updatedGroup =
          groups[index].copyWith(name: trimmedName);
      await _groupRepository.update(updatedGroup);
      final List<BoxGroupModel> newGroups = List<BoxGroupModel>.from(groups);
      newGroups[index] = updatedGroup;
      emit(GroupLoaded(newGroups));
    } on AppException catch (error) {
      emit(GroupError(message: error.message, previousGroups: groups));
    } on Exception {
      emit(GroupError(
        message: 'Impossible de mettre à jour le groupe.',
        previousGroups: groups,
      ));
    }
  }

  Future<void> _onDeleteGroupRequested(
    DeleteGroupRequested event,
    Emitter<GroupState> emit,
  ) async {
    final List<BoxGroupModel> groups = _currentGroups;
    try {
      await _boxRepository.detachFromGroup(event.groupId);
      await _groupRepository.delete(event.groupId);
      final List<BoxGroupModel> newGroups = groups
          .where((BoxGroupModel group) => group.id != event.groupId)
          .toList();
      emit(GroupLoaded(newGroups));
    } on AppException catch (error) {
      emit(GroupError(message: error.message, previousGroups: groups));
    } on Exception {
      emit(GroupError(
        message: 'Impossible de supprimer le groupe.',
        previousGroups: groups,
      ));
    }
  }
}
