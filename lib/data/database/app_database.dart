import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'database_schema.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  Database? _database;

  Future<Database> get database async {
    final Database? existing = _database;
    if (existing != null) {
      return existing;
    }

    _database = await _openDatabase();
    return _database!;
  }

  Future<Database> _openDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final databasePath = path.join(directory.path, DatabaseSchema.databaseName);

    return openDatabase(
      databasePath,
      version: DatabaseSchema.databaseVersion,
      onConfigure: (Database db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (Database db, int version) async {
        for (final String statement in DatabaseSchema.createStatements()) {
          await db.execute(statement);
        }

        for (final String statement in DatabaseSchema.seedStatements()) {
          await db.execute(statement);
        }
      },
    );
  }

  Future<void> close() async {
    final Database? existing = _database;
    if (existing == null) {
      return;
    }

    await existing.close();
    _database = null;
  }
}
