import 'package:sqflite/sqflite.dart';

import '../models/box_color_type.dart';
import '../models/box_model.dart';
import 'app_exceptions.dart';
import 'database_helper.dart';
import 'network_info.dart';

/// Fournit un accès de haut niveau aux boîtes.
///
/// Encapsule la logique métier (calcul des dates d'expiration, etc.)
/// et traduit systématiquement les erreurs techniques bas-niveau en
/// [AppException] explicites, exploitables par les BLoC.
class BoxRepository {
  final DatabaseHelper _databaseHelper;
  final NetworkInfo _networkInfo;

  BoxRepository({
    DatabaseHelper? databaseHelper,
    NetworkInfo? networkInfo,
  })  : _databaseHelper = databaseHelper ?? DatabaseHelper.instance,
        _networkInfo = networkInfo ?? NetworkInfoImpl();

  Future<List<BoxModel>> fetchAll() async {
    try {
      final Database db = await _databaseHelper.database;
      final List<Map<String, Object?>> rows = await db.query(
        DatabaseHelper.tableBoxes,
        orderBy: 'created_at DESC',
      );
      return rows.map(BoxModel.fromMap).toList(growable: false);
    } on DatabaseException {
      throw const DatabaseAccessException('Impossible de charger les boîtes.');
    } on FormatException {
      throw const InvalidDataException(
        'Certaines boîtes enregistrées sont corrompues.',
      );
    }
  }

  Future<void> insert(BoxModel box) async {
    try {
      final Database db = await _databaseHelper.database;
      await db.insert(
        DatabaseHelper.tableBoxes,
        box.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } on DatabaseException {
      throw const DatabaseAccessException(
        "Impossible d'enregistrer la nouvelle boîte.",
      );
    }
  }

  Future<void> update(BoxModel box) async {
    try {
      final Database db = await _databaseHelper.database;
      final int updatedRows = await db.update(
        DatabaseHelper.tableBoxes,
        box.toMap(),
        where: 'id = ?',
        whereArgs: <Object?>[box.id],
      );
      if (updatedRows == 0) {
        throw const NotFoundException('La boîte à modifier est introuvable.');
      }
    } on DatabaseException {
      throw const DatabaseAccessException(
        'Impossible de mettre à jour la boîte.',
      );
    }
  }

  Future<void> delete(String boxId) async {
    try {
      final Database db = await _databaseHelper.database;
      final int deletedRows = await db.delete(
        DatabaseHelper.tableBoxes,
        where: 'id = ?',
        whereArgs: <Object?>[boxId],
      );
      if (deletedRows == 0) {
        throw const NotFoundException('La boîte à supprimer est introuvable.');
      }
    } on DatabaseException {
      throw const DatabaseAccessException('Impossible de supprimer la boîte.');
    }
  }

  /// Change la couleur d'une boîte et recalcule automatiquement sa
  /// date d'expiration en fonction de la nouvelle durée associée.
  Future<BoxModel> changeColor(BoxModel box, BoxColorType newColor) async {
    final BoxModel updated = box.withColor(newColor);
    await update(updated);
    return updated;
  }

  /// Détache toutes les boîtes d'un groupe (par exemple avant sa
  /// suppression) en les rendant "sans groupe" plutôt qu'en les
  /// supprimant : cela évite toute perte de données utilisateur.
  Future<void> detachFromGroup(String groupId) async {
    try {
      final Database db = await _databaseHelper.database;
      await db.update(
        DatabaseHelper.tableBoxes,
        <String, Object?>{'group_id': null},
        where: 'group_id = ?',
        whereArgs: <Object?>[groupId],
      );
    } on DatabaseException {
      throw const DatabaseAccessException(
        'Impossible de détacher les boîtes du groupe.',
      );
    }
  }

  /// Exemple d'opération nécessitant le réseau : synchronisation avec
  /// un service distant. Si aucune connexion n'est disponible, une
  /// [NoNetworkException] explicite est levée plutôt que de laisser
  /// l'application se bloquer silencieusement ou échouer sans message.
  ///
  /// L'application fonctionne entièrement hors-ligne (stockage local
  /// via sqflite) : cette méthode illustre comment le cas limite
  /// "absence de réseau" serait géré si une synchronisation distante
  /// était ajoutée (voir README.md, section "Évolutions futures").
  Future<void> syncWithRemote() async {
    final bool connected = await _networkInfo.isConnected;
    if (!connected) {
      throw const NoNetworkException(
        'La synchronisation nécessite une connexion internet.',
      );
    }
  }
}
