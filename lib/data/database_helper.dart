import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'app_exceptions.dart';

/// Encapsule l'accès brut à la base de données SQLite locale.
///
/// Toute erreur d'initialisation est capturée et transformée en
/// [DatabaseAccessException] afin de ne jamais laisser fuiter
/// d'exceptions techniques vers les couches supérieures.
///
/// Remarque : cette implémentation cible Android/iOS via le plugin
/// `sqflite`. Pour un déploiement desktop ou web, il faudrait
/// substituer `sqflite_common_ffi` (desktop) ou
/// `sqflite_common_ffi_web` (web) au moment de l'initialisation.
class DatabaseHelper {
  DatabaseHelper._internal();

  static final DatabaseHelper instance = DatabaseHelper._internal();

  static const String _databaseName = 'organizer_app.db';
  static const int _databaseVersion = 1;

  static const String tableBoxes = 'boxes';
  static const String tableGroups = 'groups';

  Database? _database;

  Future<Database> get database async {
    final Database? existing = _database;
    if (existing != null) {
      return existing;
    }
    final Database created = await _initDatabase();
    _database = created;
    return created;
  }

  Future<Database> _initDatabase() async {
    try {
      final String databasesPath = await getDatabasesPath();
      final String path = p.join(databasesPath, _databaseName);
      return await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _onCreate,
      );
    } on Exception {
      throw const DatabaseAccessException(
        "Impossible d'initialiser la base de données locale.",
      );
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableGroups (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableBoxes (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon_code_point INTEGER NOT NULL,
        icon_font_family TEXT NOT NULL,
        icon_font_package TEXT,
        color TEXT NOT NULL,
        group_id TEXT,
        created_at TEXT NOT NULL,
        expires_at TEXT NOT NULL,
        FOREIGN KEY (group_id) REFERENCES $tableGroups (id)
          ON DELETE SET NULL
      )
    ''');
  }

  /// Ferme proprement la connexion (utile notamment pour les tests).
  Future<void> close() async {
    final Database? db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
