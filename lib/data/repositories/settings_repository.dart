import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../database/database_schema.dart';
import '../models/app_settings.dart';

class SettingsRepository {
  SettingsRepository({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  Future<AppSettings> getSettings() async {
    final Database db = await _database.database;
    final List<Map<String, Object?>> rows = await db.query(
      DatabaseSchema.appSettingsTable,
      where: 'settings_id = ?',
      whereArgs: <Object?>[1],
      limit: 1,
    );

    if (rows.isNotEmpty) {
      return AppSettings.fromMap(rows.first);
    }

    final AppSettings defaults = AppSettings.defaults();
    await saveSettings(defaults);
    return defaults;
  }

  Future<void> saveSettings(AppSettings settings) async {
    final Database db = await _database.database;
    await db.insert(
      DatabaseSchema.appSettingsTable,
      settings.copyWith(updatedAt: DateTime.now().toIso8601String()).toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
