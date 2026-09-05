import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../data/app_exceptions.dart';
import '../../data/box_repository.dart';
import '../../models/box_model.dart';
import '../../utils/notification_service.dart';
import 'box_event.dart';
import 'box_state.dart';

/// Gère l'ensemble du cycle de vie des lipos : chargement, création,
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
    on<ChangeBoxManualColorRequested>(_onChangeBoxManualColorRequested);
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
        message: 'Le nom de la lipo ne peut pas être vide.',
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
        customDuration:
            event.customDuration, // 1. Prise en compte de la durée saisie
      );

      await _repository.insert(newBox);

      // 2. Programmation de l'alarme de notification en arrière-plan
      await NotificationService.scheduleBoxExpiration(newBox);

      emit(BoxLoaded(<BoxModel>[newBox, ..._currentBoxes]));
    } on AppException catch (error) {
      emit(BoxError(message: error.message, previousBoxes: _currentBoxes));
    } on Exception {
      emit(BoxError(
        message: 'Impossible de créer la lipo.',
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
        message: 'La lipo à modifier est introuvable.',
        previousBoxes: boxes,
      ));
      return;
    }
    if (event.name.trim().isEmpty) {
      emit(BoxError(
        message: 'Le nom de la lipo ne peut pas être vide.',
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
        clearIconFontPackage: event.icon.fontPackage == null,
        groupId: event.groupId,
        clearGroup: event.clearGroup,
      );
      final BoxModel finalBox = updatedBox.color == event.color
          ? updatedBox
          : updatedBox.withColor(event.color);

      await _repository.update(finalBox);

      // Mise à jour de l'alarme système
      await NotificationService.cancelBoxNotification(finalBox.id);
      await NotificationService.scheduleBoxExpiration(finalBox);

      final List<BoxModel> newBoxes = List<BoxModel>.from(boxes);
      newBoxes[index] = finalBox;
      emit(BoxLoaded(newBoxes));
    } on AppException catch (error) {
      emit(BoxError(message: error.message, previousBoxes: boxes));
    } on Exception {
      emit(BoxError(
        message: 'Impossible de mettre à jour la lipo.',
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
        message: 'La lipo est introuvable.',
        previousBoxes: boxes,
      ));
      return;
    }
    try {
      final BoxModel updatedBox = await _repository.changeColor(
        boxes[index],
        event.newColor,
      );

      // Reprogrammation de l'alarme suite au changement de durée associé à la couleur
      await NotificationService.cancelBoxNotification(updatedBox.id);
      await NotificationService.scheduleBoxExpiration(updatedBox);

      final List<BoxModel> newBoxes = List<BoxModel>.from(boxes);
      newBoxes[index] = updatedBox;
      emit(BoxLoaded(newBoxes));
    } on AppException catch (error) {
      emit(BoxError(message: error.message, previousBoxes: boxes));
    } on Exception {
      emit(BoxError(
        message: 'Impossible de changer la couleur de la lipo.',
        previousBoxes: boxes,
      ));
    }
  }

  Future<void> _onChangeBoxManualColorRequested(
    ChangeBoxManualColorRequested event,
    Emitter<BoxState> emit,
  ) async {
    final List<BoxModel> boxes = _currentBoxes;
    final int index = boxes.indexWhere((BoxModel box) => box.id == event.boxId);
    if (index == -1) {
      emit(BoxError(
        message: 'La lipo est introuvable.',
        previousBoxes: boxes,
      ));
      return;
    }
    try {
      // Note : ceci ne modifie que la couleur affichée, pas le
      // chronomètre : aucune reprogrammation de notification n'est
      // donc nécessaire ici.
      final BoxModel updatedBox = await _repository.setManualColor(
        boxes[index],
        event.manualColor,
      );

      final List<BoxModel> newBoxes = List<BoxModel>.from(boxes);
      newBoxes[index] = updatedBox;
      emit(BoxLoaded(newBoxes));
    } on AppException catch (error) {
      emit(BoxError(message: error.message, previousBoxes: boxes));
    } on Exception {
      emit(BoxError(
        message: 'Impossible de changer la couleur de la lipo.',
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

      // Annulation de la notification programmée pour la lipo supprimée
      await NotificationService.cancelBoxNotification(event.boxId);

      final List<BoxModel> newBoxes =
          boxes.where((BoxModel box) => box.id != event.boxId).toList();
      emit(BoxLoaded(newBoxes));
    } on AppException catch (error) {
      emit(BoxError(message: error.message, previousBoxes: boxes));
    } on Exception {
      emit(BoxError(
        message: 'Impossible de supprimer la lipo.',
        previousBoxes: boxes,
      ));
    }
  }
}
