import 'package:sqflite/sqflite.dart';

import '../../core/progression.dart';
import '../database/app_database.dart';
import '../database/database_schema.dart';
import '../models/equipped_cosmetic.dart';
import '../models/game_session.dart';
import '../models/owned_cosmetic.dart';
import '../models/profile.dart';
import '../models/profile_item.dart';

class GameRepository {
  GameRepository({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  Future<Profile> createProfile({
    required int profileId,
    required String profileClass,
    String? createdAt,
  }) async {
    final Database db = await _database.database;
    final String timestamp = createdAt ?? DateTime.now().toIso8601String();

    return db.transaction<Profile>((Transaction txn) async {
      final int count =
          Sqflite.firstIntValue(
            await txn.rawQuery(
              'SELECT COUNT(*) FROM ${DatabaseSchema.profileTable}',
            ),
          ) ??
          0;

      if (count >= 3) {
        throw const DatabaseValidationException(
          'Cannot create more than 3 profiles.',
        );
      }

      final int insertedRows = await txn.rawInsert(
        '''
        INSERT INTO ${DatabaseSchema.profileTable} (
          profile_id,
          profile_class,
          profile_created_at
        )
        SELECT ?, ?, ?
        WHERE (SELECT COUNT(*) FROM ${DatabaseSchema.profileTable}) < 3
        ''',
        <Object?>[profileId, profileClass.toLowerCase(), timestamp],
      );

      // Critical 3-profile rule is enforced here and at the SQLite trigger level.
      if (insertedRows == 0) {
        throw const DatabaseValidationException(
          'Cannot create more than 3 profiles.',
        );
      }

      final List<Map<String, Object?>> rows = await txn.query(
        DatabaseSchema.profileTable,
        where: 'profile_id = ?',
        whereArgs: <Object?>[profileId],
        limit: 1,
      );

      if (rows.isEmpty) {
        throw const DatabaseValidationException(
          'Profile creation failed unexpectedly.',
        );
      }

      return Profile.fromMap(rows.first);
    });
  }

  Future<List<Profile>> getAllProfiles() async {
    final Database db = await _database.database;
    final List<Map<String, Object?>> rows = await db.query(
      DatabaseSchema.profileTable,
      orderBy: 'profile_id ASC',
    );

    return rows.map(Profile.fromMap).toList();
  }

  Future<Profile> completeFocusSession({
    required int profileId,
    required int durationMinutes,
    String sessionType = 'focus',
    String? startedAt,
    String? endedAt,
  }) async {
    _validateNonNegative(durationMinutes, 'duration_minutes');

    final Database db = await _database.database;
    final String endTimestamp = endedAt ?? DateTime.now().toIso8601String();
    final String startTimestamp = startedAt ?? endTimestamp;
    final SessionRewards rewards = progressionSystem.calculateSessionRewards(
      durationMinutes,
    );
    final int xpEarned = rewards.earnedXp;
    final int goldEarned = rewards.earnedGold;

    return db.transaction<Profile>((Transaction txn) async {
      final List<Map<String, Object?>> profileRows = await txn.query(
        DatabaseSchema.profileTable,
        where: 'profile_id = ?',
        whereArgs: <Object?>[profileId],
        limit: 1,
      );

      if (profileRows.isEmpty) {
        throw const DatabaseValidationException('Profile does not exist.');
      }

      final Profile currentProfile = Profile.fromMap(profileRows.first);
      final int nextXp = currentProfile.profileXp + xpEarned;
      final int nextLevel = progressionSystem.getLevelFromTotalXp(nextXp).level;

      await txn.insert(
        DatabaseSchema.sessionTable,
        GameSession(
          profileId: profileId,
          sessionType: sessionType,
          startedAt: startTimestamp,
          endedAt: endTimestamp,
          durationMinutes: durationMinutes,
          completed: true,
          xpEarned: xpEarned,
          goldEarned: goldEarned,
        ).toMap()..remove('session_id'),
      );

      await txn.update(
        DatabaseSchema.profileTable,
        <String, Object?>{
          'profile_xp': nextXp,
          'profile_level': nextLevel,
          'profile_gold': currentProfile.profileGold + goldEarned,
          'profile_last_played_at': endTimestamp,
          'profile_total_study_minutes':
              currentProfile.profileTotalStudyMinutes + durationMinutes,
          'profile_total_completed_sessions':
              currentProfile.profileTotalCompletedSessions + 1,
        },
        where: 'profile_id = ?',
        whereArgs: <Object?>[profileId],
      );

      final List<Map<String, Object?>> updatedRows = await txn.query(
        DatabaseSchema.profileTable,
        where: 'profile_id = ?',
        whereArgs: <Object?>[profileId],
        limit: 1,
      );

      return Profile.fromMap(updatedRows.first);
    });
  }

  Future<Profile?> getProfileById(int profileId) async {
    final Database db = await _database.database;
    final List<Map<String, Object?>> rows = await db.query(
      DatabaseSchema.profileTable,
      where: 'profile_id = ?',
      whereArgs: <Object?>[profileId],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return Profile.fromMap(rows.first);
  }

  Future<bool> deleteProfile(int profileId) async {
    final Database db = await _database.database;
    final int deletedCount = await db.delete(
      DatabaseSchema.profileTable,
      where: 'profile_id = ?',
      whereArgs: <Object?>[profileId],
    );
    return deletedCount > 0;
  }

  Future<int> insertSession(GameSession session) async {
    _validateNonNegative(session.durationMinutes, 'duration_minutes');
    _validateNonNegative(session.xpEarned, 'xp_earned');
    _validateNonNegative(session.goldEarned, 'gold_earned');

    final Database db = await _database.database;
    return db.insert(
      DatabaseSchema.sessionTable,
      session.toMap()..remove('session_id'),
    );
  }

  Future<List<GameSession>> getSessionsForProfile(int profileId) async {
    final Database db = await _database.database;
    final List<Map<String, Object?>> rows = await db.query(
      DatabaseSchema.sessionTable,
      where: 'profile_id = ?',
      whereArgs: <Object?>[profileId],
      orderBy: 'started_at DESC',
    );

    return rows.map(GameSession.fromMap).toList();
  }

  Future<List<GameSession>> getRecentSessionsForProfile({
    required int profileId,
    int limit = 10,
  }) async {
    final Database db = await _database.database;
    final List<Map<String, Object?>> rows = await db.query(
      DatabaseSchema.sessionTable,
      where: 'profile_id = ?',
      whereArgs: <Object?>[profileId],
      orderBy: 'started_at DESC',
      limit: limit,
    );

    return rows.map(GameSession.fromMap).toList();
  }

  Future<void> addItemToProfile({
    required int profileId,
    required int itemId,
    required int quantity,
  }) async {
    _validateNonNegative(quantity, 'quantity');

    final Database db = await _database.database;
    await db.transaction((Transaction txn) async {
      final List<Map<String, Object?>> existingRows = await txn.query(
        DatabaseSchema.profileItemTable,
        where: 'profile_id = ? AND item_id = ?',
        whereArgs: <Object?>[profileId, itemId],
        limit: 1,
      );

      if (existingRows.isEmpty) {
        await txn.insert(
          DatabaseSchema.profileItemTable,
          ProfileItem(
            profileId: profileId,
            itemId: itemId,
            quantity: quantity,
          ).toMap(),
        );
        return;
      }

      final int currentQuantity = existingRows.first['quantity'] as int;
      await txn.update(
        DatabaseSchema.profileItemTable,
        <String, Object?>{'quantity': currentQuantity + quantity},
        where: 'profile_id = ? AND item_id = ?',
        whereArgs: <Object?>[profileId, itemId],
      );
    });
  }

  Future<void> updateProfileItemQuantity({
    required int profileId,
    required int itemId,
    required int quantity,
  }) async {
    _validateNonNegative(quantity, 'quantity');

    final Database db = await _database.database;
    final int updated = await db.update(
      DatabaseSchema.profileItemTable,
      <String, Object?>{'quantity': quantity},
      where: 'profile_id = ? AND item_id = ?',
      whereArgs: <Object?>[profileId, itemId],
    );

    if (updated == 0) {
      throw const DatabaseValidationException(
        'Cannot update quantity for a missing profile item.',
      );
    }
  }

  Future<void> unlockCosmeticForProfile({
    required int profileId,
    required int cosmeticId,
    String? unlockedAt,
  }) async {
    final Database db = await _database.database;
    await db.insert(
      DatabaseSchema.ownedCosmeticsTable,
      OwnedCosmetic(
        profileId: profileId,
        cosmeticId: cosmeticId,
        unlockedAt: unlockedAt ?? DateTime.now().toIso8601String(),
      ).toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<List<OwnedCosmetic>> getOwnedCosmeticsForProfile(int profileId) async {
    final Database db = await _database.database;
    final List<Map<String, Object?>> rows = await db.query(
      DatabaseSchema.ownedCosmeticsTable,
      where: 'profile_id = ?',
      whereArgs: <Object?>[profileId],
      orderBy: 'unlocked_at DESC',
    );

    return rows.map(OwnedCosmetic.fromMap).toList();
  }

  Future<void> equipCosmetic({
    required int profileId,
    required String slotType,
    required int cosmeticId,
    String? equippedAt,
  }) async {
    final Database db = await _database.database;

    await db.transaction((Transaction txn) async {
      final bool isOwned = (await txn.query(
        DatabaseSchema.ownedCosmeticsTable,
        columns: <String>['profile_id'],
        where: 'profile_id = ? AND cosmetic_id = ?',
        whereArgs: <Object?>[profileId, cosmeticId],
        limit: 1,
      )).isNotEmpty;

      if (!isOwned) {
        throw const DatabaseValidationException(
          'Cannot equip a cosmetic that is not owned by the profile.',
        );
      }

      await txn.insert(
        DatabaseSchema.equippedCosmeticsTable,
        EquippedCosmetic(
          profileId: profileId,
          slotType: slotType,
          cosmeticId: cosmeticId,
          equippedAt: equippedAt ?? DateTime.now().toIso8601String(),
        ).toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<List<EquippedCosmetic>> getEquippedCosmeticsForProfile(
    int profileId,
  ) async {
    final Database db = await _database.database;
    final List<Map<String, Object?>> rows = await db.query(
      DatabaseSchema.equippedCosmeticsTable,
      where: 'profile_id = ?',
      whereArgs: <Object?>[profileId],
      orderBy: 'slot_type ASC',
    );

    return rows.map(EquippedCosmetic.fromMap).toList();
  }

  void _validateNonNegative(int value, String field) {
    if (value < 0) {
      throw DatabaseValidationException('$field cannot be negative.');
    }
  }
}

class DatabaseValidationException implements Exception {
  const DatabaseValidationException(this.message);

  final String message;

  @override
  String toString() => 'DatabaseValidationException: $message';
}
