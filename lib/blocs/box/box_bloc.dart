import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../data/app_exceptions.dart';
import '../../data/box_repository.dart';
import '../../models/box_model.dart';
import 'box_event.dart';
import 'box_state.dart';

/// Gère l'ensemble du cycle de vie des boîtes : chargement, création,
/// modification, changement de couleur et suppression.
///
/// Toute erreur levée par le [BoxRepository] est capturée et
/// transformée en un état [BoxError] exploitable par l'interface, sans
/// jamais laisser une exception non gérée remonter jusqu'à l'UI.
class BoxBloc extends Bloc<BoxEvent, BoxState> {
  final BoxRepository _repository;
  final Uuid _uuid;

  BoxBloc({
    BoxRepository? repository,
    Uuid? uuid,
  })  : _repository = repository ?? BoxRepository(),
        _uuid = uuid ?? const Uuid(),
        super(const BoxInitial()) {
    on<LoadBoxes>(_onLoadBoxes);
    on<AddBoxRequested>(_onAddBoxRequested);
    on<UpdateBoxRequested>(_onUpdateBoxRequested);
    on<ChangeBoxColorRequested>(_onChangeBoxColorRequested);
    on<DeleteBoxRequested>(_onDeleteBoxRequested);
  }

  List<BoxModel> get _currentBoxes {
    final BoxState currentState = state;
    if (currentState is BoxLoaded) {
      return currentState.boxes;
    }
    if (currentState is BoxError) {
      return currentState.previousBoxes;
    }
    return const <BoxModel>[];
  }

  Future<void> _onLoadBoxes(LoadBoxes event, Emitter<BoxState> emit) async {
    emit(const BoxLoading());
    try {
      final List<BoxModel> boxes = await _repository.fetchAll();
      emit(BoxLoaded(boxes));
    } on AppException catch (error) {
      emit(BoxError(message: error.message));
    } on Exception {
      emit(const BoxError(
        message: 'Une erreur inattendue est survenue lors du chargement.',
      ));
    }
  }

  Future<void> _onAddBoxRequested(
    AddBoxRequested event,
    Emitter<BoxState> emit,
  ) async {
    if (event.name.trim().isEmpty) {
      emit(BoxError(
        message: 'Le nom de la boîte ne peut pas être vide.',
        previousBoxes: _currentBoxes,
      ));
      return;
    }
    try {
      final BoxModel newBox = BoxModel.create(
        id: _uuid.v4(),
        name: event.name.trim(),
        icon: event.icon,
        color: event.color,
        groupId: event.groupId,
      );
      await _repository.insert(newBox);
      emit(BoxLoaded(<BoxModel>[newBox, ..._currentBoxes]));
    } on AppException catch (error) {
      emit(BoxError(message: error.message, previousBoxes: _currentBoxes));
    } on Exception {
      emit(BoxError(
        message: 'Impossible de créer la boîte.',
        previousBoxes: _currentBoxes,
      ));
    }
  }

  Future<void> _onUpdateBoxRequested(
    UpdateBoxRequested event,
    Emitter<BoxState> emit,
  ) async {
    final List<BoxModel> boxes = _currentBoxes;
    final int index = boxes.indexWhere((BoxModel box) => box.id == event.boxId);
    if (index == -1) {
      emit(BoxError(
        message: 'La boîte à modifier est introuvable.',
        previousBoxes: boxes,
      ));
      return;
    }
    if (event.name.trim().isEmpty) {
      emit(BoxError(
        message: 'Le nom de la boîte ne peut pas être vide.',
        previousBoxes: boxes,
      ));
      return;
    }
    try {
      final BoxModel updatedBox = boxes[index].copyWith(
        name: event.name.trim(),
        iconCodePoint: event.icon.codePoint,
        iconFontFamily: event.icon.fontFamily ?? 'MaterialIcons',
        iconFontPackage: event.icon.fontPackage,
        groupId: event.groupId,
        clearGroup: event.clearGroup,
      );
      final BoxModel finalBox = updatedBox.color == event.color
          ? updatedBox
          : updatedBox.withColor(event.color);
      await _repository.update(finalBox);
      final List<BoxModel> newBoxes = List<BoxModel>.from(boxes);
      newBoxes[index] = finalBox;
      emit(BoxLoaded(newBoxes));
    } on AppException catch (error) {
      emit(BoxError(message: error.message, previousBoxes: boxes));
    } on Exception {
      emit(BoxError(
        message: 'Impossible de mettre à jour la boîte.',
        previousBoxes: boxes,
      ));
    }
  }

  Future<void> _onChangeBoxColorRequested(
    ChangeBoxColorRequested event,
    Emitter<BoxState> emit,
  ) async {
    final List<BoxModel> boxes = _currentBoxes;
    final int index = boxes.indexWhere((BoxModel box) => box.id == event.boxId);
    if (index == -1) {
      emit(BoxError(
        message: 'La boîte est introuvable.',
        previousBoxes: boxes,
      ));
      return;
    }
    try {
      final BoxModel updatedBox = await _repository.changeColor(
        boxes[index],
        event.newColor,
      );
      final List<BoxModel> newBoxes = List<BoxModel>.from(boxes);
      newBoxes[index] = updatedBox;
      emit(BoxLoaded(newBoxes));
    } on AppException catch (error) {
      emit(BoxError(message: error.message, previousBoxes: boxes));
    } on Exception {
      emit(BoxError(
        message: 'Impossible de changer la couleur de la boîte.',
        previousBoxes: boxes,
      ));
    }
  }

  Future<void> _onDeleteBoxRequested(
    DeleteBoxRequested event,
    Emitter<BoxState> emit,
  ) async {
    final List<BoxModel> boxes = _currentBoxes;
    try {
      await _repository.delete(event.boxId);
      final List<BoxModel> newBoxes =
          boxes.where((BoxModel box) => box.id != event.boxId).toList();
      emit(BoxLoaded(newBoxes));
    } on AppException catch (error) {
      emit(BoxError(message: error.message, previousBoxes: boxes));
    } on Exception {
      emit(BoxError(
        message: 'Impossible de supprimer la boîte.',
        previousBoxes: boxes,
      ));
    }
  }
}
