import 'package:sqflite/sqflite.dart';

import '../models/box_group_model.dart';
import 'app_exceptions.dart';
import 'database_helper.dart';

/// Fournit un accès de haut niveau aux groupes de boîtes.
class GroupRepository {
  final DatabaseHelper _databaseHelper;

  GroupRepository({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  Future<List<BoxGroupModel>> fetchAll() async {
    try {
      final Database db = await _databaseHelper.database;
      final List<Map<String, Object?>> rows = await db.query(
        DatabaseHelper.tableGroups,
        orderBy: 'created_at DESC',
      );
      return rows.map(BoxGroupModel.fromMap).toList(growable: false);
    } on DatabaseException {
      throw const DatabaseAccessException('Impossible de charger les groupes.');
    } on FormatException {
      throw const InvalidDataException(
        'Certains groupes enregistrés sont corrompus.',
      );
    }
  }

  Future<void> insert(BoxGroupModel group) async {
    try {
      final Database db = await _databaseHelper.database;
      await db.insert(
        DatabaseHelper.tableGroups,
        group.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } on DatabaseException {
      throw const DatabaseAccessException(
        "Impossible d'enregistrer le nouveau groupe.",
      );
    }
  }

  Future<void> update(BoxGroupModel group) async {
    try {
      final Database db = await _databaseHelper.database;
      final int updatedRows = await db.update(
        DatabaseHelper.tableGroups,
        group.toMap(),
        where: 'id = ?',
        whereArgs: <Object?>[group.id],
      );
      if (updatedRows == 0) {
        throw const NotFoundException('Le groupe à modifier est introuvable.');
      }
    } on DatabaseException {
      throw const DatabaseAccessException(
        'Impossible de mettre à jour le groupe.',
      );
    }
  }

  Future<void> delete(String groupId) async {
    try {
      final Database db = await _databaseHelper.database;
      final int deletedRows = await db.delete(
        DatabaseHelper.tableGroups,
        where: 'id = ?',
        whereArgs: <Object?>[groupId],
      );
      if (deletedRows == 0) {
        throw const NotFoundException(
          'Le groupe à supprimer est introuvable.',
        );
      }
    } on DatabaseException {
      throw const DatabaseAccessException(
        'Impossible de supprimer le groupe.',
      );
    }
  }
}
